import Toybox.Graphics;
import Toybox.Lang;

//! The time, centered, in the largest numeric system font.
class TimeDisplay {

    private const TIME_FORMAT = "$1$$2$";
    private const FIELD_FORMAT = "%02d";

    //! Garmin sizes it per device
    private const FONT = Graphics.FONT_NUMBER_THAI_HOT;

    private var color as Number = Graphics.COLOR_WHITE;

    function initialize() {
    }

    function setColor(color as Number) as Void {
        self.color = color;
    }

    function draw(dc as Dc) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            Dial.centerX,
            Dial.centerY,
            FONT,
            currentTime(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function currentTime() as String {
        var clockTime = Clock.now();

        return Lang.format(TIME_FORMAT, [
            Clock.displayHour(clockTime.hour).format(FIELD_FORMAT),
            clockTime.min.format(FIELD_FORMAT)
        ]);
    }
}
