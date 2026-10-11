import Toybox.Graphics;

using Toybox.WatchUi;

class StationDataMenuDelegate extends WatchUi.Menu2InputDelegate {
    public enum {
        MENU_SETTINGS_ENABLE_BACKGROUND_DL_ID,
        MENU_GET_DATA_ID
    }

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        if (item.getId() == MENU_SETTINGS_ENABLE_BACKGROUND_DL_ID) {
            (item as MultiToggleMenuItem).next();
        } else if (item.getId() == MENU_GET_DATA_ID) {
            GetDataMenu.pushMenu();
        }
    }
}

module StationDataMenu {
    function pushMenu() {
        var menu = new WatchUi.CustomMenu(getApp().screenHeight / 3, Graphics.COLOR_WHITE, {
            :title => new CustomMenuTitle(Rez.Strings.stationDataMenuTitle),
            :theme => null
        });

        menu.addItem(new BasicCustomMenuItem(
            StationDataMenuDelegate.MENU_GET_DATA_ID,
            Rez.Strings.mainMenuLabelGetData,
            null
        ));

        menu.addItem(new MultiToggleMenuItem(
            Rez.Strings.backgroundDownloadSettingTitle,
            [Rez.Strings.no, Rez.Strings.yes],
            StationDataMenuDelegate.MENU_SETTINGS_ENABLE_BACKGROUND_DL_ID,
            "backgroundDownloadProp"
        ));

        WatchUi.pushView(menu, new StationDataMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }
}
