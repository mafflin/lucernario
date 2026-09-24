import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The wind on the dial: a triangle standing on the rim at the bearing the
//! wind blows from, pointing in the way it blows. North is at the top.
//!
//! Equilateral and always the one size, the seconds hand's. The strength is
//! said with color: the accent color for a light wind, then orange and red
//! as it picks up - see WindReading.
//!
//! Only on the style that asks for it. It reaches past the marks, into the
//! clip of a seconds hand passing it, so a partial update puts it back when
//! the clip has cut into it: a tick or two a minute.
class WindBearing {

    //! Pixels past the corners for the smoothed edges, on the box a partial
    //! update tests it against
    private const _BOX_PADDING = 1;

    //! The wind, shared with the arrow in the status row
    private var _wind as WindReading;

    //! Whether the dial shows the bearing at all
    private var _enabled as Boolean = false;

    //! The color a light wind is drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! How wide the base is, and how far either side of the bearing its ends
    //! sit on the rim, resolved in prepare()
    private var _base as Float = 0.0;
    private var _halfSpread as Float = 0.0;

    //! The corners it was last drawn with, the color, and the box around
    //! them, taken in draw() so a partial update can put it back as it was
    private var _shown as Boolean = false;
    private var _points as Array<[Numeric, Numeric]>;
    private var _drawnColor as Number = Graphics.COLOR_WHITE;
    private var _left as Number = 0;
    private var _top as Number = 0;
    private var _boxWidth as Number = 0;
    private var _boxHeight as Number = 0;

    //! The bearing the corners were worked out for
    private var _pointsBearing as Number? = null;

    //! Constructor
    //! @param wind The wind, shared with the arrow in the status row
    function initialize(wind as WindReading) {
        _wind = wind;
        _points = [[0, 0], [0, 0], [0, 0]] as Array<[Numeric, Numeric]>;
    }

    //! Size the triangle. Run after Dial.setup().
    //! @param base How wide its base is, in pixels
    function prepare(base as Float) as Void {
        _base = base;

        // The ends of the base sit on the rim: the chord of this width.
        _halfSpread = Math.asin(base / (2 * Dial.rim)).toFloat();
        _pointsBearing = null;
    }

    //! Whether the dial shows the bearing
    //! @param enabled true on the style that asks for it
    function setEnabled(enabled as Boolean) as Void {
        _enabled = enabled;
    }

    //! Set the color a light wind is drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw the triangle at the bearing, if there is one to show
    //! @param dc The drawing context
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

    //! Put the triangle back if the clip of a partial update has cut into it
    //! @param dc The drawing context
    function redraw(dc as Dc) as Void {
        if (_shown && ClipRegion.covers(_left, _top, _boxWidth, _boxHeight)) {
            paint(dc);
        }
    }

    //! Fill the triangle at its last corners
    //! @param dc The drawing context
    private function paint(dc as Dc) as Void {
        RimPainter.fill(dc, _points, _drawnColor);
    }

    //! Work out the corners at a bearing, and the box around them
    //! @param bearing The compass bearing, which the dial reads as clockwise
    //!        from the top
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

        var minX = min3(leftX, rightX, tipX) - _BOX_PADDING;
        var minY = min3(leftY, rightY, tipY) - _BOX_PADDING;

        _left = minX;
        _top = minY;
        _boxWidth = max3(leftX, rightX, tipX) + _BOX_PADDING + 1 - minX;
        _boxHeight = max3(leftY, rightY, tipY) + _BOX_PADDING + 1 - minY;
    }

    //! The least of three
    //! @param a The first
    //! @param b The second
    //! @param c The third
    //! @return The least
    private function min3(a as Number, b as Number, c as Number) as Number {
        var least = (a < b) ? a : b;

        return (least < c) ? least : c;
    }

    //! The greatest of three
    //! @param a The first
    //! @param b The second
    //! @param c The third
    //! @return The greatest
    private function max3(a as Number, b as Number, c as Number) as Number {
        var most = (a > b) ? a : b;

        return (most > c) ? most : c;
    }
}
