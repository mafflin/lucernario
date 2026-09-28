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

    //! Before drawRadial: a mark is as wide as the pen
    function setPen(dc as Dc, color as Number, widthPixels as Number) as Void {
        dc.setPenWidth(widthPixels);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    }

    //! A mark as a line. An arc cannot be made narrow enough: drawArc works
    //! in whole degrees, a line in pixels. The renderer snaps each end to a
    //! pixel, which turns a short line by degrees; every line starts a ring
    //! depth off the glass, which spreads that out and lets a shorter line
    //! lie true over a longer one.
    function drawRadial(dc as Dc, valueDegrees as Numeric, radialLength as Number) as Void {
        var radians = Dial.radiansOf(valueDegrees);
        var acrossX = Math.cos(radians);

        // Screen y grows downward.
        var acrossY = -Math.sin(radians);

        var outer = Dial.rim + Dial.ringDepth;
        var inner = Dial.rim - radialLength;

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
