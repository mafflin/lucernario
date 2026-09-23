import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The ring the rim marks and the seconds hand are drawn on: how big it is,
//! and where a value on the dial lands on the glass.
//!
//! Measured once by setup(). The draw path reads these rather than asking the
//! dc, which a partial update would do every tick.
module Dial {

    const DEGREES_PER_CIRCLE = 360;

    //! Noon at the top and values running clockwise, where the screen's own
    //! zero sits at three o'clock and runs the other way.
    const TWELVE_OCLOCK_DEGREES = 90;

    //! A full circle is a minute of seconds round
    const SECONDS_PER_TURN = 60;
    const DEGREES_PER_SECOND = DEGREES_PER_CIRCLE / SECONDS_PER_TURN;

    //! A full circle is a whole day round, one mark an hour
    const HOUR_MARKS = 24;
    const DEGREES_PER_HOUR_MARK = DEGREES_PER_CIRCLE / HOUR_MARKS;
    const MINUTES_PER_DAY = HOUR_MARKS * Clock.MINUTES_PER_HOUR;

    //! The band of rim the marks occupy, as a share of the radius rather than
    //! pixels: widths are in degrees and grow with the screen, so a fixed
    //! depth would leave marks on a large screen wider than they are long.
    const RING_DEPTH_NUMERATOR = 3;
    const RING_DEPTH_DIVISOR = 20;

    var screenWidth as Number = 0;
    var screenHeight as Number = 0;
    var centerX as Number = 0;
    var centerY as Number = 0;
    var rim as Number = 0;
    var ringDepth as Number = 0;

    //! Measure the dial for this screen. Must run before anything sizes
    //! itself off the ring.
    //! @param dc The drawing context
    function setup(dc as Dc) as Void {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;
        rim = (centerX < centerY) ? centerX : centerY;
        ringDepth = rim * RING_DEPTH_NUMERATOR / RING_DEPTH_DIVISOR;
    }

    //! A value on the dial as an angle on the screen
    //! @param valueDegrees The value, clockwise from noon
    //! @return The angle in screen degrees
    function positionOf(valueDegrees as Numeric) as Numeric {
        return TWELVE_OCLOCK_DEGREES - valueDegrees;
    }

    //! Where a minute of the day sits on the dial. A float: a minute is a
    //! quarter of a degree, and the hour hand stands at the minute, between
    //! the hour marks.
    //! @param minutes Minutes past midnight
    //! @return The value in degrees, clockwise from midnight
    function positionOfMinute(minutes as Number) as Float {
        return minutes.toFloat() * DEGREES_PER_CIRCLE / MINUTES_PER_DAY;
    }

    //! The pixel at an angle and radius. Screen y grows downward, so the sine
    //! is subtracted rather than added.
    //! @param radians The angle on the screen, as radiansOf() gives it
    //! @param radius How far from the center
    //! @return The x coordinate
    function pointX(radians as Decimal, radius as Numeric) as Number {
        return (centerX + (radius * Math.cos(radians))).toNumber();
    }

    //! @param radians The angle on the screen, as radiansOf() gives it
    //! @param radius How far from the center
    //! @return The y coordinate
    function pointY(radians as Decimal, radius as Numeric) as Number {
        return (centerY - (radius * Math.sin(radians))).toNumber();
    }

    //! A value on the dial as an angle on the screen, in radians, ready for
    //! the trig functions. Converted once per angle: the callers take both
    //! the cosine and the sine of it, and the partial update calls them every
    //! second. Screen y grows downward, so callers negate the sine.
    //! @param valueDegrees The value, clockwise from noon
    //! @return The angle in radians
    function radiansOf(valueDegrees as Numeric) as Decimal {
        return Math.toRadians(positionOf(valueDegrees));
    }

    //! Into one turn and never below zero: an arc ending where it starts is a
    //! spanless one, which drawArc renders as a full circle. A mark
    //! straddling three o'clock must not collapse into that.
    //! @param degrees The angle to normalize
    //! @return The same angle within one turn
    function wrap(degrees as Numeric) as Numeric {
        var turn = degrees;

        while (turn < 0) {
            turn += DEGREES_PER_CIRCLE;
        }

        while (turn >= DEGREES_PER_CIRCLE) {
            turn -= DEGREES_PER_CIRCLE;
        }

        return turn;
    }
}
