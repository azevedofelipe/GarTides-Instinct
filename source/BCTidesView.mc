import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

class BCTidesView extends WatchUi.View {
    private var _pageIndicator as PageIndicatorRad;
    private var _stationIndicator as PageIndicatorRad;
    private var _position as Position.Info? = null;
    private var _needGPS as Boolean = true;
    private var _app as BCTidesApp;

    private var _page as Number = 0;
    private var _pageCount as Number = 7;
    private var _pageUpdated as Boolean = true;
    private var _stationIndex as Number = 0;
    private var _stationCount as Number = 3;
    private var _showGraph as Boolean = false;

    // Public accessors for BCTidesDelegate
    public function getPage() as Number { return _page; }
    public function getStationIndex() as Number { return _stationIndex; }

    // Doesn't set _pageUpdated, so toggling with no data won't re-prompt for a download
    public function toggleView() as Void {
        _showGraph = !_showGraph;
        StorageUtil.setGraphView(_showGraph);
    }

    public function cycleStations() as Void {
        var start = _stationIndex;
        do {
            _stationIndex = (_stationIndex + 1) % _stationCount;
        } while (_stationIndex != start && !StorageUtil.isStationSetup(_stationIndex));
        StorageUtil.setLastStationIndex(_stationIndex);
        _pageUpdated = true;
    }

    public function nextPage() as Void {
        _page = (_page + 1) % _pageCount;
        _pageUpdated = true;
    }

    public function prevPage() as Void {
        _page = (_page + _pageCount - 1) % _pageCount;
        _pageUpdated = true;
    }

    function initialize(app as BCTidesApp) {
        _app = app;
        View.initialize();
        _stationIndex     = StorageUtil.getLastStationIndex();
        _showGraph        = StorageUtil.getGraphView();
        _pageIndicator    = new PageIndicatorRad(_pageCount,    Graphics.COLOR_WHITE, ALIGN_CENTER_LEFT,  /*margin*/5);
        _stationIndicator = new PageIndicatorRad(_stationCount, Graphics.COLOR_WHITE, ALIGN_CENTER_RIGHT, /*margin*/5);
    }

    function onPosition(info as Position.Info) as Void {
        _position = info;
        WatchUi.requestUpdate();
    }

