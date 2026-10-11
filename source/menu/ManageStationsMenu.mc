import Toybox.Lang;
import Toybox.Graphics;

using Toybox.WatchUi;

module ManageStationsMenu {
    function pushMenu() as Void {
        var menu = new WatchUi.CustomMenu(getApp().screenHeight / 3, Graphics.COLOR_WHITE, {
            :title => new CustomMenuTitle(Rez.Strings.mainMenuLabelManageStations),
            :theme => null
        });

        for (var i = 0; i < getApp().stationsToShow; i++) {
            var name   = StorageUtil.getStationName(i);
            var subLbl = _stationSubLabel(i);
            menu.addItem(new BasicCustomMenuItem(i, name, subLbl));
        }

        WatchUi.pushView(menu, new ManageStationsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }

    function _stationSubLabel(stationIndex as Number) as String {
        if (StorageUtil.getStationUseGPS(stationIndex)) {
            return WatchUi.loadResource(Rez.Strings.stationSourceGPS) as String;
        }
        var lat = StorageUtil.getStationLat(stationIndex);
        var lng = StorageUtil.getStationLng(stationIndex);
        if (lat == null || lng == null) {
            return WatchUi.loadResource(Rez.Strings.stationNotConfigured) as String;
        }
        return lat.format("%.3f") + ", " + lng.format("%.3f");
    }
}

class ManageStationsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) as Void {
        StationMenu.pushMenu(item.getId() as Number);
    }
}
