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
the accent hue). A theme may define extra color names and metrics and read them
in its looks with `Theme.color("name", fallback)` and
`Theme.metric("name", fallback)`. Assets placed next to `theme.json` load with
`Qt.resolvedUrl("../file.png")` from a look.

## Top-level keys

| Key | Default | Meaning |
| --- | --- | --- |
| `name` | `""` | Display name. |
| `description` | `""` | Short summary shown in the theme picker. |
| `accent` | `"#7a9cc6"` | Accent seed: a color, or `"wallpaper"` to take the hue from the current wallpaper. |
| `accentColor` | derived | Whether the theme follows the accent color setting; the theme picker marks such themes with "accent color". When left out it is true if a color is `"accent"` or an `{ "h", "s", "l" }` tone, or if `accent`, `highlight`, `primary`, `primaryContainer` or `buttonDefault` is left at its accent-based default. Set it to `false` when the theme's components ignore those colors. |
| `components` | `[]` | Component looks / effects provided in `components/`. |
| `barStyle` | `"full"` | Taskbar layout: `"full"` (an edge-to-edge strip) or `"pills"` (one floating pill per group: workspaces, media, notification area). The `barStyle` setting overrides it. |

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
| `barRadius` | 0 | Full-width edge bars (taskbar, lock / login bottom bar). |
| `spacingXs` / `spacingS` / `spacingM` / `spacingL` / `spacingXl` | 4 / 8 / 12 / 16 / 24 | Spacing scale (`spacingS` is also the avatar mat). |
| `barHeight` | 42 | Taskbar height and exclusive zone (plus `spacingS` with the `pills` bar style). |
| `shadowRoom` | 0 | Extra taskbar window height so a theme's shadow is not clipped. |
| `gap` | 8 | Gap between screen edge / bar and panels. |

## Fonts

| Token | Default | Used for |
| --- | --- | --- |
| `font` | `sans-serif` | UI text. |
| `iconFont` | `JetBrainsMono Nerd Font Propo` | Material Design glyphs. |
| `fontSmall` / `fontBody` / `fontTitle` / `fontHeadline` | 11 / 13 / 15 / 22 | Text scale. |
| `fontLarge` | 34 | Calendar clock. |
| `fontDisplay` | 112 | Lock / login clock. |
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
| `ActiveContent` (effect) | none; a `layer.effect` over an active Button's content (skipped when `restyleContent` is false, e.g. app icons) | None (content unchanged). |

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
theme: a key there wins over `theme.json`, which wins over the neutral defaults.
The login screen ignores this file and always uses the theme.

| Key | Default | Effect |
| --- | --- | --- |
| `scale` | 1 | UI scale: sizes, spacing, radii, fonts and icons. |
| `radius` | 1 | Corner radius factor (0 = square). |
| `spacing` | 1 | Spacing factor. |
| `barHeight` | theme (42) | Bar height in px (before UI scale). |
| `barStyle` | theme (`"full"`) | `"full"`: the bar is one strip across the top edge. `"pills"`: each group (workspaces and windows, media, notification area and clock) is its own floating pill, `spacingS` from the screen edges, drawn with the theme's `Surface` and `radiusLarge` (or `barRadius` if larger). Also in Settings > Layout > Bar style. |
| `barOpacity` | theme | Bar background opacity, 0..1. |
| `panelOpacity` | theme | Panel / dialog background opacity, 0..1. |
| `accent` | theme | `"wallpaper"` or `"#rrggbb"`. |
| `font` | theme | UI font family (Settings > Text lists the installed fonts). |
| `fontSize` | theme (13) | Base font size in px; the other sizes follow. |
| `iconSize` | 16 | Base icon size in px; the other icons follow. |
| `animationSpeed` | 1 | Animation speed factor (2 = twice as fast). |
| `reduceMotion` | false | Turn transitions off (spinners keep turning). |
| `avatarSize` | 112 | Lock screen avatar size in px. |
| `panelWidth` | 1 | Width factor of panels, dialogs and the lock card. |
| `dim` | 0.5 | Opacity of disabled / hint elements. |

The login screen does not read `settings.json` (it runs as the greeter user,
which cannot read your home); it always uses the theme.
