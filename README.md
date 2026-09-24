# Lucernario

A digital Garmin watch face: the time, centered, in the largest numeric font
the system has.

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

Sources are grouped by the part of the face they draw. The compiler picks up
every `.mc` under `source/`, so a new file goes in whichever folder fits.

| Path | Purpose |
| --- | --- |
| `source/app/LucernarioApp.mc` | App entry point; detects the watch face editor at startup |
| `source/app/LucernarioView.mc` | Owns the elements, applies configuration, clears the screen |
| `source/app/LucernarioDelegate.mc` | Receives live edits from the native watch face editor |
| `source/app/Palette.mc` | The colors the code names, in step with `watchface.xml` |
| `source/app/Styles.mc` | Style ids, mirroring `watchface.xml`, and the colors each implies |
| `source/time/TimeDisplay.mc` | Formats and draws the time |
| `source/time/Clock.mc` | Clock units and the 12/24 hour rule, shared by everything that shows a time |
| `source/time/Fonts.mc` | Measures the ink height of a font |
| `source/time/MinuteGate.mc` | Lets a reading refresh once a minute |
| `source/time/Daylight.mc` | Today's sunrise and sunset, off the complications |
| `source/time/ActivityTimer.mc` | Whether an activity is under way, for the system indicator over the 24 |
| `source/rim/Dial.mc` | Ring geometry: where a value lands on the glass |
| `source/rim/RimPainter.mc` | Draws the shapes on the rim |
| `source/rim/DayColors.mc` | The rim's colors: amber from sunrise to sunset, sky blue after, shaded to the style |
| `source/rim/RimMarks.mc` | The hour marks and four minor marks between each |
| `source/rim/RimNumerals.mc` | 24, 4, 8, 12, 16 and 20, turned like the marks, against their inner ends |
| `source/rim/HourHand.mc` | The hour hand, a mark twice as wide as the hour marks and a third longer |
| `source/rim/WindBearing.mc` | The wind as a triangle standing on the rim at its bearing, on the Dark Complicated style |
| `source/rim/SecondsHand.mc` | The seconds hand, an arrow pointing out, clear of the marks |
| `source/rim/ClipRegion.mc` | The box a partial update may touch |
| `source/status/StatusBar.mc` | The row of status icons above the time |
| `source/status/WindReading.mc` | The wind's bearing and strength, shared by the row's arrow and the dial |
| `source/status/Icon.mc` | One status icon; `Battery`/`Phone`/`Alarm`/`Wind`/`Meridiem` extend it |
| `source/complications/ComplicationField.mc` | The data container; a Drawable so the editor can pulse it |
| `source/complications/FieldLocation.mc` | The container slot id, mirroring `watchface.xml` |
| `source/complications/ComplicationLabel.mc` | A short name per complication type |
| `source/complications/ComplicationFormat.mc` | Turns a complication's raw value into readable text |
| `resources/configs/watchface.xml` | Declares which settings the editor offers |

## Configuration

Settings use the native watch face editor (`Application.WatchFaceConfig`),
not Connect IQ app settings. Currently configurable:

- **Style** — `Dark` (default), `Light`, or `Dark Complicated`, which
  moves the wind out of the status row and onto the dial. The editor has no background
  setting, so the style id is what carries it; `source/app/Styles.mc` decodes it.
  Ids must stay in step with `watchface.xml`.
- **Accent color** — the hour and seconds hands, and the wind bearing in a
  light wind: the things meant to stand apart.
- **Data color** — the time, the status icons and the data container, and
  the rim marks and numerals until the sun is known.
- **Data container** — one complication slot centered below the time. The
  types it offers are listed one by one in `watchface.xml` rather than opened
  up with `allowAny`, which keeps the picker to what reads well in a slot this
  size; the cost is that complications published by other Connect IQ apps are
  not offered at all. Its slot id lives in `source/complications/FieldLocation.mc` and must
  stay in step with `watchface.xml`. It defaults to the weekday and the date,
  named twice: `default="true"` in `watchface.xml` is what the editor offers,
  and the type handed to `ComplicationField` in `LucernarioView` is what the slot
  holds until the editor has said anything at all. Requires the
  `ComplicationSubscriber` permission.

