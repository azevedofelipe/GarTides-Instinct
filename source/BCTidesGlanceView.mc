import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

using Toybox.Time;
using Toybox.Time.Gregorian;

(:glance)
class BCTidesGlanceView extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    // "2h05", "45min", "1h", "now"
    private function formatCountdown(seconds as Number) as String {
        if (seconds <= 0) { return "now"; }
        var h = seconds / 3600;
        var m = (seconds % 3600) / 60;
        if (h == 0) { return m.toString() + "min"; }
        if (m == 0) { return h.toString() + "h"; }
        return h.toString() + "h" + m.format("%02d");
    }

    // Horizontal bar: white = rising, DK_GRAY = falling, 2px gap between segments.
    // 24-hour window: 6 hours before now (left edge) to 18 hours ahead (right edge).
    // Yellow 2px marker at the 25% position = "now".
    private function drawTideBar(dc as Dc, data as Array, now as Number,
                                  barX as Number, barY as Number,
                                  barW as Number, barH as Number) as Void {
        var windowSec   = 86400;          // 24 h in seconds
        var windowStart = now - 6 * 3600; // 6 h before now
        var windowEnd   = windowStart + windowSec;
        var gap         = 2;

        for (var i = 0; i < data.size() - 1; i++) {
            var e0 = data[i]     as Array;
            var e1 = data[i + 1] as Array;
            var t0 = e0[0] as Number;
            var h0 = e0[1] as Float;
            var t1 = e1[0] as Number;
            var h1 = e1[1] as Float;

            if (t1 <= windowStart || t0 >= windowEnd) { continue; }

            var seg0 = t0 < windowStart ? windowStart : t0;
            var seg1 = t1 > windowEnd   ? windowEnd   : t1;

            var x0   = barX + (seg0 - windowStart) * barW / windowSec;
            var x1   = barX + (seg1 - windowStart) * barW / windowSec;
            var segW = x1 - x0 - gap;
            if (segW < 1) { segW = 1; }

            if (h1 > h0) {
                // Rising: solid white
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x0, barY, segW, barH);
            } else {
                // Falling: checkerboard dither — fillRectangle(1,1) draws a single pixel,
                // unlike drawLine(x,y,x,y) which is a zero-length no-op on Garmin.
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                for (var py = barY; py < barY + barH; py++) {
                    var startX = x0 + ((x0 + py) % 2);
                    for (var px = startX; px < x0 + segW; px += 2) {
                        dc.fillRectangle(px, py, 1, 1);
                    }
                }
            }
        }

        // "Now" marker: 2px wide, 1px taller than the bar, yellow
        var markerX = barX + barW * 6 / 24;
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(markerX, barY - 4, 2, barH + 8);
    }

    function onUpdate(dc as Dc) {
        var stationIndex = StorageUtil.getLastStationIndex();
        var data         = TideUtil.tideData(stationIndex);
        var now          = Time.now().value().toNumber();

        if (data == null || data.size() < 2) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0, 0, Graphics.FONT_GLANCE, "No tide data", Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0, dc.getFontHeight(Graphics.FONT_GLANCE), Graphics.FONT_GLANCE,
                "Open app to load", Graphics.TEXT_JUSTIFY_LEFT);
            return;
        }

        var nextEvent = TideUtil.getNextEvent(now, stationIndex);
        var nextTime  = nextEvent[:eventTime] as Number?;
        if (nextTime == null) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0, 0, Graphics.FONT_GLANCE, "Data expired", Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0, dc.getFontHeight(Graphics.FONT_GLANCE), Graphics.FONT_GLANCE,
                "Open app to refresh", Graphics.TEXT_JUSTIFY_LEFT);
            return;
        }

        var mult       = PropUtil.heightMultiplier();
        var units      = PropUtil.units();
        var hOffset    = StorageUtil.getStationHeightOffset(stationIndex);
        var nextHeight = ((nextEvent[:eventHeight] as Float) + hOffset) * mult;
        var nextType   = nextEvent[:eventType] as String;
        var secsUntil  = nextTime - now;

        var stationName = StorageUtil.getStationName(stationIndex);
        if (stationName.length() > 14) {
            stationName = stationName.substring(0, 12) + "..";
        }

        var fH   = dc.getFontHeight(Graphics.FONT_GLANCE);
        var barH = 8;
        var barY = fH + 3;

        // ── Station name ──────────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, 0, Graphics.FONT_GLANCE, stationName, Graphics.TEXT_JUSTIFY_LEFT);

        // ── Tide bar ──────────────────────────────────────────────────────────
        drawTideBar(dc, data, now, 0, barY, dc.getWidth(), barH);

        // ── Next tide: "L 0.9m in 2h30" ──────────────────────────────────────
        var line = nextType + " " + nextHeight.format("%.2f") + units +
                   " in " + formatCountdown(secsUntil);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, barY + barH + 3, Graphics.FONT_GLANCE, line, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
