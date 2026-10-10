import Toybox.Complications;
import Toybox.Lang;

//! Always Celsius, whatever the watch shows; whole degrees in its unit
class TemperatureKind extends FieldKind {

    function initialize(resourceId as ResourceId?) {
        FieldKind.initialize(resourceId);
    }

    protected function format(value as Complications.Value, complication as Complications.Complication) as String {
        return ValueFormat.temperature(ValueFormat.decimal(value));
    }
}
