import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Draws the shapes that sit on the rim: the hour marks and the seconds hand.
//!
//! The hand is an arc as wide as the pen is thick, which is the shape it was
//! lifted as. The marks are lines running inward from the rim, because an arc
//! cannot be made narrow enough - see drawRadial.
//!
//! Both want the smoothing the view turns on once per update. A mark is a
//! degree or two of arc, and hard edged its two sides land on whichever pixels
//! the angle happens to fall on, which reads as a leaning tick.
module RimPainter {

    //! A mark on the rim drawn as a line running inward from the rim, as wide
    //! as the pen is thick.
    //!
    //! The arc below cannot draw a narrow mark: drawArc takes its span in
    //! degrees and the renderer works in whole ones, so every width between
    //! one degree and two comes out as the same mark. A line is measured in
    //! pixels and steps one pixel at a time, which at the rim is finer than a
    //! degree by a factor of about four.
    //! @param dc The drawing context
    //! @param valueDegrees Where on the dial it sits, clockwise from noon
    //! @param color The color to draw in
    //! @param widthPixels How wide the mark is
    //! @param radialLength How far in from the rim it reaches
    function drawRadial(dc as Dc, valueDegrees as Numeric, color as Number, widthPixels as Number, radialLength as Number) as Void {
        var radians = Dial.radiansOf(valueDegrees);
        var acrossX = Math.cos(radians);

        // Screen y grows downward, so the sine of the angle is negated.
        var acrossY = -Math.sin(radians);

        var outer = Dial.rim;
        var inner = outer - radialLength;

        dc.setPenWidth(widthPixels);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(
            Dial.centerX + (outer * acrossX),
            Dial.centerY + (outer * acrossY),
            Dial.centerX + (inner * acrossX),
            Dial.centerY + (inner * acrossY)
        );
    }

    //! A mark on the rim: an arc as wide as the pen is thick.
    //! @param dc The drawing context
    //! @param valueDegrees Where on the dial it sits, clockwise from noon
    //! @param color The color to draw in
    //! @param angularWidthDegrees How wide the mark is
    //! @param radialLength How far in from the rim it reaches
    function drawArc(dc as Dc, valueDegrees as Numeric, color as Number, angularWidthDegrees as Numeric, radialLength as Number) as Void {
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
