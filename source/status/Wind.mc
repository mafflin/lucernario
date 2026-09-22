import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Weather;

//! The wind, as an arrow in the status bar.
//!
//! Lifted from the electric watch face, which draws it as a triangle standing
//! on the rim. The reading is the same: a bearing, and a strength in three
//! steps. Here one arrow is turned to the bearing, and the strength is said
//! with color rather than with size.
//!
//! The one item in the row with no artwork behind it. It used to draw the
//! same kind of bitmap as the rest, turned by drawBitmap2, and on the MIP
//! devices that made it the worst looking thing on the face: turning a bitmap
//! needs the bilinear filter, the filter makes part opaque pixels out of an
//! arrow that had none, and a MIP panel cannot composite those - it keeps or
//! drops each one as it draws, so the tail thickened and thinned with the
//! bearing. Three corners turned in code and filled have nothing to sample,
//! and they are smoothed by the same setAntiAlias the rim marks rely on.
class Wind extends Icon {

    //! The API reports metres per second; the limits below read as km/h.
    private const _KMH_PER_MS = 3.6;
    private const _LIGHT_LIMIT_KMH = 20;
    private const _MODERATE_LIMIT_KMH = 40;

    private const _LIGHT = 0;
    private const _MODERATE = 1;
    private const _STRONG = 2;

    //! Colors the two harder steps are drawn in, whatever the face's own
    //! color is. A light wind is left in the face's color: it is the ordinary
    //! case, and nothing worth calling out.
    private const _MODERATE_COLOR = Graphics.COLOR_ORANGE;
    private const _STRONG_COLOR = Graphics.COLOR_RED;

    //! The arrow's corners on the same 24 unit grid the SVGs are drawn on,
    //! scaled to whatever square the row gives this icon. Only the left wing
    //! is named: the right one mirrors it about the middle.
    //!
    //! These follow the dart the bitmap drew - apex at 12,2, wings low and
    //! wide - with the wings moved out half a unit, from 4.5 and 19.5 to 4
    //! and 20. That half unit is what makes the arrow symmetric: straddling a
    //! pixel, whichever way those two corners round, the base comes out off
    //! centre by one. On whole units every corner lands on a whole pixel at
    //! both sizes, 24 and 36, whenever the arrow points at a quarter of the
    //! compass.
    //!
    //! The notch that made it a dart rather than a triangle did not survive
    //! the move. fillPolygon wants a convex shape, and cutting the notch
    //! would take either a concave one or two triangles meeting along an
    //! edge, which the smoothing leaves a seam down: each side rounds its own
    //! half of the shared pixels, and the two halves do not add back up to a
    //! covered pixel.
    private const _GRID = 24.0;
    private const _MIDDLE = _GRID / 2;
    private const _APEX_X = 12;
    private const _APEX_Y = 2;
    private const _WING_X = 4;
    private const _WING_Y = 20;

    //! A compass bearing, which the arrow reads as a clock angle: north up
    private var _bearing as Number? = null;

    //! Which of the three steps the strength calls for
    private var _strength as Number = _LIGHT;

    //! The square the row has given this icon to fill
    private var _square as Number = 0;

    //! The arrow's corners relative to the middle of that square, turned to
    //! the bearing. Held rather than worked out per draw: a partial update
    //! asks for the row again every second the hand sweeps into it, and the
    //! bearing moves once an hour at best.
    private var _corners as Array< Array<Float> >? = null;

    //! Once a minute: the phone refills the weather by the hour at best, and
    //! the row asks every draw.
    private var _reading as MinuteGate;

    //! Constructor. No resource: this icon draws itself.
    function initialize() {
        Icon.initialize(null);
        _reading = new MinuteGate();
    }

    //! Shown once there is a bearing to point at. A watch with no weather
    //! never reads the clock.
    //! @param settings The device settings
    //! @return true when there is a wind to show
    function on(settings as System.DeviceSettings) as Boolean {
        if (!(Toybox has :Weather)) {
            return false;
        }

        readWind();

        return (_bearing != null);
    }

