import Toybox.Graphics;

using Toybox.WatchUi;

class DisplayOptionsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        (item as MultiToggleMenuItem).next();
    }
}

module DisplayOptionsMenu {
    function pushMenu() {
        var menu = new WatchUi.CustomMenu(getApp().screenHeight / 3, Graphics.COLOR_WHITE, {
            :title => new CustomMenuTitle(Rez.Strings.displayOptionsMenuTitle),
            :theme => null
        });

        menu.addItem(new MultiToggleMenuItem(
            Rez.Strings.unitsSettingTitle,
            [Rez.Strings.unitsSettingSystem, Rez.Strings.unitsSettingMetric, Rez.Strings.unitsSettingImperial],
            null,
            "unitsProp"
        ));

        menu.addItem(new MultiToggleMenuItem(
            Rez.Strings.datumSettingTitle,
            [Rez.Strings.datumSettingMSL, Rez.Strings.datumSettingMLLW],
            null,
            "datumProp"
        ));

        WatchUi.pushView(menu, new DisplayOptionsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }
}
