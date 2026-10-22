# NixOS module: services.zarishell.greeter (greetd + cage + Quickshell).
{ config, lib, pkgs, ... }:
let
  cfg = config.services.zarishell.greeter;
  zs = pkgs.callPackage ./packages.nix { };
  greeterQml = zs.mkGreeter { inherit (cfg) wallpaper; };
  stateDir = cfg.stateDir;

  wrapper = pkgs.writeShellScript "zarishell-greeter" ''
    # Writable dirs for the greeter user (its home is /var/empty).
    export HOME=${stateDir}
    export XDG_CACHE_HOME=${stateDir}/cache
    export XDG_STATE_HOME=${stateDir}/state
    export XDG_CONFIG_HOME=${stateDir}/config
    export XDG_DATA_HOME=${stateDir}/data
    # pam_systemd normally provides /run/user/<uid>; fall back just in case.
    if [ -z "''${XDG_RUNTIME_DIR:-}" ] || [ ! -w "$XDG_RUNTIME_DIR" ]; then
      export XDG_RUNTIME_DIR=$(${pkgs.coreutils}/bin/mktemp -d /tmp/qs-greeter.XXXXXX)
    fi
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export XCURSOR_THEME=${cfg.cursor.name} XCURSOR_SIZE=${toString cfg.cursor.size}
    export XCURSOR_PATH=${cfg.cursor.package}/share/icons
    ${lib.optionalString cfg.softwareCursor ''
      # NVIDIA: wlroots software cursor avoids invisible-cursor issues.
      export WLR_NO_HARDWARE_CURSORS=1
    ''}
    export QS_GREETER_SESSIONS=${config.services.displayManager.sessionData.desktops}/share/wayland-sessions
    export QS_GREETER_STATE=${stateDir}
    export QS_GREETER_MAIN_MONITOR=${lib.escapeShellArg cfg.mainMonitor}
    export QS_GREETER_SESSION_COMMAND=${lib.escapeShellArg cfg.sessionCommand}
    export QS_GREETER_SESSION_NAME=${lib.escapeShellArg cfg.sessionName}
    export QS_GREETER_HOST_LABEL=${lib.escapeShellArg cfg.hostLabel}
    export PATH=${lib.makeBinPath [ pkgs.systemd pkgs.coreutils pkgs.bash ]}:$PATH
    exec ${pkgs.cage}/bin/cage -s -d -- ${cfg.quickshellPackage}/bin/quickshell -p ${greeterQml}
  '';
in
{
  options.services.zarishell.greeter = {
    enable = lib.mkEnableOption "the ZariShell greetd greeter (Quickshell in cage)";

    quickshellPackage = lib.mkPackageOption pkgs "quickshell" { };

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Image copied into the greeter (must be world-readable at build time). null = the theme's fallback background.";
    };

    mainMonitor = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "DP-1";
      description = "Output for the login card; empty = auto (external, most pixels, at 0,0).";
    };

    sessionCommand = lib.mkOption {
      type = lib.types.str;
      default = "start-hyprland";
      description = "Default session command (space-separated) when no .desktop session matches.";
    };

    sessionName = lib.mkOption {
      type = lib.types.str;
      default = "Hyprland";
      description = "Label for the fallback session.";
    };

    hostLabel = lib.mkOption {
      type = lib.types.str;
      default = "NixOS";
      description = "Text in the greeter's bottom bar.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/qs-greeter";
      description = "Writable greeter state (last user/session, Quickshell cache).";
    };

    cursor = {
      package = lib.mkOption { type = lib.types.package; default = pkgs.kdePackages.breeze; };
      name = lib.mkOption { type = lib.types.str; default = "breeze_cursors"; };
      size = lib.mkOption { type = lib.types.int; default = 24; };
    };

    softwareCursor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set WLR_NO_HARDWARE_CURSORS=1 (helps on NVIDIA).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      useTextGreeter = false;
      settings.default_session = {
        command = "${wrapper}";
        user = "greeter";
      };
    };

    systemd.tmpfiles.rules = [ "d ${stateDir} 0750 greeter greeter - -" ];

    # The greeter runs in the logind seat session greetd opens.
    users.users.greeter.extraGroups = [ "video" "input" ];
  };
}
