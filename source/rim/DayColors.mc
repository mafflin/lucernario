import Toybox.Graphics;
import Toybox.Lang;

//! The colors of the day around the rim: amber from the minute the sun rises
//! to the minute it sets, sky blue the rest of the way round - bright on the
//! dark style, dark on the light one, so they read against either
//! background. Until the sun is known, the data color.
//!
//! Shared by the rim marks and the numerals, so the two always agree.
class DayColors {

    //! The day and night colors for each style
    private const _DARK_STYLE_DAY = Palette.AMBER;
    private const _DARK_STYLE_NIGHT = Palette.SKY;
    private const _LIGHT_STYLE_DAY = Palette.DARK_AMBER;
    private const _LIGHT_STYLE_NIGHT = Palette.DARK_SKY;

    //! Where the sun is through the day. The view's, refreshed by it once per
    //! full update.
    private var _daylight as Daylight;

    //! The day and night colors for the current style, set by setLight()
    private var _dayColor as Number = _DARK_STYLE_DAY;
    private var _nightColor as Number = _DARK_STYLE_NIGHT;

    //! The color used until the sun is known
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Where the sun rises and sets on the dial, read by refresh(), null
    //! when not known
    private var _rise as Float? = null;
    private var _set as Float? = null;

    //! Constructor
    //! @param daylight Where the sun is through the day
    function initialize(daylight as Daylight) {
        _daylight = daylight;
    }

    //! Set the color used until the sun is known
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Pick the day and night colors for the style's background
    //! @param isLight true for the light style
    function setLight(isLight as Boolean) as Void {
        _dayColor = isLight ? _LIGHT_STYLE_DAY : _DARK_STYLE_DAY;
        _nightColor = isLight ? _LIGHT_STYLE_NIGHT : _DARK_STYLE_NIGHT;
    }

    //! Take where the sun is now onto the dial. Run once per full update,
    //! after the daylight has refreshed.
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

    //! The color at a moment of the day: day or night by where the sun is
    //! then, or the data color while the sun is not known
    //! @param degrees Where it sits on the dial, clockwise from midnight
    //! @return The color to draw it in
    function colorAt(degrees as Numeric) as Number {
        var rise = _rise;
        var set = _set;

        if ((rise == null) || (set == null)) {
            return _color;
        }

        // Far enough from the time zone's meridian the day can run across
        // midnight, with the sun setting earlier on the dial than it rose.
        var isDay = (rise <= set)
            ? ((degrees >= rise) && (degrees < set))
            : ((degrees >= rise) || (degrees < set));

        return isDay ? _dayColor : _nightColor;
    }
}
