import Toybox.Complications;
import Toybox.Lang;

//! The sun's next turn as H:MM by the 12/24 hour setting: the sunset while
//! the sun is up, beside a setting sun, and the sunrise while it is down,
//! beside a rising one; the sun in the dial's twilight color through dawn
//! and dusk.
//! The sunset complication stands for it; the times are the dial's. Until
//! they are known, the sunset as the system gives it.
class SunKind extends FieldKind {

    private const CLOCK_FORMAT = "$1$:$2$";

    private const TWILIGHT_COLOR = Palette.ORANGE;

    private var risingIcon as Icon;
    private var settingIcon as Icon;

    //! As of the last read
    private var isUp as Boolean = true;
    private var isTwilight as Boolean = false;

    function initialize() {
        FieldKind.initialize(null);
        risingIcon = new Icon(Rez.Drawables.Sunrise);
        settingIcon = new Icon(Rez.Drawables.Sunset);
    }

    function icon() as Icon? {
        return isUp ? settingIcon : risingIcon;
    }

    function iconTint(color as Number) as Number {
        return isTwilight ? TWILIGHT_COLOR : color;
    }

    //! The sun turns whether or not the system sends anything
    function followsClock() as Boolean {
        return true;
    }

    function text(complication as Complications.Complication) as String {
        var daylight = Sun.daylight();
        var minute = Clock.minuteOfDay();
        var up = daylight.isUpAt(minute);

        if (up == null) {
            isUp = true;
            isTwilight = false;
            return FieldKind.text(complication);
        }

        isUp = up;
        isTwilight = daylight.isTwilightAt(minute);

        return clockOf((up ? daylight.sunset() : daylight.sunrise()) as Number);
    }

    //! The complication carries seconds past midnight
    protected function format(value as Complications.Value, complication as Complications.Complication) as String {
        return clockOf(ValueFormat.wholeNumber(value) / Clock.SECONDS_PER_MINUTE);
    }

    private function clockOf(minuteOfDay as Number) as String {
        var hour = Clock.displayHour(minuteOfDay / Clock.MINUTES_PER_HOUR);

        return ValueFormat.pair(CLOCK_FORMAT, hour, minuteOfDay % Clock.MINUTES_PER_HOUR);
    }
}