Both colors offer the same thirty named colors, declared explicitly in
`watchface.xml` rather than with `allowAny`: the editor wants a label per
color, and with `allowAny` the fēnix 8 Solar filled its picker with garbled
entries. Every channel is 00, 55, AA or FF — the 64 color MIP palette — so
none of them dither on those screens. Black is there for the light style.

Left unset, both fall back to whatever reads against the style's background:
white on the dark style, black on the light one. A color the user has chosen
is kept as it is when the style changes.

The color of the rim marks and numerals is not configurable: amber from the
exact minute the sun rises to the minute it sets and sky blue the rest of the
day — Amber and Sky on the dark style, Dark Amber and Dark Sky on the light
one — from the sunrise and sunset complications, the same numbers the data
container shows. Each mark and numeral takes the color of the moment it
stands for. Until the sun is known they are drawn in the data color.

The container's top sits at 66% of the screen height. The status row mirrors
it: the row's bottom sits as far from the top of the screen as the
container's top is from the bottom, lifted by a twenty second of the height to even the pair up by eye,
so the two frame the time on every screen.

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
`source/complications/ComplicationLabel.mc` carries a four character name per type instead,
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

The seconds hand keeps sweeping in low power mode through
`LucernarioView.onPartialUpdate()`: it clips to the pixels the hand is vacating,
puts the rim back there, then clips to where it is going and draws it. The
hand is an arrow set in far enough that even the corners of its clip box
stay off the marks, round pen ends included, so a tick never repaints
them: only the numeral nearest the hand's last position, the status row, the
wind bearing and the hour hand, both of which reach past the marks, and only
when the box has cut into them. If that
costs more than the system allows, `onPowerBudgetExceeded` fires on the
delegate, partial updates are switched off, and the hand comes off the screen
while asleep rather than standing still.

The rim marks and the hour hand are drawn as lines running inward from the
rim, with the width as a pen width in pixels. An arc cannot be made narrow
enough: `drawArc` takes its span in degrees and the renderer works in whole
ones, so every width from one degree to two comes out as the same mark. A
pixel at the rim is roughly a quarter of a degree, which is a useful step on
a shape this small. The pen is round, so a line runs half its width past each
end; every clearance and clip box counts that in.

The rim is 24 hour marks with four thin minor marks between each pair, one
every twelve minutes, and the numerals 24, 4, 8, 12, 16 and 20 against the
inner ends of their marks.

While an activity is under way the system draws its own indicator at the top
of the screen, over the 24, so the 24 is left off then. `ActivityTimer` reads
that off `Activity.Info.timerState`, which not every watch hands a watch
face; where it does not, the 24 stays. The stopwatch has no API at all and
is not covered.

The status row carries battery, phone, alarm, wind and AM/PM. The wind is one
arrow in the row, pointing downwind (the bearing is where the wind comes from,
so a southerly, 180, points up), with the strength said in color: the
data color up to 20 km/h, orange above that, red above 40. None of them have
a setting: each icon shows whenever the thing it reports is worth reporting.

On the `Dark Complicated` style the wind leaves the row for the dial: an
equilateral triangle the size of the seconds hand, standing on the rim at
the bearing the wind blows from and pointing the way it blows, north at the
top. It takes the accent color in a light wind and the same orange and red
above that. It reaches past the marks, so a partial update puts it back when
the seconds hand's clip cuts into it, as it does the hour hand.

The icon artwork is white on transparent, so it is drawn with `drawBitmap2`
and tinted to the data color; untinted it would be invisible on the light
style. The battery overrides that for its two lowest levels, which stay red
and orange.

The wind is the one item with no artwork: `Wind.paint()` overrides
`Icon.paint()` and fills three corners it turns itself. A bitmap cannot be
turned without the bilinear filter, the filter makes part opaque pixels out
of an arrow that had none, and a MIP panel cannot composite those - it keeps
or drops each one as it draws, so the tail used to thicken and thin with the
bearing. Corners turned in code have nothing to sample, and they are smoothed
by the same `setAntiAlias` the rim marks rely on. It has no bitmap to measure
either, so `StatusBar.draw()` hands it the square the battery is running at.

