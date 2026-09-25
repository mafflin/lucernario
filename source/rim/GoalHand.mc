import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The goal hand: a dot going round once to the goal picked in the editor's
//! goal slot, in the accent color, just inside the marks. A Drawable so the
//! editor can pulse it in place. The seconds hand passes over it, so it is
//! put back when the hand's clip cuts into it.
class GoalHand extends WatchUi.Drawable {

    //! Air between the dot and the marks' pen ends, for the smoothing
    private const _MARK_GAP = 2;
    private const _MIN_RADIUS = 2;

    private var _progress as GoalProgress;
    private var _enabled as Boolean = false;
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare()
    private var _radius as Number = _MIN_RADIUS;
    private var _center as Number = 0;

    //! As last drawn, so a partial update can put it back; empty when not shown
    private var _x as Number = 0;
    private var _y as Number = 0;
    private var _box as Box;

    function initialize(progress as GoalProgress) {
        Drawable.initialize({ :identifier => FieldLocation.GOAL });

        _progress = progress;
        _box = new Box();
    }

    //! After the marks are prepared; as wide across as two hour marks
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

    //! Hidden while the editor pulses it, so it is not drawn twice
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

    //! What the editor outlines: the dot, or where it starts with no reading
    function getBoundingBox() as Graphics.BoundingBox {
        if (_box.isEmpty()) {
            place(0.0);
        }

        var boundingBox = new Graphics.BoundingBox();
        boundingBox.addRectangle(_box.left, _box.top, _box.width, _box.height);

        return boundingBox;
    }

    private function place(share as Float) as Void {
        var radians = Dial.radiansOf(share * Dial.DEGREES_PER_CIRCLE);
        var across = (2 * _radius) + 1;

        _x = Dial.pointX(radians, _center);
        _y = Dial.pointY(radians, _center);
        _box.aroundCenter(_x, _y, across, across);
    }

    private function paint(dc as Dc) as Void {
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_x, _y, _radius);
    }
}
