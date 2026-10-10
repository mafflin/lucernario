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
Everything but `source/rim/` (and `Styles`, `ActivityTimer` and `Fonts`, which
serve it) is shared with Cerchio and kept the same.

| Path | Purpose |
| --- | --- |
| `source/app/LucernarioApp.mc` | App entry point; detects the watch face editor at startup |
| `source/app/LucernarioView.mc` | Owns the elements; draws the face off screen once a minute and the seconds over it |
| `source/app/LucernarioDelegate.mc` | Receives live edits and the power budget notice |
| `source/app/Editor.mc` | Applies the editor's settings; answers what to pulse and what was tapped |
| `source/app/FaceBuffer.mc` | The off screen face, and whether it is current |
| `source/app/Styles.mc` | Style ids, mirroring `watchface.xml`: whether the rim has numerals |
| `source/app/Palette.mc` | The colors the code names |
| `source/app/Numbers.mc` | Smaller, larger, and whether a value falls in a span round a circle |
| `source/app/CurrentWeather.mc` | The weather the phone last sent, and the m/s to km/h factor |
| `source/time/TimeDisplay.mc` | Formats and draws the time |
| `source/time/Clock.mc` | Clock units, minutes of the day and the 12/24 hour rule |
| `source/time/MinuteGate.mc` | Lets a reading refresh once a minute |
| `source/time/GoalProgress.mc` | Progress to the day's steps goal |
| `source/time/ActivityTimer.mc` | Whether an activity is under way, for the system indicator over the 12 |
| `source/time/Fonts.mc` | Measures the ink height of a font |
| `source/sun/Sun.mc` | The one shared `Daylight` |
| `source/sun/Daylight.mc` | Sunrise and sunset off the complications, solar noon, dawn and dusk |
| `source/sun/Twilight.mc` | Civil dawn and dusk (the sun 6° down), from the latitude and the date |
| `source/sun/Latitude.mc` | The latitude, from the weather's location or the last fix |
| `source/rim/Dial.mc` | Ring geometry: where a value lands on the glass |
| `source/rim/RimPainter.mc` | Draws the shapes on the rim |
| `source/rim/DayColors.mc` | The rim's colors: amber from sunrise to sunset, sky blue after |
| `source/rim/RimMarks.mc` | The hour marks and three minor marks between each |
| `source/rim/RimNumerals.mc` | 12, 16, 20, 24, 4 and 8, turned like the marks, against their inner ends; off on Plain |
| `source/rim/HourHand.mc` | The hour hand, a rhombus: the seconds hand's arrow at 5° across to its 8° and mirrored inward, the outer tip on the minor marks' tips, in the rim's colors inverted |
| `source/rim/GoalHand.mc` | The goal hand, a ring just inside the hour marks, solid once the goal is done |
| `source/rim/SecondsHand.mc` | The seconds hand, an arrow pointing out inside the marks |
| `source/status/StatusBar.mc` | The row of status icons above the time |
| `source/status/Icon.mc` | A tinted bitmap; `Battery`/`Phone`/`Alarm`/`Recovery`/`Wind`/`Meridiem` extend it, and the fields use it |
| `source/status/WindReading.mc` | The wind's bearing, calm and strength, for the row's wind icon |
| `source/status/IconText.mc` | An icon and its digits on one line, for the data fields |
| `source/complications/DataFields.mc` | The two fields side by side, centered as one, and their live updates |
| `source/complications/ComplicationField.mc` | One field; a Drawable so the editor can pulse it |
| `source/complications/FieldKinds.mc` | The kind and icon each complication type is shown with |
| `source/complications/FieldKind.mc` | How a field shows a type; `*Kind.mc` format their own |
| `source/complications/WeatherIcon.mc` | The weather's conditions as one icon, a moon at night |
| `source/complications/ValueFormat.mc` | What the kinds format with |
| `source/complications/ComplicationReader.mc` | Reads a complication, null on a watch that throws for it |
| `source/complications/SlotId.mc` | The editor's slot ids, mirroring `watchface.xml` |
| `resources/configs/watchface.xml` | Declares which settings the editor offers |

## Configuration

Settings use the native watch face editor (`Application.WatchFaceConfig`),
not Connect IQ app settings. Currently configurable:

- **Style** — `Numerals` (default) or `Plain`, named for what the rim
  carries. The only difference is the rim numerals: `Numerals` has them,
  `Plain` leaves them off. The background is always black.
  `source/app/Styles.mc` decodes the id. Ids must stay in step with
  `watchface.xml`.
