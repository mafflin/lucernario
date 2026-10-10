import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The row of status icons above the time. No settings: every icon shows
//! whenever it has something to report.
class StatusBar {

    //! Lifts the row so it and the data container frame the time by eye
    private const LIFT_DIVISOR = 22;

    //! Half an icon of air between items, down to MIN_GAP on a round screen
    private const GAP_DIVISOR = 2;
    private const MIN_GAP = 2;
    private const MARGIN = 2;

    private var icons as Array<Icon>;

    //! Always on screen, so its artwork is the row's measure
    private var battery as Battery;

    //! Has to be told its size
    private var wind as Wind;

    //! The line below the time the row mirrors
    private var mirrorY as Number = 0;

    //! One box answers for the whole row. Empty while nothing shows.
    private var row as Box;

    //! Air between icons, settled with the row
    private var gap as Number = 0;

    function initialize(windReading as WindReading) {
        battery = new Battery();
        wind = new Wind(windReading);
        row = new Box();

        icons = [
            battery,
            new Phone(),
            new Alarm(),
            wind,
            new Meridiem()
        ] as Array<Icon>;
    }

    //! Once per layout
    function mirror(y as Number) as Void {
        mirrorY = y;
    }

    function setColor(color as Number) as Void {
        for (var i = 0; i < icons.size(); i++) {
            icons[i].setTint(color);
        }
    }

    function draw(dc as Dc) as Void {
        var count = countShown();

        row.clear();

        if (count == 0) {
            return;
        }

        // The wind has no bitmap to measure; it fills the battery's square.
        wind.setSquare(battery.height());

        layOut(count);
        drawIcons(dc);
    }

    //! One test for the row; past it, each item tests itself
    function redraw(dc as Dc) as Void {
        if (!ClipRegion.covers(row)) {
            return;
        }

        for (var i = 0; i < icons.size(); i++) {
            icons[i].redraw(dc);
        }
    }

    //! Size the row, centered, and the gap between its icons
    private function layOut(count as Number) as Void {
        var rowHeight = tallestShown();
        var top = rowCenterY(rowHeight) - (rowHeight / 2);
        var iconsWidth = shownWidth();

        gap = gapFor(count, rowHeight, chordAt(top) - iconsWidth);

        var rowWidth = iconsWidth + ((count - 1) * gap);

        row.set((Dial.screenWidth - rowWidth) / 2, top, rowWidth, rowHeight);
    }

    //! Each centered on the row's middle
    private function drawIcons(dc as Dc) as Void {
        var middle = row.top + (row.height / 2);
        var x = row.left;

        for (var i = 0; i < icons.size(); i++) {
            var icon = icons[i];

            if (!icon.isShown()) {
                continue;
            }

            icon.draw(dc, x, middle - (icon.height() / 2));
            x += icon.width() + gap;
        }
    }

    //! The row's bottom as far from the top as the frame line is from the
    //! bottom, lifted a touch
    private function rowCenterY(rowHeight as Number) as Number {
        var screenHeight = Dial.screenHeight;

        return screenHeight - mirrorY - (rowHeight / 2) - (screenHeight / LIFT_DIVISOR);
    }

    private function shownWidth() as Number {
        var total = 0;

        for (var i = 0; i < icons.size(); i++) {
            if (icons[i].isShown()) {
                total += icons[i].width();
            }
        }

        return total;
    }

    private function tallestShown() as Number {
        var tallest = 0;

        for (var i = 0; i < icons.size(); i++) {
            if (icons[i].isShown() && (icons[i].height() > tallest)) {
                tallest = icons[i].height();
            }
        }

        return tallest;
    }

    //! Half an icon, giving way before the outermost item runs off the glass:
    //! spare is the room the icons leave
    private function gapFor(count as Number, rowHeight as Number, spare as Number) as Number {
        var preferred = rowHeight / GAP_DIVISOR;

        if (count < 2) {
            return preferred;
        }

        var room = spare / (count - 1);
        var fitted = (room < preferred) ? room : preferred;

        return (fitted < MIN_GAP) ? MIN_GAP : fitted;
    }

    //! The width of the screen at the row's top edge, the far one from the
    //! middle
    private function chordAt(top as Number) as Number {
        var rim = Dial.rim;
        var fromMiddle = Dial.centerY - top;

        if (fromMiddle >= rim) {
            return Dial.screenWidth;
        }

        var half = Math.sqrt((rim * rim) - (fromMiddle * fromMiddle));
        var chord = (2 * half).toNumber() - (2 * MARGIN);

        return (chord < Dial.screenWidth) ? chord : Dial.screenWidth;
    }

    //! How many icons show this draw
    private function countShown() as Number {
        var settings = Clock.settings();
        var count = 0;

        for (var i = 0; i < icons.size(); i++) {
            if (icons[i].updateShown(settings)) {
                count++;
            }
        }

        return count;
    }
}
