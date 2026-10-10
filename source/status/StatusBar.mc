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

    //! The line below the time the row mirrors
    private var mirrorY as Number = 0;

    //! One box answers for the whole row. Empty while nothing shows.
    private var row as Box;

    //! Settled each draw
    private var rowHeight as Number = 0;
    private var gap as Number = 0;

    function initialize() {
        row = new Box();

        icons = [
            new Battery(),
            new Phone(),
            new Alarm(),
            new Recovery(),
            new Wind(),
            new Meridiem()
        ] as Array<Icon>;
    }

    function setColor(color as Number) as Void {
        for (var i = 0; i < icons.size(); i++) {
            icons[i].setTint(color);
        }
    }

    //! Once per layout
    function mirror(y as Number) as Void {
        mirrorY = y;
    }

    function draw(dc as Dc) as Void {
        var count = countShown();

        row.clear();

        if (count == 0) {
            return;
        }

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
        rowHeight = tallestShown();

        var top = rowCenterY() - (rowHeight / 2);
        var iconsWidth = shownWidth();

        gap = gapFor(count, chordAt(top) - iconsWidth);

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
    private function rowCenterY() as Number {
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
    private function gapFor(count as Number, spare as Number) as Number {
        var preferred = rowHeight / GAP_DIVISOR;

        if (count < 2) {
            return preferred;
        }

        var room = spare / (count - 1);

        return Numbers.max(Numbers.min(room, preferred), MIN_GAP);
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

        return Numbers.min(chord, Dial.screenWidth);
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
