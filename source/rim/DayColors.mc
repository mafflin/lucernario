import Toybox.Graphics;
import Toybox.Lang;

//! The rim's colors: amber from sunrise to sunset, sky blue after - bright
//! on the dark style, dark on the light one. The data color until the sun
//! is known. Shared by the marks and the numerals so they always agree.
class DayColors {

    private const _DARK_STYLE_DAY = Palette.AMBER;
    private const _DARK_STYLE_NIGHT = Palette.SKY;
    private const _LIGHT_STYLE_DAY = Palette.DARK_AMBER;
    private const _LIGHT_STYLE_NIGHT = Palette.DARK_SKY;

    private var _daylight as Daylight;

    private var _dayColor as Number = _DARK_STYLE_DAY;
    private var _nightColor as Number = _DARK_STYLE_NIGHT;

    //! Until the sun is known
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Sunrise and sunset on the dial, null when not known
    private var _rise as Float? = null;
    private var _set as Float? = null;

    function initialize(daylight as Daylight) {
        _daylight = daylight;
    }

    function setColor(color as Number) as Void {
        _color = color;
    }

    function setLight(isLight as Boolean) as Void {
        _dayColor = isLight ? _LIGHT_STYLE_DAY : _DARK_STYLE_DAY;
        _nightColor = isLight ? _LIGHT_STYLE_NIGHT : _DARK_STYLE_NIGHT;
    }

    //! Once per full update, after the daylight has refreshed
    function refresh() as Void {
        var sunrise = _daylight.sunrise();
        var sunset = _daylight.sunset();

        if ((sunrise == null) || (sunset == null)) {
            _rise = null;
            _set = null;
            return;
        }

        _rise = Dial.positionOfMinute(sunrise);
        _set = Dial.positionOfMinute(sunset);
    }

    //! The color at a moment of the day, in degrees clockwise from midnight
    function colorAt(degrees as Numeric) as Number {
        var rise = _rise;
        var set = _set;

        if ((rise == null) || (set == null)) {
            return _color;
        }

        // Far from the time zone's meridian the day can run across midnight.
        var isDay = (rise <= set)
            ? ((degrees >= rise) && (degrees < set))
            : ((degrees >= rise) || (degrees < set));

        return isDay ? _dayColor : _nightColor;
    }
}
