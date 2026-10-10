import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

//! Shown while there is recovery time left, its length said with color as
//! the wind's strength is: amber past a day, orange past two.
class Recovery extends Icon {

    //! The limits in minutes, which the complication carries: a day and two
    private const MODERATE_LIMIT_MINUTES = 1440;
    private const LONG_LIMIT_MINUTES = 2880;

    //! Up to a day is the ordinary case and keeps its drawer's color
    private const MODERATE_COLOR = Palette.AMBER;
    private const LONG_COLOR = Palette.ORANGE;

    private var recoveryId as Complications.Id;

    private var minutes as Number = 0;

    //! Once a minute: the time counts down by the minute at most
    private var minuteGate as MinuteGate;

    function initialize() {
        Icon.initialize(Rez.Drawables.Recovery);
        recoveryId = new Complications.Id(Complications.COMPLICATION_TYPE_RECOVERY_TIME);
        minuteGate = new MinuteGate();
    }

    //! Read here, once a minute: the row asks every icon before it draws
    function isReporting(settings as System.DeviceSettings) as Boolean {
        if (minuteGate.opens()) {
            var value = ComplicationReader.valueOf(recoveryId);

            minutes = (value != null) ? ComplicationFormat.wholeNumber(value) : 0;
        }

        return minutes > 0;
    }

    //! Amber past a day, orange past two, the given color otherwise
    protected function tint() as Number {
        if (minutes > LONG_LIMIT_MINUTES) {
            return LONG_COLOR;
        }

        if (minutes > MODERATE_LIMIT_MINUTES) {
            return MODERATE_COLOR;
        }

        return Icon.tint();
    }
}
