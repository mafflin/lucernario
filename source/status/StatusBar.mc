import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The row of status icons above the time. No settings: every icon shows
//! whenever it has something to report.
class StatusBar {

    //! Lifts the row so it and the data container frame the time by eye
    private const _LIFT_DIVISOR = 22;

    //! Half an icon of air between items, down to _MIN_GAP on a round screen
    private const _GAP_DIVISOR = 2;
    private const _MIN_GAP = 2;
    private const _MARGIN = 2;

    private var _icons as Array<Icon>;

    //! Always on screen, so its artwork is the row's measure
    private var _battery as Battery;

    //! Has to be told its size
    private var _wind as Wind;

    //! The data container's top, which the row sits opposite
    private var _mirrorY as Number = 0;

    //! One box answers for the whole row. Empty while nothing shows.
    private var _row as Box;

    function initialize(wind as WindReading) {
        _battery = new Battery();
        _wind = new Wind(wind);
        _row = new Box();

        _icons = [
            _battery,
            new Phone(),
            new Alarm(),
            _wind,
            new Meridiem()
        ] as Array<Icon>;
    }

    //! Once per layout, after the container is placed
    function mirror(y as Number) as Void {
        _mirrorY = y;
    }

    //! false while the dial shows the bearing instead
    function setWindShown(shown as Boolean) as Void {
        _wind.setEnabled(shown);
    }

    function setColor(color as Number) as Void {
        for (var i = 0; i < _icons.size(); i++) {
            _icons[i].setTint(color);
        }
    }

    function draw(dc as Dc) as Void {
        var total = markVisible();

        _row.clear();

        if (total == 0) {
            return;
        }

        // The wind has no bitmap to measure; it fills the battery's square.
        _wind.setSquare(_battery.height());

        var tall = tallest();
        var centerY = middle(dc, tall);
        var items = itemsWidth();
        var gap = gapFor(total, centerY, items, tall);
        var rowWidth = items + ((total - 1) * gap);
        var x = (dc.getWidth() - rowWidth) / 2;

        _row.set(x, centerY - (tall / 2), rowWidth, tall);

        for (var i = 0; i < _icons.size(); i++) {
            if (!_icons[i].shown()) {
                continue;
            }

            _icons[i].draw(dc, x, centerY - (_icons[i].height() / 2));
            x += _icons[i].width() + gap;
        }
    }

    //! One test for the row; past it, each item tests itself
    function redraw(dc as Dc) as Void {
        if (!ClipRegion.covers(_row)) {
            return;
        }

        for (var i = 0; i < _icons.size(); i++) {
            _icons[i].redraw(dc);
        }
    }

    //! The row's bottom as far from the top as the container's top is from
    //! the bottom, lifted a touch
    private function middle(dc as Dc, tall as Number) as Number {
        var height = dc.getHeight();

        return height - _mirrorY - (tall / 2) - (height / _LIFT_DIVISOR);
    }

    private function itemsWidth() as Number {
        var width = 0;

        for (var i = 0; i < _icons.size(); i++) {
            if (_icons[i].shown()) {
                width += _icons[i].width();
            }
        }

        return width;
    }

    private function tallest() as Number {
        var height = 0;

        for (var i = 0; i < _icons.size(); i++) {
            if (_icons[i].shown() && (_icons[i].height() > height)) {
                height = _icons[i].height();
            }
        }

        return height;
    }

    //! The gap gives way before the outermost item runs off the glass
    private function gapFor(total as Number, centerY as Number, items as Number, tall as Number) as Number {
        var gap = tall / _GAP_DIVISOR;

        if (total < 2) {
            return gap;
        }

        var room = (available(centerY, tall) - items) / (total - 1);

        if (room < gap) {
            gap = room;
        }

        if (gap < _MIN_GAP) {
            gap = _MIN_GAP;
        }

        return gap;
    }

    //! The chord of the screen at the row's far edge
    private function available(centerY as Number, tall as Number) as Number {
        var rim = Dial.rim;
        var edge = Dial.centerY - centerY + (tall / 2);

        if (edge >= rim) {
            return Dial.screenWidth;
        }

        var half = Math.sqrt((rim * rim) - (edge * edge));
        var chord = (2 * half).toNumber() - (2 * _MARGIN);

        return (chord < Dial.screenWidth) ? chord : Dial.screenWidth;
    }

    //! How many icons show this draw
    private function markVisible() as Number {
        var settings = Clock.settings();
        var total = 0;

        for (var i = 0; i < _icons.size(); i++) {
            if (_icons[i].mark(settings)) {
                total++;
            }
        }

        return total;
    }
}
