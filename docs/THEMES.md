# Writing themes

This page is a reference for theme authors. A theme is a folder with a
`theme.json` and, optionally, QML looks for some components. Anything a theme
leaves out falls back to the neutral defaults below and the flat looks in
`shell/base/`, so an empty `{}` theme gives the plain base shell.

## Layout

```
themes/<name>/
  theme.json          tokens: name, accent, colors, metrics, fonts, motion,
                      and "components" (the looks this theme overrides)
  components/*.qml    optional looks for the components listed below
```

User themes live in `${XDG_CONFIG_HOME:-~/.config}/zarishell/themes/<name>/`
and take precedence over packaged themes with the same name. The active theme
is the folder `~/.config/zarishell/current` links to, otherwise the theme named
by `$ZARISHELL_THEME` (default `aero`). The login screen uses the same themes.

Themes switch live from the settings panel or over IPC:

```sh
quickshell -c shell ipc call theme list
quickshell -c shell ipc call theme set base   # theme id or path to folder
quickshell -c shell ipc call theme next       # also: prev, current
quickshell -c shell ipc call theme reload     # rescan themes and reload QML looks
```

## Values

Colors are `"#rrggbb"`, `"#aarrggbb"`, `"transparent"`, `[r, g, b, a]` (0..1),
`"accent"` or `{ "h", "s", "l", "a" }` (a tone whose hue is offset by `h` from
the accent hue). Tones are written against the theme's own `accent`; when the
accent setting picks another color, their saturation and lightness shift with
it, so a paler or darker accent gives paler or darker tones. A theme may define extra color names and metrics and read them
in its looks with `Theme.color("name", fallback)` and
`Theme.metric("name", fallback)`. Assets placed next to `theme.json` load with
`Qt.resolvedUrl("../file.png")` from a look.

## Top-level keys

| Key | Default | Meaning |
| --- | --- | --- |
| `name` | `""` | Display name. |
| `description` | `""` | A few words shown in the theme picker, next to a preview drawn from the theme's colors, radii, bar and font. |
| `accent` | `"#7a9cc6"` | Accent seed: a color, or `"wallpaper"` to take the hue from the current wallpaper. |
| `components` | `[]` | Component looks / effects provided in `components/`. |

## Colors

| Token | Neutral default | Used for |
| --- | --- | --- |
| `surface` | `#24282e` | Desktop color behind the wallpaper; base of backdrops. |
| `bar` | slate, a 0.92 | Taskbar and the lock / login bottom bars. |
| `panel` | slate, a 0.96 | Panels, dialogs, toasts, logon card. |
| `panelError` | red, a 0.94 | Critical toasts. |
| `accent` | `"accent"` | Accent icons and text. |
| `highlight` | `"accent"` | Hover, selection and active fills. |
| `primary` | `"accent"` | Filled controls (slider fill, round go button, orbs). |
| `textPrimary` | `#ffffff` | Text on `primary`. |
| `primaryContainer` | accent tone, a 0.9 | Picture-frame background, launcher selection. |
| `textPrimaryContainer` | `#ffffff` | Text on `primaryContainer`. |
| `surfaceContainer` | white a 0.08 | Cards inside panels. |
| `surfaceContainerHigh` | white a 0.14 | Raised cards. |
| `surfaceContainerHighest` | white a 0.12 | Picture-frame mats. |
| `inset` | black a 0.22 | Recessed wells (tracks, fields, trays). |
| `insetBorder` | black a 0.30 | Edge of recessed wells. |
| `border` | black a 0.35 | Outer 1px edge of controls, orbs and badges. |
| `borderLight` | white a 0.10 | Surface edge, picture edge. |
| `insetEdge` | white a 0.10 | Edge of framed bar trays. |
| `outline` | white a 0.45 | Focus rings and strong outlines. |
| `outlineVariant` | white a 0.16 | Subtle outlines. |
| `outlineFaint` | white a 0.08 | Notification cards, inner edge of the launcher list. |
| `divider` | white a 0.12 | Divider lines. |
| `dividerStrong` | white a 0.22 | Strong divider lines (bar edge, split tiles). |
| `textSurface` | `#ffffff` | Body text and icons. |
| `textSurfaceVariant` | white a 0.70 | Secondary text. |
| `textSoft` | white a 0.85 | Secondary display text (lock-screen date). |
| `textShadow` | `transparent` | Shadow under text (none when transparent). |
| `scrim` | black a 0.35 | Dim behind popups; base backdrop dim. |
| `scrimStrong` | black a 0.6 | Dim behind modal dialogs (polkit). |
| `backdrop` | `#000000` | Window color behind the lock / login backdrop. |
| `buttonDefault` | accent tone, a 0.63 | Fill of the default dialog button. |
| `badge` | `#d9463a` | Unread count badge. |
| `error` | `#ff6b5e` | Error text and icons. |
| `errorContainer` | `error` a 0.22 | Error banners. |
| `errorOutline` | `error` a 0.6 | Error banner edge. |
| `criticalContainer` | `error` a 0.3 | Critical notification cards. |
| `danger` | `error` | Destructive action icon (shut down). |
| `dangerHighlight` | `error` | Destructive action hover (shut down, restart). |
| `success` | `#7fd45a` | Success and "normal" meters. |
| `warning` | `#f2c94c` | Warnings and caps lock hint. |

