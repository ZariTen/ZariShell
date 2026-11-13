# Writing themes

A theme is a folder containing `theme.json` and optional QML components:

```text
themes/<name>/
  theme.json
  components/<Name>.qml
```

Put user themes in `${XDG_CONFIG_HOME:-~/.config}/zarishell/themes/<name>/`.
Missing tokens and components use the defaults in
[`shell/Theme.qml`](../shell/Theme.qml) and [`shell/base/`](../shell/base/).
An empty `{}` gives the flat Base look.

## theme.json

```json
{
  "name": "My theme",
  "description": "A short description",
  "accent": "#7a9cc6",
  "colors": { "panel": "#24282e", "textSurface": "#ffffff" },
  "metrics": { "radius": 5 },
  "fonts": { "font": "sans-serif" },
  "components": ["Button"]
}
```

List only components you supply. `accent` accepts a color or `"wallpaper"`.

## Colors

Color values accept `"#rrggbb"`, `"#aarrggbb"`, `"transparent"`, `[r, g, b, a]`
(channels 0–1), or `"accent"`. Use `{ "h": 0, "s": 0.4, "l": 0.5, "a": 1 }`
for accent-relative tones: `h` offsets the hue; saturation and lightness follow
accent overrides.

| Group | Tokens |
| --- | --- |
| Backgrounds | `surface`, `bar`, `panel`, `panelError`, `backdrop` |
| Accent and selection | `accent`, `highlight`, `primary`, `primaryContainer`, `buttonDefault` |
| Containers | `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest` |
| Recessed areas | `inset`, `insetBorder`, `insetEdge` |
| Borders and lines | `border`, `borderLight`, `outline`, `outlineVariant`, `outlineFaint`, `divider`, `dividerStrong` |
| Text | `textSurface`, `textSurfaceVariant`, `textPrimary`, `textPrimaryContainer`, `textSoft`, `textShadow` |
| Overlays | `scrim`, `scrimStrong`, `badge` |
| Status | `error`, `errorContainer`, `errorOutline`, `criticalContainer`, `danger`, `dangerHighlight`, `success`, `warning` |

## Shape, fonts and motion

| Section | Tokens |
| --- | --- |
| `metrics` | `radiusSmall`, `radius`, `radiusLarge`, `radiusFull`, `radiusFrame`, `barRadius` |
| `fonts` | `font`, `iconFont`, `fontDisplayWeight` |
| `motion` | `durShort`, `durMedium`, `durLong` (ms); `emphasized`, `standard` (Bezier curves) |

Sizes, spacing and bar layout come from
[user settings](CONFIGURATION.md#settings-keys), not theme tokens.

## Components

Each look reads the generic component through `control`.

| Component | Properties |
| --- | --- |
| `Surface` | `radius`, `color`, `shadow`, `headerHeight` |
| `Button` | `active`, `framed`, `radius`, `tint`, `hovered`, `pressed`, `lit`, `level`, `restyleContent` |
| `Highlight` | `tint`, `level`, `bordered`, `radius` |
| `Switch` | `checked`, `hovered`, `pressed` |
| `Slider` | `value`, `tone`, `interactive`, `hovered`, `pressed` |
| `Field` | `focused`, `prominent` |
| `Frame` | `padding`, `radius`, `innerRadius`, `color`, `bordered` |
| `Fill` | `color`, `radius`, `bordered`, `role` (`button`, `orb`, `badge`) |
| `Backdrop` | `source`, `role` (`lock`, `login`) |
| `Divider` | `strong` |

Optional effects: `Glow` for clocks and `ActiveContent` for active button content.
`restyleContent: false` skips `ActiveContent`; `plainContent` is never restyled.
See the [bundled themes](../themes/) for working examples.

Read custom tokens with `Theme.color("name", fallback)` or
`Theme.metric("name", fallback)`. Load assets relative to a component with
`Qt.resolvedUrl("../file.png")`.

For [theme selection](CONFIGURATION.md#theme-selection) and
[Hyprland blur](CONFIGURATION.md#compositor-blur), see the configuration guide.
