import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;

//! Civil twilight, the sun 6° below the horizon. Garmin gives no dawn or
//! dusk, so they come from the latitude and the date, either side of noon.
//! Without a location the latitude comes from the day's length.
module Twilight {

    //! The sun's altitude at dawn and dusk, degrees
    const ALTITUDE = -6.0;

    //! The sun's center at sunrise and sunset, refraction included, degrees
    const HORIZON = -0.833;

    //! Closer to an equinox every latitude has a day of about 12 hours, so the
    //! day's length says nothing about it; degrees, about five days
    const MIN_DECLINATION = 2.0;

    //! The earth's tilt, degrees
    const TILT = 23.44;

    const DAYS_PER_YEAR = 365.0;

    //! The winter solstice falls this many days before the year starts
    const SOLSTICE_LEAD = 10;

    //! The earth turns a degree in four minutes
    const MINUTES_PER_DEGREE = 4.0;

    //! Leap years ignored: a day off moves the sun under half a degree
    const DAYS_BEFORE_MONTH = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

    //! From dawn to solar noon, and from noon to dusk. Null without a
    //! latitude, or when the sun never sinks or never climbs that far.
    function minutesFromNoon(dayLength as Number) as Number? {
        var sunDeclination = declination();
        var latitude = latitudeOf(dayLength, sunDeclination);

        if (latitude == null) {
            return null;
        }

        var hourAngle = hourAngleOf(latitude, sunDeclination);

        if (hourAngle == null) {
            return null;
        }

        return (hourAngle * MINUTES_PER_DEGREE).toNumber();
    }

    //! Radians: where the watch is if it knows, what the day's length says
    //! otherwise
    function latitudeOf(dayLength as Number, sunDeclination as Decimal) as Decimal? {
        var degrees = Latitude.read();

        if (degrees != null) {
            return Math.toRadians(degrees);
        }

        return latitudeFromDayLength(dayLength, sunDeclination);
    }

    //! Radians, the latitude whose sunrise and sunset lie this many minutes
    //! apart. Solves cos(h)·cos(d)·cos(lat) + sin(d)·sin(lat) = sin(HORIZON);
    //! of the two roots, the one on the globe.
    function latitudeFromDayLength(dayLength as Number, sunDeclination as Decimal) as Decimal? {
        if (Math.toDegrees(sunDeclination).abs() < MIN_DECLINATION) {
            return null;
        }

        var hourAngle = Math.toRadians(dayLength / 2.0 / MINUTES_PER_DEGREE);
        var cosineTerm = Math.cos(hourAngle) * Math.cos(sunDeclination);
        var sineTerm = Math.sin(sunDeclination);
        var ratio = Math.sin(Math.toRadians(HORIZON)) / Math.sqrt((cosineTerm * cosineTerm) + (sineTerm * sineTerm));

        if (ratio.abs() > 1) {
            return null;
        }

        var middle = Math.atan2(sineTerm, cosineTerm);
        var spread = Math.acos(ratio);
        var latitude = middle + spread;

        return (latitude.abs() <= (Math.PI / 2)) ? latitude : (middle - spread);
    }

    //! Degrees the earth turns from noon until the sun is down to ALTITUDE
    function hourAngleOf(latitude as Decimal, sunDeclination as Decimal) as Decimal? {
        var cosine = (Math.sin(Math.toRadians(ALTITUDE)) - (Math.sin(latitude) * Math.sin(sunDeclination)))
            / (Math.cos(latitude) * Math.cos(sunDeclination));

        if ((cosine < -1) || (cosine > 1)) {
            return null;
        }

        return Math.toDegrees(Math.acos(cosine));
    }

    //! How far north of the equator the sun stands today, radians
    function declination() as Decimal {
        var turn = 2 * Math.PI * (dayOfYear() + SOLSTICE_LEAD) / DAYS_PER_YEAR;

        return -Math.toRadians(TILT) * Math.cos(turn);
    }

    //! 0 on January 1st
    function dayOfYear() as Number {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        return (DAYS_BEFORE_MONTH[(today.month as Number) - 1] as Number) + today.day - 1;
    }
}
