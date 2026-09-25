import Toybox.Graphics;
import Toybox.Lang;

//! The editor's styles. The editor has no background setting, so the style
//! carries it. Ids must match the <style> ids in watchface.xml.
module Styles {
    enum Value {
        DARK = 1,
        LIGHT = 2,
        DARK_COMPLICATED = 3
    }

    const DEFAULT = DARK;

    function backgroundOf(style as Number) as Number {
        return isLight(style) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }

    //! The color to fall back on: whatever reads against the background
    function foregroundOf(style as Number) as Number {
        return isLight(style) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
    }

    function isLight(style as Number) as Boolean {
        return (style == LIGHT);
    }

    //! Wind as a bearing on the dial, recovery hours on the rim marks
    function isComplicated(style as Number) as Boolean {
        return (style == DARK_COMPLICATED);
    }
}