    //! The square this icon fills, which the row hands over.
    //!
    //! With no bitmap there is nothing to measure, and the size the rest of
    //! the row runs at is a build decision - 24px or 36px, picked by the
    //! resourcePath lines in monkey.jungle - rather than one to make a second
    //! time here.
    //! @param square The width and height to fill
    function setSquare(square as Number) as Void {
        if (square == _square) {
            return;
        }

        _square = square;
        _corners = null;
    }

    //! The width of the icon in pixels
    //! @return The width
    function width() as Number {
        return _square;
    }

    //! The height of the icon in pixels
    //! @return The height
    function height() as Number {
        return _square;
    }

    //! Orange once the wind picks up, red when it is hard, the face's own
    //! color the rest of the time
    //! @return The color to draw in
    protected function tint() as Number {
        if (_strength == _STRONG) {
            return _STRONG_COLOR;
        }

        if (_strength == _MODERATE) {
            return _MODERATE_COLOR;
        }

        return Icon.tint();
    }

    //! Fill the arrow, pointing along the bearing.
    //!
    //! Smoothed by the setAntiAlias the view asserts once per draw, which a
    //! triangle has more to gain from than anything square: all three of its
    //! sides slope, and hard edged they read as a staircase rather than as a
    //! lean.
    //! @param dc The drawing context
    //! @param x The left edge
    //! @param y The top edge
    protected function paint(dc as Dc, x as Number, y as Number) as Void {
        if (_square == 0) {
            return;
        }

        if (_corners == null) {
            _corners = cornersFor(_bearing);
        }

        var corners = _corners as Array< Array<Float> >;
        var middleX = x + (_square / 2.0);
        var middleY = y + (_square / 2.0);

        dc.setColor(tint(), Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [pixel(middleX + corners[0][0]), pixel(middleY + corners[0][1])],
            [pixel(middleX + corners[1][0]), pixel(middleY + corners[1][1])],
            [pixel(middleX + corners[2][0]), pixel(middleY + corners[2][1])]
        ]);
    }

    //! The nearest whole pixel. Rounded rather than truncated: truncation
    //! pulls every corner the same way, which at a bearing off the quarters
    //! drags the whole arrow up and to the left by most of a pixel.
    //! @param value The coordinate to place
    //! @return The pixel it lands on
    private function pixel(value as Float) as Number {
        return Math.round(value).toNumber();
    }

    //! The three corners, in pixels from the middle of the square, turned so
    //! the arrow points along the bearing.
    //! @param bearing The compass bearing in degrees, null before a reading
    //! @return The corners, apex first
    private function cornersFor(bearing as Number?) as Array< Array<Float> > {
        // Screen y grows downward, so a positive angle comes out clockwise,
        // which is the way a compass counts.
        var angle = 0.0;

        if (bearing != null) {
            angle = Math.toRadians(bearing).toFloat();
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

    //! One corner, turned about the middle of the square
    //! @param dx How far across the middle it sits
    //! @param dy How far down the middle it sits
    //! @param sine The sine of the angle to turn by
    //! @param cosine The cosine of the angle to turn by
    //! @return The turned corner
    private function turn(dx as Float, dy as Float, sine as Float, cosine as Float) as Array<Float> {
        return [
            (dx * cosine) - (dy * sine),
            (dx * sine) + (dy * cosine)
        ];
    }

    //! The bearing the wind blows from, and how hard
    private function readWind() as Void {
        if (!_reading.opens()) {
            return;
        }

        _bearing = null;
        _corners = null;
        _strength = _LIGHT;

        var conditions = Weather.getCurrentConditions();

        if (conditions == null) {
            return;
        }

        var bearing = conditions.windBearing;

        if (bearing == null) {
            return;
        }

        _bearing = bearing;
        _strength = strengthFor(conditions.windSpeed);
    }

    //! A bearing but no speed still counts as light: direction known,
    //! strength not.
    //! @param speed The wind speed in metres per second, null if unknown
    //! @return Which of the three steps the wind is in
    private function strengthFor(speed as Numeric?) as Number {
        if (speed == null) {
            return _LIGHT;
        }

        var kmh = speed * _KMH_PER_MS;

        if (kmh <= _LIGHT_LIMIT_KMH) {
            return _LIGHT;
        }

        if (kmh <= _MODERATE_LIMIT_KMH) {
            return _MODERATE;
        }

        return _STRONG;
    }
}
