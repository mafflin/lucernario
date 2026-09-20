import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! The charge level, as one of eleven bitmaps.
//!
//! The only icon that says something with color: the artwork carries the
//! level, and the color carries how much that level matters.
class Battery extends Icon {

    private const _PERCENT_PER_LEVEL = 10;
    private const _TOP_LEVEL = 10;
    private const _EMPTY_LEVEL = 0;
    private const _LOW_LEVEL = 1;
    private const _NO_LEVEL = -1;
    private const _NO_MINUTE = -1;

    //! Colors the two lowest levels are drawn in, whatever the face's own
    //! color is. Both read against a light background and a dark one.
    private const _EMPTY_COLOR = Graphics.COLOR_RED;
    private const _LOW_COLOR = Graphics.COLOR_ORANGE;

    private var _images as Array<ResourceId> = [
        Rez.Drawables.Battery0,
        Rez.Drawables.Battery10,
        Rez.Drawables.Battery20,
        Rez.Drawables.Battery30,
        Rez.Drawables.Battery40,
        Rez.Drawables.Battery50,
        Rez.Drawables.Battery60,
        Rez.Drawables.Battery70,
        Rez.Drawables.Battery80,
        Rez.Drawables.Battery90,
        Rez.Drawables.Battery100
    ];

    private var _cachedLevel as Number = _NO_LEVEL;
    private var _cachedMinute as Number = _NO_MINUTE;

    //! Constructor. No single resource: bitmap() picks one per charge level.
    function initialize() {
        Icon.initialize(null);
    }

    //! The bitmap for the current charge level
    //! @return The bitmap
    protected function bitmap() as BitmapResource {
        // Reached from the partial update too, so look the charge up once a
        // minute rather than once a call.
        var minute = System.getClockTime().min;

        if (minute != _cachedMinute) {
            _cachedMinute = minute;
            _cachedLevel = level();
        }

        return choose(_images, _cachedLevel);
    }

    //! Red when empty, orange when low, the face's own color otherwise
    //! @return The color to draw in
    protected function tint() as Number {
        if (_cachedLevel == _EMPTY_LEVEL) {
            return _EMPTY_COLOR;
        }

        if (_cachedLevel == _LOW_LEVEL) {
            return _LOW_COLOR;
        }

        return Icon.tint();
    }

    //! The charge as one of eleven levels
    //! @return The level, 0 to 10
    private function level() as Number {
        var reading = System.getSystemStats().battery.toNumber() / _PERCENT_PER_LEVEL;

        if (reading < 0) {
            return 0;
        }

        if (reading > _TOP_LEVEL) {
            return _TOP_LEVEL;
        }

        return reading;
    }
}
