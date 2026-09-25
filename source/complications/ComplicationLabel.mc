import Toybox.Complications;
import Toybox.Lang;

//! A short name per complication type: the system's shortLabel runs too
//! long. One case per type in watchface.xml, same order. A type above
//! minApiLevel cannot be named here, which keeps sleep score off both lists.
//! Types whose value reads as what it is get no label.
module ComplicationLabel {

    const NOTHING = "";

    function of(type as Complications.Type?) as String {
        if (type == null) {
            return NOTHING;
        }

        switch (type) {
            case Complications.COMPLICATION_TYPE_BATTERY:              return "BAT";
            case Complications.COMPLICATION_TYPE_STEPS:                return "ST";
            case Complications.COMPLICATION_TYPE_CALORIES:             return "CAL";
            case Complications.COMPLICATION_TYPE_FLOORS_CLIMBED:       return "FLR";
            case Complications.COMPLICATION_TYPE_INTENSITY_MINUTES:    return "IM";
            case Complications.COMPLICATION_TYPE_DATE:                 return NOTHING;
            case Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY:     return NOTHING;
            case Complications.COMPLICATION_TYPE_SUNRISE:              return "RISE";
            case Complications.COMPLICATION_TYPE_SUNSET:               return "SET";
            case Complications.COMPLICATION_TYPE_ALTITUDE:             return "ALT";
            case Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE:   return "BAR";
            case Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT:   return "MSG";
            case Complications.COMPLICATION_TYPE_HEART_RATE:           return "HR";
            case Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE:  return "RUN";
            case Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE: return "BIKE";
            case Complications.COMPLICATION_TYPE_RECOVERY_TIME:        return "RH";
            case Complications.COMPLICATION_TYPE_STRESS:               return "STR";
            case Complications.COMPLICATION_TYPE_BODY_BATTERY:         return "BB";
            case Complications.COMPLICATION_TYPE_VO2MAX_RUN:           return "VO2R";
            case Complications.COMPLICATION_TYPE_VO2MAX_BIKE:          return "VO2B";
            case Complications.COMPLICATION_TYPE_TRAINING_STATUS:      return NOTHING;
            case Complications.COMPLICATION_TYPE_PULSE_OX:             return "SPO2";
            case Complications.COMPLICATION_TYPE_RESPIRATION_RATE:     return "RESP";
            case Complications.COMPLICATION_TYPE_SOLAR_INPUT:          return "SOL";
            case Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE:  return "TEMP";
            case Complications.COMPLICATION_TYPE_HIGH_LOW_TEMPERATURE: return NOTHING;
        }

        // COMPLICATION_TYPE_INVALID, and anything a later system adds
        return NOTHING;
    }
}
