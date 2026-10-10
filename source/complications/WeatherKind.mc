import Toybox.Complications;
import Toybox.Lang;

//! The weather: an icon for the conditions, beside the temperature, 12°.
//! A dash when the temperature is not known. The complication's own value
//! goes unread; all of it comes off the weather itself.
class WeatherKind extends FieldKind {

    //! Nothing known: the field still shows
    private const UNKNOWN = "--";

    private var conditionIcon as WeatherIcon;

    function initialize() {
        FieldKind.initialize(null);
        conditionIcon = new WeatherIcon();
    }

    function icon() as Icon? {
        return conditionIcon;
    }

    function text(complication as Complications.Complication) as String {
        var conditions = CurrentWeather.conditions();

        conditionIcon.setCondition((conditions != null) ? conditions.condition : null);

        if (conditions == null) {
            return UNKNOWN;
        }

        var temperature = conditions.temperature;

        return (temperature != null) ? ValueFormat.temperature(temperature.toFloat()) : UNKNOWN;
    }
}
