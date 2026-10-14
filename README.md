# ZariShell

A dark Windows 7 Aero styled desktop shell for Hyprland, written in native
[Quickshell](https://quickshell.org) QML, plus a matching greetd greeter.

```
shell/      desktop shell (bar, panels, notifications, lock screen, …)
greeter/    greetd greeter; Theme/Glass/AeroButton/MdIcon/StyledText are
            symlinks into shell/ so both share one look
nix/        packages.nix, hm-module.nix, nixos-module.nix, scripts/
flake.nix
```

## Theming

- `shell/Theme.qml`: colors, fonts, radii and motion for the shell **and** the greeter.
  The glass tint follows the wallpaper hue.
- `greeter/GreeterConfig.qml`: greeter behaviour. Values come from the NixOS module (env vars).

## Use with flakes

```nix
inputs.zarishell = {
  url = "github:ZariTen/ZariShell";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Home Manager (desktop shell):

```nix
imports = [ inputs.zarishell.homeManagerModules.default ];
programs.zarishell = {
  enable = true;
  wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";
  wallpaper = "${config.home.homeDirectory}/Pictures/Wallpapers/space.png";
};
```

Options: `enable`, `package`, `configName` (default `shell`, used by
`quickshell -c shell ipc call …` keybinds), `systemdTarget`
(`hyprland-session.target`), `wallpaperDir`, `wallpaper`, `screenshot.enable`,
`runtimePackages`, `extraPackages`.

NixOS (greeter):

```nix
imports = [ inputs.zarishell.nixosModules.default ];
services.zarishell.greeter.enable = true;
```

Options: `enable`, `quickshellPackage`, `wallpaper` (path or null),
`mainMonitor` (empty = auto), `sessionCommand` (`start-hyprland`), `sessionName`,
`hostLabel`, `stateDir` (`/var/lib/qs-greeter`), `cursor.{package,name,size}`,
`softwareCursor`.

The greeter runs Quickshell inside `cage` as the `greeter` user, lists users
with uid 1000–60000 and a login shell, remembers the last user/session and
detects sessions from the system's `wayland-sessions`. If it fails, switch to a
TTY with Ctrl+Alt+F2 and roll back (`nixos-rebuild switch --rollback`).

Packages: `shell`, `greeter`, `screenshot-region`.

## License

MIT, see `LICENSE`.
