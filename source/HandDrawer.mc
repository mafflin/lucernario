import Toybox.Graphics;
import Toybox.Lang;

//! Draws the shapes that sit on the rim: the hour marks and the seconds hand.
//! Both are the same shape, an arc as wide as the pen is thick.
module HandDrawer {

    //! Whether the screen can smooth what it draws. Asked once: a partial
    //! update has no business looking a symbol up every tick.
    var antiAlias as Boolean = false;

    //! Ask the screen whether it smooths
    //! @param dc The drawing context
    function setup(dc as Dc) as Void {
        antiAlias = (dc has :setAntiAlias);
    }

    //! Turn smoothing on for everything drawn after it.
    //!
    //! Asserted once per dc the system hands the face rather than by each
    //! shape around itself, and re-asserted every update because the dc
    //! between two updates is the system's.
    //! @param dc The drawing context
    function smooth(dc as Dc) as Void {
        if (antiAlias) {
            dc.setAntiAlias(true);
        }
    }

    //! A mark on the rim: an arc as wide as the pen is thick.
    //!
    //! Wants the smoothing above. A mark is a degree or two of arc, and hard
    //! edged its two sides land on whichever pixels the angle happens to fall
    //! on, which reads as a leaning tick.
    //! @param dc The drawing context
    //! @param valueDegrees Where on the dial it sits, clockwise from noon
    //! @param color The color to draw in
    //! @param angularWidthDegrees How wide the mark is
    //! @param radialLength How far in from the rim it reaches
    function draw(dc as Dc, valueDegrees as Numeric, color as Number, angularWidthDegrees as Numeric, radialLength as Number) as Void {
        var position = Dial.positionOf(valueDegrees);

        // Float: a one degree mark would otherwise start and end on the same
        // integer degree, and drawArc renders a spanless arc as a full circle.
        var half = angularWidthDegrees / 2.0;

        dc.setPenWidth(radialLength);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(
            Dial.centerX,
            Dial.centerY,
            Dial.rim - (radialLength / 2),
            Graphics.ARC_CLOCKWISE,
            Dial.wrap(position + half),
            Dial.wrap(position - half)
        );
    }
}
