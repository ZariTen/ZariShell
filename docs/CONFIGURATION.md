# Configuration

For installation, see the [README](../README.md). This reference covers user
settings, runtime integration, the lock screen and the optional greetd greeter.
Theme authors should use [Writing themes](THEMES.md).

## User settings

Open the settings panel from quick settings, or bind it in Hyprland:

```ini
bind = SUPER, comma, exec, quickshell -c shell ipc call settings toggle
```

Changes apply live and are saved to
`${XDG_CONFIG_HOME:-~/.config}/zarishell/settings.json`. You can edit this flat
JSON object by hand; missing keys use their defaults. Invalid JSON is left
untouched, and panel changes are not saved until the file is fixed or deleted.

IPC examples use the default config name `shell`. If you change
`programs.zarishell.configName`, use that name instead.

## Settings keys

User settings are applied on top of the theme. Keys marked "theme" default to
the theme's value; the rest are the same in every theme.

| Key | Default | Effect |
| --- | --- | --- |
| `scale` | 1 | UI scale: sizes, spacing, radii, fonts and icons. |
| `radius` | 1 | Corner radius factor (0 = square). |
| `spacing` | 1 | Spacing factor. |
| `barHeight` | 42 | Bar height in px (before UI scale). |
| `barStyle` | `"full"` | `"full"`: one strip along the top edge. `"floating"`: one strip `barGap` from the top and sides, with rounded corners. `"pills"`: each group (workspaces and windows, media, notification area and clock) is its own floating pill, `barGap` from the screen edges. Floating strips and pills use the theme's `Surface` and `barRadius` (at least `radiusLarge`). Settings > Layout > Bar style. |
| `workspaceStyle` | `"dots"` | Workspace indicators: `"dots"` (default circles), `"numbers"` (workspace numbers or custom names), `"pills"` (horizontal capsules, elongated when active), or `"diamonds"`. Shape styles use hollow markers for empty workspaces and filled markers for occupied ones; the active workspace is highlighted, and urgent workspaces use the error color. Settings > Layout > Workspace style. Invalid values fall back to dots. |
| `barGap` | 8 | Gap in px between the screen edges and a floating bar or pills (before UI scale). Settings > Layout > Bar gap. |
| `barOpacity` | theme | Bar background opacity, 0..1. |
| `panelOpacity` | theme | Panel / dialog background opacity, 0..1. |
| `accent` | theme | `"wallpaper"` or `"#rrggbb"`. |
| `font` | theme | UI font family (Settings > Text lists the installed fonts). |
| `fontSize` | 13 | Base font size in px; the other sizes follow. |
| `iconSize` | 16 | Base icon size in px; the other icons follow. |
| `animationSpeed` | 1 | Animation speed factor (2 = twice as fast). |
| `clockFormat` / `dateFormat` / `longDateFormat` | `""` | Qt date/time patterns; empty uses locale short time, short date and long date. Shared by bar, calendar and lock. Greeter equivalents: `QS_GREETER_CLOCK_FORMAT`, `QS_GREETER_DATE_FORMAT`, `QS_GREETER_LONG_DATE_FORMAT`. Clocks update each minute, even if a custom format contains seconds. |
| `notificationTimeout` | 5000 | Default popup lifetime in ms (0–600000; 0 = persistent). Sender timeout -1 uses this default, 0 is persistent, and positive values are honored. Critical notifications remain persistent, including after hover. |
| `notificationHistoryLimit` / `notificationPopupLimit` | 50 / 4 | History cap (1–1000) and popup cap (0–20; 0 disables popups). Values are rounded and clamped; wrong types use defaults. |
| `diskMounts` | `["/", "$HOME"]` | Paths queried by the system monitor, defaulting to root and the actual home directory. Absolute, control-free path strings are passed as separate arguments; duplicates are removed. Invalid arrays use defaults; `[]` disables disk rows. Rows show actual mount points reported by df. |
| `useSystemdScope` | `"auto"` | Launcher scope mode: `"auto"` uses systemd scopes when systemd-run and a reachable user manager are available, otherwise launches directly; `false` bypasses systemd and `true` requires it. Applications are never retried after launching. Terminal entries retain desktop-entry execution. |
| `clipboardHistory` | true | Settings > Privacy > Clipboard history. Disabling stops history collection, queries and pasting, and drops the in-memory list. Existing cliphist database entries are not deleted. |
| `reduceMotion` | false | Turn transitions off (spinners keep turning). |
| `avatarSize` | 112 | Lock screen avatar size in px. |
| `panelWidth` | 1 | Width factor of panels, dialogs and the lock card. |
| `dim` | 0.5 | Opacity of disabled / hint elements. |
| `wifiDevice` | `""` | Prefer this discovered, usable Wi-Fi interface. Empty or invalid values select a connected adapter, then retain the current usable adapter or choose by interface name. |

The login screen does not read `settings.json` (it runs as the greeter user,
which cannot read your home); it uses the theme's looks and the defaults.

## Theme selection

User themes live in `${XDG_CONFIG_HOME:-~/.config}/zarishell/themes/<name>/`
and take precedence over packaged themes with the same name. The active theme
is the folder `${XDG_CONFIG_HOME:-~/.config}/zarishell/current` links to,
otherwise the theme named by `$ZARISHELL_THEME` (default `aero`). The login
screen uses the same themes.

Themes switch live from the settings panel or over IPC:

```sh
quickshell -c shell ipc call theme list
quickshell -c shell ipc call theme set base   # theme id or path to folder
quickshell -c shell ipc call theme next       # also: prev, current
quickshell -c shell ipc call theme reload     # rescan themes and reload QML looks
```

