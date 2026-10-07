import Toybox.Complications;
import Toybox.Lang;

//! Today's sunrise and sunset, off the complications - the same numbers the
//! data container shows - solar noon halfway between, and dawn and dusk
//! either side of noon. Read once a minute.
class Daylight {

    //! Minutes past midnight, null when not known
    private var sunriseMinute as Number? = null;
    private var sunsetMinute as Number? = null;
    private var dawnMinute as Number? = null;
    private var duskMinute as Number? = null;

    private var sunriseId as Complications.Id;
    private var sunsetId as Complications.Id;
    private var minuteGate as MinuteGate;

    function initialize() {
        sunriseId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE);
        sunsetId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNSET);
        minuteGate = new MinuteGate();
    }

    function refresh() as Void {
        if (!minuteGate.opens()) {
            return;
        }

        sunriseMinute = minutesOf(sunriseId);
        sunsetMinute = minutesOf(sunsetId);
        refreshTwilight();
    }

    function sunrise() as Number? {
        return sunriseMinute;
    }

    function sunset() as Number? {
        return sunsetMinute;
    }

    function dawn() as Number? {
        return dawnMinute;
    }

    function dusk() as Number? {
        return duskMinute;
    }

    //! Solar noon, halfway from sunrise to sunset; null with either unknown
    function zenith() as Number? {
        var rise = sunriseMinute;
        var length = dayLength();

        if ((rise == null) || (length == null)) {
            return null;
        }

        return wrap(rise + (length / 2));
    }

    //! Minutes from sunrise to sunset, which may run across midnight
    private function dayLength() as Number? {
        var rise = sunriseMinute;
        var set = sunsetMinute;

        if ((rise == null) || (set == null)) {
            return null;
        }

        return wrap(set - rise);
    }

    //! Twilight has to reach past sunrise and sunset, or the latitude is off
    private function refreshTwilight() as Void {
        dawnMinute = null;
        duskMinute = null;

        var noon = zenith();
        var length = dayLength();

        if ((noon == null) || (length == null)) {
            return;
        }

        var fromNoon = Twilight.minutesFromNoon(length);

        if ((fromNoon == null) || ((fromNoon * 2) <= length)) {
            return;
        }

        dawnMinute = wrap(noon - fromNoon);
        duskMinute = wrap(noon + fromNoon);
    }

    //! Into a day's minutes, from a turn either side
    private function wrap(minutes as Number) as Number {
        return (minutes + Clock.MINUTES_PER_DAY) % Clock.MINUTES_PER_DAY;
    }

    //! The complication carries seconds past midnight
    private function minutesOf(id as Complications.Id) as Number? {
        // Some watches throw on a complication they do not carry.
        try {
            var value = Complications.getComplication(id).value;

            if (value == null) {
                return null;
            }

            return ComplicationFormat.seconds(value) / Clock.SECONDS_PER_MINUTE;
        } catch (exception) {
            return null;
        }
    }
}
