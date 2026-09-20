import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Weather;

//! The wind, as an arrow in the status bar.
//!
//! Lifted from the electric watch face, which draws it as a triangle standing
//! on the rim. The reading is the same: a bearing, and a strength in three
//! steps. Here one arrow is turned to the bearing, and the strength is said
//! with color rather than with size.
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

    private const _NO_MINUTE = -1;

    //! A compass bearing, which the arrow reads as a clock angle: north up
    private var _bearing as Number? = null;

    //! Which of the three arrows the strength calls for
    private var _strength as Number = _LIGHT;

    //! The turn that puts the arrow on the bearing, worked out when the
    //! reading changes rather than on every draw
    private var _rotation as AffineTransform? = null;

    private var _cachedMinute as Number = _NO_MINUTE;

    //! Constructor
    function initialize() {
        Icon.initialize(Rez.Drawables.Wind);
    }

    //! Shown once there is a bearing to point at. A watch with no weather
    //! never reads the clock or loads a bitmap.
    //! @param settings The device settings
    //! @return true when there is a wind to show
    function on(settings as System.DeviceSettings) as Boolean {
        if (!(Toybox has :Weather)) {
            return false;
        }

        readWind();

        return (_bearing != null);
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

    //! The turn that puts the arrow on the bearing
    //! @return The transform, or null before there is a reading
    protected function transform() as AffineTransform? {
        return _rotation;
    }

    //! The bearing the wind blows from, and how hard.
    //!
    //! Once a minute: the phone refills this by the hour at best, and the row
    //! asks every draw.
    private function readWind() as Void {
        var minute = System.getClockTime().min;

        if (minute == _cachedMinute) {
            return;
        }

        _cachedMinute = minute;
        _bearing = null;
        _rotation = null;
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
        _rotation = rotationFor(bearing);
    }

    //! Turn the artwork, which points north, around its own middle
    //! @param bearing The compass bearing in degrees
    //! @return The transform to draw with
    private function rotationFor(bearing as Number) as AffineTransform {
        // AffineTransform takes floats, and toRadians hands back a double.
        var halfWidth = (width() / 2.0).toFloat();
        var halfHeight = (height() / 2.0).toFloat();
        var angle = Math.toRadians(bearing).toFloat();

        var rotation = new Graphics.AffineTransform();

        // Screen y grows downward, so a positive angle reads as clockwise,
        // which is the way a compass counts.
        rotation.translate(halfWidth, halfHeight);
        rotation.rotate(angle);
        rotation.translate(-halfWidth, -halfHeight);

        return rotation;
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
