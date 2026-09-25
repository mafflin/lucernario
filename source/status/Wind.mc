import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

//! The wind as an arrow in the status row, turned to the bearing, strength
//! said with color - see WindReading. Drawn as three corners rather than a
//! turned bitmap: the bilinear filter makes part-opaque pixels a MIP panel
//! cannot composite, so a turned bitmap's tail wobbles with the bearing.
class Wind extends Icon {

    //! Corners on the 24 unit grid the SVGs use, scaled to the row's square.
    //! Whole units so every corner lands on a pixel at 24 and 36; the right
    //! wing mirrors the left. A convex triangle: a notched dart would need
    //! two polygons, and smoothing leaves a seam where they meet.
    private const _GRID = 24.0;
    private const _MIDDLE = _GRID / 2;
    private const _APEX_X = 12;
    private const _APEX_Y = 2;
    private const _WING_X = 4;
    private const _WING_Y = 20;

    private var _wind as WindReading;
    private var _enabled as Boolean = true;

    //! The square the row gives this icon
    private var _square as Number = 0;

    //! Corners about the square's middle, held until the bearing moves
    private var _corners as Array< Array<Float> >? = null;
    private var _cornersBearing as Number? = null;

    function initialize(wind as WindReading) {
        Icon.initialize(null);
        _wind = wind;
    }

    //! false while the dial shows the bearing instead
    function setEnabled(enabled as Boolean) as Void {
        _enabled = enabled;
    }

    function on(settings as System.DeviceSettings) as Boolean {
        return _enabled && (_wind.bearing() != null);
    }

    //! No bitmap to measure: the size is the build's, 24px or 36px
    function setSquare(square as Number) as Void {
        if (square == _square) {
            return;
        }

        _square = square;
        _corners = null;
    }

    function width() as Number {
        return _square;
    }

    function height() as Number {
        return _square;
    }

    protected function tint() as Number {
        return _wind.colorFor(Icon.tint());
    }

    protected function paint(dc as Dc, x as Number, y as Number) as Void {
        if (_square == 0) {
            return;
        }

        var bearing = _wind.bearing();

        if ((_corners == null) || (bearing != _cornersBearing)) {
            _corners = cornersFor(bearing);
            _cornersBearing = bearing;
        }

        var corners = _corners as Array< Array<Float> >;
        var middleX = x + (_square / 2.0);
        var middleY = y + (_square / 2.0);

        dc.setColor(tint(), Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [Dial.pixel(middleX + corners[0][0]), Dial.pixel(middleY + corners[0][1])],
            [Dial.pixel(middleX + corners[1][0]), Dial.pixel(middleY + corners[1][1])],
            [Dial.pixel(middleX + corners[2][0]), Dial.pixel(middleY + corners[2][1])]
        ]);
    }

    //! Apex first, turned to point downwind
    private function cornersFor(bearing as Number?) as Array< Array<Float> > {
        // Screen y grows downward, so a positive angle is clockwise, as a
        // compass counts.
        var angle = 0.0;

        // The bearing is where the wind comes from; the arrow points where it goes.
        if (bearing != null) {
            angle = Math.toRadians(bearing + Dial.HALF_TURN).toFloat();
        }

        var sine = Math.sin(angle).toFloat();
        var cosine = Math.cos(angle).toFloat();
        var scale = _square / _GRID;

        return [
            turn((_APEX_X - _MIDDLE) * scale, (_APEX_Y - _MIDDLE) * scale, sine, cosine),
            turn((_WING_X - _MIDDLE) * scale, (_WING_Y - _MIDDLE) * scale, sine, cosine),
            turn((_MIDDLE - _WING_X) * scale, (_WING_Y - _MIDDLE) * scale, sine, cosine)
        ];
    }

    private function turn(dx as Float, dy as Float, sine as Float, cosine as Float) as Array<Float> {
        return [
            (dx * cosine) - (dy * sine),
            (dx * sine) + (dy * cosine)
        ];
    }
}
