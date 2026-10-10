import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! 24 hour marks, midnight at the top, all the same size, with three minor
//! marks between each pair. Colored with the day - see DayColors - the mark
//! nearest solar noon in the night's color and, if minor, twice as wide.
class RimMarks {

    //! Width as a share of the radius, in pixels - see RimPainter.drawRadial
    private const WIDTH_NUMERATOR = 1;
    private const WIDTH_DIVISOR = 40;
    private const MIN_WIDTH = 1;

    //! Reach as a share of the ring
    private const HOUR_LENGTH_NUMERATOR = 1;
    private const HOUR_LENGTH_DIVISOR = 2;

    //! Minor marks between hour marks: quarter hour steps
    private const MINOR_MARKS = 3;
    private const STEPS_PER_HOUR = MINOR_MARKS + 1;
    private const MARK_COUNT = Dial.HOUR_MARKS * STEPS_PER_HOUR;

    //! Minor reach: two thirds of two fifths of the ring, rounded down at
    //! each step
    private const MINOR_BASE_NUMERATOR = 2;
    private const MINOR_BASE_DIVISOR = 5;
    private const MINOR_LENGTH_NUMERATOR = 2;
    private const MINOR_LENGTH_DIVISOR = 3;
    private const MINOR_WIDTH = 1;
    private const WIDE_MINOR_WIDTH = MINOR_WIDTH * 2;

    //! Resolved in prepare()
    private var hourLength as Number = 0;
    private var hourWidth as Number = MIN_WIDTH;
    private var minorLength as Number = 0;

    //! The night's color, to stand out among the day's marks around it
    private const ZENITH_COLOR = Palette.SKY;

    private var dayColors as DayColors;

    //! The mark nearest solar noon, null until the sun is known
    private var zenithIndex as Number? = null;

    function initialize(dayColors as DayColors) {
        self.dayColors = dayColors;
    }

    //! After Dial.setup()
    function prepare() as Void {
        hourLength = Dial.ringDepth * HOUR_LENGTH_NUMERATOR / HOUR_LENGTH_DIVISOR;
        hourWidth = Dial.rim * WIDTH_NUMERATOR / WIDTH_DIVISOR;

        if (hourWidth < MIN_WIDTH) {
            hourWidth = MIN_WIDTH;
        }

        var minorBase = Dial.ringDepth * MINOR_BASE_NUMERATOR / MINOR_BASE_DIVISOR;

        minorLength = minorBase * MINOR_LENGTH_NUMERATOR / MINOR_LENGTH_DIVISOR;
    }

    //! How far in from the rim an hour mark comes: the longest
    function reach() as Number {
        return hourLength;
    }

    //! How far in from the rim a minor mark's pen comes
    function minorReach() as Number {
        return minorLength + RimPainter.penRadius(MINOR_WIDTH);
    }

    //! An hour mark's
    function width() as Number {
        return hourWidth;
    }

    function draw(dc as Dc) as Void {
        var degreesPerStep = Dial.DEGREES_PER_HOUR_MARK.toFloat() / STEPS_PER_HOUR;

        zenithIndex = indexNearest(dayColors.zenith(), degreesPerStep);

        for (var index = 0; index < MARK_COUNT; index++) {
            drawMark(dc, index, index * degreesPerStep);
        }
    }

    //! In the day's color, or the night's nearest solar noon, a minor mark
    //! twice as wide there. index counts every mark clockwise from the top,
    //! hour marks on every fourth.
    private function drawMark(dc as Dc, index as Number, degrees as Float) as Void {
        var isHour = (index % STEPS_PER_HOUR) == 0;
        RimPainter.setPen(dc, colorOf(index, degrees), isHour ? hourWidth : minorWidth(index));
        RimPainter.drawRadial(dc, degrees, isHour ? hourLength : minorLength);
    }

    private function colorOf(index as Number, degrees as Float) as Number {
        return (index == zenithIndex) ? ZENITH_COLOR : dayColors.colorAt(degrees);
    }

    //! The mark nearest a place on the dial, null for none
    private function indexNearest(degrees as Float?, degreesPerStep as Float) as Number? {
        if (degrees == null) {
            return null;
        }

        return Math.round(degrees / degreesPerStep).toNumber() % MARK_COUNT;
    }

    private function minorWidth(index as Number) as Number {
        return (index == zenithIndex) ? WIDE_MINOR_WIDTH : MINOR_WIDTH;
    }
}
