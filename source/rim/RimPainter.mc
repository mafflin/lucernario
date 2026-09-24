import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Draws the shapes that sit on the rim: the marks, the hour hand and the
//! seconds hand.
//!
//! The marks and the hour hand are lines running inward from the rim,
//! because an arc cannot be made narrow enough - see drawRadial. The seconds
//! hand is a triangle, filled from the corners it works out itself.
//!
//! All want the smoothing the view turns on once per update. A mark is a
//! line a few pixels wide at an angle, and hard edged its two sides land on
//! whichever pixels the angle happens to fall on, which reads as a leaning
//! tick. A triangle is all sloping sides, where a hard edge shows as a
//! staircase.
//!
//! The pen is round, so a line runs past each of its ends by half its width.
//! Anything that keeps clear of a line, or boxes it, counts that in.
module RimPainter {

    //! How far past the rim a mark's line starts, in mark lengths. The
    //! renderer lands each end of a line on a whole pixel, and on a mark a
    //! few pixels long that pixel turns it by several degrees - more than
    //! the gap between two minor marks. Started out past the glass, where the
    //! round screen hides it, the outer end's pixel is spread over a line
    //! four times as long.
    const OVERSHOOT_LENGTHS = 3;

    //! A mark on the rim drawn as a line running inward from the rim, as wide
    //! as the pen is thick.
    //!
    //! An arc cannot draw a narrow mark: drawArc takes its span in
    //! degrees and the renderer works in whole ones, so every width between
    //! one degree and two comes out as the same mark. A line is measured in
    //! pixels and steps one pixel at a time, which at the rim is finer than a
    //! degree by a factor of about four.
    //!
    //! Only the inner end is seen, rounded to the nearest pixel; the outer
    //! one lies off the glass - see OVERSHOOT_LENGTHS.
    //! @param dc The drawing context
    //! @param valueDegrees Where on the dial it sits, clockwise from the top
    //! @param color The color to draw in
    //! @param widthPixels How wide the mark is
    //! @param radialLength How far in from the rim it reaches
    function drawRadial(dc as Dc, valueDegrees as Numeric, color as Number, widthPixels as Number, radialLength as Number) as Void {
        var radians = Dial.radiansOf(valueDegrees);
        var acrossX = Math.cos(radians);

        // Screen y grows downward, so the sine of the angle is negated.
        var acrossY = -Math.sin(radians);

        var outer = Dial.rim + (radialLength * OVERSHOOT_LENGTHS);
        var inner = Dial.rim - radialLength;

        dc.setPenWidth(widthPixels);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(
            pixel(Dial.centerX + (outer * acrossX)),
            pixel(Dial.centerY + (outer * acrossY)),
            pixel(Dial.centerX + (inner * acrossX)),
            pixel(Dial.centerY + (inner * acrossY))
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

    //! The nearest whole pixel. Rounded rather than left to the renderer,
    //! which truncates and so leans every mark the same way.
    //! @param value The coordinate to place
    //! @return The pixel it lands on
    function pixel(value as Decimal) as Number {
        return Math.round(value).toNumber();
    }
}
