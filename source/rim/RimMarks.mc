import Toybox.Graphics;
import Toybox.Lang;

//! 24 hour marks, midnight at the top, with three minor marks between each
//! pair. Colored with the day - see DayColors. On the complicated style the
//! hours left to recover take the accent color on the outer quarter of an
//! hour mark's reach, twice as wide on the minor marks: the 24, then one
//! mark per hour clockwise, hour and minor alike. The whole dial is 95
//! hours.
class RimMarks {

    //! Width as a share of the radius, in pixels - see RimPainter.drawRadial
    private const WIDTH_NUMERATOR = 1;
    private const WIDTH_DIVISOR = 40;
    private const MIN_WIDTH = 1;

    //! Reach as a share of the ring
    private const LENGTH_NUMERATOR = 2;
    private const LENGTH_DIVISOR = 5;

    //! Minor marks between hour marks: quarter hour steps
    private const MINOR_MARKS = 3;
    private const STEPS_PER_HOUR = MINOR_MARKS + 1;
    private const MARK_COUNT = Dial.HOUR_MARKS * STEPS_PER_HOUR;

    //! Minor reach as a share of an hour mark's
    private const MINOR_LENGTH_NUMERATOR = 2;
    private const MINOR_LENGTH_DIVISOR = 3;
    private const MINOR_WIDTH = 1;
    private const MINOR_RECOVERY_WIDTH = MINOR_WIDTH * 2;

    //! Recovery reach as a share of an hour mark's
    private const RECOVERY_LENGTH_DIVISOR = 4;

    //! Resolved in prepare()
    private var hourLength as Number = 0;
    private var hourWidth as Number = MIN_WIDTH;
    private var minorLength as Number = 0;
    private var recoveryLength as Number = 0;

    private var dayColors as DayColors;

    private var recoveryShown as Boolean = false;

    //! Marks in the recovery color, clockwise from the 24; none at zero
    private var recoveryMarks as Number = 0;
    private var recoveryColor as Number = Graphics.COLOR_WHITE;

    function initialize(dayColors as DayColors) {
        self.dayColors = dayColors;
    }

    //! After Dial.setup()
    function prepare() as Void {
        hourLength = Dial.ringDepth * LENGTH_NUMERATOR / LENGTH_DIVISOR;
        hourWidth = Dial.rim * WIDTH_NUMERATOR / WIDTH_DIVISOR;

        if (hourWidth < MIN_WIDTH) {
            hourWidth = MIN_WIDTH;
        }

        minorLength = hourLength * MINOR_LENGTH_NUMERATOR / MINOR_LENGTH_DIVISOR;
        recoveryLength = hourLength / RECOVERY_LENGTH_DIVISOR;
    }

    //! How far in from the rim an hour mark comes
    function reach() as Number {
        return hourLength;
    }

    function width() as Number {
        return hourWidth;
    }

    function setRecoveryShown(shown as Boolean) as Void {
        recoveryShown = shown;
    }

    //! Once per full update; null when there are none
    function setRecoveryHours(hours as Number?) as Void {
        if (!recoveryShown || (hours == null)) {
            recoveryMarks = 0;
            return;
        }

        // The 24 starts the count; each hour adds the mark after it.
        recoveryMarks = hours + 1;
    }

    function setRecoveryColor(color as Number) as Void {
        recoveryColor = color;
    }

    function draw(dc as Dc) as Void {
        var degreesPerStep = Dial.DEGREES_PER_HOUR_MARK.toFloat() / STEPS_PER_HOUR;

        for (var index = 0; index < MARK_COUNT; index++) {
            drawMark(dc, index, index * degreesPerStep);
        }
    }

    //! In the day's color; among the hours left, the outer quarter of an hour
    //! mark's reach in the recovery color. index counts every mark clockwise
    //! from the 24, hour marks on every fourth.
    private function drawMark(dc as Dc, index as Number, degrees as Float) as Void {
        var isHour = (index % STEPS_PER_HOUR) == 0;

        RimPainter.setPen(dc, dayColors.colorAt(degrees), isHour ? hourWidth : MINOR_WIDTH);
        RimPainter.drawRadial(dc, degrees, isHour ? hourLength : minorLength);

        if (index < recoveryMarks) {
            RimPainter.setPen(dc, recoveryColor, isHour ? hourWidth : MINOR_RECOVERY_WIDTH);
            RimPainter.drawRadial(dc, degrees, recoveryLength);
        }
    }
}
