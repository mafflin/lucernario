import Toybox.Graphics;
import Toybox.Lang;

//! Renders the current time centered on the screen, in the largest numeric
//! font the system has.
class TimeDisplay {

    //! How the time is laid out
    private const _TIME_FORMAT = "$1$$2$";

    //! How each field is padded
    private const _FIELD_FORMAT = "%02d";

    //! The font the time is drawn with: the largest of the system's numeric
    //! fonts, which Garmin sizes per device to fill a watch face.
    private const _FONT = Graphics.FONT_NUMBER_THAI_HOT;

    //! The color the time is drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Constructor
    function initialize() {
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
            _FONT,
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
        var halfInk = Fonts.inkHeightOf(dc, _FONT) / 2;

        return ((dc.getHeight() / 2) + halfInk).toNumber();
    }

    //! The time as it is drawn right now
    //! @return The formatted time
    private function currentTime() as String {
        var clockTime = Clock.now();

        return Lang.format(_TIME_FORMAT, [
            Clock.displayHour(clockTime.hour).format(_FIELD_FORMAT),
            clockTime.min.format(_FIELD_FORMAT)
        ]);
    }
}