## Metrics

| Token | Default | Used for |
| --- | --- | --- |
| `radiusSmall` | 3 | Small chips, bar cover art. |
| `radius` | 5 | Controls, cards, pictures inside frames. |
| `radiusLarge` | 8 | Panels and surfaces. |
| `radiusFull` | 999 | Pills and circles (clamped to half the size). |
| `radiusFrame` | 10 | Matted picture frames (avatars). |
| `barRadius` | 0 | Floating taskbar and bar pills (at least `radiusLarge`). Edge bars are square. |

Themes set looks, not sizes. Spacing (4 / 8 / 12 / 16 / 24), the panel gap
(8), the bar's height, style and gap, control sizes and font sizes are the same
in every theme and come from the settings below. The old geometry keys
(`spacingXs` … `spacingXl`, `barHeight`, `shadowRoom`, `gap`, `floatInset`,
top-level `barStyle`, and the font sizes `fontSmall` … `fontDisplay`) are
ignored if a theme still sets them.

## Fonts

| Token | Default | Used for |
| --- | --- | --- |
| `font` | `sans-serif` | UI text. |
| `iconFont` | `JetBrainsMono Nerd Font Propo` | Material Design glyphs. |
| `fontDisplayWeight` | 300 (Light) | Weight of the large clocks. |

## Motion

| Token | Default | Used for |
| --- | --- | --- |
| `durShort` / `durMedium` / `durLong` | 150 / 280 / 420 | Animation durations (ms). |
| `emphasized` / `standard` | M3 curves | Bezier easing curves. |

## Components

Each generic component lives in `shell/<Name>.qml`; its look is loaded from
`themes/<theme>/components/<Name>.qml` when the theme lists the name, else from
`shell/base/<Name>.qml`. A look reads its component as `control` (see
`shell/Button.qml` and `shell/base/Button.qml`).

| Component | Properties a look reads | Base look |
| --- | --- | --- |
| `Surface` | `radius`, `color`, `shadow`, `headerHeight` | Flat body with a `borderLight` edge. |
| `Button` | `active`, `framed`, `radius`, `tint`, `hovered`, `pressed`, `lit`, `level`, `restyleContent` | Faint fill when framed, tint wash on hover / active. |
| `Highlight` | `tint`, `level`, `bordered`, `radius` | Even tint wash, optional tinted edge. |
| `Switch` | `checked`, `hovered`, `pressed` | Pill track filled with `highlight` when on, round thumb. |
| `Slider` | `value`, `tone`, `interactive`, `hovered`, `pressed` | Inset track, solid fill colored by `tone`. |
| `Field` | `focused`, `prominent` | Inset well, accent edge when focused. |
| `Frame` | `padding`, `radius`, `innerRadius`, `color`, `bordered` | Nothing (drawn over the picture). |
| `Fill` | `color`, `radius`, `bordered`, `role` (`button`, `orb`, `badge`) | Solid shape. |
| `Backdrop` | `source`, `role` (`lock`, `login`) | Wallpaper (or `surface`) under `scrim`. |
| `Divider` | `strong` | `divider` / `dividerStrong` line. |
| `Glow` (effect) | none; a `layer.effect` for the lock / login clock | None (no effect). |
| `ActiveContent` (effect) | none; a `layer.effect` over an active Button's content (skipped when `restyleContent` is false, e.g. app icons; never applied to `plainContent`, e.g. theme previews) | None (content unchanged). |

`Frame` (mat Surface plus clipped picture), `Fill` and `Backdrop` are used by
the lock screen, login screen, bar and media panel; `Glow` is applied with
`Theme.effect("Glow")` and `ActiveContent` with `Theme.effect("ActiveContent")`;
each is skipped when the theme does not provide it.

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

## Settings keys

User settings in `~/.config/zarishell/settings.json` are applied on top of the
theme. Keys marked "theme" default to the theme's value; the rest are the same
in every theme. The login screen ignores this file and uses the defaults.

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
| `useSystemdScope` | `"auto"` | Launcher scope mode: `"auto"` uses systemd scopes when systemd-run and a reachable user manager are available, otherwise launches directly; `false` bypasses systemd and `true` requires it. Applications are never retried after launching. Terminal entries retain desktop-entry execution. |
| `clipboardHistory` | true | Settings > Privacy > Clipboard history. Disabling stops history collection, queries and pasting, and drops the in-memory list. Existing cliphist database entries are not deleted. |
| `reduceMotion` | false | Turn transitions off (spinners keep turning). |
| `avatarSize` | 112 | Lock screen avatar size in px. |
| `panelWidth` | 1 | Width factor of panels, dialogs and the lock card. |
| `dim` | 0.5 | Opacity of disabled / hint elements. |
| `wifiDevice` | `""` | Prefer this discovered, usable Wi-Fi interface. Empty or invalid values select a connected adapter, then retain the current usable adapter or choose by interface name. |

The login screen does not read `settings.json` (it runs as the greeter user,
which cannot read your home); it uses the theme's looks and the defaults.

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
