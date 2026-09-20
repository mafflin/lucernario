import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

//! The row of status icons above the time.
//!
//! Lifted from the electric watch face without the cat, the notifications,
//! the do not disturb and the GPS icons, and without the setting that turned
//! the row off: every icon this face carries is on, and shows whenever the
//! thing it reports is worth reporting.
class StatusBar {

    //! Where the row sits, as a fraction of the screen height. Electric
    //! mirrors this against its date; this face has none, so it is placed
    //! outright, clear of both the rim and the top of the time.
    private const _CENTER_Y_RATIO = 0.22;

    //! Half an icon of air between items, down to _MIN_GAP where the row
    //! would run off a round screen. Taken from the icons, so it grows with
    //! them.
    private const _GAP_DIVISOR = 2;
    private const _MIN_GAP = 2;
    private const _MARGIN = 2;

    private var _icons as Array<Icon>;

    //! Where the last full draw put the row, so one box answers for every
    //! item before any is asked about itself.
    private var _rowX as Number = 0;
    private var _rowY as Number = 0;
    private var _rowWidth as Number = 0;
    private var _rowHeight as Number = 0;

    //! Constructor
    function initialize() {
        _icons = [
            new Battery(),
            new Phone(),
            new Alarm(),
            new Meridiem()
        ] as Array<Icon>;
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

        _rowHeight = 0;

        if (total == 0) {
            return;
        }

        var tall = tallest();
        var centerY = middle(dc);
        var items = itemsWidth();
        var gap = gapFor(total, centerY, items, tall);
        var x = (dc.getWidth() - items - ((total - 1) * gap)) / 2;

        _rowX = x;
        _rowY = centerY - (tall / 2);
        _rowWidth = items + ((total - 1) * gap);
        _rowHeight = tall;

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
        if (_rowHeight == 0) {
            return;
        }

        if (!ClipRegion.covers(_rowX, _rowY, _rowWidth, _rowHeight)) {
            return;
        }

        for (var i = 0; i < _icons.size(); i++) {
            _icons[i].redraw(dc);
        }
    }

    //! The row holds its vertical center whatever the tallest item is
    //! @param dc The drawing context
    //! @return The y the row is centered on
    private function middle(dc as Dc) as Number {
        return (dc.getHeight() * _CENTER_Y_RATIO).toNumber();
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