    function onLayout(dc as Dc) as Void {
        if (_position == null || _position.accuracy < Position.QUALITY_POOR) {
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        }
    }

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function drawNoDataWarning(dc as Dc, x as Number, y as Number, w as Number, h as Number, message as String or ResourceId or Symbol, showDownloadPrompt as Boolean) as Void {
        message = message instanceof String ? message : WatchUi.loadResource(message) as String;

        var maxY = getApp().screenHeight * 0.57;
        y = y > maxY ? maxY.toNumber() : y;

        var textArea = new WatchUi.TextArea({
            :text            => message,
            :color           => Graphics.COLOR_RED,
            :backgroundColor => Graphics.COLOR_TRANSPARENT,
            :font            => Graphics.FONT_SMALL,
            :justification   => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX            => x,
            :locY            => y,
            :width           => w,
            :height          => h
        });
        textArea.draw(dc);

        if (!_pageUpdated || !showDownloadPrompt) {
            return;
        }

        WatchUi.pushView(
            new WatchUi.Confirmation(WatchUi.loadResource(Rez.Strings.downloadDataPrompt) as String),
            new DownloadDataConfirmationDelegate(_stationIndex),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    // Draws the moon phase inside the top-right circle (cx=144, cy=31, r=31).
    // Icon centred at y=24 (shifted up) so the text label clears the circle bottom at y=62.
    function drawCircleIndicator(dc as Dc, selectedDay as Time.Moment) as Void {
        drawMoonPhase(dc, 144, 24, selectedDay);
    }

    // Per-pixel 3D moon: Bayer 2x2 ordered dithering simulates a sphere lit from upper-right.
    // Shadow side determined by the same two-circle offset logic as before.
    // Full moon uses yellow with a compressed gradient (50–100%) so it stays mostly filled.
    // New moon shows as a sparse dithered ring (dark, barely visible).
    function drawMoonPhase(dc as Dc, cx as Number, cy as Number, day as Time.Moment) as Void {
        var r = 15;
        var daysSince = (day.value() - 947225640) / 86400.0f;
        var cycles = daysSince / 29.53059f;
        var frac = cycles - cycles.toNumber().toFloat();
        if (frac < 0.0f) { frac += 1.0f; }
        var phase = (frac * 8.0f).toNumber() % 8;

        var sdx = 0;
        if      (phase == 1) { sdx = -(r / 2); }
        else if (phase == 2) { sdx = -r; }
        else if (phase == 3) { sdx = -(r * 3 / 2); }
        else if (phase == 5) { sdx =  (r * 3 / 2); }
        else if (phase == 6) { sdx =  r; }
        else if (phase == 7) { sdx =  (r / 2); }

        var r2 = r * r;
        var isFullMoon = (phase == 4);

        if (phase == 0) {
            // New moon: sparse dithered ring outline
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            for (var dy = -r; dy <= r; dy++) {
                for (var dx = -r; dx <= r; dx++) {
                    var d2 = dx * dx + dy * dy;
                    if (d2 < (r - 2) * (r - 2) || d2 > r2) { continue; }
                    if ((cx + dx + cy + dy) % 2 == 0) {
                        dc.fillRectangle(cx + dx, cy + dy, 1, 1);
                    }
                }
            }
        } else {
            if (isFullMoon) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }

            for (var dy = -r; dy <= r; dy++) {
                for (var dx = -r; dx <= r; dx++) {
                    if (dx * dx + dy * dy > r2) { continue; }

                    // Shadow mask — pixel is dark if inside the offset shadow circle
                    if (!isFullMoon) {
                        var sdxOff = dx - sdx;
                        if (sdxOff * sdxOff + dy * dy <= r2) { continue; }
                    }

                    // 3D illumination: light from upper-right → illum high at (+dx, -dy)
                    // Full moon: compressed range 8–16 so it stays ≥50% filled everywhere
                    // Other phases: full range 0–16 for a strong gradient
                    var illum;
                    if (isFullMoon) {
                        illum = ((dx - dy + 2 * r) * 8) / (4 * r) + 8;
                    } else {
                        illum = ((dx - dy + 2 * r) * 16) / (4 * r);
                    }
                    if (illum > 16) { illum = 16; }
                    if (illum < 0)  { illum = 0;  }

                    // 2×2 Bayer ordered dither thresholds (0, 8, 12, 4 out of 16)
                    var xm = (cx + dx) % 2;
                    var ym = (cy + dy) % 2;
                    var bayer;
                    if      (xm == 0 && ym == 0) { bayer = 0;  }
                    else if (xm == 1 && ym == 0) { bayer = 8;  }
                    else if (xm == 0 && ym == 1) { bayer = 12; }
                    else                          { bayer = 4;  }

                    if (illum > bayer) {
                        dc.fillRectangle(cx + dx, cy + dy, 1, 1);
                    }
                }
            }
        }

        var labels = ["Nova", "Cresc", "Q.Cr", "G.Cr", "Cheia", "G.Mg", "Q.Mg", "Ming"];
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + r + 8, Graphics.FONT_XTINY, labels[phase],
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Table of the day's highs/lows starting at row y; inset is the side margin as a fraction of screen width.
    // compact spaces rows by the font ascent instead of the full cell height (the cell includes ~10px of padding).
    function drawTideTable(dc as Dc, y as Number, inset as Float, compact as Boolean) as Void {
        var w = dc.getWidth();
        var selectedDay = Time.today().add(new Time.Duration(Gregorian.SECONDS_PER_DAY * _page));
        var endDay = selectedDay.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));
        var tableX = (w * inset).toNumber();
        var tableW = w - 2 * tableX;
        var col1 = tableX + tableW / 4;
        var col2 = tableX + 3 * tableW / 4;
        var mult = PropUtil.heightMultiplier();
        var units = PropUtil.units();
        var hOffset = StorageUtil.getStationHeightOffset(_stationIndex);
        var rowH = compact
            ? Graphics.getFontAscent(Graphics.FONT_TINY) - 4
            : dc.getFontHeight(Graphics.FONT_TINY) - 4;

        var data = TideUtil.tideData(_stationIndex);
        var entries = 0;
        if (data != null) {
            for (var i = 0; i < data.size(); i++) {
                var t = data[i][0] as Number;
                var evtHeight = data[i][1] as Float;
                if (t > endDay.value()) { break; }
                if (t >= selectedDay.value()) {
                    var m = new Time.Moment(t);
                    var label = "";
                    if (i > 0 && i < data.size() - 1) {
                        label = (evtHeight > (data[i-1][1] as Float)) ? "H" : "L";
                    }
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(col1, y, Graphics.FONT_TINY,
                        DateUtil.formatTimeStringShort(m) + " " + label,
                        Graphics.TEXT_JUSTIFY_CENTER);
                    dc.drawText(col2, y, Graphics.FONT_TINY,
                        ((evtHeight + hOffset) * mult).format("%.2f") + units,
                        Graphics.TEXT_JUSTIFY_CENTER);
                    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                    dc.drawLine(tableX + tableW / 2, y, tableX + tableW / 2, y + rowH);
                    y += rowH;
                    entries++;
                }
            }
        }

        if (entries == 0) {
            drawNoDataForDate(dc);
        }
    }

