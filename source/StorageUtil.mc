import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Lang;

(:background)
module StorageUtil {

    // Returns property key like "station1Lat" for index 0, suffix "Lat"
    function stationPropKey(stationIndex as Number, suffix as String) as String {
        return "station" + (stationIndex + 1).toString() + suffix;
    }

    // ── Tide data (persistent storage) ───────────────────────────────────────

    function getTideData() as Array<Array<Array>?>? {
        return Storage.getValue("tideData");
    }

    function setTideData(tideData as Array<Array<Array>?>?) as Void {
        Storage.setValue("tideData", tideData);
    }

    function getMaxTidesArray() as Array<Float?> {
        var maxTides = Storage.getValue("maxTides") as Array<Float?>;
        if (maxTides == null) {
            maxTides = [];
            for (var i = 0; i < getApp().stationsToShow; i++) {
                maxTides.add(null);
            }
        }
        return maxTides;
    }

    function setMaxTide(stationIndex as Number, maxTide as Float) as Void {
        var maxTides = getMaxTidesArray();
        maxTides[stationIndex] = maxTide;
        Storage.setValue("maxTides", maxTides);
    }

    function getMaxTide(stationIndex as Number) as Float? {
        return getMaxTidesArray()[stationIndex];
    }

    // ── Station config (from Properties, set via Garmin Connect app) ─────────

    (:glance)
    function getStationName(stationIndex as Number) as String {
        var name = Properties.getValue(stationPropKey(stationIndex, "Name")) as String?;
        if (name == null || name.length() == 0) {
            return (Application.loadResource(Rez.Strings.stationDefaultName) as String)
                + " " + (stationIndex + 1).toString();
        }
        return name;
    }

    function getStationUseGPS(stationIndex as Number) as Boolean {
        var v = Properties.getValue(stationPropKey(stationIndex, "UseGPS"));
        if (v instanceof Boolean) { return v; }
        return false;
    }

    function setStationUseGPS(stationIndex as Number, useGPS as Boolean) as Void {
        Properties.setValue(stationPropKey(stationIndex, "UseGPS"), useGPS);
    }

    function getStationLat(stationIndex as Number) as Float? {
        var s = Properties.getValue(stationPropKey(stationIndex, "Lat")) as String?;
        if (s == null || s.length() == 0) { return null; }
        return s.toFloat();
    }

    function getStationLng(stationIndex as Number) as Float? {
        var s = Properties.getValue(stationPropKey(stationIndex, "Lng")) as String?;
        if (s == null || s.length() == 0) { return null; }
        return s.toFloat();
    }

    // Save current GPS position as fixed coords and switch to Fixed mode
    function saveGPSAsFixed(stationIndex as Number, lat as Float, lng as Float) as Void {
        Properties.setValue(stationPropKey(stationIndex, "Lat"), lat.format("%.6f"));
        Properties.setValue(stationPropKey(stationIndex, "Lng"), lng.format("%.6f"));
        Properties.setValue(stationPropKey(stationIndex, "UseGPS"), false);
    }

    // Returns [lat, lng] for the station, or null if not available
    function getStationCoords(stationIndex as Number) as Array<Float>? {
        if (getStationUseGPS(stationIndex)) {
            var pos = getApp().currentPosition;
            if (pos == null) { return null; }
            var deg = pos.toDegrees();
            return [deg[0].toFloat(), deg[1].toFloat()];
        }
        var lat = getStationLat(stationIndex);
        var lng = getStationLng(stationIndex);
        if (lat == null || lng == null) { return null; }
        return [lat, lng];
    }

    // True if the station slot is configured (even if GPS fix isn't available yet)
    function isStationSetup(stationIndex as Number) as Boolean {
        if (getStationUseGPS(stationIndex)) {
            return true;
        }
        return getStationLat(stationIndex) != null && getStationLng(stationIndex) != null;
    }

    // ── Last viewed station (shared with glance view) ────────────────────────

    (:glance)
    function getLastStationIndex() as Number {
        var idx = Storage.getValue("lastStationIdx") as Number?;
        return idx != null ? idx : 0;
    }

    function setLastStationIndex(idx as Number) as Void {
        Storage.setValue("lastStationIdx", idx);
    }

    // ── Main view mode: list (false) or graph (true) ─────────────────────────

    function getGraphView() as Boolean {
        return Storage.getValue("graphView") == true;
    }

    function setGraphView(graph as Boolean) as Void {
        Storage.setValue("graphView", graph);
    }

    (:glance)
    function getStationHeightOffset(stationIndex as Number) as Float {
        var s = Properties.getValue(stationPropKey(stationIndex, "HeightOffset")) as String?;
        if (s == null || s.length() == 0) { return 0.0f; }
        var v = s.toFloat();
        return v != null ? v : 0.0f;
    }

    function getNumConfiguredStations() as Number {
        var count = 0;
        for (var i = 0; i < getApp().stationsToShow; i++) {
            if (isStationSetup(i)) { count++; }
        }
        return count;
    }
}
