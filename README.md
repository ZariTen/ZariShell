# ZariShell

A themeable desktop shell for Hyprland, built with [Quickshell](https://quickshell.org).
One shell, many looks, and a login screen to match.

## Features

- Bar with workspaces, media, tray, and clock, as a full strip or floating pills
- Quick settings for Wi-Fi, Bluetooth, volume, and brightness
- App launcher, window switcher, and clipboard history
- Notification center and toasts
- Media, calendar, and system monitor panels
- Lock screen, power menu, and polkit prompts
- Wallpaper picker with an accent color taken from the wallpaper
- Live theme switching and a settings panel, no restart needed
- Optional greetd login screen in the same style

## Themes

- **Aero** (default): tinted Windows 7 glass
- **Base**: flat, neutral slate
- **Ink**: black ink on warm paper
- **Liquid Glass**: frosted glass capsules
- **Metro**: Windows 8 tiles
- **Modern**: dark rounded islands with a soft glow

You can also write your own; see [docs/THEMES.md](docs/THEMES.md).

## Installation

Add the flake input:

```nix
inputs.zarishell = {
  url = "github:ZariTen/ZariShell";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Enable the shell with Home Manager:

```nix
imports = [ inputs.zarishell.homeManagerModules.default ];
programs.zarishell.enable = true;
```

Enable the login screen on NixOS (optional):

```nix
imports = [ inputs.zarishell.nixosModules.default ];
services.zarishell.greeter.enable = true;
```

## Configuration

Open the settings panel from quick settings, or bind it in Hyprland:

```
bind = SUPER, comma, exec, quickshell -c shell ipc call settings toggle
```

Changes apply live and are saved to `~/.config/zarishell/settings.json`, which
you can also edit by hand. For glass themes, enable Hyprland layer blur; see
[docs/THEMES.md](docs/THEMES.md#compositor-blur).

## License

[MIT](LICENSE)
