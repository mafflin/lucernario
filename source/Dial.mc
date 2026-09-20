import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The ring the rim marks and the seconds hand are drawn on: how big it is,
//! and where a value on the dial lands on the glass.
//!
//! Measured once by setup(). The draw path reads these rather than asking the
//! dc, which a partial update would do every tick.
module Dial {

    //! Noon at the top and values running clockwise, where the screen's own
    //! zero sits at three o'clock and runs the other way.
    const TWELVE_OCLOCK_DEGREES = 90;

    const DEGREES_PER_CIRCLE = 360;

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
