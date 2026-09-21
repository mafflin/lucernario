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
- The product list is exactly the devices that support
  `Application.WatchFaceConfig`, which is the whole configuration model and is
  itself API 5.1.0. Anything older cannot run this face at all: adding a
  pre-System-8 device to the list makes it fail to load rather than fall back.
  The authoritative list is the Supported Devices section of the
  [WatchFaceConfig docs](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/WatchFaceConfig.html).

## Layout

| Path | Purpose |
| --- | --- |
| `source/KardiaApp.mc` | App entry point; detects the watch face editor at startup |
| `source/KardiaView.mc` | Owns the elements, applies configuration, clears the screen |
| `source/TimeDisplay.mc` | Formats and draws the time |
| `source/ComplicationField.mc` | The data container; a Drawable so the editor can pulse it |
| `source/FieldLocation.mc` | The container slot id, mirroring `watchface.xml` |
| `source/ComplicationFormat.mc` | Turns a complication's raw value into readable text |
| `source/StatusBar.mc` | The row of status icons above the time |
| `source/Icon.mc` | One status icon; `Battery`/`Phone`/`Alarm`/`Wind`/`Meridiem` extend it |
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

- **Style** — `Dark` (default) or `Light`. The editor has no background
  setting, so the style id is what carries it; `source/Styles.mc` decodes it.
  Ids must stay in step with `watchface.xml`.
- **Accent color** — the seconds hand, the one thing meant to stand apart.
- **Data color** — everything else: the time, the hour marks, the status
  icons and the data container.

Both offer the same thirty named colors, declared explicitly in
`watchface.xml` rather than with `allowAny`: the editor wants a label per
color, and with `allowAny` the fēnix 8 Solar filled its picker with garbled
entries. The list is the electric watch face's, where every channel is 00,
55, AA or FF — the 64 color MIP palette — so none of them dither on those
screens. Black is added for the light style.
- **Data container** — one complication slot centered below the time. The
  types it offers are listed one by one in `watchface.xml` rather than opened
  up with `allowAny`, which keeps the picker to what reads well in a slot this
  size; the cost is that complications published by other Connect IQ apps are
  not offered at all. Its slot id lives in `source/FieldLocation.mc` and must
  stay in step with `watchface.xml`. It defaults to the weekday and the date,
  named twice: `default="true"` in `watchface.xml` is what the editor offers,
  and the type handed to `ComplicationField` in `KardiaView` is what the slot
  holds until the editor has said anything at all. Requires the
  `ComplicationSubscriber` permission.

The container is placed off `TimeDisplay.inkBottomIn()` rather than a fixed
height, so it follows the time wherever it ends up on a given screen.

The system hands over a raw value and almost never formats it, so
`ComplicationFormat` does. Most types are a count that `Complication.unit`
finishes off, but some need more: sunrise and sunset are a time of day (19:13,
not 69238) and recovery time is a duration, both carried in seconds. The
current temperature arrives in Celsius however the watch is set, with the
`UNIT_TEMPERATURE` enum rather than a string for a unit, so it is converted
against `temperatureUnits` and shown in whole degrees with a degree mark. The
sea level pressure arrives in pascals, six figures wide, and is shown in bars
to three decimals, which is what it takes for weather to move the number at
all; the `BAR` label carries the unit, and `DeviceSettings` has no pressure
unit to follow in any case. The altitude is meters however the watch is set, and is
converted against `elevationUnits` and shown in whole meters or feet; the
weekly run and bike distances are meters too, converted against
`distanceUnits` and shown to a tenth of a kilometer or mile. The battery, the
pulse ox and the solar input are percentages that arrive as a bare number, so
they are given the sign. The
high and low is the one type the system formats itself, as a string along the
lines of "H 21 / L 12" and with no mark on either number; the mark goes in
after each of them. Anything else falls through to value plus unit.

The container draws a short label in front of the value. The system's own
`shortLabel` and `longLabel` run long enough to overflow the slot, so
`source/ComplicationLabel.mc` carries a four character name per type instead,
one case per type offered in `watchface.xml`; the types whose value already
reads as what it is, like the date and the training status, get none.

A complication type above the face's `minApiLevel` cannot be offered at all,
because naming the symbol is what fails rather than reaching it. A `switch`
walks its case labels until one matches, so a case for a type the watch has
never heard of is evaluated on every type the table does not know, and brings
the watch down with a Symbol Not Found error - which is an error rather than
an exception, so the `try` in `ComplicationField.refresh()` cannot catch it.
`COMPLICATION_TYPE_SLEEP_SCORE` is API 6.0.2 against this face's floor of
5.1.0 and is left out for that reason; every type the face does offer is API
4.2.0.

There are no pictograms to use instead: `Complication.getIcon()` is documented
as working only for user complications, meaning ones published by other
Connect IQ apps, and returns null for the built-in types.

Left unset, both fall back to whatever reads against the style's background:
white on the dark style, black on the light one. A color the user has chosen
is kept as it is when the style changes.

The hand keeps sweeping in low power mode through
`KardiaView.onPartialUpdate()`: it clips to the pixels the hand is vacating,
puts the rim back there, then clips to where it is going and draws it. If that
costs more than the system allows, `onPowerBudgetExceeded` fires on the
delegate, partial updates are switched off, and the hand comes off the screen
while asleep rather than standing still.

The rim marks, the hand and the status bar are lifted from the electric watch
face. The marks are hour marks only at one size, the hand is one size, and the
row carries battery, phone, alarm, wind and AM/PM with the cat,
notifications, do not disturb and GPS icons left behind. The wind is
electric's too, where it is a triangle standing on the rim; here it is one
arrow in the row, turned to the bearing with an `AffineTransform` passed to
`drawBitmap2`, with the strength said in color: the data color up to 20 km/h,
orange above that, red above 40. None of them have a setting: each icon
shows whenever the thing it reports is worth reporting.

The icon artwork is white on transparent, so it is drawn with `drawBitmap2`
and tinted to the accent color; untinted it would be invisible on the light
style. The battery overrides that for its two lowest levels, which stay red
and orange.

Icons come in two sizes, 24px in `resources/` and 36px in
`resources-large-icons/`, selected by the `resourcePath` lines in
`monkey.jungle`.

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
   `FontFitter.VECTOR_FACES` is the face preference, `RobotoRegular` first;
   `getVectorFont` answers with the first of them the device carries.
2. Otherwise walk a ladder of system fonts down from `FONT_NUMBER_THAI_HOT`.

On round displays the usable width is not the screen width but the chord
across the circle at the text box's corners, which `usableWidthAt()` accounts
for.

`TimeDisplay` sizes against `widestTime()` rather than the current time, so
the layout never jumps between minutes. Both that string and the rendered time
come from `_TIME_FORMAT`, so changing the format automatically resizes the
font.

The time is fitted with an inset of `Dial.ringDepth`, keeping it clear of the
marks and the hand on the rim.
