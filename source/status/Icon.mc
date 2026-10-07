import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! One status bar item. No settings: it shows whenever it has something to
//! report.
class Icon {

    private const NONE_CHOSEN = -1;

    //! Where the last full draw put it, empty if it was not drawn
    private var box as Box;

    //! For icons with just the one bitmap
    private var resourceId as ResourceId?;

    private var loaded as BitmapResource? = null;

    //! For icons that pick from a set
    private var chosenIndex as Number = NONE_CHOSEN;

    //! Asked of the bitmap once: loading is not free
    private var measuredWidth as Number? = null;
    private var measuredHeight as Number? = null;

    private var shown as Boolean = false;
    private var plainTint as Number = Graphics.COLOR_WHITE;

    //! resourceId is null for icons that override bitmap()
    function initialize(resourceId as ResourceId?) {
        self.resourceId = resourceId;
        box = new Box();
    }

    //! Whether there is anything to report. Overridden per icon.
    function isReporting(settings as System.DeviceSettings) as Boolean {
        return true;
    }

    //! Settle whether the icon shows this draw. Compared to true: a setting
    //! like alarmCount is null on a watch without the feature.
    function updateShown(settings as System.DeviceSettings) as Boolean {
        shown = (isReporting(settings) == true);

        if (!shown) {
            forget();
        }

        return shown;
    }

    function isShown() as Boolean {
        return shown;
    }

    function setTint(color as Number) as Void {
        plainTint = color;
    }

    function width() as Number {
        measure();

        return measuredWidth as Number;
    }

    function height() as Number {
        measure();

        return measuredHeight as Number;
    }

    //! So a partial update does not put it back on a repainted screen
    function forget() as Void {
        box.clear();
    }

    function draw(dc as Dc, x as Number, y as Number) as Void {
        box.set(x, y, width(), height());
        paint(dc, x, y);
    }

    //! Put it back if the clip has cut into it
    function redraw(dc as Dc) as Void {
        if (!ClipRegion.covers(box)) {
            return;
        }

        paint(dc, box.left, box.top);
    }

    //! Overridden by icons that pick from a set
    protected function bitmap() as BitmapResource {
        if (loaded == null) {
            loaded = WatchUi.loadResource(resourceId as ResourceId) as BitmapResource;
        }

        return loaded as BitmapResource;
    }

    //! Overridden by the battery and the wind, which say something with color
    protected function tint() as Number {
        return plainTint;
    }

    //! One of a set, held until the choice moves
    protected function choose(images as Array<ResourceId>, index as Number) as BitmapResource {
        if (index != chosenIndex) {
            chosenIndex = index;
            loaded = WatchUi.loadResource(images[index]) as BitmapResource;
        }

        return loaded as BitmapResource;
    }

    //! The artwork is white on transparent, tinted to the data color.
    //! Overridden by the wind, which draws itself.
    protected function paint(dc as Dc, x as Number, y as Number) as Void {
        if (!(dc has :drawBitmap2)) {
            dc.drawBitmap(x, y, bitmap());
            return;
        }

        dc.drawBitmap2(x, y, bitmap(), { :tintColor => tint() });
    }

    private function measure() as Void {
        if (measuredWidth != null) {
            return;
        }

        var image = bitmap();

        measuredWidth = image.getWidth();
        measuredHeight = image.getHeight();
    }
}
