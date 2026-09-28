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
        var left = shape.left;
        var top = shape.top;
        var right = shape.left + shape.width;
        var bottom = shape.top + shape.height;

        if (left < 0) { left = 0; }
        if (top < 0) { top = 0; }
        if (right > Dial.screenWidth) { right = Dial.screenWidth; }
        if (bottom > Dial.screenHeight) { bottom = Dial.screenHeight; }

        boxX = left;
        boxY = top;
        boxWidth = right - left;
        boxHeight = bottom - top;

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
