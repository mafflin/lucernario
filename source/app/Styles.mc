import Toybox.Lang;

//! The editor's styles, named for what the rim carries. Ids must match the
//! <style> ids in watchface.xml.
module Styles {
    enum Value {
        NUMERALS = 1,
        NUMERALS_AND_DATA = 2,
        DATA = 3,
        DATA_LITE = 4
    }

    const DEFAULT = NUMERALS;

    function hasNumerals(style as Number) as Boolean {
        return (style == NUMERALS) || (style == NUMERALS_AND_DATA);
    }

    //! Recovery marks and the goal hand, both off the activity monitor
    function hasActivity(style as Number) as Boolean {
        return style != NUMERALS;
    }

    //! The wind on the dial rather than in the status row
    function hasWindBearing(style as Number) as Boolean {
        return (style == NUMERALS_AND_DATA) || (style == DATA);
    }
}
