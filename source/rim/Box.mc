import Toybox.Lang;

//! An upright box around a shape: what a partial update clips to, and what
//! everything under the hand is tested against. One per shape, filled in
//! place so the per-second path allocates nothing. Padded on every side by
//! ClipRegion.PADDING for smoothed edges.
class Box {

    //! Nothing inside while either count is zero
    var left as Number = 0;
    var top as Number = 0;
    var width as Number = 0;
    var height as Number = 0;

    function initialize() {
    }

    function isEmpty() as Boolean {
        return (width <= 0) || (height <= 0);
    }

    //! For a shape that is not on screen
    function clear() as Void {
        width = 0;
        height = 0;
    }

    //! A rectangle as it is, unpadded
    function set(x as Number, y as Number, w as Number, h as Number) as Void {
        left = x;
        top = y;
        width = w;
        height = h;
    }

    //! Around a rectangle centered on a point
    function aroundCenter(centerX as Number, centerY as Number, w as Number, h as Number) as Void {
        set(
            centerX - (w / 2) - ClipRegion.PADDING,
            centerY - (h / 2) - ClipRegion.PADDING,
            w + (2 * ClipRegion.PADDING),
            h + (2 * ClipRegion.PADDING)
        );
    }

    //! Around a line, with the pen's reach on every side
    function aroundLine(x1 as Number, y1 as Number, x2 as Number, y2 as Number, reach as Number) as Void {
        enclose(least(x1, x2), least(y1, y2), most(x1, x2), most(y1, y2), reach);
    }

    function aroundCorners(x1 as Number, y1 as Number, x2 as Number, y2 as Number, x3 as Number, y3 as Number) as Void {
        enclose(
            least(least(x1, x2), x3),
            least(least(y1, y2), y3),
            most(most(x1, x2), x3),
            most(most(y1, y2), y3),
            0
        );
    }

    private function enclose(minX as Number, minY as Number, maxX as Number, maxY as Number, reach as Number) as Void {
        var pad = reach + ClipRegion.PADDING;

        // The far pixel is inside, so the count is one more than the difference.
        set(
            minX - pad,
            minY - pad,
            (maxX - minX) + 1 + (2 * pad),
            (maxY - minY) + 1 + (2 * pad)
        );
    }

    private function least(a as Number, b as Number) as Number {
        return (a < b) ? a : b;
    }

    private function most(a as Number, b as Number) as Number {
        return (a > b) ? a : b;
    }
}