- **Accent color** — the seconds, hour and goal hands; the hour hand only
  until the sun is known.
- **Data color** — the time, the status icons and the data fields, and the
  rim marks and numerals until the sun is known.
- **Data fields** — two complication slots side by side below the time,
  left defaulting to steps and right to the weekday and date. The types are
  listed one by one in `watchface.xml` rather than opened up with
  `allowAny`, and each has a case in `FieldKinds`; the two lists are meant to
  stay in step. Slot ids live in `source/complications/SlotId.mc`. Requires
  the `ComplicationSubscriber` permission.

Both colors offer the same 29 named colors, declared explicitly in
`watchface.xml` rather than with `allowAny`: the editor wants a label per
color, and with `allowAny` the fēnix 8 Solar filled its picker with garbled
entries. Every channel is 00, 55, AA or FF — the 64 color MIP palette — so
none of them dither on those screens. Black is left out: the background is
black.

Left unset, both fall back to white. A color the user has chosen is kept as
it is when the style changes.

## The rim

The color of the rim marks and numerals is not configurable: amber from the
exact minute the sun rises to the minute it sets and sky blue the rest of the
day, from the sunrise and sunset complications. Each mark and numeral takes
the color of the moment it stands for. The one mark nearest solar noon,
halfway from sunrise to sunset, is sky blue, the night's color, to stand out
among the amber. Until the sun is known they are drawn in the data color.

The hour hand takes the same two colors the other way round: sky blue by day
and amber through the night, so it stands out from the marks it sits among.
Until the sun is known it is drawn in the accent color.

The rim marks are drawn as lines running inward from the rim, with the
width as a pen width in pixels. An arc cannot be made narrow enough:
`drawArc` takes its span in degrees and the renderer works in whole ones, so
every width from one degree to two comes out as the same mark. A pixel at the
rim is roughly a quarter of a degree, which is a useful step on a shape this
small. The pen is round, so a line runs half its width past each end; every
clearance counts that in.

The rim is 24 hour marks with three thin minor marks between each pair, one
every quarter hour, and the numerals 12, 16, 20, 24, 4 and 8 against the
inner ends of their marks - left off on `Plain`. Noon is at the top and
midnight at the bottom, so the sun travels the upper half.

While an activity is under way the system draws its own indicator at the top
of the screen, over the 12, so the 12 is left off then. `ActivityTimer` reads
that off `Activity.Info.timerState` once a minute, which not every watch
hands a watch face; where it does not, the 12 stays. The stopwatch has no API
at all and is not covered.

The goal hand is an accent colored dot, as wide across as two hour marks,
four pixels inside the hour marks' inner ends, passing under the hour hand.
It goes round once from the 12 as the day's steps goal (`steps` over
`stepGoal`, read once a minute) is done, and stays at the 12 past it. It is
a ring while the goal is in progress - its line half the dot's radius, at
least 2px - and solid once the goal is done. With no goal to read, it stays
off.

## Drawing

Everything but the seconds hand is drawn off screen once a minute, into a
`BufferedBitmap` that `FaceBuffer` holds. A full update copies it to the
screen and draws the seconds hand over it; anything that changes the face -
a setting, the editor pulsing a field, waking - invalidates it.

The seconds hand keeps sweeping in low power mode through
`LucernarioView.onPartialUpdate()`: it clips to the box around the hand's
old position and its new one, copies the off screen face back there, and
draws the hand. Every second's corners and box are worked out once per
screen. A data field's live update redraws only the fields' row, off screen,
and copies that box to the screen. If a partial update costs more than the
system allows, `onPowerBudgetExceeded` fires on the delegate, partial updates
are switched off, and the hand comes off the screen while asleep rather than
standing still. Without room in the graphics pool for the buffer the face is
drawn straight on screen, and the hand does not show while asleep.

Watches with an AMOLED screen never get partial updates, and in always-on
mode they blank a face that lights more than a tenth of the screen. Where
`DeviceSettings.requiresBurnInProtection` is set, the face asleep is the
time alone on black; everything else comes back on waking.

## Status row

The status row mirrors a line at 66% of the screen height, lifted by 1/22 of
the height; the data fields start 2% below that line. It carries battery,
phone, alarm, recovery, wind and AM/PM. None of them have a setting: each
icon shows whenever the thing it reports is worth reporting.

