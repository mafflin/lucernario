import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The ring the rim is drawn on, and where a value on the dial lands on the
//! glass. Measured once: a partial update should not ask the dc every tick.
module Dial {

    const DEGREES_PER_CIRCLE = 360;
    const HALF_TURN = DEGREES_PER_CIRCLE / 2;
    const QUARTER_TURN = DEGREES_PER_CIRCLE / 4;

    //! Dial zero is at the top; screen zero is at three o'clock, counterclockwise
    const TOP_DEGREES = 90;

    //! Midnight at the bottom, noon at the top: the sun crosses the upper half
    const MIDNIGHT_DEGREES = HALF_TURN;

    const SECONDS_PER_TURN = 60;
    const DEGREES_PER_SECOND = DEGREES_PER_CIRCLE / SECONDS_PER_TURN;

    //! A full circle is a day, one mark an hour
    const HOUR_MARKS = 24;
    const DEGREES_PER_HOUR_MARK = DEGREES_PER_CIRCLE / HOUR_MARKS;

    //! The ring the rim is sized off, as a share of the radius
    const RING_DEPTH_NUMERATOR = 3;
    const RING_DEPTH_DIVISOR = 20;

    var screenWidth as Number = 0;
    var screenHeight as Number = 0;
    var centerX as Number = 0;
    var centerY as Number = 0;
    var rim as Number = 0;
    var ringDepth as Number = 0;

    //! Before anything sizes itself off the ring
    function setup(dc as Dc) as Void {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;
        rim = (centerX < centerY) ? centerX : centerY;
        ringDepth = rim * RING_DEPTH_NUMERATOR / RING_DEPTH_DIVISOR;
    }

    //! Degrees clockwise from the top. A float: a minute is a quarter degree.
    function positionOfMinute(minutes as Number) as Float {
        var degrees = (minutes.toFloat() * DEGREES_PER_CIRCLE / Clock.MINUTES_PER_DAY) + MIDNIGHT_DEGREES;

        return (degrees < DEGREES_PER_CIRCLE) ? degrees : (degrees - DEGREES_PER_CIRCLE);
    }

    //! The pixel at a screen angle and radius. Screen y grows downward.
    function pointX(radians as Decimal, radius as Numeric) as Number {
        return pixel(centerX + (radius * Math.cos(radians)));
    }

    function pointY(radians as Decimal, radius as Numeric) as Number {
        return pixel(centerY - (radius * Math.sin(radians)));
    }

    //! Rounded, not truncated: truncation drags every point the same way
    function pixel(value as Decimal) as Number {
        return Math.round(value).toNumber();
    }

    //! A dial value as a screen angle in radians, converted once per angle
    function radiansOf(valueDegrees as Numeric) as Decimal {
        return Math.toRadians(TOP_DEGREES - valueDegrees);
    }
}
