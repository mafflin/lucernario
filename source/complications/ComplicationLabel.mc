import Toybox.Complications;
import Toybox.Lang;

//! A short name for each complication type.
//!
//! The system's own shortLabel runs too long for a container this size, so
//! the face carries its own. Keep these to about four characters, so the
//! label and the value together stay inside the slot.
//!
//! One case per type offered in resources/configs/watchface.xml, in the same
//! order: a type dropped there should lose its case here as well. A type
//! above the face's minApiLevel cannot be named here at all, which is what
//! keeps sleep score off both lists. The types
//! whose value already reads as what it is - the date, the weekday, the
//! training status and the high and low - get no label.
module ComplicationLabel {

    //! What to show for a type with no label of its own
    const NOTHING = "";

    //! The short name for a complication type
    //! @param type The complication type, null if the system did not say
    //! @return The label, or an empty string
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
