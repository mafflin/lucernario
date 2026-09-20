# Kardia

A digital Garmin watch face: the time, centered, in the largest font the
screen allows.

## Requirements

- **Connect IQ SDK 8.1 or newer** (developed against 9.2.0). 8.1 is the first
  SDK whose simulator can drive the native (on-device) watch face editor,
  which is how this face is configured. The SDK version is selected in the
  Connect IQ SDK Manager, not in this project.
- Target API level is `5.1.0` (Connect IQ System 8), set in `manifest.xml`.
  This is separate from the SDK version above.

## Layout

| Path | Purpose |
| --- | --- |
| `source/KardiaApp.mc` | App entry point; detects the watch face editor at startup |
| `source/KardiaView.mc` | Owns the elements, applies configuration, clears the screen |
| `source/TimeDisplay.mc` | Formats and draws the time |
| `source/RimMarks.mc` | The twelve hour marks around the rim |
| `source/SecondsHand.mc` | The seconds hand sweeping the rim |
| `source/Dial.mc` | Ring geometry: where a value lands on the glass |
| `source/HandDrawer.mc` | Draws the arc shapes on the rim |
| `source/ClipRegion.mc` | The box a partial update may touch |
| `source/Styles.mc` | Style ids, mirroring `watchface.xml` |
| `source/FontFitter.mc` | Picks the largest font a screen can carry |
| `source/KardiaDelegate.mc` | Receives live edits from the native watch face editor |
| `resources/configs/watchface.xml` | Declares which settings the editor offers |

## Configuration

Settings use the native watch face editor (`Application.WatchFaceConfig`),
not Connect IQ app settings. Currently configurable:

- **Accent color** — the color of the time and seconds. Defaults to white.
- **Style** — `Time` (default) or `Time and Seconds`. The second style adds
  the hour marks and the seconds hand on the rim; they have no setting of
  their own. Style ids live in `source/Styles.mc` and must stay in step with
  `watchface.xml`.

The hand keeps sweeping in low power mode through
`KardiaView.onPartialUpdate()`: it clips to the pixels the hand is vacating,
puts the rim back there, then clips to where it is going and draws it. If that
costs more than the system allows, `onPowerBudgetExceeded` fires on the
delegate, partial updates are switched off, and the hand comes off the screen
while asleep rather than standing still.

The rim marks and the hand are lifted from the electric watch face, cut down
to hour marks only and one size for each.

`resources/configs/watchface.xml` declares what the editor shows.
`KardiaView.updateConfiguration()` applies it, and is called both at startup
(from `onLayout`) and on every edit (from `KardiaDelegate`).

## Testing the settings

The simulator's **Settings > Trigger App Settings** is for the older
`settings.xml` / `Application.Properties` path and will *not* show this
face's settings.

For the native editor, use the **Run Native Pairing** launch configuration in
`.vscode/launch.json` (`runNativePairing: true`), which requires SDK 8.1+.

Settings can also be driven directly from code with
`WatchFaceConfig.setSettings()`, which is useful for automated checks.

## Launcher icon

`assets/launcher_icon.svg` is the source of truth. The PNG the build consumes
is generated from it, recolored white (the SVG's own fill is black, which
would disappear against the device's dark app list):

```sh
sed 's|<path |<path fill="#FFFFFF" |' assets/launcher_icon.svg \
  | rsvg-convert -w 65 -h 65 -b none -o resources/drawables/launcher_icon.png
```

65x65 is what fenix847mm asks for. Devices that want another size scale the
image and emit a build warning; to silence one, drop a correctly sized copy in
`resources-<device>/drawables/`. Each device's required size is in the SDK at
`~/Library/Application Support/Garmin/ConnectIQ/Devices/<device>/compiler.json`
under `launcherIcon`.

## Font sizing

`FontFitter.largestFor(dc, text)` returns the largest font that can draw
`text` within the screen:

1. If the device supports vector fonts, binary search the largest size.
2. Otherwise walk a ladder of system fonts down from `FONT_NUMBER_THAI_HOT`.

On round displays the usable width is not the screen width but the chord
across the circle at the text box's corners, which `usableWidthAt()` accounts
for.

`TimeDisplay` sizes against `widestTime()` rather than the current time, so
the layout never jumps between minutes. Both that string and the rendered time
come from `_TIME_FORMAT`, so changing the format automatically resizes the
font.

When the rim is shown the time is fitted with an inset of `Dial.ringDepth`,
keeping it clear of the marks and the hand. It is therefore sized again
whenever the style changes, which `onUpdate` does on the next draw.
