# Home Manager module: programs.zarishell
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.zarishell;
  zs = pkgs.callPackage ./packages.nix { };
in
{
  options.programs.zarishell = {
    enable = lib.mkEnableOption "ZariShell, an Aero-styled Quickshell desktop shell";

    package = lib.mkOption {
      type = lib.types.package;
      default = zs.shell;
      description = "Quickshell config directory for the shell.";
    };

    configName = lib.mkOption {
      type = lib.types.str;
      default = "shell";
      description = "Quickshell config name (`quickshell -c <name>`; used by IPC keybinds).";
    };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "hyprland-session.target";
      description = "systemd user target that starts the shell.";
    };

    wallpaperDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Pictures/Wallpapers";
      description = "Folder listed by the wallpaper picker.";
    };

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/me/Pictures/Wallpapers/space.png";
      description = "Default wallpaper path until one is picked (null = none).";
    };

    screenshot.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the `screenshot-region` helper.";
    };

    runtimePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [ brightnessctl cliphist wl-clipboard coreutils pciutils zs.nvml ];
      description = "Programs the shell's Process {} calls need on the service PATH (pciutils and zarishell-nvml name and read GPUs for the system monitor).";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [ brightnessctl cliphist libnotify grim slurp hyprpicker ];
      description = "Extra packages installed into home.packages alongside the shell.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional cfg.screenshot.enable zs.screenshot-region ++ cfg.extraPackages;

    programs.quickshell = {
      enable = true;
      systemd = {
        enable = true;
        target = cfg.systemdTarget;
      };
      activeConfig = cfg.configName;
      configs.${cfg.configName} = cfg.package;
    };

    systemd.user.services.quickshell = {
      # Restart on `home-manager switch` so QML edits take effect; otherwise the
      # running instance keeps the old store path.
      Unit.X-Restart-Triggers = [ "${cfg.package}" ];
      # User services don't get the login PATH; Process {} calls need these.
      Service.Environment = [
        "PATH=${lib.makeBinPath cfg.runtimePackages}:%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
        "ZARISHELL_WALLPAPER_DIR=${cfg.wallpaperDir}"
      ] ++ lib.optional (cfg.wallpaper != null) "ZARISHELL_WALLPAPER=${cfg.wallpaper}";
    };
  };
}
