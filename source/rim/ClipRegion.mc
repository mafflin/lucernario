import Toybox.Graphics;
import Toybox.Lang;

//! What a partial update is allowed to touch: one box around the seconds
//! hand, and the test that tells what is drawn under it whether it falls
//! inside. A partial update has a budget, and the cheapest draw is the one
//! never issued.
module ClipRegion {

    //! Pixels past the hand on every side, for its smoothed edges. Its
    //! corners are whole pixels already, so there is no rounding to cover.
    const PADDING = 1;

    //! The last box, so callers can test it without allocating
    var boxX as Number = 0;
    var boxY as Number = 0;
    var boxWidth as Number = 0;
    var boxHeight as Number = 0;

    //! Restrict drawing to the box around one position of the hand
    //! @param dc The drawing context
    //! @param left The hand's leftmost pixel
    //! @param top The hand's topmost pixel
    //! @param right The hand's rightmost pixel
    //! @param bottom The hand's bottommost pixel
    function clip(dc as Dc, left as Number, top as Number, right as Number, bottom as Number) as Void {
        var x1 = left - PADDING;
        var y1 = top - PADDING;
        var x2 = right + PADDING + 1;
        var y2 = bottom + PADDING + 1;

        if (x1 < 0) { x1 = 0; }
        if (y1 < 0) { y1 = 0; }
        if (x2 > Dial.screenWidth) { x2 = Dial.screenWidth; }
        if (y2 > Dial.screenHeight) { y2 = Dial.screenHeight; }

        boxX = x1;
        boxY = y1;
        boxWidth = x2 - x1;
        boxHeight = y2 - y1;

        dc.setClip(boxX, boxY, boxWidth, boxHeight);
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