Icons come in two sizes, 24px in `resources/` and 36px in
`resources-large-icons/`, selected by the `resourcePath` lines in
`monkey.jungle`. Both are generated from `assets/icons/`; see Icon artwork
below.

`resources/configs/watchface.xml` declares what the editor shows.
`LucernarioView.updateConfiguration()` applies it, and is called both at startup
(from `onLayout`) and on every edit (from `LucernarioDelegate`).

## Testing the settings

The simulator's **Settings > Trigger App Settings** is for the older
`settings.xml` / `Application.Properties` path and will *not* show this
face's settings.

For the native editor, use the **Run Native Pairing** launch configuration in
`.vscode/launch.json` (`runNativePairing: true`), which requires SDK 8.1+.

Settings can also be driven directly from code with
`WatchFaceConfig.setSettings()`, which is useful for automated checks.

## Icon artwork

`assets/icons/*.svg` is the source of truth for every icon, the launcher
included. The PNGs the build consumes are generated from them by

```sh
sh assets/generate-icons.sh
```

which needs `rsvg-convert` (librsvg) and `python3`. Each path is refilled
white on the way through, because the SVGs are black on transparent: the
status icons are
tinted at draw time and would be invisible untinted on the dark style, and the
launcher icon sits in the device's dark app list.

The status icons render at 24px into `resources/` and 36px into
`resources-large-icons/`. AM and PM are the exception: their art is 18 units
by 10 inside the same 24 unit box, so rendering it square would leave two
small letters in a lot of space. The script crops the box to the letters and
pads it back out, which is where their 33x21 and 49x30 come from.

The 24px set is also flattened, by `assets/flatten-alpha.py`: every pixel
comes out either opaque or clear, with nothing in between. That set is what
the MIP devices get, and a MIP panel holds 64 colours and cannot composite,
so the eight bit alpha channel `packingFormat="png"` preserves is no use to
it - the watch reduces the edges to on or off as it draws them, and it does a
poor job. The alarm's ring broke apart and the AM/PM stems came out 3px and
4px alternately. Deciding at generation time instead means the artwork that
ships is the artwork that appears. The cutoff and the reasoning behind it are
at the top of the script.

Flattening is why the small AM/PM box is `1 5 22 14` at scale 1.5 rather than
a box cropped tight to the letters. Every edge in those two glyphs sits on an
odd unit, so from an odd origin at that scale all five stems land on whole
pixels and come out 3px. The 36px set is not flattened - AMOLED screens do
composite, and their soft edges are the reason they look right - so its box is
left cropped to the ratio.

`direction.svg` is no longer rendered: the wind arrow is drawn rather than
placed, for the reason above. The file stays as the drawing its corners were
taken off.

The launcher icon is 65x65, which is what fenix847mm asks for. Devices that
want another size scale the image and emit a build warning; to silence one, drop a correctly sized copy in
`resources-<device>/drawables/`. Each device's required size is in the SDK at
`~/Library/Application Support/Garmin/ConnectIQ/Devices/<device>/compiler.json`
under `launcherIcon`.

## Fonts

The time is drawn in `FONT_NUMBER_THAI_HOT`, the largest numeric system font,
which Garmin sizes per device. The rim numerals are turned to follow the
marks, which takes a vector font and `drawAngledText`: the first of a few
Roboto and Swiss 721 faces the watch carries, at 80% of `FONT_TINY`'s height.
A watch without them draws the numerals upright in `FONT_TINY` itself.
Nothing is fitted at runtime.

`Fonts.inkHeightOf(dc, font)` is the height of the glyphs rather than the font
box: digits stand on the baseline, so the descent the font reserves is empty
space. It is what centers the rim numerals' digits in their stretch of the
ring.

## License

Copyright (c) 2026 Siarhei Ivanouski. Released under the MIT License; see
[LICENSE](LICENSE).
