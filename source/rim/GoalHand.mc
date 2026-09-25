import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! A dot going round once to the goal, just inside the marks
class GoalHand extends WatchUi.Drawable {

    //! Air between the dot and the marks
    private const _MARK_GAP = 2;
    private const _MIN_RADIUS = 2;

    private var _progress as GoalProgress;
    private var _enabled as Boolean = false;
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare()
    private var _radius as Number = _MIN_RADIUS;
    private var _center as Number = 0;

    //! As last drawn; empty when not shown
    private var _x as Number = 0;
    private var _y as Number = 0;
    private var _box as Box;

    function initialize(progress as GoalProgress) {
        Drawable.initialize({ :identifier => SlotId.GOAL });

        _progress = progress;
        _box = new Box();
    }

    //! After the marks are prepared
    function prepare(markReach as Number, markWidth as Number) as Void {
        _radius = (markWidth < _MIN_RADIUS) ? _MIN_RADIUS : markWidth;
        _center = Dial.rim - markReach - RimPainter.penRadius(markWidth) - _MARK_GAP - _radius;
    }

    function setEnabled(enabled as Boolean) as Void {
        _enabled = enabled;
    }

    function isEnabled() as Boolean {
        return _enabled;
    }

    function setColor(color as Number) as Void {
        _color = color;
    }

    function draw(dc as Dc) as Void {
        var share = _progress.share();

        if (!_enabled || (share == null)) {
            _box.clear();
            return;
        }

        place(share);

        if (isVisible) {
            paint(dc);
        }
    }

    //! Put it back if the clip has cut into it
    function redraw(dc as Dc) as Void {
        if (ClipRegion.covers(_box)) {
            paint(dc);
        }
    }

    //! A box of its own when not shown, so redraw() finds nothing
    function getBoundingBox() as Graphics.BoundingBox {
        var box = _box;

        if (box.isEmpty()) {
            var radians = Dial.radiansOf(0);

            box = new Box();
            surround(box, Dial.pointX(radians, _center), Dial.pointY(radians, _center));
        }

        var boundingBox = new Graphics.BoundingBox();
        boundingBox.addRectangle(box.left, box.top, box.width, box.height);

        return boundingBox;
    }

    private function place(share as Float) as Void {
        var radians = Dial.radiansOf(share * Dial.DEGREES_PER_CIRCLE);

        _x = Dial.pointX(radians, _center);
        _y = Dial.pointY(radians, _center);
        surround(_box, _x, _y);
    }

    private function surround(box as Box, x as Number, y as Number) as Void {
        var across = (2 * _radius) + 1;

        box.aroundCenter(x, y, across, across);
    }

    private function paint(dc as Dc) as Void {
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_x, _y, _radius);
    }
}
