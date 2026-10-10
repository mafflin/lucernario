import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;

//! The wind off the weather: bearing, strength in three steps, and the color
//! for each step, for the row's arrow.
class WindReading {

    //! The API reports m/s; the limits read as km/h
    private const KMH_PER_MS = 3.6;
    private const LIGHT_LIMIT_KMH = 20;
    private const MODERATE_LIMIT_KMH = 40;

    private const LIGHT = 0;
    private const MODERATE = 1;
    private const STRONG = 2;

    //! A light wind is the ordinary case and keeps its drawer's color
    private const MODERATE_COLOR = Graphics.COLOR_ORANGE;
    private const STRONG_COLOR = Graphics.COLOR_RED;

    //! Where the wind blows from, north up; null when unknown
    private var currentBearing as Number? = null;

    private var strength as Number = LIGHT;

    //! Once a minute: the phone refills the weather by the hour at best
    private var minuteGate as MinuteGate;

    function initialize() {
        minuteGate = new MinuteGate();
    }

    //! Once per full update
    function refresh() as Void {
        if (!minuteGate.opens()) {
            return;
        }

        currentBearing = null;
        strength = LIGHT;

        var conditions = currentConditions();

        if (conditions == null) {
            return;
        }

        var bearing = conditions.windBearing;

        if (bearing == null) {
            return;
        }

        currentBearing = bearing;
        strength = strengthFor(conditions.windSpeed);
    }

    function bearing() as Number? {
        return currentBearing;
    }

    //! Orange when moderate, red when strong, the given color otherwise
    function colorFor(lightColor as Number) as Number {
        if (strength == STRONG) {
            return STRONG_COLOR;
        }

        if (strength == MODERATE) {
            return MODERATE_COLOR;
        }

        return lightColor;
    }

    //! Null on a watch without weather, or before the phone has sent any
    private function currentConditions() as Weather.CurrentConditions? {
        if (!(Toybox has :Weather)) {
            return null;
        }

        return Weather.getCurrentConditions();
    }

    //! A bearing without a speed counts as light
    private function strengthFor(speed as Numeric?) as Number {
        if (speed == null) {
            return LIGHT;
        }

        var kmh = speed * KMH_PER_MS;

        if (kmh <= LIGHT_LIMIT_KMH) {
            return LIGHT;
        }

        if (kmh <= MODERATE_LIMIT_KMH) {
            return MODERATE;
        }

        return STRONG;
    }
}
