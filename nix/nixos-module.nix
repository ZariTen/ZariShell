# NixOS module: lock PAM policy and optional greetd greeter.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.zarishell.greeter;
  pamCfg = config.services.zarishell.pam;
  zs = pkgs.callPackage ./packages.nix { };
  greeterQml = zs.mkGreeter { inherit (cfg) wallpaper; };
  stateDir = cfg.stateDir;
  singleLine = lib.types.addCheck lib.types.str
    (value: builtins.match "[^[:cntrl:]]*" value != null);
  tmpfilesPath = "\"${lib.replaceStrings [ "\\" "\"" "%" ] [ "\\\\" "\\\"" "%%" ] stateDir}\"";

  wrapper = pkgs.writeShellScript "zarishell-greeter" ''
    # Writable dirs for the greeter user (its home is /var/empty).
    export HOME=${lib.escapeShellArg stateDir}
    export XDG_CACHE_HOME=${lib.escapeShellArg "${stateDir}/cache"}
    export XDG_STATE_HOME=${lib.escapeShellArg "${stateDir}/state"}
    export XDG_CONFIG_HOME=${lib.escapeShellArg "${stateDir}/config"}
    export XDG_DATA_HOME=${lib.escapeShellArg "${stateDir}/data"}
    # pam_systemd normally provides /run/user/<uid>; fall back just in case.
    if [ -z "''${XDG_RUNTIME_DIR:-}" ] || [ ! -w "$XDG_RUNTIME_DIR" ]; then
      export XDG_RUNTIME_DIR=$(${pkgs.coreutils}/bin/mktemp -d /tmp/qs-greeter.XXXXXX)
    fi
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export XCURSOR_THEME=${lib.escapeShellArg cfg.cursor.name} XCURSOR_SIZE=${lib.escapeShellArg (toString cfg.cursor.size)}
    export XCURSOR_PATH=${lib.escapeShellArg "${cfg.cursor.package}/share/icons"}
    ${lib.optionalString cfg.softwareCursor ''
      # NVIDIA: wlroots software cursor avoids invisible-cursor issues.
      export WLR_NO_HARDWARE_CURSORS=1
    ''}
    export QS_GREETER_SESSIONS=${lib.escapeShellArg "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"}
    export QS_GREETER_MIN_UID=${lib.escapeShellArg (toString cfg.minUid)}
    export QS_GREETER_MAX_UID=${lib.escapeShellArg (toString cfg.maxUid)}
    export QS_GREETER_STATE=${lib.escapeShellArg stateDir}
    export QS_GREETER_MAIN_MONITOR=${lib.escapeShellArg cfg.mainMonitor}
    export QS_GREETER_SESSION_COMMAND=${lib.escapeShellArg cfg.sessionCommand}
    export QS_GREETER_SESSION_NAME=${lib.escapeShellArg cfg.sessionName}
    export QS_GREETER_HOST_LABEL=${lib.escapeShellArg cfg.hostLabel}
    export PATH=${lib.escapeShellArg (lib.makeBinPath [ pkgs.systemd pkgs.coreutils pkgs.bash pkgs.getent ])}:"$PATH"
    exec ${lib.escapeShellArg "${pkgs.cage}/bin/cage"} -s -d -- ${lib.escapeShellArg "${cfg.quickshellPackage}/bin/quickshell"} -p ${lib.escapeShellArg (toString greeterQml)}
  '';
in
{
  options.services.zarishell.pam = {
    enable = lib.mkEnableOption "a dedicated PAM policy for the ZariShell lock screen";

    serviceName = lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9][A-Za-z0-9_.-]*";
      default = "zarishell";
      description = "PAM service to provision. Must match programs.zarishell.pamService in Home Manager or ZARISHELL_PAM_SERVICE for standalone use.";
    };
  };

  options.services.zarishell.greeter = {
    enable = lib.mkEnableOption "the ZariShell greetd greeter (Quickshell in cage)";

    quickshellPackage = lib.mkPackageOption pkgs "quickshell" { };

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Image copied into the greeter (must be world-readable at build time). null = the theme's fallback background.";
    };

    mainMonitor = lib.mkOption {
      type = singleLine;
      default = "";
      example = "DP-1";
      description = "Output for the login card; empty = auto (external, most pixels, at 0,0).";
    };

    minUid = lib.mkOption {
      type = lib.types.ints.between 0 4294967294;
      default = 1000;
      description = "Minimum UID shown in the NSS user picker (manual login is unrestricted).";
    };

    maxUid = lib.mkOption {
      type = lib.types.addCheck (lib.types.ints.between 0 4294967294) (value: value >= cfg.minUid);
      default = 60000;
      description = "Maximum UID shown in the NSS user picker; must not be below minUid.";
    };

    sessionCommand = lib.mkOption {
      type = singleLine;
      default = "start-hyprland";
      description = "Default session command when no .desktop session matches. Single/double quotes and backslash escapes group arguments; no shell expansion.";
    };

    sessionName = lib.mkOption {
      type = singleLine;
      default = "Hyprland";
      description = "Label for the fallback session.";
    };

    hostLabel = lib.mkOption {
      type = singleLine;
      default = "NixOS";
      description = "Text in the greeter's bottom bar.";
    };

    stateDir = lib.mkOption {
      type = singleLine;
      default = "/var/lib/qs-greeter";
      description = "Writable greeter state (last user/session, Quickshell cache).";
    };

    cursor = {
      package = lib.mkOption { type = lib.types.package; default = pkgs.kdePackages.breeze; };
      name = lib.mkOption { type = singleLine; default = "breeze_cursors"; };
      size = lib.mkOption { type = lib.types.int; default = 24; };
    };

    softwareCursor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set WLR_NO_HARDWARE_CURSORS=1 (helps on NVIDIA).";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf pamCfg.enable {
      security.pam.services.${pamCfg.serviceName} = { };
    })
    (lib.mkIf cfg.enable {
      services.greetd = {
        enable = true;
        useTextGreeter = false;
        settings.default_session = {
          command = "${wrapper}";
          user = "greeter";
        };
      };

      systemd.tmpfiles.rules = [ "d ${tmpfilesPath} 0750 greeter greeter - -" ];

      # The greeter runs in the logind seat session greetd opens.
      users.users.greeter.extraGroups = [ "video" "input" ];
    })
  ];
}
