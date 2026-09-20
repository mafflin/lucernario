import Toybox.Complications;
import Toybox.Lang;

//! A short name for each complication type.
//!
//! The system's own shortLabel runs too long for a container this size, so
//! the face carries its own. Keep these to about four characters: two sit
//! side by side under the time, and neither clips what it overflows into.
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
            case Complications.COMPLICATION_TYPE_BATTERY:                     return "BAT";
            case Complications.COMPLICATION_TYPE_STEPS:                       return "STEP";
            case Complications.COMPLICATION_TYPE_CALORIES:                    return "KCAL";
            case Complications.COMPLICATION_TYPE_FLOORS_CLIMBED:              return "FLR";
            case Complications.COMPLICATION_TYPE_INTENSITY_MINUTES:           return "IM";
            case Complications.COMPLICATION_TYPE_DATE:                        return NOTHING;
            case Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY:            return NOTHING;
            case Complications.COMPLICATION_TYPE_CURRENT_WEATHER:             return "WX";
            case Complications.COMPLICATION_TYPE_FORECAST_WEATHER_1DAY:       return "WX1";
            case Complications.COMPLICATION_TYPE_FORECAST_WEATHER_2DAY:       return "WX2";
            case Complications.COMPLICATION_TYPE_FORECAST_WEATHER_3DAY:       return "WX3";
            case Complications.COMPLICATION_TYPE_CALENDAR_EVENTS:             return "CAL";
            case Complications.COMPLICATION_TYPE_SUNRISE:                     return "RISE";
            case Complications.COMPLICATION_TYPE_SUNSET:                      return "SET";
            case Complications.COMPLICATION_TYPE_ALTITUDE:                    return "ALT";
            case Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE:          return "BARO";
            case Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT:          return "MSG";
            case Complications.COMPLICATION_TYPE_HEART_RATE:                  return "HR";
            case Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE:         return "RUN";
            case Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE:        return "BIKE";
            case Complications.COMPLICATION_TYPE_RECOVERY_TIME:               return "RCVY";
            case Complications.COMPLICATION_TYPE_STRESS:                      return "STRS";
            case Complications.COMPLICATION_TYPE_BODY_BATTERY:                return "BB";
            case Complications.COMPLICATION_TYPE_VO2MAX_RUN:                  return "VO2R";
            case Complications.COMPLICATION_TYPE_VO2MAX_BIKE:                 return "VO2B";
            case Complications.COMPLICATION_TYPE_TRAINING_STATUS:             return "TRN";
            case Complications.COMPLICATION_TYPE_RACE_PREDICTOR_5K:           return "5K";
            case Complications.COMPLICATION_TYPE_RACE_PREDICTOR_10K:          return "10K";
            case Complications.COMPLICATION_TYPE_RACE_PREDICTOR_HALF_MARATHON: return "HALF";
            case Complications.COMPLICATION_TYPE_RACE_PREDICTOR_MARATHON:     return "MAR";
            case Complications.COMPLICATION_TYPE_RACE_PACE_PREDICTOR_5K:      return "P5K";
            case Complications.COMPLICATION_TYPE_RACE_PACE_PREDICTOR_10K:     return "P10K";
            case Complications.COMPLICATION_TYPE_RACE_PACE_PREDICTOR_HALF_MARATHON: return "PHLF";
            case Complications.COMPLICATION_TYPE_RACE_PACE_PREDICTOR_MARATHON: return "PMAR";
            case Complications.COMPLICATION_TYPE_PULSE_OX:                    return "SPO2";
            case Complications.COMPLICATION_TYPE_RESPIRATION_RATE:            return "RESP";
            case Complications.COMPLICATION_TYPE_SOLAR_INPUT:                 return "SOLR";
            case Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE:         return "TEMP";
            case Complications.COMPLICATION_TYPE_HIGH_LOW_TEMPERATURE:        return "H/L";
            case Complications.COMPLICATION_TYPE_WHEELCHAIR_PUSHES:           return "PUSH";
            case Complications.COMPLICATION_TYPE_LAST_GOLF_ROUND_SCORE:       return "GOLF";
            case Complications.COMPLICATION_TYPE_SLEEP_SCORE:                 return "SLP";
        }

        // COMPLICATION_TYPE_INVALID, and anything a later system adds
        return NOTHING;
    }
}
