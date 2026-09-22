import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Draws the shapes that sit on the rim: the hour marks, the seconds hand and
//! the hour hand.
//!
//! The seconds hand is an arc as wide as the pen is thick, which is the shape
//! it was lifted as. The marks are lines running inward from the rim, because
//! an arc cannot be made narrow enough - see drawRadial. The hour hand is a
//! triangle standing on the inner edge of the ring.
//!
//! All want the smoothing the view turns on once per update. A mark is a
//! degree or two of arc, and hard edged its two sides land on whichever pixels
//! the angle happens to fall on, which reads as a leaning tick. A triangle is
//! all sloping sides, where a hard edge shows as a staircase.
module RimPainter {

    //! Half the square root of three, as a number rather than a call
    const EQUILATERAL_HEIGHT = 0.866;

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

    //! The corners of a triangle with its base on the inner edge of the ring
    //! and its point out at the glass: a hand pointing at an hour rather than
    //! a mark. Equilateral, so the height falls out of the base and nothing
    //! else sets how far it reaches.
    //!
    //! The corners rather than the drawing, because the hand stands still for
    //! a minute at a time while the seconds hand sweeps over it: worked out
    //! on the full draw, and filled again from the same three points.
    //! @param valueDegrees Where on the dial it points, clockwise from midnight
    //! @param widthDegrees The span of its base
    //! @return The three corners, as [x, y] pairs
    function arrowPoints(valueDegrees as Numeric, widthDegrees as Numeric) as Array<[Numeric, Numeric]> {
        var baseRadius = Dial.rim - Dial.ringDepth;
        var point = Dial.radiansOf(valueDegrees);
        var half = Math.toRadians(widthDegrees / 2.0);
        var left = point + half;
        var right = point - half;

        var height = 2 * baseRadius * Math.sin(half) * EQUILATERAL_HEIGHT;
        var tipRadius = baseRadius + height;

        // The chord stands in for the ring's edge: at most half a pixel of bow.
        return [
            [Dial.pointX(left, baseRadius), Dial.pointY(left, baseRadius)],
            [Dial.pointX(right, baseRadius), Dial.pointY(right, baseRadius)],
            [Dial.pointX(point, tipRadius), Dial.pointY(point, tipRadius)]
        ] as Array<[Numeric, Numeric]>;
    }

    //! Fill a shape from its corners
    //! @param dc The drawing context
    //! @param points The corners, as [x, y] pairs
    //! @param color The color to fill with
    function fill(dc as Dc, points as Array<[Numeric, Numeric]>, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(points);
    }
}