- **Battery** stays orange at its lowest level and amber at the next.
- **Recovery** shows while the recovery time complication has any left. It
  takes the data color up to a day, amber (`Palette.AMBER`) past a day and
  orange (`Palette.ORANGE`, 0xFF5500) past two. The complication carries
  minutes.
- **Wind** is always shown: a ring with a wedge in it pointing downwind (the
  bearing is where the wind comes from, so a southerly, 180, points up),
  snapped to the nearest eighth of the compass, and the ring alone when the
  wind is unknown or calm (under 0.5 km/h, which rounds to 0). The strength
  is said in color: the data color up to 20 km/h, amber above that, orange
  above 40.

The wind is one bitmap to each eighth of the compass rather than one bitmap
turned on the watch. A bitmap cannot be turned without the bilinear filter,
the filter makes part opaque pixels out of artwork that had none, and a MIP
panel cannot composite those - it keeps or drops each one as it draws, so a
turned icon thickens and thins with the bearing. Turned at generation time,
each eighth is flattened as it stands.

## Data fields

Each field is an icon and its value in `FONT_TINY`, the two fields side by
side and centered as one. The system hands over a raw value and almost never
formats it, so the kind `FieldKinds` picks per type does:

- **Weather** - an icon for the conditions beside the temperature; the
  complication's own value goes unread. Between sunset and sunrise a sun
  gives way to a moon, or to its cloud alone.
- **Sunset** - the sun's next turn: the sunset while the sun is up and the
  sunrise while it is down, by the 12/24 hour setting, its icon orange
  through dawn and dusk. Read again every minute.
- **Recovery time** - whole hours, rounded up; the complication carries
  minutes.
- **Temperature**, **high and low** - Celsius however the watch is set,
  converted against `temperatureUnits`, whole degrees with a mark. The high
  and low is the one type the system formats itself, as "H 21 / L 12" or
  similar; a mark goes in after each number.
- **Altitude** - meters, converted against `elevationUnits`, whole units.
- **Weekly run and bike** - meters, converted against `distanceUnits`, to a
  tenth of a kilometer or mile; a week without a run shows 0.0.
- **Battery** - given the percent sign.
- The rest show the value with whatever unit the system supplies; the dates
  read as what they are and get no icon.

Garmin gives no dawn or dusk, so they are civil twilight, the sun 6° below
the horizon, worked out in `source/sun/Twilight.mc` from the date and the
latitude: the weather's observation location, or the last fix, with no
positioning permission. With neither, the latitude comes from the day's
length - except within about five days of an equinox, when every latitude
has a twelve hour day; then there is no twilight to show.

A complication type above the face's `minApiLevel` cannot be offered at all,
because naming the symbol is what fails rather than reaching it. A `switch`
walks its case labels until one matches, so a case for a type the watch has
never heard of is evaluated on every type the table does not know, and brings
the watch down with a Symbol Not Found error - which is an error rather than
an exception, so no `try` can catch it. `COMPLICATION_TYPE_SLEEP_SCORE` is
API 6.0.2 against this face's floor of 5.1.0 and is left out for that
reason.

`Complication.getIcon()` is documented as working only for user
complications, meaning ones published by other Connect IQ apps, and returns
null for the built-in types, so the field icons are the face's own.

## Icons

The icon artwork is white on transparent, so it is drawn with `drawBitmap2`
and tinted as it draws. Status icons come in two sizes, 24px in `resources/`
and 36px in `resources-large-icons/`, and the suns and field icons in 24px
and 32px, selected by the `resourcePath` lines in `monkey.jungle`. All are
generated from `assets/icons/`; see Icon artwork below.

`resources/configs/watchface.xml` declares what the editor shows.
`LucernarioView.updateConfiguration()` applies it through `Editor`, and is
called both at startup (from `onLayout`) and on every edit (from
`LucernarioDelegate`).

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
tinted at draw time and would be invisible untinted on the black background,
and the
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

The wind's eight icons all come from `wind/bearing.svg`, which points north
- a wind from the south - and is turned about its middle for the rest; the
script's `TURN` does that. `wind/calm.svg` is the same ring alone.

The weather icons in `assets/icons/weather/` are Material Design Icons
(pictogrammers.com/library/mdi, Apache 2.0), @mdi/svg 7.4.47, renamed without
their `weather-` prefix.

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
