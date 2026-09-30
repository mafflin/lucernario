import Toybox.Graphics;
import Toybox.Lang;

//! 24 hour marks, midnight at the top, the even ones longer and wider, with
//! three minor marks between each pair. Colored with the day - see DayColors.
//! On the complicated style the hours left to recover take the data color
//! instead, the minor marks among them twice as wide: the 24, then one mark
//! per hour clockwise, hour and minor alike. The whole dial is 95 hours.
class RimMarks {

    //! Width as a share of the radius, in pixels - see RimPainter.drawRadial
    private const WIDTH_NUMERATOR = 1;
    private const WIDTH_DIVISOR = 40;
    private const MIN_WIDTH = 1;

    //! Reach as a share of the ring, longer on the even hours
    private const EVEN_LENGTH_NUMERATOR = 1;
    private const EVEN_LENGTH_DIVISOR = 2;
    private const ODD_LENGTH_NUMERATOR = 2;
    private const ODD_LENGTH_DIVISOR = 5;

    //! Minor marks between hour marks: quarter hour steps
    private const MINOR_MARKS = 3;
    private const STEPS_PER_HOUR = MINOR_MARKS + 1;
    private const MARK_COUNT = Dial.HOUR_MARKS * STEPS_PER_HOUR;

    //! Minor reach as a share of an odd hour mark's
    private const MINOR_LENGTH_NUMERATOR = 2;
    private const MINOR_LENGTH_DIVISOR = 3;
    private const MINOR_WIDTH = 1;
    private const MINOR_RECOVERY_WIDTH = MINOR_WIDTH * 2;

    //! Resolved in prepare()
    private var evenLength as Number = 0;
    private var oddLength as Number = 0;
    private var hourWidth as Number = MIN_WIDTH;
    private var oddHourWidth as Number = MIN_WIDTH;
    private var minorLength as Number = 0;

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
        evenLength = Dial.ringDepth * EVEN_LENGTH_NUMERATOR / EVEN_LENGTH_DIVISOR;
        oddLength = Dial.ringDepth * ODD_LENGTH_NUMERATOR / ODD_LENGTH_DIVISOR;
        hourWidth = Dial.rim * WIDTH_NUMERATOR / WIDTH_DIVISOR;

        if (hourWidth < MIN_WIDTH) {
            hourWidth = MIN_WIDTH;
        }

        oddHourWidth = (hourWidth + 1) / 2;

        minorLength = oddLength * MINOR_LENGTH_NUMERATOR / MINOR_LENGTH_DIVISOR;
    }

    //! How far in from the rim an even hour mark comes: the longest
    function reach() as Number {
        return evenLength;
    }

    //! How far in from the rim a minor mark's pen comes
    function minorReach() as Number {
        return minorLength + RimPainter.penRadius(MINOR_WIDTH);
    }

    //! An even hour mark's: the odd ones are half as wide
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

    //! In the day's color, or the recovery color among the hours left, the
    //! minor marks twice as wide there. index counts every mark clockwise from
    //! the 24, hour marks on every fourth.
    private function drawMark(dc as Dc, index as Number, degrees as Float) as Void {
        var isHour = (index % STEPS_PER_HOUR) == 0;
        var recovering = index < recoveryMarks;
        var color = recovering ? recoveryColor : dayColors.colorAt(degrees);

        RimPainter.setPen(dc, color, isHour ? hourWidthAt(index) : minorWidth(recovering));
        RimPainter.drawRadial(dc, degrees, isHour ? hourLengthAt(index) : minorLength);
    }

    private function minorWidth(recovering as Boolean) as Number {
        return recovering ? MINOR_RECOVERY_WIDTH : MINOR_WIDTH;
    }

    private function hourLengthAt(index as Number) as Number {
        return isEvenHour(index) ? evenLength : oddLength;
    }

    //! Half width on the odd hours
    private function hourWidthAt(index as Number) as Number {
        return isEvenHour(index) ? hourWidth : oddHourWidth;
    }

    private function isEvenHour(index as Number) as Boolean {
        return (index / STEPS_PER_HOUR) % 2 == 0;
    }
}
