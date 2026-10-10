import Toybox.Lang;

//! The editor's styles, named for what the rim carries. Ids must match the
//! <style> ids in watchface.xml.
module Styles {
    enum Value {
        NUMERALS = 1,
        PLAIN = 2
    }

    const DEFAULT = NUMERALS;

    function hasNumerals(style as Number) as Boolean {
        return style == NUMERALS;
    }
}
