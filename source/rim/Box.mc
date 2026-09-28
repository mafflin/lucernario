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
    function set(left as Number, top as Number, width as Number, height as Number) as Void {
        self.left = left;
        self.top = top;
        self.width = width;
        self.height = height;
    }

    //! Around a rectangle centered on a point
    function aroundCenter(centerX as Number, centerY as Number, shapeWidth as Number, shapeHeight as Number) as Void {
        set(
            centerX - (shapeWidth / 2) - ClipRegion.PADDING,
            centerY - (shapeHeight / 2) - ClipRegion.PADDING,
            shapeWidth + (2 * ClipRegion.PADDING),
            shapeHeight + (2 * ClipRegion.PADDING)
        );
    }

    //! Around a shape's corners, and penReach past them on every side
    function aroundPoints(points as Array<[Numeric, Numeric]>, penReach as Number) as Void {
        var minX = points[0][0].toNumber();
        var minY = points[0][1].toNumber();
        var maxX = minX;
        var maxY = minY;

        for (var i = 1; i < points.size(); i++) {
            var x = points[i][0].toNumber();
            var y = points[i][1].toNumber();

            if (x < minX) { minX = x; }
            if (x > maxX) { maxX = x; }
            if (y < minY) { minY = y; }
            if (y > maxY) { maxY = y; }
        }

        var pad = penReach + ClipRegion.PADDING;

        // The far pixel is inside, so the count is one more than the difference.
        set(
            minX - pad,
            minY - pad,
            (maxX - minX) + 1 + (2 * pad),
            (maxY - minY) + 1 + (2 * pad)
        );
    }
}
