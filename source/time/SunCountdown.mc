import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The minutes left to the next sunrise or sunset behind its sun, through
//! the hour before it and gone once it comes. Below the data field, close
//! enough to the seconds hand that a partial update puts it back.
class SunCountdown {

    private const FONT = Graphics.FONT_XTINY;

    //! The digits' share of the font's ascent, the rest being air above them.
    //! Measured off a 280px screenshot: 14px digits.
    private const DIGIT_SHARE = 0.85;
    private const WINDOW_MINUTES = Clock.MINUTES_PER_HOUR;

    //! Air between the icon and the digits, as a share of the icon's width
    private const GAP_DIVISOR = 8;

    private var daylight as Daylight;
    private var sunriseIcon as Icon;
    private var sunsetIcon as Icon;

    private var enabled as Boolean = false;
    private var color as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare()
    private var centerX as Number = 0;
    private var textTop as Number = 0;
    private var iconTop as Number = 0;

    //! The rows both the icon and the digits cover, for the box
    private var boxTop as Number = 0;
    private var boxHeight as Number = 0;

    //! Set in refresh(), the text empty while there is nothing to count down to
    private var icon as Icon;
    private var text as String = "";

    //! Where the last full draw put the icon and the digits, for redraw()
    private var iconLeft as Number = 0;
    private var textLeft as Number = 0;
    private var box as Box;

    function initialize(daylight as Daylight) {
        self.daylight = daylight;
        box = new Box();
        sunriseIcon = new Icon(Rez.Drawables.Sunrise);
        sunsetIcon = new Icon(Rez.Drawables.Sunset);
        icon = sunriseIcon;
    }

    //! Once per layout, top being where the data field ends
    function prepare(dc as Dc, centerX as Number, top as Number) as Void {
        var ascent = Fonts.inkHeightOf(dc, FONT);
        var digitHeight = Math.round(ascent * DIGIT_SHARE).toNumber();

        self.centerX = centerX;
        textTop = top;

        // Centered on the digits, which sit at the bottom of the ascent. Both
        // suns are the same size, so either places it.
        iconTop = top + ascent - ((digitHeight + icon.height()) / 2);

        var textBottom = top + dc.getFontHeight(FONT);
        var iconBottom = iconTop + icon.height();

        boxTop = (iconTop < textTop) ? iconTop : textTop;
        boxHeight = ((iconBottom > textBottom) ? iconBottom : textBottom) - boxTop;
    }

    function setEnabled(enabled as Boolean) as Void {
        self.enabled = enabled;
    }

    function setColor(color as Number) as Void {
        self.color = color;
        sunriseIcon.setTint(color);
        sunsetIcon.setTint(color);
    }

    //! Once per full update, after the daylight has refreshed
    function refresh() as Void {
        text = "";
        box.clear();

        if (!enabled) {
            return;
        }

        var now = Clock.now();
        var minute = (now.hour * Clock.MINUTES_PER_HOUR) + now.min;
        var sunriseLeft = minutesUntil(daylight.sunrise(), minute);
        var sunsetLeft = minutesUntil(daylight.sunset(), minute);

        if (sunriseLeft != null) {
            show(sunriseIcon, sunriseLeft);
        } else if (sunsetLeft != null) {
            show(sunsetIcon, sunsetLeft);
        }
    }

    //! The icon and the digits, centered together
    function draw(dc as Dc) as Void {
        if (text.length() == 0) {
            return;
        }

        var iconWidth = icon.width();
        var gap = iconWidth / GAP_DIVISOR;
        var textWidth = dc.getTextWidthInPixels(text, FONT);
        var width = iconWidth + gap + textWidth;

        iconLeft = centerX - (width / 2);
        textLeft = iconLeft + iconWidth + gap;
        box.set(iconLeft, boxTop, width, boxHeight);

        paint(dc);
    }

    //! Put it back if the clip has cut into it
    function redraw(dc as Dc) as Void {
        if (!ClipRegion.covers(box)) {
            return;
        }

        paint(dc);
    }

    private function paint(dc as Dc) as Void {
        icon.draw(dc, iconLeft, iconTop);

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textLeft, textTop, FONT, text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function show(icon as Icon, minutesLeft as Number) as Void {
        self.icon = icon;
        text = minutesLeft.toString();
    }

    //! Within the window, null outside it or when the event is not known
    private function minutesUntil(event as Number?, minute as Number) as Number? {
        if (event == null) {
            return null;
        }

        var left = (event - minute + Clock.MINUTES_PER_DAY) % Clock.MINUTES_PER_DAY;

        return ((left > 0) && (left <= WINDOW_MINUTES)) ? left : null;
    }
}
