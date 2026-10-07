import Toybox.Activity;
import Toybox.Lang;
import Toybox.Weather;

//! Where on earth the watch is, north to south: the weather's location, or
//! the last fix. Degrees, north positive.
module Latitude {

    //! Null with neither
    function read() as Float? {
        var latitude = weatherLatitude();

        return (latitude != null) ? latitude : lastFixLatitude();
    }

    //! Null on a watch without weather, or before the phone has sent any
    function weatherLatitude() as Float? {
        if (!(Toybox has :Weather)) {
            return null;
        }

        var conditions = Weather.getCurrentConditions();

        if (conditions == null) {
            return null;
        }

        var location = conditions.observationLocationPosition;

        if (location == null) {
            return null;
        }

        return location.toDegrees()[0].toFloat();
    }

    function lastFixLatitude() as Float? {
        var location = Activity.getActivityInfo().currentLocation;

        if (location == null) {
            return null;
        }

        return location.toDegrees()[0].toFloat();
    }
}
