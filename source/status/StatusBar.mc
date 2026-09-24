import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

//! The row of status icons above the time.
//!
//! There is no setting for the row or its icons: every icon this face
//! carries is on, and shows whenever the thing it reports is worth
//! reporting.
class StatusBar {

    //! Neither the data container nor the time fills its font box evenly;
    //! this much of the screen height evens the pair up by eye.
    private const _LIFT_DIVISOR = 22;

    //! Half an icon of air between items, down to _MIN_GAP where the row
    //! would run off a round screen. Taken from the icons, so it grows with
    //! them.
    private const _GAP_DIVISOR = 2;
    private const _MIN_GAP = 2;
    private const _MARGIN = 2;

    private var _icons as Array<Icon>;

    //! The battery, kept to hand as the one item always on screen: it is what
    //! the wind is measured against. See draw().
    private var _battery as Battery;

    //! The wind, kept to hand because it has to be told its size
    private var _wind as Wind;

    //! The y this row is placed opposite, so it and the data container
    //! frame the time: the container's top, set by mirror()
    private var _mirrorY as Number = 0;

    //! Where the last full draw put the row, so one box answers for every
    //! item before any is asked about itself. Empty while nothing shows.
    private var _row as Box;

    //! Constructor
    //! @param wind The wind, shared with the bearing on the dial
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

    //! Sit as far above the middle of the screen as the data container sits
    //! below it. Run once per layout, after the container is placed.
    //! @param y The top of the data container
    function mirror(y as Number) as Void {
        _mirrorY = y;
    }

    //! Whether the row carries the wind arrow
    //! @param shown false while the dial shows the bearing instead
    function setWindShown(shown as Boolean) as Void {
        _wind.setEnabled(shown);
    }

    //! Set the color the icons are drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        for (var i = 0; i < _icons.size(); i++) {
            _icons[i].setTint(color);
        }
    }

    //! Draw the row
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        var total = markVisible();

        _row.clear();

        if (total == 0) {
            return;
        }

        // The wind fills its square rather than placing a bitmap in it, so it
        // has no size of its own to report. The battery is the one item that
        // is always on screen, which makes its artwork the row's measure.
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

    //! Put the row back where a partial update has cut into it. One test for
    //! the whole row instead of one per item; past it, each item puts itself
    //! back only if the clip reaches it.
    //! @param dc The drawing context
    function redraw(dc as Dc) as Void {
        if (!ClipRegion.covers(_row)) {
            return;
        }

        for (var i = 0; i < _icons.size(); i++) {
            _icons[i].redraw(dc);
        }
    }

    //! Where the row is centered: its bottom as far from the top of the
    //! screen as the container's top is from the bottom, lifted a touch
    //! @param dc The drawing context
    //! @param tall The height of the tallest icon
    //! @return The y the row is centered on
    private function middle(dc as Dc, tall as Number) as Number {
        var height = dc.getHeight();

        return height - _mirrorY - (tall / 2) - (height / _LIFT_DIVISOR);
    }

    //! The width of every showing icon, before any gaps
    //! @return The width in pixels
    private function itemsWidth() as Number {
        var width = 0;

        for (var i = 0; i < _icons.size(); i++) {
            if (_icons[i].shown()) {
                width += _icons[i].width();
            }
        }

        return width;
    }

    //! The height of the tallest showing icon
    //! @return The height in pixels
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
    //! @param total How many icons are showing
    //! @param centerY The y the row is centered on
    //! @param items The width of the icons themselves
    //! @param tall The height of the tallest icon
    //! @return The gap in pixels
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

    //! The chord of the screen at the row edge furthest from the middle
    //! @param centerY The y the row is centered on
    //! @param tall The height of the tallest icon
    //! @return The width available in pixels
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

    //! Work out which icons have something to report this draw
    //! @return How many are showing
    private function markVisible() as Number {
        var settings = System.getDeviceSettings();
        var total = 0;

        for (var i = 0; i < _icons.size(); i++) {
            if (_icons[i].mark(settings)) {
                total++;
            }
        }

        return total;
    }
}
