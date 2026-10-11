import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Background;

using Toybox.WatchUi;

(:background)
module WebRequests {

    function downloadAllStationData() as Void {
        for (var i = 0; i < getApp().stationsToShow; i++) {
            if (StorageUtil.isStationSetup(i)) {
                downloadStationData(i);
            }
        }
    }

    function downloadStationData(stationIndex as Number) as Void {
        var apiKey = PropUtil.getApiKey();
        if (apiKey == null) {
            System.println("Stormglass API key not set");
            return;
        }

        var coords = StorageUtil.getStationCoords(stationIndex);
        if (coords == null) {
            System.println("No coordinates available for station " + stationIndex.toString());
            return;
        }

        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => { "Authorization" => apiKey },
            :context => stationIndex
        };

        Communications.makeWebRequest(
            "https://api.stormglass.io/v2/tide/extremes/point",
            {
                "lat"   => coords[0].format("%.6f"),
                "lng"   => coords[1].format("%.6f"),
                "start" => DateUtil.getFromDateString(),
                "end"   => DateUtil.getToDateString(),
                "datum" => PropUtil.getDatum()
            },
            options,
            new Method(WebRequests, :onReceiveStormglassData)
        );
    }

    function onReceiveStormglassData(responseCode as Number, data as Dictionary?, context as Object) as Void {
        if (responseCode == 200 && data != null) {
            var tideEvents = data["data"];
            if (tideEvents instanceof Array) {
                processData(tideEvents as Array, context as Number);
                return;
            }
        } else if (responseCode == Communications.BLE_CONNECTION_UNAVAILABLE) {
            System.println("Failed: BLE connection unavailable");
        } else {
            System.println("Stormglass request failed: " + responseCode.toString());
        }
    }

    function processData(args as Array, stationIndex as Number) as Void {
        var app = getApp();
        var maxTide = 0.0;

        if (app.tideData == null) {
            app.tideData = [];
            for (var i = 0; i < app.stationsToShow; i++) {
                app.tideData.add([]);
            }
        }
        app.tideData[stationIndex] = [];

        for (var i = 0; i < args.size(); i++) {
            var eventData = args[i] as Dictionary;
            var height  = eventData["height"];
            var timeStr = eventData["time"];
            if (!(height instanceof Float) && !(height instanceof Double)) {
                height = (height as Number).toFloat();
            }
            if (timeStr == null || !(timeStr instanceof String)) { continue; }
            var h = (height as Float);
            if (h > maxTide) { maxTide = h; }
            app.tideData[stationIndex].add([DateUtil.parseDateString(timeStr as String).value(), h]);
        }

        app.tideDataValid[stationIndex] = true;
        StorageUtil.setTideData(app.tideData);
        StorageUtil.setMaxTide(stationIndex, maxTide);

        System.println("Updated station " + stationIndex.toString() + " (" + StorageUtil.getStationName(stationIndex) + ")");

        if (app.background) {
            Background.exit(true);
        } else {
            Notification.showNotification(Rez.Strings.dataReceivedMessage as String, 2000);
            WatchUi.requestUpdate();
        }
    }
}
