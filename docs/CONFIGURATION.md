# Configuration

Open settings from quick settings, or bind it in Hyprland:

```ini
bind = SUPER, comma, exec, quickshell -c shell ipc call settings toggle
```

Settings save to `${XDG_CONFIG_HOME:-~/.config}/zarishell/settings.json` and apply
live. You can edit the JSON directly; missing keys use defaults. Invalid JSON
is left untouched and blocks saving. The greeter does not read this file.

## Settings keys

Sizes are in pixels before UI scaling. "Theme" means the active theme's value.

| Key | Default | Purpose |
| --- | --- | --- |
| `scale` | 1 | Overall UI scale. |
| `radius` | 1 | Corner radius multiplier; 0 makes corners square. |
| `spacing` | 1 | Spacing multiplier. |
| `barHeight` | 42 | Bar height. |
| `barStyle` | `"full"` | `"full"`, `"floating"` or `"pills"`. |
| `workspaceStyle` | `"dots"` | `"dots"`, `"numbers"`, `"pills"` or `"diamonds"`. |
| `barGap` | 8 | Floating bar's distance from screen edges. |
| `barOpacity` / `panelOpacity` | Theme | Background opacity, 0–1. |
| `accent` | Theme | `"wallpaper"` or `"#rrggbb"`. |
| `font` | Theme | Font family. |
| `fontSize` / `iconSize` | 13 / 16 | Base text and icon sizes. |
| `animationSpeed` | 1 | Animation multiplier; 2 is twice as fast. |
| `reduceMotion` | false | Disable transitions; spinners still run. |
| `avatarSize` | 112 | Lock-screen avatar size. |
| `panelWidth` | 1 | Panel width multiplier. |
| `dim` | 0.5 | Dimmed-item opacity factor. |
| `clockFormat` / `dateFormat` / `longDateFormat` | `""` | Qt format patterns; empty uses the locale. Clocks update each minute. |
| `notificationTimeout` | 5000 | Default popup duration in ms; 0 keeps it visible. Sender timeouts take precedence; critical popups stay visible. |
| `notificationHistoryLimit` / `notificationPopupLimit` | 50 / 4 | History and popup caps; popup limit 0 hides popups. |
| `diskMounts` | Root and home | Absolute paths to monitor; `[]` hides disk rows. |
| `useSystemdScope` | `"auto"` | Auto-detect systemd scopes; `false` bypasses them, `true` requires them. |
| `clipboardHistory` | true | Enable collection and history access. Disabling does not delete stored entries. |
| `wifiDevice` | `""` | Preferred Wi-Fi interface; empty selects automatically. |

## Launcher calculator

Type arithmetic such as `2 + 2` directly in the launcher. Prefix functions or
unit conversions with `=`, for example `= sqrt(81)` or `= 10 km to mi`.
The result appears above application matches; press Enter or click it to copy.

This uses Qalculate's `qalc`, included in the Home Manager runtime defaults.
Standalone installations and custom `runtimePackages` need `libqalculate` and
`coreutils` on PATH. Exchange-rate updates are disabled; currency conversions
may use older locally available rates.

## Theme selection

User themes go in `${XDG_CONFIG_HOME:-~/.config}/zarishell/themes/<name>/`.
Choose one in settings, or use IPC:

```sh
quickshell -c shell ipc call theme list
quickshell -c shell ipc call theme set aero
```

Other theme commands: `next`, `prev`, `current`, `reload`. IPC examples assume
`programs.zarishell.configName = "shell"`.

## Compositor blur

Enable Hyprland layer blur for glass themes. Example Lua rule:

```lua
hl.layer_rule({ name = "shell", match = { namespace = "^shell-(bar|panel|notification|osd|polkit)$" },
    no_anim = true, ignore_alpha = 0.5, blur = true, blur_popups = true })
```

Use `ignore_alpha = 0.2` for Liquid Glass. Keep surface opacity above this
threshold so Hyprland blurs it.

## System setup

Wi-Fi requires NetworkManager; audio uses PipeWire. The Home Manager module
provides the shell's command-line helpers. If you override `runtimePackages`,
keep the tools needed by your enabled features.

`nm-connection-editor` is optional for repairing saved Wi-Fi profiles. You can
use `nmcli` instead. Updating the shell package through Home Manager can restart
Quickshell; updating the lockfile alone does not.

| Environment variable | Purpose |
| --- | --- |
| `ZARISHELL_THEME` | Packaged fallback theme; default `aero`. |
| `ZARISHELL_WALLPAPER_DIR` / `ZARISHELL_WALLPAPER` | Wallpaper folder and default image; also exposed as Home Manager options `wallpaperDir` / `wallpaper`. |
| `ZARISHELL_SCREENSHOT_DIR` | Screenshot folder; otherwise uses XDG Pictures/Screenshots, then `$HOME/Pictures/Screenshots`. |
| `QS_GREETER_CLOCK_FORMAT` / `QS_GREETER_DATE_FORMAT` / `QS_GREETER_LONG_DATE_FORMAT` | Greeter date/time patterns. |

The wallpaper picker overrides the default image. Disable the screenshot helper
with `programs.zarishell.screenshot.enable = false`.

## Greeter

NixOS options live under `services.zarishell.greeter`:

- `sessionCommand`: fallback command; default `start-hyprland`. Quoted arguments
  work, but shell expansion does not.
- `minUid` / `maxUid`: user-picker range; defaults 1000 / 60000. Standalone
  equivalents: `QS_GREETER_MIN_UID` / `QS_GREETER_MAX_UID`.

Users come from NSS. Manual username entry remains available for unlisted users.

## Lock authentication

The lock screen defaults to the `hyprlock` PAM service. **Provision that policy
before locking**, or authentication may be unavailable. Home Manager cannot
create system PAM policies.

For a dedicated policy on NixOS:

```nix
# NixOS
imports = [ inputs.zarishell.nixosModules.default ];
services.zarishell.pam.enable = true;
```

```nix
# Home Manager
programs.zarishell.pamService = "zarishell";
```

For custom names, match `services.zarishell.pam.serviceName` with
`programs.zarishell.pamService`. Standalone launches use `ZARISHELL_PAM_SERVICE`.
Other distributions must provide a suitable PAM policy themselves. This is
separate from greetd login authentication.

## Translations

Strings are marked for translation, but Quickshell 0.3.2 has no catalog loader.
Language packs are not supported yet.
