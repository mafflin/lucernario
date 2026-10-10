import Toybox.Graphics;
import Toybox.Lang;

//! An icon and the digits beside it, together on a line: a data field.
//! Either may be missing.
module IconText {

    const FONT = Graphics.FONT_TINY;

    //! The digits' share of the font's ascent, the rest being air above them.
    //! Set by eye off a 260px screenshot: 18px digits.
    const DIGIT_SHARE = 0.80;

    //! Air between the icon and the digits, as a share of the icon's width
    const GAP_DIVISOR = 8;

    function heightIn(dc as Dc) as Number {
        return dc.getFontHeight(FONT);
    }

    //! The icon, the air after it and the digits, side by side
    function widthOf(dc as Dc, icon as Icon?, text as String) as Number {
        var textWidth = (text.length() > 0) ? dc.getTextWidthInPixels(text, FONT) : 0;

        return iconSpan(icon, text) + textWidth;
    }

    //! The icon and digits as one group from its left edge, the digits in
    //! color and the icon in iconColor. top is the top of the digits' font
    //! box; the icon is centered on the digits, which sit at the bottom of
    //! the ascent.
    function draw(dc as Dc, left as Number, top as Number, icon as Icon?, text as String, color as Number, iconColor as Number) as Void {
        if (icon != null) {
            icon.setTint(iconColor);
            icon.draw(dc, left, iconTop(top, icon));
        }

        if (text.length() > 0) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(left + iconSpan(icon, text), top, FONT, text, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    //! Where the icon's top goes, for digits whose font box starts at top
    function iconTop(top as Number, icon as Icon) as Number {
        var ascent = Graphics.getFontAscent(FONT);
        var digitHeight = Dial.pixel(ascent * DIGIT_SHARE);

        return top + ascent - ((digitHeight + icon.height()) / 2);
    }

    //! The icon and the air after it, where the digits start; no air without
    //! digits
    function iconSpan(icon as Icon?, text as String) as Number {
        if (icon == null) {
            return 0;
        }

        var iconWidth = icon.width();

        return (text.length() > 0) ? (iconWidth + (iconWidth / GAP_DIVISOR)) : iconWidth;
    }
}
