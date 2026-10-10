import Toybox.Lang;
import Toybox.Weather;

//! The weather the phone last sent, for the weather field, the wind and the
//! latitude
module CurrentWeather {

    //! The weather reports wind speed in m/s; the face shows km/h
    const KMH_PER_MS = 3.6;

    //! Null on a watch without weather, or before the phone has sent any
    function conditions() as Weather.CurrentConditions? {
        if (!(Toybox has :Weather)) {
            return null;
        }

        return Weather.getCurrentConditions();
    }
}
