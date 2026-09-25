import Toybox.Graphics;
import Toybox.Lang;

//! 24 hour marks, midnight at the top, with four minor marks between each
//! pair. Colored with the day - see DayColors. On the complicated style the
//! hours left to recover take the accent color: the 24, then one mark per
//! hour clockwise, hour and minor alike. The whole dial is 119 hours.
class RimMarks {

    //! Width as a share of the radius, in pixels - see RimPainter.drawRadial
    private const _WIDTH_NUMERATOR = 1;
    private const _WIDTH_DIVISOR = 40;
    private const _MIN_WIDTH = 1;

    //! Reach as a share of the ring
    private const _LENGTH_NUMERATOR = 2;
    private const _LENGTH_DIVISOR = 5;

    //! Minor marks between hour marks: twelve minute steps
    private const _MINOR_MARKS = 4;
    private const _MINOR_STEPS = _MINOR_MARKS + 1;

    //! Minor reach as a share of an hour mark's
    private const _MINOR_LENGTH_NUMERATOR = 2;
    private const _MINOR_LENGTH_DIVISOR = 3;
    private const _MINOR_WIDTH = 1;

    //! Resolved in prepare()
    private var _length as Number = 0;
    private var _width as Number = _MIN_WIDTH;
    private var _minorLength as Number = 0;

    private var _dayColors as DayColors;

    private var _recoveryShown as Boolean = false;

    //! Marks in the recovery color, clockwise from the 24; none at zero
    private var _recoveryMarks as Number = 0;
    private var _recoveryColor as Number = Graphics.COLOR_WHITE;

    function initialize(dayColors as DayColors) {
        _dayColors = dayColors;
    }

    //! After Dial.setup()
    function prepare() as Void {
        _length = Dial.ringDepth * _LENGTH_NUMERATOR / _LENGTH_DIVISOR;
        _width = Dial.rim * _WIDTH_NUMERATOR / _WIDTH_DIVISOR;

        if (_width < _MIN_WIDTH) {
            _width = _MIN_WIDTH;
        }

        _minorLength = _length * _MINOR_LENGTH_NUMERATOR / _MINOR_LENGTH_DIVISOR;
    }

    //! How far in from the rim an hour mark comes
    function reach() as Number {
        return _length;
    }

    function width() as Number {
        return _width;
    }

    function setRecoveryShown(shown as Boolean) as Void {
        _recoveryShown = shown;
    }

    //! Once per full update; null when there are none
    function setRecoveryHours(hours as Number?) as Void {
        if (!_recoveryShown || (hours == null)) {
            _recoveryMarks = 0;
            return;
        }

        // The 24 starts the count; each hour adds the mark after it.
        _recoveryMarks = hours + 1;
    }

    function setRecoveryColor(color as Number) as Void {
        _recoveryColor = color;
    }

    function draw(dc as Dc) as Void {
        var minorStep = Dial.DEGREES_PER_HOUR_MARK.toFloat() / _MINOR_STEPS;

        for (var mark = 0; mark < Dial.HOUR_MARKS; mark++) {
            var hour = positionOf(mark);
            var first = mark * _MINOR_STEPS;

            RimPainter.drawRadial(dc, hour, colorAt(first, hour), _width, _length);

            for (var step = 1; step < _MINOR_STEPS; step++) {
                var degrees = hour + (step * minorStep);
                RimPainter.drawRadial(dc, degrees, colorAt(first + step, degrees), _MINOR_WIDTH, _minorLength);
            }
        }
    }

    //! The recovery color while the mark is among the hours left, the day's
    //! otherwise. index counts every mark clockwise from the 24.
    private function colorAt(index as Number, degrees as Numeric) as Number {
        if (index < _recoveryMarks) {
            return _recoveryColor;
        }

        return _dayColors.colorAt(degrees);
    }

    //! Degrees clockwise from midnight
    private function positionOf(mark as Number) as Number {
        return mark * Dial.DEGREES_PER_HOUR_MARK;
    }
}
