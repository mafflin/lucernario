import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Draws the rim's shapes: lines running in from the rim for the marks and
//! the hour hand, filled triangles for the seconds hand and the wind. All
//! rely on the smoothing the view turns on once per update. The pen is
//! round, so a line runs past each end by penRadius.
module RimPainter {

    //! An equilateral triangle's height over its base
    const EQUILATERAL_HEIGHT = 0.866;

    //! How far past the rim a mark's line starts, in mark lengths. The
    //! renderer snaps each end to a pixel, which turns a short line by
    //! several degrees; starting off the glass spreads that over four times
    //! the length.
    const OVERSHOOT_LENGTHS = 3;

    //! A mark as a line, as wide as the pen. An arc cannot be made narrow
    //! enough: drawArc works in whole degrees, a line in pixels.
    function drawRadial(dc as Dc, valueDegrees as Numeric, color as Number, widthPixels as Number, radialLength as Number) as Void {
        var radians = Dial.radiansOf(valueDegrees);
        var acrossX = Math.cos(radians);

        // Screen y grows downward.
        var acrossY = -Math.sin(radians);

        var outer = Dial.rim + (radialLength * OVERSHOOT_LENGTHS);
        var inner = Dial.rim - radialLength;

        dc.setPenWidth(widthPixels);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(
            Dial.pixel(Dial.centerX + (outer * acrossX)),
            Dial.pixel(Dial.centerY + (outer * acrossY)),
            Dial.pixel(Dial.centerX + (inner * acrossX)),
            Dial.pixel(Dial.centerY + (inner * acrossY))
        );
    }

    //! Half the pen's width, rounded up
    function penRadius(widthPixels as Number) as Number {
        return (widthPixels + 1) / 2;
    }

    function fill(dc as Dc, points as Array<[Numeric, Numeric]>, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(points);
    }
}
