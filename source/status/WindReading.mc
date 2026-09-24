import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;

//! The wind off the weather: the bearing it blows from and its strength in
//! three steps, and the color each step is said in.
//!
//! Shared by the arrow in the status row and the bearing on the dial, so the
//! two can never disagree.
class WindReading {

    //! The API reports metres per second; the limits below read as km/h.
    private const _KMH_PER_MS = 3.6;
    private const _LIGHT_LIMIT_KMH = 20;
    private const _MODERATE_LIMIT_KMH = 40;

    private const _LIGHT = 0;
    private const _MODERATE = 1;
    private const _STRONG = 2;

    //! Colors the two harder steps are drawn in, whatever the face's own
    //! colors are. A light wind is the ordinary case and nothing worth
    //! calling out, so it takes whatever color its drawer is in.
    private const _MODERATE_COLOR = Graphics.COLOR_ORANGE;
    private const _STRONG_COLOR = Graphics.COLOR_RED;

    //! The compass bearing the wind blows from, north up, null when unknown
    private var _bearing as Number? = null;

    //! Which of the three steps the strength calls for
    private var _strength as Number = _LIGHT;

    //! Once a minute: the phone refills the weather by the hour at best.
    private var _reading as MinuteGate;

    //! Constructor
    function initialize() {
        _reading = new MinuteGate();
    }

    //! Read the wind, if the minute has moved on. Once per full update,
    //! before anything that shows it draws.
    function refresh() as Void {
        if (!_reading.opens()) {
            return;
        }

        _bearing = null;
        _strength = _LIGHT;

        // A watch with no weather has nothing to read.
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

    //! Where the wind blows from
    //! @return The compass bearing in degrees, null when not known
    function bearing() as Number? {
        return _bearing;
    }

    //! Orange once the wind picks up, red when it is hard, and the given
    //! color the rest of the time
    //! @param lightColor The color for a light wind
    //! @return The color to draw in
    function colorFor(lightColor as Number) as Number {
        if (_strength == _STRONG) {
            return _STRONG_COLOR;
        }

        if (_strength == _MODERATE) {
            return _MODERATE_COLOR;
        }

        return lightColor;
    }

    //! A bearing but no speed still counts as light: direction known,
    //! strength not.
    //! @param speed The wind speed in metres per second, null if unknown
    //! @return Which of the three steps the wind is in
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
