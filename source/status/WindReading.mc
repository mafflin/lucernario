import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;

//! The wind off the weather: bearing, strength in three steps, and the color
//! for each step. Shared by the row's arrow and the dial's bearing.
class WindReading {

    //! The API reports m/s; the limits read as km/h
    private const _KMH_PER_MS = 3.6;
    private const _LIGHT_LIMIT_KMH = 20;
    private const _MODERATE_LIMIT_KMH = 40;

    private const _LIGHT = 0;
    private const _MODERATE = 1;
    private const _STRONG = 2;

    //! A light wind is the ordinary case and keeps its drawer's color
    private const _MODERATE_COLOR = Graphics.COLOR_ORANGE;
    private const _STRONG_COLOR = Graphics.COLOR_RED;

    //! Where the wind blows from, north up; null when unknown
    private var _bearing as Number? = null;

    private var _strength as Number = _LIGHT;

    //! Once a minute: the phone refills the weather by the hour at best
    private var _reading as MinuteGate;

    function initialize() {
        _reading = new MinuteGate();
    }

    //! Once per full update
    function refresh() as Void {
        if (!_reading.opens()) {
            return;
        }

        _bearing = null;
        _strength = _LIGHT;

        if (!(Toybox has :Weather)) {
            return;
        }

        var conditions = Weather.getCurrentConditions();

        if (conditions == null) {
            return;
        }

        var bearing = conditions.windBearing;

        if (bearing == null) {
            return;
        }

        _bearing = bearing;
        _strength = strengthFor(conditions.windSpeed);
    }

    function bearing() as Number? {
        return _bearing;
    }

    //! Orange when moderate, red when strong, the given color otherwise
    function colorFor(lightColor as Number) as Number {
        if (_strength == _STRONG) {
            return _STRONG_COLOR;
        }

        if (_strength == _MODERATE) {
            return _MODERATE_COLOR;
        }

        return lightColor;
    }

    //! A bearing without a speed counts as light
    private function strengthFor(speed as Numeric?) as Number {
        if (speed == null) {
            return _LIGHT;
        }

        var kmh = speed * _KMH_PER_MS;

        if (kmh <= _LIGHT_LIMIT_KMH) {
            return _LIGHT;
        }

        if (kmh <= _MODERATE_LIMIT_KMH) {
            return _MODERATE;
        }

        return _STRONG;
    }
}
