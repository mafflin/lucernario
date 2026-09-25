import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! One status bar item. No settings: it shows whenever it has something to
//! report.
class Icon {

    private const _NONE_CHOSEN = -1;

    //! Where the last full draw put it, empty if it was not drawn
    private var _box as Box;

    //! For icons with just the one bitmap
    private var _resourceId as ResourceId?;

    private var _resource as BitmapResource? = null;

    //! For icons that pick from a set
    private var _chosenIndex as Number = _NONE_CHOSEN;

    //! Asked of the bitmap once: loading is not free
    private var _measuredWidth as Number? = null;
    private var _measuredHeight as Number? = null;

    private var _visible as Boolean = false;
    private var _tint as Number = Graphics.COLOR_WHITE;

    //! resourceId is null for icons that override bitmap()
    function initialize(resourceId as ResourceId?) {
        _resourceId = resourceId;
        _box = new Box();
    }

    //! Whether there is anything to report. Overridden per icon.
    function on(settings as System.DeviceSettings) as Boolean {
        return true;
    }

    //! Settle whether the icon shows this draw. Compared to true: a setting
    //! like alarmCount is null on a watch without the feature.
    function mark(settings as System.DeviceSettings) as Boolean {
        _visible = (on(settings) == true);

        if (!_visible) {
            forget();
        }

        return _visible;
    }

    function shown() as Boolean {
        return _visible;
    }

    function setTint(tint as Number) as Void {
        _tint = tint;
    }

    function width() as Number {
        measure();

        return _measuredWidth as Number;
    }

    function height() as Number {
        measure();

        return _measuredHeight as Number;
    }

    //! So a partial update does not put it back on a repainted screen
    function forget() as Void {
        _box.clear();
    }

    function draw(dc as Dc, x as Number, y as Number) as Void {
        _box.set(x, y, width(), height());
        paint(dc, x, y);
    }

    //! Put it back if the clip has cut into it
    function redraw(dc as Dc) as Void {
        if (!ClipRegion.covers(_box)) {
            return;
        }

        paint(dc, _box.left, _box.top);
    }

    //! Overridden by icons that pick from a set
    protected function bitmap() as BitmapResource {
        if (_resource == null) {
            _resource = WatchUi.loadResource(_resourceId as ResourceId) as BitmapResource;
        }

        return _resource as BitmapResource;
    }

    //! Overridden by the battery and the wind, which say something with color
    protected function tint() as Number {
        return _tint;
    }

    //! One of a set, held until the choice moves
    protected function choose(images as Array<ResourceId>, index as Number) as BitmapResource {
        if (index != _chosenIndex) {
            _chosenIndex = index;
            _resource = WatchUi.loadResource(images[index]) as BitmapResource;
        }

        return _resource as BitmapResource;
    }

    //! The artwork is white on transparent, so it is tinted: untinted it
    //! would vanish on the light style. Overridden by the wind, which draws
    //! itself.
    protected function paint(dc as Dc, x as Number, y as Number) as Void {
        if (!(dc has :drawBitmap2)) {
            dc.drawBitmap(x, y, bitmap());
            return;
        }

        dc.drawBitmap2(x, y, bitmap(), { :tintColor => tint() });
    }

    private function measure() as Void {
        if (_measuredWidth != null) {
            return;
        }

        var image = bitmap();

        _measuredWidth = image.getWidth();
        _measuredHeight = image.getHeight();
    }
}
