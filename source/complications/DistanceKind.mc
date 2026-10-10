import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

//! Meters, as kilometers or miles by the watch's setting, without the unit:
//! the weekly run and bike
class DistanceKind extends FieldKind {

    private const METERS_PER_KILOMETER = 1000.0;
    private const METERS_PER_MILE = 1609.344;

    //! Whole kilometers would hide a short run
    private const DISTANCE_FORMAT = "%.1f";

    function initialize(resourceId as ResourceId?) {
        FieldKind.initialize(resourceId);
    }

    //! Zero when the system has no value: a week without a run comes as
    //! nothing, not as 0, while one without a ride comes as 0
    function text(complication as Complications.Complication) as String {
        var value = complication.value;

        return format((value != null) ? value : 0, complication);
    }

    protected function format(value as Complications.Value, complication as Complications.Complication) as String {
        var meters = ValueFormat.decimal(value);
        var perUnit = (Clock.settings().distanceUnits == System.UNIT_STATUTE) ? METERS_PER_MILE : METERS_PER_KILOMETER;

        return (meters / perUnit).format(DISTANCE_FORMAT);
    }
}
