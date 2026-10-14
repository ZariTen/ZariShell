# ZariShell

A dark Windows 7 Aero style desktop shell for Hyprland, built with [Quickshell](https://quickshell.org), plus a matching login screen.

## Install

Add it to your flake:

```nix
inputs.zarishell = {
  url = "github:ZariTen/ZariShell";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Shell (Home Manager):

```nix
imports = [ inputs.zarishell.homeManagerModules.default ];
programs.zarishell.enable = true;
```

Login screen (NixOS):

```nix
imports = [ inputs.zarishell.nixosModules.default ];
services.zarishell.greeter.enable = true;
```

## Theming

Edit `shell/Theme.qml`. It styles both the shell and the login screen.

## License

MIT