    function drawNoDataForDate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.noDataAvailableForDate) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Half-cosine interpolation between two consecutive extremes (same model as TideUtil.getHeightAtT)
    private function heightBetween(e0 as Array, e1 as Array, t as Number) as Float {
        var t0 = e0[0] as Number;
        var t1 = e1[0] as Number;
        var h0 = (e0[1] as Float).toFloat();
        var h1 = (e1[1] as Float).toFloat();
        if (t1 == t0) { return h0; }
        var frac = (t - t0).toFloat() / (t1 - t0);
        return (h0 + h1) / 2.0f + (h0 - h1) / 2.0f * Toybox.Math.cos(Toybox.Math.PI * frac);
    }

    // Graph view: tide curve on top, the day's high/low table underneath
    function drawTideGraph(dc as Dc) as Void {
        if (drawTideCurve(dc, 68, 90)) {
            drawTideTable(dc, 94, 0.18f, true);
        } else {
            drawNoDataForDate(dc);
        }
    }

    // Tide curve for the selected day (local midnight to midnight) between rows plotTop..plotBottom,
    // with a dot at each high/low and a vertical line at the current time.
    // Returns false if there is no data covering the day.
    function drawTideCurve(dc as Dc, plotTop as Number, plotBottom as Number) as Boolean {
        var data = TideUtil.tideData(_stationIndex) as Array<Array>;
        var n = data.size();
        if (n < 2) { return false; }

        var w = dc.getWidth();
        var daySec = Gregorian.SECONDS_PER_DAY;
        var dayStart = Time.today().value() + daySec * _page;
        var dayEnd = dayStart + daySec;

        // Extremes bracketing the day: last one at/before midnight through first one at/after the next midnight
        var first = 0;
        var last = n - 1;
        for (var i = 0; i < n; i++) {
            var t = data[i][0] as Number;
            if (t <= dayStart) { first = i; }
            if (t >= dayEnd) { last = i; break; }
        }
        if ((data[first][0] as Number) >= dayEnd || (data[last][0] as Number) <= dayStart) {
            return false;
        }

        var minH = (data[first][1] as Float).toFloat();
        var maxH = minH;
        for (var i = first + 1; i <= last; i++) {
            var eh = (data[i][1] as Float).toFloat();
            if (eh < minH) { minH = eh; }
            if (eh > maxH) { maxH = eh; }
        }
        var range = maxH - minH;
        if (range < 0.01f) { range = 0.01f; }

        var gx0 = (w * 0.1).toNumber();
        var gw = w - 2 * gx0;
        var plotH = plotBottom - plotTop;

        // Curve, with a 25% dither fill underneath
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var seg = first;
        var prevY = -1;  // -1: no previous point (gap in data)
        for (var x = gx0; x <= gx0 + gw; x++) {
            var t = dayStart + ((x - gx0) * daySec) / gw;
            while (seg < last - 1 && (data[seg + 1][0] as Number) < t) { seg++; }
            if (t < (data[seg][0] as Number) || t > (data[seg + 1][0] as Number)) {
                prevY = -1;
                continue;
            }
            var y = plotBottom - ((heightBetween(data[seg], data[seg + 1], t) - minH) / range * plotH).toNumber();
            if (prevY >= 0) {
                dc.drawLine(x - 1, prevY, x, y);
            }
            if (x % 2 == 0) {
                for (var yy = y + 2 + (x / 2) % 2; yy <= plotBottom; yy += 2) {
                    dc.drawPoint(x, yy);
                }
            }
            prevY = y;
        }

        var now = Time.now().value();
        if (now >= dayStart && now < dayEnd) {
            // Black gap either side so the line stands out from the dither fill, plus a down-arrow on top
            var nx = gx0 + ((now - dayStart) * gw) / daySec;
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(nx - 1, plotTop - 2, 3, plotBottom - plotTop + 4);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(nx, plotTop - 2, nx, plotBottom + 2);
            dc.fillPolygon([[nx - 3, plotTop - 6], [nx + 4, plotTop - 6], [nx, plotTop - 2]]);
        }

        // Black ring so each marker stands out against the fill
        for (var i = first; i <= last; i++) {
            var t = data[i][0] as Number;
            if (t < dayStart || t >= dayEnd) { continue; }
            var ex = gx0 + ((t - dayStart) * gw) / daySec;
            var ey = plotBottom - (((data[i][1] as Float).toFloat() - minH) / range * plotH).toNumber();
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(ex, ey, 4);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(ex, ey, 2);
        }
        return true;
    }

    // Header text is centered in the top-left safe zone (x=0..99).
    // The top-right circle (cx=144,cy=31,r=31) is drawn by drawCircleIndicator.
    private const HEADER_CENTER_X_RATIO = 0.28f;  // 49px for 176px screen, centre of 0..99

    function drawDateString(dc as Dc, selectedDay as Time.Moment) as Void {
        var dateInfo = Gregorian.info(selectedDay, Time.FORMAT_MEDIUM);
        var cx = (dc.getWidth() * HEADER_CENTER_X_RATIO).toNumber();
        dc.drawText(cx, (dc.getHeight() * 0.09).toNumber(), Graphics.FONT_TINY,
            dateInfo.month + " " + dateInfo.day.toString(),
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawStationName(dc as Dc) as Void {
        var cx = (dc.getWidth() * HEADER_CENTER_X_RATIO).toNumber();
        var name = StorageUtil.getStationName(_stationIndex);
        if (name.length() > 12) {
            name = name.substring(0, 9) + "...";
        }
        dc.drawText(cx, (dc.getHeight() * 0.19).toNumber(), Graphics.FONT_XTINY,
            name, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function updateLocation(position as Position.Location) as Void {
        _app.currentPosition = position;
    }

    function dealWithPosition() as Void {
        if (_needGPS) {
            if (_position == null || _position.accuracy == null || _position.accuracy < Position.QUALITY_POOR) {
                _position = Position.getInfo();
            }
            if (_position.accuracy != null && _position.accuracy != Position.QUALITY_NOT_AVAILABLE && _position.position != null) {
                if (_position.accuracy >= Position.QUALITY_POOR) {
                    Position.enableLocationEvents(Position.LOCATION_DISABLE, self.method(:onPosition));
                    _needGPS = false;
                }
            }
        }
        if (_position != null && _position.position != null) {
            updateLocation(_position.position);
        }
        if (_position == null || _position.position == null || _position.accuracy == Position.QUALITY_NOT_AVAILABLE) {
            var cc = Toybox.Weather.getCurrentConditions() as Toybox.Weather.CurrentConditions;
            if (cc != null) {
                var pos = cc.observationLocationPosition as Position.Location;
                if (pos != null) {
                    updateLocation(pos);
                }
            }
        }
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dealWithPosition();

        var selectedDay = Time.today().add(new Time.Duration(Gregorian.SECONDS_PER_DAY * _page));
        drawDateString(dc, selectedDay);
        drawStationName(dc);
        _pageIndicator.draw(dc, _page);
        _stationIndicator.draw(dc, _stationIndex);

        drawCircleIndicator(dc, selectedDay);

        var tblX = (dc.getWidth() * 0.1).toNumber();
        var tblY = 66;
        var tblW = dc.getWidth() - tblX * 2;
        var tblH = (dc.getHeight() * 0.47).toNumber();

        if (!StorageUtil.isStationSetup(_stationIndex)) {
            drawNoDataWarning(dc, tblX, tblY, tblW, tblH, Rez.Strings.noStationConfiguredMessage, false);
        } else if (TideUtil.tideData(_stationIndex) != null && _app.tideDataValid[_stationIndex]) {
            if (_showGraph) {
                drawTideGraph(dc);
            } else {
                drawTideTable(dc, 72, 0.1f, false);
            }
        } else {
            drawNoDataWarning(dc, tblX, tblY, tblW, tblH, Rez.Strings.noDataAvailableForStation, true);
        }

        _pageUpdated = false;
    }
}
