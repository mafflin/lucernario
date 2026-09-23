import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Draws the shapes that sit on the rim: the day and night band, the hour
//! marks, the hour hand and the seconds hand.
//!
//! The band is arcs running in from the rim, from one moment of the day to
//! another.
//!
//! The marks and the hour hand are lines running inward from the rim,
//! because an arc cannot be made narrow enough - see drawRadial. The seconds
//! hand is a triangle, filled from the corners it works out itself.
//!
//! All want the smoothing the view turns on once per update. A mark is a
//! degree or two of arc, and hard edged its two sides land on whichever pixels
//! the angle happens to fall on, which reads as a leaning tick. A triangle is
//! all sloping sides, where a hard edge shows as a staircase.
module RimPainter {

    //! A mark on the rim drawn as a line running inward from the rim, as wide
    //! as the pen is thick.
    //!
    //! An arc cannot draw a narrow mark: drawArc takes its span in
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

    //! A stretch of the rim filled from one value on the dial to another,
    //! clockwise
    //! @param dc The drawing context
    //! @param fromDegrees Where it starts, clockwise from noon
    //! @param toDegrees Where it ends, clockwise from noon
    //! @param color The color to fill with
    //! @param radialLength How far in from the rim it reaches
    function drawBand(dc as Dc, fromDegrees as Numeric, toDegrees as Numeric, color as Number, radialLength as Number) as Void {
        var from = Dial.wrap(Dial.positionOf(fromDegrees));
        var to = Dial.wrap(Dial.positionOf(toDegrees));

        // drawArc renders a spanless arc as a full circle.
        if (from == to) {
            return;
        }

        dc.setPenWidth(radialLength);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(
            Dial.centerX,
            Dial.centerY,
            Dial.rim - (radialLength / 2),
            Graphics.ARC_CLOCKWISE,
            from,
            to
        );
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
