import Toybox.Application.WatchFaceConfig;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The native watch face editor's side of the face: applies its settings,
//! and answers what to pulse and what was tapped.
class Editor {

    //! Until the editor picks one
    private const DEFAULT_COLOR = Graphics.COLOR_WHITE;

    private var fields as DataFields;

    private var currentStyle as Number = Styles.DEFAULT;
    private var currentAccent as Number = DEFAULT_COLOR;
    private var currentData as Number = DEFAULT_COLOR;

    //! The slot of the field the editor pulses, and so draws itself; null
    //! for none
    private var pulsed as Number? = null;

    function initialize(fields as DataFields) {
        self.fields = fields;
    }

    function style() as Number {
        return currentStyle;
    }

    //! The hands
    function accentColor() as Number {
        return currentAccent;
    }

    //! The time, the status row and the data fields, and the rim until the
    //! sun is known
    function dataColor() as Number {
        return currentData;
    }

    function pulsedSlot() as Number? {
        return pulsed;
    }

    //! editedType is null while initializing
    function apply(config as WatchFaceConfig.Settings, editedType as WatchFaceConfigType?) as Void {
        var styleId = config.styleId;

        currentStyle = (styleId != null) ? styleId : Styles.DEFAULT;
        currentAccent = colorOf(config.accentColor);
        currentData = colorOf(config.complicationColor);
        applyComplications(config.complicationSettings);

        // On to another setting: no field is being pulsed.
        if (editedType != WatchUi.WATCH_FACE_CONFIG_TYPE_COMPLICATION) {
            pulsed = null;
        }
    }

    //! The drawable to pulse; null for a slot that is not a data field
    function pulse(complication as ComplicationRef) as ComplicationDrawableRef? {
        var field = fields.fieldFor(complication.uniqueIdentifier);

        if (field == null) {
            return null;
        }

        pulsed = field.getSlotId();

        return new WatchUi.ComplicationDrawableRef({
            :drawable => field,
            :boundingBox => field.getBoundingBox()
        });
    }

    //! The slot under a tap, or null
    function tappedSlot(x as Number, y as Number) as Number? {
        return fields.slotAt(x, y);
    }

    private function colorOf(chosen as WatchFaceConfig.Color?) as Number {
        if ((chosen != null) && (chosen.color != null)) {
            return chosen.color as Number;
        }

        return DEFAULT_COLOR;
    }

    private function applyComplications(slots as Array<WatchFaceConfig.ComplicationRef>?) as Void {
        if (slots == null) {
            return;
        }

        for (var i = 0; i < slots.size(); i++) {
            applySlot(slots[i]);
        }
    }

    //! null until picked: the default type stands
    private function applySlot(slot as WatchFaceConfig.ComplicationRef) as Void {
        var complicationId = slot.complicationId;
        var field = fields.fieldFor(slot.uniqueIdentifier);

        if (field == null) {
            return;
        }

        if (complicationId != null) {
            field.setComplicationId(complicationId);
        }

        field.refresh();
    }
}
