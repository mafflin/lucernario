import Toybox.Lang;

//! The wind off the weather: bearing, whether it is calm, strength in three
//! steps, and the color for each step.
class WindReading {

    //! The limits read as km/h
    private const LIGHT_LIMIT_KMH = 20;
    private const MODERATE_LIMIT_KMH = 40;

    //! Below this the speed rounds to 0 km/h, as the weather field shows it
    private const CALM_LIMIT_KMH = 0.5;

    private const LIGHT = 0;
    private const MODERATE = 1;
    private const STRONG = 2;

    //! A light wind is the ordinary case and keeps its drawer's color
    private const MODERATE_COLOR = Palette.AMBER;
    private const STRONG_COLOR = Palette.ORANGE;

    //! Where the wind blows from, north up; null when unknown
    private var currentBearing as Number? = null;

    private var calm as Boolean = false;
    private var strength as Number = LIGHT;

    //! Once a minute: the phone refills the weather by the hour at best
    private var minuteGate as MinuteGate;

    function initialize() {
        minuteGate = new MinuteGate();
    }

    //! Once per draw of the row; reads at most once a minute
    function refresh() as Void {
        if (!minuteGate.opens()) {
            return;
        }

        currentBearing = null;
        calm = false;
        strength = LIGHT;

        var conditions = CurrentWeather.conditions();

        if (conditions == null) {
            return;
        }

        var bearing = conditions.windBearing;

        if (bearing == null) {
            return;
        }

        var speed = conditions.windSpeed;

        currentBearing = bearing;
        calm = (speed != null) ? ((speed * CurrentWeather.KMH_PER_MS) < CALM_LIMIT_KMH) : false;
        strength = strengthFor(speed);
    }

    function bearing() as Number? {
        return currentBearing;
    }

    //! A bearing without a speed is not calm
    function isCalm() as Boolean {
        return calm;
    }

    //! Amber when moderate, orange when strong, the given color otherwise
    function colorFor(lightColor as Number) as Number {
        if (strength == STRONG) {
            return STRONG_COLOR;
        }

        if (strength == MODERATE) {
            return MODERATE_COLOR;
        }

        return lightColor;
    }

    //! A bearing without a speed counts as light
    private function strengthFor(speed as Numeric?) as Number {
        if (speed == null) {
            return LIGHT;
        }

        var kmh = speed * CurrentWeather.KMH_PER_MS;

        if (kmh <= LIGHT_LIMIT_KMH) {
            return LIGHT;
        }

        if (kmh <= MODERATE_LIMIT_KMH) {
            return MODERATE;
        }

        return STRONG;
    }
}
