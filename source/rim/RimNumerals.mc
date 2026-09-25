import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! 24, 4, 8, 12, 16 and 20 against the inner ends of their marks, colored
//! with the day. Turned to follow the marks, 8 through 16 flipped so they
//! do not read upside down; a watch without vector fonts gets them upright.
//! The seconds hand crosses one every ten seconds, so a partial update puts
//! back only the nearest.
class RimNumerals {

    private const _COUNT = 6;
    private const _HOURS_APART = Dial.HOUR_MARKS / _COUNT;
    private const _SECONDS_APART = Dial.SECONDS_PER_TURN / _COUNT;

    //! Air between the marks and the digits, as a share of the ring
    private const _GAP_DIVISOR = 5;

    //! The system font the vector one is sized off, and falls back to
    private const _FONT = Graphics.FONT_TINY;

    //! The vector font a touch smaller than the system one
    private const _SIZE_NUMERATOR = 4;
    private const _SIZE_DIVISOR = 5;

    //! In order: the first the watch carries is used
    private const _FACES = ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular", "Swiss721Regular"];

    private const _JUSTIFY = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    private var _font as FontType = _FONT;
    private var _turned as Boolean = false;

    //! Per numeral, resolved in prepare()
    private var _texts as Array<String>;
    private var _xs as Array<Number>;
    private var _ys as Array<Number>;
    private var _angles as Array<Number>;
    private var _boxes as Array<Box>;

    private var _dayColors as DayColors;

    //! The 24 is left off while the system's activity indicator sits over it
    private var _topHidden as Boolean = false;

    //! Per numeral, taken in draw() so a partial update need not work it out
    private var _colors as Array<Number>;

    function initialize(dayColors as DayColors) {
        _dayColors = dayColors;
        _colors = new [_COUNT] as Array<Number>;
        _texts = new [_COUNT] as Array<String>;
        _xs = new [_COUNT] as Array<Number>;
        _ys = new [_COUNT] as Array<Number>;
        _angles = new [_COUNT] as Array<Number>;
        _boxes = new [_COUNT] as Array<Box>;

        for (var i = 0; i < _COUNT; i++) {
            // Midnight reads as 24, not 0.
            var hour = (i == 0) ? Dial.HOUR_MARKS : (i * _HOURS_APART);

            _texts[i] = hour.toString();
            _boxes[i] = new Box();
        }
    }

    //! After Dial.setup()
    function prepare(dc as Dc, markReach as Number) as Void {
        chooseFont(dc);

        var ink = Fonts.inkHeightOf(dc, _font);
        var height = dc.getFontHeight(_font);

        // Center the digits, not the font box: shift the anchor by half the
        // empty descent, which lies toward the middle for upright numerals
        // and toward the glass for flipped ones.
        var descent = height - ink;
        var middle = Dial.rim - markReach - (Dial.ringDepth / _GAP_DIVISOR) - (ink / 2);

        for (var i = 0; i < _COUNT; i++) {
            var degrees = positionOf(i);
            var flipped = _turned && isUpsideDown(degrees);
            var radius = flipped ? (middle + (descent / 2)) : (middle - (descent / 2));
            var radians = Dial.radiansOf(degrees);
            var width = dc.getTextWidthInPixels(_texts[i], _font);

            _xs[i] = Dial.pointX(radians, radius);
            _ys[i] = Dial.pointY(radians, radius);
            _angles[i] = _turned ? angleOf(degrees, flipped) : 0;

            boxAround(i, width, height);
        }
    }

    function draw(dc as Dc, hideTop as Boolean) as Void {
        _topHidden = hideTop;

        for (var i = 0; i < _COUNT; i++) {
            _colors[i] = _dayColors.colorAt(positionOf(i));

            if (isShown(i)) {
                paint(dc, i);
            }
        }
    }

    //! Put back the numeral nearest the hand's last second, if cut into
    function redraw(dc as Dc, second as Number) as Void {
        var i = ((second + (_SECONDS_APART / 2)) / _SECONDS_APART) % _COUNT;

        if (isShown(i) && ClipRegion.covers(_boxes[i])) {
            paint(dc, i);
        }
    }

    private function isShown(i as Number) as Boolean {
        return (i != 0) || !_topHidden;
    }

    private function paint(dc as Dc, i as Number) as Void {
        dc.setColor(_colors[i], Graphics.COLOR_TRANSPARENT);

        if (_turned) {
            dc.drawAngledText(_xs[i], _ys[i], _font as VectorFont, _texts[i], _JUSTIFY, _angles[i]);
        } else {
            dc.drawText(_xs[i], _ys[i], _font, _texts[i], _JUSTIFY);
        }
    }

    //! Degrees clockwise from midnight
    private function positionOf(i as Number) as Number {
        return i * _HOURS_APART * Dial.DEGREES_PER_HOUR_MARK;
    }

    //! The bottom of the dial, past a quarter turn either side of the top
    private function isUpsideDown(degrees as Number) as Boolean {
        return (degrees > Dial.QUARTER_TURN) && (degrees < (Dial.DEGREES_PER_CIRCLE - Dial.QUARTER_TURN));
    }

    //! Counterclockwise, the way drawAngledText turns; flipped ones half a
    //! turn more
    private function angleOf(degrees as Number, flipped as Boolean) as Number {
        var angle = Dial.DEGREES_PER_CIRCLE - degrees;

        if (flipped) {
            angle += Dial.HALF_TURN;
        }

        return angle % Dial.DEGREES_PER_CIRCLE;
    }

    //! A vector font if the watch can turn text, the system font otherwise
    private function chooseFont(dc as Dc) as Void {
        _font = _FONT;
        _turned = false;

        if (!(Graphics has :getVectorFont) || !(dc has :drawAngledText)) {
            return;
        }

        var font = Graphics.getVectorFont({
            :face => _FACES,
            :size => dc.getFontHeight(_FONT) * _SIZE_NUMERATOR / _SIZE_DIVISOR
        });

        if (font != null) {
            _font = font;
            _turned = true;
        }
    }

    //! The upright box the turned text fills
    private function boxAround(i as Number, width as Number, height as Number) as Void {
        var radians = Math.toRadians(_angles[i]);
        var cosine = Math.cos(radians).abs();
        var sine = Math.sin(radians).abs();

        _boxes[i].aroundCenter(
            _xs[i],
            _ys[i],
            Dial.pixel((width * cosine) + (height * sine)),
            Dial.pixel((width * sine) + (height * cosine))
        );
    }
}
