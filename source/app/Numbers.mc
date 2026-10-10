import Toybox.Lang;

module Numbers {

    function min(first as Number, second as Number) as Number {
        return (first < second) ? first : second;
    }

    function max(first as Number, second as Number) as Number {
        return (first > second) ? first : second;
    }
}
