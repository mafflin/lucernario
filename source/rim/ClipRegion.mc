import Toybox.Graphics;
import Toybox.Lang;

//! What a partial update may touch: one box around the seconds hand, and
//! the test that tells anything under it whether the clip has cut into it.
module ClipRegion {

    //! Pixels past a shape on every side, for its smoothed edges
    const PADDING = 1;

    //! The last clip, as four numbers so the module constructs nothing
    var boxX as Number = 0;
    var boxY as Number = 0;
    var boxWidth as Number = 0;
    var boxHeight as Number = 0;

    //! Clip to a box, cut down to the screen
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

    //! Whether the last clip shares a pixel with a box
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
