import Toybox.Lang;

module Numbers {

    function min(first as Number, second as Number) as Number {
        return (first < second) ? first : second;
    }

    function max(first as Number, second as Number) as Number {
        return (first > second) ? first : second;
    }

    //! From one point on a circle clockwise up to, not including, the other;
    //! the span may run across the circle's zero, as minutes past midnight
    //! or degrees round the dial do
    function isBetween(value as Numeric, from as Numeric, to as Numeric) as Boolean {
        return (from <= to)
            ? ((value >= from) && (value < to))
            : ((value >= from) || (value < to));
    }
}
