import Toybox.Application;
import Toybox.Lang;
import Toybox.Graphics;

using Toybox.WatchUi;

module StationMenu {
    const SOURCE_ITEM_ID  = 0;
    const SAVE_GPS_ITEM_ID = 1;
    const GET_DATA_ITEM_ID = 2;

    function pushMenu(stationIndex as Number) as Void {
        var menu = new WatchUi.CustomMenu(getApp().screenHeight / 3, Graphics.COLOR_WHITE, {
            :title => new CustomMenuTitle(StorageUtil.getStationName(stationIndex)),
            :theme => null
        });

        // Source toggle: GPS or Fixed
        var useGPS   = StorageUtil.getStationUseGPS(stationIndex);
        var srcLabel = useGPS
            ? Rez.Strings.stationSourceGPS
            : Rez.Strings.stationSourceFixed;
        menu.addItem(new BasicCustomMenuItem(
            [SOURCE_ITEM_ID, stationIndex],
            Rez.Strings.stationSourceTitle,
            srcLabel
        ));

        // Save GPS as fixed location (only shown when a GPS fix is available)
        if (getApp().currentPosition != null) {
            menu.addItem(new BasicCustomMenuItem(
                [SAVE_GPS_ITEM_ID, stationIndex],
                Rez.Strings.stationSaveGPS,
                null
            ));
        }

        // Download tide data
        menu.addItem(new BasicCustomMenuItem(
            [GET_DATA_ITEM_ID, stationIndex],
            Rez.Strings.mainMenuLabelGetData,
            null
        ));

        WatchUi.pushView(menu, new StationMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }
}

class StationMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) as Void {
        var id           = item.getId() as Array<Number>;
        var action       = id[0];
        var stationIndex = id[1];

        if (action == StationMenu.SOURCE_ITEM_ID) {
            var current = StorageUtil.getStationUseGPS(stationIndex);
            StorageUtil.setStationUseGPS(stationIndex, !current);
            // Refresh the menu to show the updated label
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            StationMenu.pushMenu(stationIndex);

        } else if (action == StationMenu.SAVE_GPS_ITEM_ID) {
            var pos = getApp().currentPosition;
            if (pos != null) {
                var coords = pos.toDegrees();
                StorageUtil.saveGPSAsFixed(stationIndex, coords[0].toFloat(), coords[1].toFloat());
                getApp().tideDataValid[stationIndex] = false;
            }
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            StationMenu.pushMenu(stationIndex);

        } else if (action == StationMenu.GET_DATA_ITEM_ID) {
            WebRequests.downloadStationData(stationIndex);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }
}
