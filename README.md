# ZariShell

A Windows 7 Aero style desktop shell for Hyprland, built with [Quickshell](https://quickshell.org), plus a matching login screen.

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

A theme is a folder under `themes/` (shared by the shell and the login
screen). Aero is the first one and the default.

```
themes/<name>/
  theme.json          tokens: accent, colors, metrics, fonts, motion
  components/*.qml    optional looks for Button, Field, Highlight, Slider,
                      Surface, Switch (list them in theme.json "components")
```

Any token a theme leaves out falls back to a neutral default, and any
component it does not override uses the flat look in `shell/base/`. Colors are
`"#rrggbb"`, `"#aarrggbb"`, `[r, g, b, a]`, `"accent"` or
`{ "h", "s", "l", "a" }` (a tone relative to the accent hue). `"accent"` is
`"wallpaper"` (hue taken from the wallpaper) or a color. A component look reads
its generic component as `control` (see `shell/Button.qml` and
`themes/aero/components/Button.qml`).

The active theme is `~/.config/zarishell/current` (for example a symlink to a
theme folder) when it contains a `theme.json`, otherwise the packaged theme
named by `$ZARISHELL_THEME` (default `aero`).

## License

MIT
