import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! The charge as one of eleven bitmaps, red when empty and orange when low.
class Battery extends Icon {

    private const PERCENT_PER_LEVEL = 10;
    private const EMPTY_LEVEL = 0;
    private const LOW_LEVEL = 1;
    private const TOP_LEVEL = 10;

    private const EMPTY_COLOR = Graphics.COLOR_RED;
    private const LOW_COLOR = Graphics.COLOR_ORANGE;

    //! One per level
    private var images as Array<ResourceId> = [
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

    //! Read once a minute, on the full draw: bitmap() is reached from the
    //! partial update too
    private var level as Number = EMPTY_LEVEL;
    private var minuteGate as MinuteGate;

    function initialize() {
        Icon.initialize(null);
        minuteGate = new MinuteGate();
    }

    //! Always; the read rides along, once a draw
    function isReporting(settings as System.DeviceSettings) as Boolean {
        if (minuteGate.opens()) {
            level = readLevel();
        }

        return true;
    }

    protected function bitmap() as BitmapResource {
        return choose(images, level);
    }

    protected function tint() as Number {
        if (level == EMPTY_LEVEL) {
            return EMPTY_COLOR;
        }

        if (level == LOW_LEVEL) {
            return LOW_COLOR;
        }

        return Icon.tint();
    }

    private function readLevel() as Number {
        var charge = System.getSystemStats().battery.toNumber() / PERCENT_PER_LEVEL;

        if (charge < EMPTY_LEVEL) {
            return EMPTY_LEVEL;
        }

        if (charge > TOP_LEVEL) {
            return TOP_LEVEL;
        }

        return charge;
    }
}
