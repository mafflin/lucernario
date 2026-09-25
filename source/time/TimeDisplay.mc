import Toybox.Graphics;
import Toybox.Lang;

//! The time, centered, in the largest numeric system font.
class TimeDisplay {

    private const _TIME_FORMAT = "$1$$2$";
    private const _FIELD_FORMAT = "%02d";

    //! The largest numeric font, which Garmin sizes per device
    private const _FONT = Graphics.FONT_NUMBER_THAI_HOT;

    private var _color as Number = Graphics.COLOR_WHITE;

    function initialize() {
    }

    function setColor(color as Number) as Void {
        _color = color;
    }

    function draw(dc as Dc) as Void {
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            Dial.centerX,
            Dial.centerY,
            _FONT,
            currentTime(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function currentTime() as String {
        var clockTime = Clock.now();

        return Lang.format(_TIME_FORMAT, [
            Clock.displayHour(clockTime.hour).format(_FIELD_FORMAT),
            clockTime.min.format(_FIELD_FORMAT)
        ]);
    }
}
