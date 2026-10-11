import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Properties;

class CustomMenuTitle extends WatchUi.Drawable {
    private var _title as String;

    public function initialize(title as String or ResourceId) {
        Drawable.initialize({});
        if (title instanceof String) {
            _title = title;
        } else {
            _title = WatchUi.loadResource(title) as String;
        }
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, _title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class BasicCustomMenuItem extends WatchUi.CustomMenuItem {
    private var _label as String or ResourceId;
    private var _subLabel as String?;

    public function initialize(id as Object?, label as String or ResourceId, subLabel as String or ResourceId or Null) {
        CustomMenuItem.initialize(id, {});
        _label = label;
        updateSubLabel(subLabel);
    }

    public function draw(dc as Dc) as Void {
        var sLabel = _label instanceof String ? _label : WatchUi.loadResource(_label) as String;
        var font = Graphics.FONT_SMALL;
        if (isFocused()) {
            font = Graphics.FONT_LARGE;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawLine(0, 0, dc.getWidth(), 0);
        dc.drawLine(0, dc.getHeight() - 1, dc.getWidth(), dc.getHeight() - 1);

        var justifyLR = Graphics.TEXT_JUSTIFY_CENTER;
        var xOffset   = dc.getWidth() / 2;
        if (getApp().screenHeight > 400) {
            justifyLR = Graphics.TEXT_JUSTIFY_LEFT;
            font -= 1;
            xOffset = 5;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        if (isFocused() && _subLabel != null) {
            dc.drawText(xOffset, dc.getHeight() * .3, font,                 sLabel,    justifyLR | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(xOffset, dc.getHeight() * .7, Graphics.FONT_SMALL, _subLabel, justifyLR | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(xOffset, dc.getHeight() / 2, font, sLabel, justifyLR | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    public function getLabel() as String {
        return _label instanceof String ? _label : WatchUi.loadResource(_label) as String;
    }

    public function updateSubLabel(subLabel as String or ResourceId or Null) {
        if (subLabel == null || subLabel instanceof String) {
            _subLabel = subLabel;
        } else {
            _subLabel = WatchUi.loadResource(subLabel) as String;
        }
        if (_subLabel != null && _subLabel.length() == 0) {
            _subLabel = null;
        }
    }
}

class MultiToggleMenuItem extends BasicCustomMenuItem {
    private var _subLabelOptions as Array<ResourceId>;
    private var _propName as String;
    private var _index as Number;

    public function initialize(label as ResourceId,
                               subLabelOptions as Array<ResourceId>,
                               identifier as Object?,
                               propName as String) {
        BasicCustomMenuItem.initialize(identifier, label, null);
        _subLabelOptions = subLabelOptions;
        _propName = propName;
        _index = Properties.getValue(_propName);
        if (_index instanceof Boolean) {
            _index = _index ? 1 : 0;
        }
        updateSubLabel(_subLabelOptions[_index]);
    }

    public function next() {
        _index = (_index + 1) % _subLabelOptions.size();
        Properties.setValue(_propName, _index);
        updateSubLabel(_subLabelOptions[_index]);
    }
}
