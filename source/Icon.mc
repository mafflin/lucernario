import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! One item in the status bar. Lifted from the electric watch face, with the
//! per icon settings dropped: every icon this face carries is on, and shows
//! whenever the thing it reports is worth reporting.
class Icon {

    //! Where the last full draw put this icon, null if it was not drawn
    private var _lastX as Number? = null;
    private var _lastY as Number? = null;

    //! The resource this icon draws, for the icons that have just the one
    private var _resourceId as ResourceId?;

    //! The loaded bitmap, held on to across draws
    private var _resource as BitmapResource? = null;

    //! Which of a set is loaded, for the icons that pick from several
    private var _chosenIndex as Number = -1;

    //! Sizes differ by device, so they are asked of the bitmap once: the
    //! partial update asks every second, and loading is not free.
    private var _measuredWidth as Number? = null;
    private var _measuredHeight as Number? = null;

    //! Whether this icon has anything to report right now
    private var _visible as Boolean = false;

    //! The color the icon is drawn in
    private var _tint as Number = Graphics.COLOR_WHITE;

    //! Constructor
    //! @param resourceId The bitmap to draw, or null when the icon picks from
    //!        a set and overrides bitmap()
    function initialize(resourceId as ResourceId?) {
        _resourceId = resourceId;
    }

    //! Whether this icon has anything to report. Overridden per icon.
    //! @param settings The device settings
    //! @return true when the icon should be shown
    function on(settings as System.DeviceSettings) as Boolean {
        return true;
    }

    //! Work out whether this icon is showing this draw.
    //!
    //! Compared rather than tested: a setting like alarmCount comes back null
    //! on a device without the feature, and the row wants a plain answer.
    //! @param settings The device settings
    //! @return true when the icon is showing
    function mark(settings as System.DeviceSettings) as Boolean {
        _visible = (on(settings) == true);

        if (!_visible) {
            forget();
        }

        return _visible;
    }

    //! Whether this icon is showing
    //! @return true when it is
    function shown() as Boolean {
        return _visible;
    }

    //! Set the color the icon is drawn in
    //! @param tint The color to use
    function setTint(tint as Number) as Void {
        _tint = tint;
    }

    //! The width of the icon in pixels
    //! @return The width
    function width() as Number {
        if (_measuredWidth == null) {
            _measuredWidth = bitmap().getWidth();
        }

        return _measuredWidth as Number;
    }

    //! The height of the icon in pixels
    //! @return The height
    function height() as Number {
        if (_measuredHeight == null) {
            _measuredHeight = bitmap().getHeight();
        }

        return _measuredHeight as Number;
    }

    //! Forget where this icon was, so a partial update does not put it back
    //! somewhere the screen has since been repainted
    function forget() as Void {
        _lastX = null;
        _lastY = null;
    }

    //! Draw the icon, remembering where it went
    //! @param dc The drawing context
    //! @param x The left edge
    //! @param y The top edge
    function draw(dc as Dc, x as Number, y as Number) as Void {
        _lastX = x;
        _lastY = y;

        paint(dc, x, y);
    }

    //! Put the icon back if the clip has cut into it
    //! @param dc The drawing context
    function redraw(dc as Dc) as Void {
        var x = _lastX;
        var y = _lastY;

        if ((x == null) || (y == null)) {
            return;
        }

        if (!ClipRegion.covers(x, y, width(), height())) {
            return;
        }

        paint(dc, x, y);
    }

    //! The bitmap to draw. Overridden by the icons that pick from a set.
    //! @return The bitmap
    protected function bitmap() as BitmapResource {
        if (_resource == null) {
            _resource = WatchUi.loadResource(_resourceId as ResourceId) as BitmapResource;
        }

        return _resource as BitmapResource;
    }

    //! The color to draw in. Overridden by the battery, which says something
    //! with color that the rest of the row does not.
    //! @return The color
    protected function tint() as Number {
        return _tint;
    }

    //! One bitmap out of a set, held on to until the choice moves. The row
    //! asks for the size several times a draw and loading is not free.
    //! @param images The set to choose from
    //! @param index Which one
    //! @return The bitmap
    protected function choose(images as Array<ResourceId>, index as Number) as BitmapResource {
        if (index != _chosenIndex) {
            _chosenIndex = index;
            _resource = WatchUi.loadResource(images[index]) as BitmapResource;
        }

        return _resource as BitmapResource;
    }

    //! Put the bitmap on the screen in the icon's color.
    //!
    //! The artwork is white on transparent, so it is tinted rather than drawn
    //! as it is: on the light style an untinted icon would be invisible.
    //!
    //! Always at its own size, where every source pixel lands on one output
    //! pixel and sampling has nothing to decide. Overridden by the wind,
    //! which has no artwork to place: it draws its arrow.
    //! @param dc The drawing context
    //! @param x The left edge
    //! @param y The top edge
    protected function paint(dc as Dc, x as Number, y as Number) as Void {
        if (!(dc has :drawBitmap2)) {
            dc.drawBitmap(x, y, bitmap());
            return;
        }

        dc.drawBitmap2(x, y, bitmap(), { :tintColor => tint() });
    }
}
