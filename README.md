# ZariShell

A themeable desktop shell for Hyprland built with [Quickshell](https://quickshell.org), plus a matching
login screen. The shell code only draws neutral, flat parts; every look comes
from a theme. Six themes are bundled: Aero (tinted glass, the default), Base
(flat neutral slate), Ink (black ink on paper), Liquid Glass (Apple-style frosted
glass), Metro (Windows 8 tiles) and Modern (a Noctalia-style rice); see [Packaged themes](#packaged-themes).

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
screen):

```
themes/<name>/
  theme.json          tokens: name, accent, colors, metrics, fonts, motion,
                      and "components" (the looks this theme overrides)
  components/*.qml    optional looks for the components listed below
```

Themes are discovered from `${XDG_CONFIG_HOME:-~/.config}/zarishell/themes/<name>/theme.json`
(user themes, which take precedence on name collisions) and the packaged
`themes/<name>/theme.json` (`aero`, `base`, `ink`, `liquid`, `metro` and `modern`). The active theme is
`~/.config/zarishell/current` (a symlink to the active theme folder) when it
contains a `theme.json`, otherwise the theme named by `$ZARISHELL_THEME`
(default `aero`).

Switch themes live without restarting from the **Theme** tab in the settings
panel, or over IPC:

```sh
quickshell -c shell ipc call theme list
quickshell -c shell ipc call theme current
quickshell -c shell ipc call theme set base   # theme id or path to folder
quickshell -c shell ipc call theme next       # also: prev
quickshell -c shell ipc call theme reload     # rescan themes and reload QML looks
```

Switching updates `~/.config/zarishell/current` so the choice persists across
restarts.

User settings (see [Settings](#settings)) are applied on top of these tokens.
Any token a theme leaves out falls back to the neutral default shown below, and
any component it does not override uses the flat look in `shell/base/`. So an
empty `{}` theme gives the plain base shell: flat translucent slate, 1px
borders, no gloss, glow, blur or shadows.

Colors are `"#rrggbb"`, `"#aarrggbb"`, `"transparent"`, `[r, g, b, a]` (0..1),
`"accent"` or `{ "h", "s", "l", "a" }` (a tone whose hue is offset by `h` from
the accent hue). A theme may add its own extra color names and read them in its
components with `Theme.color("name", fallback)` (Aero uses `sheenTop`,
`sheenMid` and `badgeTop`; Ink `paper`; Liquid `glassFill`, `rimLight`, `rimShade`,
`innerGlow`, `sheenTop`, `sheenBottom`, `glassShadow`, `activeFill`, `activeGlyph` and `activeKnob`; Metro `tileHover` and `startScreen`;
Modern `glow` and `sheen`). Extra metrics work the same way with
`Theme.metric("name", fallback)` (Modern uses `floatInset`). A theme folder may
also carry its own assets next to `theme.json`; a look loads them with
`Qt.resolvedUrl("../file.png")` (Ink tiles `paper-grain.png`).

### Packaged themes

| Theme | Look | What it shows off | Overrides |
| --- | --- | --- | --- |
| `aero` | Windows 7 glass: translucent tinted panels, glossy sheen, soft glow. | Wallpaper accent, translucency, gloss. | Backdrop, Button, Field, Fill, Frame, Glow, Highlight, Slider, Surface, Switch |
| `base` | Flat neutral slate (no `components`). | The fallback looks in `shell/base/`. | none |
| `ink` | Black ink on warm paper: paper grain, hairline rules, raised sheets printed slightly out of register, ink underlines on buttons, brush-stroke dividers, ruler sliders with a diamond thumb, square ink switches, the wallpaper as a faded monochrome print on the lock / login screen. Serif type (Noto Serif). | A light theme (every text-on-color token checked for dark text), custom typography, a theme asset. | Backdrop, Button, Divider, Field, Fill, Frame, Glow, Highlight, Slider, Surface, Switch |
| `liquid` | Apple Liquid Glass: milky frosted capsules and circles with one thin bright rim (strongest top-left and bottom-right, visible all round) and a faint inner wash, white glyphs with a text shadow, solid white active states with dark gray glyphs (buttons, tiles, switches, slider fills), capsule sliders and switches whose thumb stretches when pressed, springy motion, a pill bar. Noto Sans. | A faint wallpaper accent, the ActiveContent effect, a theme-private helper (`GlassEdge.qml`, not listed in `components`, used by its sibling looks). Wants `ignore_alpha = 0.2` (see Compositor blur). | ActiveContent, Backdrop, Button, Field, Fill, Frame, Glow, Highlight, Slider, Surface, Switch |
| `metro` | Windows 8: opaque flat tiles, square corners, flyouts attached to the bar, a cobalt accent band on panels, light-weight Noto Sans for large text, rectangular switches, thin sliders, buttons that shrink when pressed. | Metrics (all radii and the gap 0), motion (fast decelerating slide / scale), one accent on a solid palette. | Backdrop, Button, Field, Highlight, Slider, Surface, Switch |
| `modern` | A Noctalia-style Hyprland rice: dark rounded islands with soft shadows, a floating pill bar, a pastel accent taken from the wallpaper, glowing orbs, thick gradient sliders, springy switches, a glowing lock clock. JetBrainsMono Nerd Font. | Wallpaper accent, large radii, the Glow effect, `shadowRoom`, overshooting motion curves. | Backdrop, Button, Divider, Field, Fill, Glow, Highlight, Slider, Surface, Switch |

Ink and Metro use fonts from `noto-fonts`; Modern uses
`nerd-fonts.jetbrains-mono` (already needed for the icons). Metro looks closest
to Windows 8 with Segoe UI (not packaged; Selawik is a free alternative):
install it and set the `font` setting to use it.
Liquid Glass uses Noto Sans; set the `font` setting to Inter or SF Pro if
installed for a closer match.

### Compositor blur

The glass looks (Aero, Liquid Glass, Modern) only draw tint, rims and shadows;
the frosting behind panels comes from Hyprland's layer blur. The shell's layers
use the namespaces `shell-bar`, `shell-panel`, `shell-notification`,
`shell-osd` and `shell-polkit`. Pixels at or below `ignore_alpha` are not
blurred, so themes keep panel alpha above it and shadows below it. Liquid Glass keeps
its clear glass at alpha 0.42-0.44, so use `ignore_alpha = 0.2` with it
(its shadows stay below that). A rule like
this (Lua config) enables it; a larger blur `size` and more `passes` in
`decoration.blur` give the softer, Liquid-Glass-like frosting (that setting is
global, so it also affects windows):

```lua
hl.layer_rule({ name = "shell", match = { namespace = "^shell-(bar|panel|notification|osd|polkit)$" },
    no_anim = true, ignore_alpha = 0.5, blur = true, blur_popups = true })
```

### Top-level keys

| Key | Default | Meaning |
| --- | --- | --- |
| `name` | `""` | Display name. |
| `description` | `""` | Short summary shown in the theme picker. |
| `accent` | `"#7a9cc6"` | Accent seed: a color, or `"wallpaper"` to take the hue from the current wallpaper. |
| `accentColor` | derived | Whether the theme follows the accent color setting; the theme picker marks such themes with "accent color". When left out it is true if a color is `"accent"` or an `{ "h", "s", "l" }` tone, or if `accent`, `highlight`, `primary`, `primaryContainer` or `buttonDefault` is left at its accent-based default. Set it to `false` when the theme's components ignore those colors. |
| `components` | `[]` | Component looks / effects provided in `components/`. |
| `barStyle` | `"full"` | Taskbar layout: `"full"` (an edge-to-edge strip) or `"pills"` (one floating pill per group: workspaces, media, notification area). The `barStyle` setting overrides it. |

### Colors

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

### Metrics

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

### Fonts

| Token | Default | Used for |
| --- | --- | --- |
| `font` | `sans-serif` | UI text. |
| `iconFont` | `JetBrainsMono Nerd Font Propo` | Material Design glyphs. |
| `fontSmall` / `fontBody` / `fontTitle` / `fontHeadline` | 11 / 13 / 15 / 22 | Text scale. |
| `fontLarge` | 34 | Calendar clock. |
| `fontDisplay` | 112 | Lock / login clock. |
| `fontDisplayWeight` | 300 (Light) | Weight of the large clocks. |

### Motion

| Token | Default | Used for |
| --- | --- | --- |
| `durShort` / `durMedium` / `durLong` | 150 / 280 / 420 | Animation durations (ms). |
| `emphasized` / `standard` | M3 curves | Bezier easing curves. |

### Components

Each generic component lives in `shell/<Name>.qml`; its look is loaded from
`themes/<theme>/components/<Name>.qml` when the theme lists the name, else from
`shell/base/<Name>.qml`. A look reads its component as `control` (see
`shell/Button.qml` and `themes/aero/components/Button.qml`).

| Component | Properties a look reads | Base look | Aero look |
| --- | --- | --- | --- |
| `Surface` | `radius`, `color`, `shadow`, `headerHeight` | Flat body with a `borderLight` edge. | Tinted glass with a sheen band, light inner edge and drop shadow. |
| `Button` | `active`, `framed`, `radius`, `tint`, `hovered`, `pressed`, `lit`, `level`, `restyleContent` | Faint fill when framed, tint wash on hover / active. | Glossy glass face with a hover glow. |
| `Highlight` | `tint`, `level`, `bordered`, `radius` | Even tint wash, optional tinted edge. | Tint rising from the bottom edge. |
| `Switch` | `checked`, `hovered`, `pressed` | Pill track filled with `highlight` when on, round thumb. | Glossy track and thumb. |
| `Slider` | `value`, `tone`, `interactive`, `hovered`, `pressed` | Inset track, solid fill colored by `tone`. | Glossy progress bar (green / amber / red / accent) with a round thumb. |
| `Field` | `focused`, `prominent` | Inset well, accent edge when focused. | Recessed well; prominent fields get an accent focus glow. |
| `Frame` | `padding`, `radius`, `innerRadius`, `color`, `bordered` | Nothing (drawn over the picture). | Glass reflection over the top of avatars and cover art. |
| `Fill` | `color`, `radius`, `bordered`, `role` (`button`, `orb`, `badge`) | Solid shape. | Glossy two-tone orb; badges use `badgeTop`. |
| `Backdrop` | `source`, `role` (`lock`, `login`) | Wallpaper (or `surface`) under `scrim`. | Blurred, darkened wallpaper under a vertical dim; gradient fallback on the login screen. |
| `Divider` | `strong` | `divider` / `dividerStrong` line. | (base) |
| `Glow` (effect) | none; a `layer.effect` for the lock / login clock | None (no effect). | Soft accent halo. |
| `ActiveContent` (effect) | none; a `layer.effect` over an active Button's content (skipped when `restyleContent` is false, e.g. app icons) | None (content unchanged). | (base); Liquid Glass turns it dark gray on the solid white face. |

`Frame` (mat Surface plus clipped picture), `Fill` and `Backdrop` are used by
the lock screen, login screen, bar and media panel; `Glow` is applied with
`Theme.effect("Glow")` and `ActiveContent` with `Theme.effect("ActiveContent")`;
each is skipped when the theme does not provide it.

## Settings

Open the settings panel from the slider icon in quick settings, or over IPC:

```sh
quickshell -c shell ipc call settings toggle        # also: open, close
quickshell -c shell ipc call settings set scale 1.2 # value is JSON
quickshell -c shell ipc call settings reset scale
```

A Hyprland bind could be `bind = SUPER, comma, exec, quickshell -c shell ipc call settings toggle`
(`shell` is the default `programs.zarishell.configName`).

Changes apply live and are saved to
`${XDG_CONFIG_HOME:-~/.config}/zarishell/settings.json`, a flat JSON object
that you may also edit by hand (edits apply live too). Precedence: a key in
`settings.json` wins over the theme's `theme.json`, which wins over the neutral
defaults. A missing key follows the theme; every row has a reset button and
every section a "Reset section" button, which remove the keys. Saving is
debounced; an invalid file is ignored (one warning) and never overwritten.
Nix does not manage this file.

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

## License

MIT
