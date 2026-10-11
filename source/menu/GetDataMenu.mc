import Toybox.Lang;
import Toybox.Graphics;

using Toybox.WatchUi;

module GetDataMenu {
    const GET_ALL_STATIONS_ID = -1;

    function pushMenu() {
        var configuredCount = StorageUtil.getNumConfiguredStations();
        if (configuredCount == 0) {
            Notification.showNotification(Rez.Strings.noStationConfiguredMessage, 2000);
            return;
        }

        var menu = new WatchUi.CustomMenu(getApp().screenHeight / 3, Graphics.COLOR_WHITE, {
            :title => new CustomMenuTitle(Rez.Strings.mainMenuLabelGetData),
            :theme => null
        });

        if (configuredCount > 1) {
            menu.addItem(new BasicCustomMenuItem(
                GET_ALL_STATIONS_ID,
                Rez.Strings.getDataMenuAll,
                null
            ));
        }

        for (var i = 0; i < getApp().stationsToShow; i++) {
            if (!StorageUtil.isStationSetup(i)) { continue; }
            var useGPS = StorageUtil.getStationUseGPS(i);
            var subLbl = useGPS
                ? (WatchUi.loadResource(Rez.Strings.stationSourceGPS) as String)
                : _coordsSubLabel(i);
            menu.addItem(new BasicCustomMenuItem(i, StorageUtil.getStationName(i), subLbl));
        }

        WatchUi.pushView(menu, new GetDataMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }

    function _coordsSubLabel(stationIndex as Number) as String {
        var lat = StorageUtil.getStationLat(stationIndex);
        var lng = StorageUtil.getStationLng(stationIndex);
        if (lat == null || lng == null) { return ""; }
        return lat.format("%.3f") + ", " + lng.format("%.3f");
    }
}

class GetDataMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) as Void {
        var id = item.getId() as Number;
        if (id == GetDataMenu.GET_ALL_STATIONS_ID) {
            WebRequests.downloadAllStationData();
        } else {
            WebRequests.downloadStationData(id);
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
