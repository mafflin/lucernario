import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

//! Renders the current time centered on the screen, in the largest font the
//! display can carry.
class TimeDisplay {

    //! How the time is laid out. The string used to size the font is built
    //! from this same format, so the two can never drift apart.
    private const _TIME_FORMAT = "$1$$2$";

    //! How each field is padded. Must produce the same width as _WIDEST_FIELD.
    private const _FIELD_FORMAT = "%02d";

    //! The widest a single field can render. Digits are uniform width in the
    //! faces we use, so any two digits would do.
    private const _WIDEST_FIELD = "88";

    //! Hours shown on a 12 hour clock face
    private const _HOURS_ON_CLOCK_FACE = 12;

    //! The font the time is drawn with, resolved in prepare()
    private var _font as FontType = Graphics.FONT_NUMBER_HOT;

    //! The color the time is drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Constructor
    function initialize() {
    }

    //! Resolve the largest font this screen can carry. Call once per layout,
    //! and again whenever the space left for the time changes.
    //! @param dc The drawing context
    //! @param inset Pixels to keep clear around the edge of the screen
    function prepare(dc as Dc, inset as Number) as Void {
        _font = FontFitter.largestFor(dc, widestTime(), inset);
    }

    //! Set the color the time is drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw the current time in the center of the given context
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            _font,
            currentTime(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    //! How far down the screen the digits reach.
    //!
    //! The glyphs, not the font box: the descent the font reserves below the
    //! baseline is empty space, and anything placed under the time would sit
    //! needlessly low if it allowed for it.
    //! @param dc The drawing context
    //! @return The y coordinate of the bottom of the digits
    function inkBottomIn(dc as Dc) as Number {
        var halfInk = FontFitter.inkHeightOf(dc, _font) / 2;

        return ((dc.getHeight() / 2) + halfInk).toNumber();
    }

    //! The time as it is drawn right now
    //! @return The formatted time
    private function currentTime() as String {
        var clockTime = System.getClockTime();

        return Lang.format(_TIME_FORMAT, [
            displayHour(clockTime).format(_FIELD_FORMAT),
            clockTime.min.format(_FIELD_FORMAT)
        ]);
    }

    //! The widest string the time can ever render as. Sizing the font against
    //! this keeps the layout from jumping between minutes.
    //! @return The formatted time at its widest
    private function widestTime() as String {
        return Lang.format(_TIME_FORMAT, [_WIDEST_FIELD, _WIDEST_FIELD]);
    }

    //! The hour to show, honoring the device's 12/24 hour setting
    //! @param clockTime The current time
    //! @return The hour as the user expects to read it
    private function displayHour(clockTime as System.ClockTime) as Number {
        var hour = clockTime.hour;

        if (System.getDeviceSettings().is24Hour) {
            return hour;
        }

        hour = hour % _HOURS_ON_CLOCK_FACE;

        // Midnight and noon read as 12, not 0
        if (hour == 0) {
            return _HOURS_ON_CLOCK_FACE;
        }

        return hour;
    }
}