## Compositor blur

Glass looks only draw tint, rims and shadows; the frosting comes from
Hyprland's layer blur. The shell's layers use the namespaces `shell-bar`,
`shell-panel`, `shell-notification`, `shell-osd` and `shell-polkit`. Pixels at
or below `ignore_alpha` are not blurred, so keep panel alpha above it and
shadows below it (Liquid Glass wants `ignore_alpha = 0.2`). Example (Lua
config):

```lua
hl.layer_rule({ name = "shell", match = { namespace = "^shell-(bar|panel|notification|osd|polkit)$" },
    no_anim = true, ignore_alpha = 0.5, blur = true, blur_popups = true })
```

## Runtime integration

ZariShell targets Hyprland on Wayland. Wi-Fi uses NetworkManager's `nmcli`,
audio uses PipeWire, and session/power actions use Hyprland and systemd.
The launcher can bypass systemd scopes with `useSystemdScope`.

The Home Manager module supplies Bash, brightnessctl, cliphist, wl-clipboard,
coreutils, pciutils and getent on the shell service's PATH. If you override
`programs.zarishell.runtimePackages`, retain the tools used by enabled features.
The screenshot helper is installed by default; disable it with
`programs.zarishell.screenshot.enable = false`.

`nm-connection-editor` is an optional helper for editing saved Wi-Fi profiles
and credentials. Without it, use `nmcli` or another NetworkManager interface;
its absence does not prevent the shell from starting or connecting to networks.

Home Manager also exposes `wallpaperDir` and `wallpaper`, passed as
`ZARISHELL_WALLPAPER_DIR` and `ZARISHELL_WALLPAPER`. A wallpaper chosen in the
picker takes precedence over the configured default.

The Home Manager service has a package restart trigger: applying a new shell
package with Home Manager can restart Quickshell. Updating a flake lockfile
alone does not activate or restart it.

## Screenshot directory

`screenshot-region` saves to `ZARISHELL_SCREENSHOT_DIR` when set. Otherwise it
uses `$XDG_PICTURES_DIR/Screenshots`, or the Pictures directory from
`$XDG_CONFIG_HOME/user-dirs.dirs`, falling back to `$HOME/Pictures/Screenshots`.
The configuration is parsed as data (only a leading `$HOME`/`${HOME}` is expanded),
never sourced or evaluated as shell code.

## Translation readiness

Shell and greeter interface messages use extractable `qsTr()` literals, with
placeholders for dynamic content. Application/user content, commands and setting
keys are not translated. Quickshell 0.3.2 uses `QQmlEngine` and has no built-in
catalog loader: these annotations prepare translation sources, but do not load
`.qm` files or provide language packs. Setting `Qt.uiLanguage` alone is not a
translation loader.

## Greeter user discovery

The greeter enumerates accounts with NSS `getent passwd`, including directory
providers that support enumeration. `services.zarishell.greeter.minUid` /
`maxUid` (defaults 1000 / 60000) set the picker range and are exported as
`QS_GREETER_MIN_UID` / `QS_GREETER_MAX_UID`. Environment values outside
0–4294967294 or an inverted range fall back to defaults. Non-login shells are
excluded. Other user/manual login stays available when discovery fails or a
provider does not enumerate users. The lock screen resolves its displayed
identity with a keyed NSS lookup and falls back to the account name.

## Greeter session commands

`services.zarishell.greeter.sessionCommand` / `QS_GREETER_SESSION_COMMAND`
accepts single/double-quoted and backslash-escaped arguments, without shell
expansion. Detected desktop `Exec` lines use desktop-entry escaping: `%%` is a
literal percent; file/URL field codes are removed when no files are supplied.
`%c` expands the entry name, `%k` its desktop-file path, and standalone `%i`
expands to `--icon` plus the Icon value when present. Malformed
commands are skipped (an invalid configured fallback cannot start a session).
Greeter text options and cursor names reject ASCII control characters. Spaces,
quotes and shell metacharacters are passed literally; `stateDir` also preserves
literal percent signs in its tmpfiles rule.

## Lock authentication

The lock screen authenticates with the PAM service named by
`ZARISHELL_PAM_SERVICE`. Standalone launches keep `hyprlock` as the fallback
when that variable is unset or empty; the corresponding system PAM policy must
already exist. This does not require running the hyprlock program.

The Home Manager module exposes `programs.zarishell.pamService` (default
`"hyprlock"` for compatibility) and passes it to the Quickshell user service.
**Home Manager cannot install a system PAM policy.** To use a dedicated policy
on NixOS, set `programs.zarishell.pamService = "zarishell"` in Home Manager,
import the NixOS module and explicitly enable the policy in system configuration:

```nix
{
  imports = [ zarishell.nixosModules.default ];
  services.zarishell.pam.enable = true;
  # services.zarishell.pam.serviceName = "zarishell"; # default
}
```

This provisions `/etc/pam.d/zarishell` using NixOS's normal PAM policy, without
enabling or requiring `services.zarishell.greeter.enable`. For a custom service
name, set `services.zarishell.pam.serviceName` and
`programs.zarishell.pamService` to the same name. Standalone launches using this
dedicated policy must set `ZARISHELL_PAM_SERVICE=zarishell` (or the custom name).

Without this NixOS module, an administrator must provision
`/etc/pam.d/<service-name>` manually using the distribution's appropriate
screen-lock authentication policy, or select an already-provisioned policy
such as `hyprlock`. Do not use an allow-all PAM policy. A missing or unsuitable
policy can leave authentication unavailable after locking; provision it before
relying on the lock screen. These settings affect the session lock only, not
greetd login authentication.
