# ZariShell

A themeable desktop shell for Hyprland, built with [Quickshell](https://quickshell.org).

- Bar, workspaces, app launcher, window switcher and clipboard history
- Wi-Fi, Bluetooth, audio, brightness and media controls
- Notifications, calendar, system monitor and wallpaper picker
- Lock screen, polkit prompts and optional greetd login screen

Bundled themes: Aero (default), Base, Ink, Liquid Glass, Metro and Modern.

## Installation

Add the flake input:

```nix
inputs.zarishell = {
  url = "github:ZariTen/ZariShell";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Enable the shell in Home Manager:

```nix
imports = [ inputs.zarishell.homeManagerModules.default ];
programs.zarishell.enable = true;
```

For the optional NixOS login screen:

```nix
imports = [ inputs.zarishell.nixosModules.default ];
services.zarishell.greeter.enable = true;
```

Before using the lock screen, [configure PAM](docs/CONFIGURATION.md#lock-authentication).

## Documentation

- [Configuration](docs/CONFIGURATION.md): settings and system setup
- [Writing themes](docs/THEMES.md): tokens and components

## License

[MIT](LICENSE)
