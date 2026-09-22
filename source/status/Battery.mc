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
    private const _EMPTY_LEVEL = 0;
    private const _LOW_LEVEL = 1;
    private const _TOP_LEVEL = 10;

    //! Colors the two lowest levels are drawn in, whatever the face's own
    //! color is. Both read against a light background and a dark one.
    private const _EMPTY_COLOR = Graphics.COLOR_RED;
    private const _LOW_COLOR = Graphics.COLOR_ORANGE;

    //! One bitmap per level, from empty to full
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

    //! The level last read. Reached from the partial update too, so the
    //! charge is looked up once a minute rather than once a call.
    private var _level as Number = _EMPTY_LEVEL;
    private var _reading as MinuteGate;

    //! Constructor. No single resource: bitmap() picks one per charge level.
    function initialize() {
        Icon.initialize(null);
        _reading = new MinuteGate();
    }

    //! The bitmap for the current charge level
    //! @return The bitmap
    protected function bitmap() as BitmapResource {
        if (_reading.opens()) {
            _level = level();
        }

        return choose(_images, _level);
    }

    //! Red when empty, orange when low, the face's own color otherwise
    //! @return The color to draw in
    protected function tint() as Number {
        if (_level == _EMPTY_LEVEL) {
            return _EMPTY_COLOR;
        }

        if (_level == _LOW_LEVEL) {
            return _LOW_COLOR;
        }

        return Icon.tint();
    }

    //! The charge as one of eleven levels
    //! @return The level, empty to top
    private function level() as Number {
        var reading = System.getSystemStats().battery.toNumber() / _PERCENT_PER_LEVEL;

        if (reading < _EMPTY_LEVEL) {
            return _EMPTY_LEVEL;
        }

        if (reading > _TOP_LEVEL) {
            return _TOP_LEVEL;
        }

        return reading;
    }
}
