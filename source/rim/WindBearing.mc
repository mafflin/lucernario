import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The wind on the dial: an equilateral triangle the size of the seconds
//! hand, standing on the rim at the bearing, pointing the way it blows.
//! Accent color for a light wind, then orange and red - see WindReading.
//! Reaching past the marks, it is put back when the seconds hand's clip
//! cuts into it.
class WindBearing {

    private var _wind as WindReading;
    private var _enabled as Boolean = false;

    //! For a light wind
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Base width, and half the angle its ends span on the rim
    private var _base as Float = 0.0;
    private var _halfSpread as Float = 0.0;

    //! As last drawn, so a partial update can put it back
    private var _shown as Boolean = false;
    private var _points as Array<[Numeric, Numeric]>;
    private var _drawnColor as Number = Graphics.COLOR_WHITE;
    private var _box as Box;
    private var _pointsBearing as Number? = null;

    function initialize(wind as WindReading) {
        _wind = wind;
        _points = [[0, 0], [0, 0], [0, 0]] as Array<[Numeric, Numeric]>;
        _box = new Box();
    }

    //! After Dial.setup()
    function prepare(base as Float) as Void {
        _base = base;

        // The base is a chord of the rim.
        _halfSpread = Math.asin(base / (2 * Dial.rim)).toFloat();
        _pointsBearing = null;
    }

    function setEnabled(enabled as Boolean) as Void {
        _enabled = enabled;
    }

    function setColor(color as Number) as Void {
        _color = color;
    }

    function draw(dc as Dc) as Void {
        var bearing = _wind.bearing();

        _shown = false;

        if (!_enabled || (bearing == null)) {
            return;
        }

        _shown = true;

        if (bearing != _pointsBearing) {
            place(bearing);
        }

        _drawnColor = _wind.colorFor(_color);
        paint(dc);
    }

    //! Put it back if the clip has cut into it
    function redraw(dc as Dc) as Void {
        if (_shown && ClipRegion.covers(_box)) {
            paint(dc);
        }
    }

    private function paint(dc as Dc) as Void {
        RimPainter.fill(dc, _points, _drawnColor);
    }

    //! A compass bearing reads as clockwise from the top of the dial
    private function place(bearing as Number) as Void {
        var point = Dial.radiansOf(bearing);
        var left = point + _halfSpread;
        var right = point - _halfSpread;
        var tipRadius = Dial.rim - (_base * RimPainter.EQUILATERAL_HEIGHT);

        var leftX = Dial.pointX(left, Dial.rim);
        var leftY = Dial.pointY(left, Dial.rim);
        var rightX = Dial.pointX(right, Dial.rim);
        var rightY = Dial.pointY(right, Dial.rim);
        var tipX = Dial.pointX(point, tipRadius);
        var tipY = Dial.pointY(point, tipRadius);

        _points[0] = [leftX, leftY];
        _points[1] = [rightX, rightY];
        _points[2] = [tipX, tipY];
        _pointsBearing = bearing;

        _box.aroundCorners(leftX, leftY, rightX, rightY, tipX, tipY);
    }
}
