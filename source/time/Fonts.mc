import Toybox.Graphics;
import Toybox.Lang;

module Fonts {

    //! The height of the glyphs, not the font box: digits never reach below
    //! the baseline, so the descent is empty space
    function inkHeightOf(dc as Dc, font as FontType) as Number {
        if (Graphics has :getFontAscent) {
            return Graphics.getFontAscent(font);
        }

        return dc.getFontHeight(font);
    }
}
