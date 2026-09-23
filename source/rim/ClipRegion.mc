import Toybox.Graphics;
import Toybox.Lang;

//! What a partial update is allowed to touch: one box around the seconds
//! hand, and the tests that tell what is drawn under it whether it falls
//! inside. A partial update has a budget, and the cheapest draw is the one
//! never issued.
module ClipRegion {

    //! Pixels past the dot on every side, for its smoothed edge. Its center
    //! is a whole pixel already, so there is no rounding to cover.
    const PADDING = 1;

    //! The box's own reach. It is a square around the dot, a few degrees
    //! either side of it at the ring; this is comfortably more.
    const SLOP_DEGREES = 9;

    //! The last box, so callers can test it without allocating
    var boxX as Number = 0;
    var boxY as Number = 0;
    var boxWidth as Number = 0;
    var boxHeight as Number = 0;
    var centerDegrees as Numeric = 0;

    //! Restrict drawing to the square around one position of the dot
    //! @param dc The drawing context
    //! @param x The dot's center
    //! @param y The dot's center
    //! @param radius The dot's radius
    //! @param valueDegrees Where the dot sits, clockwise from noon
    function clip(dc as Dc, x as Number, y as Number, radius as Number, valueDegrees as Numeric) as Void {
        var reach = radius + PADDING;
        var x1 = x - reach;
        var y1 = y - reach;
        var x2 = x + reach + 1;
        var y2 = y + reach + 1;

        if (x1 < 0) { x1 = 0; }
        if (y1 < 0) { y1 = 0; }
        if (x2 > Dial.screenWidth) { x2 = Dial.screenWidth; }
        if (y2 > Dial.screenHeight) { y2 = Dial.screenHeight; }

        boxX = x1;
        boxY = y1;
        boxWidth = x2 - x1;
        boxHeight = y2 - y1;
        centerDegrees = valueDegrees;

        dc.setClip(boxX, boxY, boxWidth, boxHeight);
    }

    //! Can something at this angle land inside the last box? Cheaper than
    //! issuing a draw the clip throws away.
    //! @param valueDegrees Where the shape sits, clockwise from noon
    //! @param angularWidthDegrees How wide the shape is
    //! @return true when it may fall inside the box
    function reaches(valueDegrees as Numeric, angularWidthDegrees as Numeric) as Boolean {
        var gap = centerDegrees - valueDegrees;

        if (gap < 0) {
            gap = -gap;
        }

        if (gap > (Dial.DEGREES_PER_CIRCLE / 2)) {
            gap = Dial.DEGREES_PER_CIRCLE - gap;
        }

        return gap <= (SLOP_DEGREES + (angularWidthDegrees / 2.0));
    }

    //! Whether the last box overlaps the given rectangle. Lets anything drawn
    //! inside the rim ask once whether a partial update has cut into it.
    //! @param x The left edge
    //! @param y The top edge
    //! @param width The width
    //! @param height The height
    //! @return true when the two overlap
    function covers(x as Number, y as Number, width as Number, height as Number) as Boolean {
        return (x < (boxX + boxWidth))
            && ((x + width) > boxX)
            && (y < (boxY + boxHeight))
            && ((y + height) > boxY);
    }
}
