import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

//! Meters whatever the watch shows, in its unit but without it; whole units,
//! as fine as the altimeter knows
class AltitudeKind extends FieldKind {

    private const FEET_PER_METER = 3.28084;

    function initialize(resourceId as ResourceId?) {
        FieldKind.initialize(resourceId);
    }

    protected function format(value as Complications.Value, complication as Complications.Complication) as String {
        var height = ValueFormat.decimal(value);

        if (Clock.settings().elevationUnits == System.UNIT_STATUTE) {
            height *= FEET_PER_METER;
        }

        return ValueFormat.rounded(height);
    }
}
