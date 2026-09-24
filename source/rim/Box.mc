import Toybox.Lang;

//! An upright box around something drawn on the face: what a partial update
//! clips to around the seconds hand, and what everything the hand can sweep
//! over is tested against to see whether the clip has cut into it.
//!
//! One per shape, filled in place on the full draw rather than made anew:
//! the per-second path allocates nothing. Whatever it is put around, it is
//! padded on every side for the smoothed edges a shape spills past its own
//! pixels - see ClipRegion.PADDING.
class Box {

    //! The top left pixel, and how many pixels across and down. Nothing
    //! inside while either count is zero.
    var left as Number = 0;
    var top as Number = 0;
    var width as Number = 0;
    var height as Number = 0;

    //! Constructor
    function initialize() {
    }

    //! Whether there is anything inside
    //! @return true when the box holds no pixels
    function isEmpty() as Boolean {
        return (width <= 0) || (height <= 0);
    }

    //! Leave nothing inside, for a shape that is not on screen
    function clear() as Void {
        width = 0;
        height = 0;
    }

    //! Take a rectangle as it is, unpadded
    //! @param x The left edge
    //! @param y The top edge
    //! @param w The width
    //! @param h The height
    function set(x as Number, y as Number, w as Number, h as Number) as Void {
        left = x;
        top = y;
        width = w;
        height = h;
    }

    //! Around a rectangle centered on a point
    //! @param centerX Where its middle sits across
    //! @param centerY Where its middle sits down
    //! @param w The rectangle's width
    //! @param h The rectangle's height
    function aroundCenter(centerX as Number, centerY as Number, w as Number, h as Number) as Void {
        set(
            centerX - (w / 2) - ClipRegion.PADDING,
            centerY - (h / 2) - ClipRegion.PADDING,
            w + (2 * ClipRegion.PADDING),
            h + (2 * ClipRegion.PADDING)
        );
    }

    //! Around a line between two pixels, with the pen's reach on every side
    //! @param x1 One end
    //! @param y1 One end
    //! @param x2 The other end
    //! @param y2 The other end
    //! @param reach How far past the line the pen goes
    function aroundLine(x1 as Number, y1 as Number, x2 as Number, y2 as Number, reach as Number) as Void {
        enclose(least(x1, x2), least(y1, y2), most(x1, x2), most(y1, y2), reach);
    }

    //! Around three corners
    //! @param x1 The first corner
    //! @param y1 The first corner
    //! @param x2 The second corner
    //! @param y2 The second corner
    //! @param x3 The third corner
    //! @param y3 The third corner
    function aroundCorners(x1 as Number, y1 as Number, x2 as Number, y2 as Number, x3 as Number, y3 as Number) as Void {
        enclose(
            least(least(x1, x2), x3),
            least(least(y1, y2), y3),
            most(most(x1, x2), x3),
            most(most(y1, y2), y3),
            0
        );
    }

    //! Around the pixels from one corner to another, plus a reach on every
    //! side and the padding
    //! @param minX The leftmost pixel
    //! @param minY The topmost pixel
    //! @param maxX The rightmost pixel
    //! @param maxY The bottommost pixel
    //! @param reach How far past those the shape goes
    private function enclose(minX as Number, minY as Number, maxX as Number, maxY as Number, reach as Number) as Void {
        var pad = reach + ClipRegion.PADDING;

        // The far pixel is inside the box, so the count is one more than the
        // difference.
        set(
            minX - pad,
            minY - pad,
            (maxX - minX) + 1 + (2 * pad),
            (maxY - minY) + 1 + (2 * pad)
        );
    }

    //! The lesser of two
    //! @param a The first
    //! @param b The second
    //! @return The lesser
    private function least(a as Number, b as Number) as Number {
        return (a < b) ? a : b;
    }

    //! The greater of two
    //! @param a The first
    //! @param b The second
    //! @return The greater
    private function most(a as Number, b as Number) as Number {
        return (a > b) ? a : b;
    }
}
