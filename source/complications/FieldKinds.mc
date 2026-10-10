import Toybox.Complications;
import Toybox.Lang;

//! The kind of field each complication type is shown as, and its icon. One
//! case per type in watchface.xml, same order - the two lists are meant to
//! stay in step. A type above minApiLevel cannot be named here, which keeps
//! sleep score off both lists.
module FieldKinds {

    //! A new kind for a type; the dates read as what they are and get the
    //! plain kind without an icon, as does anything unknown
    function of(type as Complications.Type?) as FieldKind {
        if (type == null) {
            return new FieldKind(null);
        }

        switch (type) {
            case Complications.COMPLICATION_TYPE_ALTITUDE:             return new AltitudeKind(Rez.Drawables.FieldAltitude);
            case Complications.COMPLICATION_TYPE_BATTERY:              return new PercentKind(Rez.Drawables.FieldBattery);
            case Complications.COMPLICATION_TYPE_BODY_BATTERY:         return new FieldKind(Rez.Drawables.FieldHuman);
            case Complications.COMPLICATION_TYPE_CALORIES:             return new FieldKind(Rez.Drawables.FieldCalories);
            case Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE:  return new TemperatureKind(Rez.Drawables.FieldThermometer);
            case Complications.COMPLICATION_TYPE_CURRENT_WEATHER:      return new WeatherKind();
            case Complications.COMPLICATION_TYPE_HEART_RATE:           return new FieldKind(Rez.Drawables.FieldHeart);
            case Complications.COMPLICATION_TYPE_HIGH_LOW_TEMPERATURE: return new HighLowKind(Rez.Drawables.FieldThermometer);
            case Complications.COMPLICATION_TYPE_INTENSITY_MINUTES:    return new FieldKind(Rez.Drawables.FieldTimer);
            case Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT:   return new FieldKind(Rez.Drawables.FieldNotifications);
            case Complications.COMPLICATION_TYPE_RECOVERY_TIME:        return new HoursKind(Rez.Drawables.FieldRecovery);
            case Complications.COMPLICATION_TYPE_STEPS:                return new FieldKind(Rez.Drawables.FieldSteps);
            case Complications.COMPLICATION_TYPE_SUNSET:               return new SunKind();
            case Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE: return new DistanceKind(Rez.Drawables.FieldBike);
            case Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE:  return new DistanceKind(Rez.Drawables.FieldRun);
        }

        // The dates, COMPLICATION_TYPE_INVALID, and anything a later system
        // adds
        return new FieldKind(null);
    }
}
