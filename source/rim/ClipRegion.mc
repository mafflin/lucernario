import Toybox.Graphics;
import Toybox.Lang;

//! What a partial update is allowed to touch: one box around the seconds
//! hand, and the test that tells what is drawn under it whether it falls
//! inside. A partial update has a budget, and the cheapest draw is the one
//! never issued.
module ClipRegion {

    //! Pixels past a shape on every side, for its smoothed edges. Shapes are
    //! placed on whole pixels already, so there is no rounding to cover.
    const PADDING = 1;

    //! The last clip, kept as four numbers rather than a Box so the module
    //! has nothing to construct
    var boxX as Number = 0;
    var boxY as Number = 0;
    var boxWidth as Number = 0;
    var boxHeight as Number = 0;

    //! Restrict drawing to the box around one position of the hand, cut down
    //! to the screen
    //! @param dc The drawing context
    //! @param shape The box around the hand, padded already
    function clip(dc as Dc, shape as Box) as Void {
        var x1 = shape.left;
        var y1 = shape.top;
        var x2 = shape.left + shape.width;
        var y2 = shape.top + shape.height;

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

    //! Whether the last clip overlaps a shape's box. Lets anything drawn
    //! inside the rim ask once whether a partial update has cut into it.
    //! @param shape The box around the shape
    //! @return true when the two share a pixel
    function covers(shape as Box) as Boolean {
        if (shape.isEmpty()) {
            return false;
        }

        return (shape.left < (boxX + boxWidth))
            && ((shape.left + shape.width) > boxX)
            && (shape.top < (boxY + boxHeight))
            && ((shape.top + shape.height) > boxY);
    }
}
