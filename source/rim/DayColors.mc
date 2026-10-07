import Toybox.Graphics;
import Toybox.Lang;

//! The rim's colors: amber from sunrise to sunset, sky blue after. The data
//! color until the sun is known. Shared by the marks, the numerals and the
//! hour hand, which takes the other color so it stands out from the marks
//! around it.
class DayColors {

    private const DAY_COLOR = Palette.AMBER;
    private const NIGHT_COLOR = Palette.SKY;

    private var daylight as Daylight;

    //! Until the sun is known
    private var fallbackColor as Number = Graphics.COLOR_WHITE;

    //! Sunrise and sunset on the dial, null when not known
    private var sunrisePosition as Float? = null;
    private var sunsetPosition as Float? = null;

    function initialize(daylight as Daylight) {
        self.daylight = daylight;
    }

    function setFallbackColor(color as Number) as Void {
        fallbackColor = color;
    }

    //! Once per full update, after the daylight has refreshed
    function refresh() as Void {
        var sunrise = daylight.sunrise();
        var sunset = daylight.sunset();

        if ((sunrise == null) || (sunset == null)) {
            sunrisePosition = null;
            sunsetPosition = null;
            return;
        }

        sunrisePosition = Dial.positionOfMinute(sunrise);
        sunsetPosition = Dial.positionOfMinute(sunset);
    }

    //! The color at a moment of the day, in degrees clockwise from midnight
    function colorAt(degrees as Numeric) as Number {
        var isDay = isDayAt(degrees);

        if (isDay == null) {
            return fallbackColor;
        }

        return isDay ? DAY_COLOR : NIGHT_COLOR;
    }

    //! The night color by day and the day color by night, null until the sun
    //! is known
    function invertedColorAt(degrees as Numeric) as Number? {
        var isDay = isDayAt(degrees);

        if (isDay == null) {
            return null;
        }

        return isDay ? NIGHT_COLOR : DAY_COLOR;
    }

    //! Null until the sun is known
    private function isDayAt(degrees as Numeric) as Boolean? {
        var rise = sunrisePosition;
        var set = sunsetPosition;

        if ((rise == null) || (set == null)) {
            return null;
        }

        // Far from the time zone's meridian the day can run across midnight.
        return (rise <= set)
            ? ((degrees >= rise) && (degrees < set))
            : ((degrees >= rise) || (degrees < set));
    }
}
