import Toybox.Complications;
import Toybox.Lang;

//! Today's sunrise and sunset off the complications, solar noon halfway
//! between, and dawn and dusk either side of noon. Read once a minute,
//! worked out again only when the sun moves.
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

    //! true when the sun has moved, about once a day
    function refresh() as Boolean {
        if (!minuteGate.opens()) {
            return false;
        }

        var sunrise = minutesOf(sunriseId);
        var sunset = minutesOf(sunsetId);

        if ((sunrise == sunriseMinute) && (sunset == sunsetMinute)) {
            return false;
        }

        sunriseMinute = sunrise;
        sunsetMinute = sunset;
        refreshTwilight();

        return true;
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

    //! Between sunrise and sunset; null while either is not known
    function isUpAt(minute as Number) as Boolean? {
        var rise = sunriseMinute;
        var set = sunsetMinute;

        if ((rise == null) || (set == null)) {
            return null;
        }

        return Numbers.isBetween(minute, rise, set);
    }

    //! From dawn to sunrise, or sunset to dusk; false while they are not
    //! known
    function isTwilightAt(minute as Number) as Boolean {
        var rise = sunriseMinute;
        var set = sunsetMinute;
        var dawn = dawnMinute;
        var dusk = duskMinute;

        if ((rise == null) || (set == null) || (dawn == null) || (dusk == null)) {
            return false;
        }

        return Numbers.isBetween(minute, dawn, rise) || Numbers.isBetween(minute, set, dusk);
    }

    //! Solar noon, halfway from sunrise to sunset; null with either unknown
    function zenith() as Number? {
        var rise = sunriseMinute;
        var length = dayLength();

        if ((rise == null) || (length == null)) {
            return null;
        }

        return Clock.wrapMinutes(rise + (length / 2));
    }

    //! Minutes from sunrise to sunset, which may run across midnight
    private function dayLength() as Number? {
        var rise = sunriseMinute;
        var set = sunsetMinute;

        if ((rise == null) || (set == null)) {
            return null;
        }

        return Clock.wrapMinutes(set - rise);
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

        dawnMinute = Clock.wrapMinutes(noon - fromNoon);
        duskMinute = Clock.wrapMinutes(noon + fromNoon);
    }

    //! The complication carries seconds past midnight
    private function minutesOf(id as Complications.Id) as Number? {
        var value = ComplicationReader.valueOf(id);

        if (value == null) {
            return null;
        }

        return ValueFormat.wholeNumber(value) / Clock.SECONDS_PER_MINUTE;
    }
}
