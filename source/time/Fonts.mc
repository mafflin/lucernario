import Toybox.Graphics;
import Toybox.Lang;

module Fonts {

    //! The height of the glyphs, not the font box: digits never reach below
    //! the baseline, so the descent is empty space
    function inkHeightOf(font as FontType) as Number {
        return Graphics.getFontAscent(font);
    }
}
