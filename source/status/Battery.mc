import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! The charge as one of eleven bitmaps, red when empty and orange when low.
class Battery extends Icon {

    private const _PERCENT_PER_LEVEL = 10;
    private const _EMPTY_LEVEL = 0;
    private const _LOW_LEVEL = 1;
    private const _TOP_LEVEL = 10;

    //! Both read against either background
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

    //! Read once a minute: bitmap() is reached from the partial update too
    private var _level as Number = _EMPTY_LEVEL;
    private var _reading as MinuteGate;

    function initialize() {
        Icon.initialize(null);
        _reading = new MinuteGate();
    }

    protected function bitmap() as BitmapResource {
        if (_reading.opens()) {
            _level = level();
        }

        return choose(_images, _level);
    }

    protected function tint() as Number {
        if (_level == _EMPTY_LEVEL) {
            return _EMPTY_COLOR;
        }

        if (_level == _LOW_LEVEL) {
            return _LOW_COLOR;
        }

        return Icon.tint();
    }

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
