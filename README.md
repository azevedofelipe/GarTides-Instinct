# GarTides

A Garmin Connect IQ widget for tide predictions at any location worldwide, optimised for the **Garmin Instinct 3 Solar 45mm**. Forked from [bc_tides](https://github.com/bain-syrowik/bc_tides) and adapted for use with the [Stormglass API](https://stormglass.io).

---

## Features

- **Tide table** — shows all high and low tide events for the selected day, with time and height
- **Tide graph** — the day's tide curve with the high/low table underneath; press SELECT to switch between table and graph
- **7-day view** — swipe forward/back through today and the next 6 days
- **3 configurable stations** — set fixed coordinates or use GPS for any location in the world
- **Moon phase indicator** — displayed in the top-right circle of the Instinct 3 display, with icon and label
- **Units** — metric (m) or imperial (ft), configurable in Garmin Connect settings
- **Auto data refresh** — downloads fresh tide data in the background once per day (~2am)
- **Manual refresh** — trigger a download on demand from inside the app
- **Glance view** — shows upcoming tide at a glance from the watch face widget screen
- **English and French localisation** (app settings labels)

---

## How to Use

### Navigation

| Button | Action |
|--------|--------|
| **UP / DOWN** | Scroll through days (today + 6 days ahead) |
| **SELECT** (short press) | Toggle between tide table and tide graph |
| **MENU** (long press) | Open the settings menu |

### Settings Menu

Accessed by long-pressing the **MENU** button (top-left on Instinct 3):

- **Next Station** — cycles to the next configured station
- **Manage Stations** — configure station names, coordinates, and GPS use
- **Display Options** — change units and other display preferences
- **Station Data** — view raw data info for the current station
- **Refresh GPS** — force a GPS position update

### Screen Layout

```
┌─────────────────────┐
│  Jun 7    [Moon 🌙] │  ← date (left) + moon phase icon + label (top-right circle)
│  Rio de Jan...      │  ← station name (truncated to ~12 chars)
│                     │
│  06:14 L  0.1m      │  ← tide table rows (time, H/L, height)
│  12:38 H  1.4m      │
│  18:52 L  0.2m      │
│  01:03 H  1.3m      │
└─────────────────────┘
```

Page indicators on the left edge show which day you are viewing. Station indicators on the right edge show which station is active.

---

## Data Refresh

### Automatic (background)

If **Auto-Update Data** is enabled in the Garmin Connect app settings, GarTides schedules a background wake-up approximately once per day, timed for around **2am local time**. The watch connects to your phone and silently downloads fresh tide data for all configured stations. No action is needed from you.

If the watch is out of Bluetooth range at 2am the refresh is skipped and retried the following day.

### Manual

When you open the widget and a station has no data (or data has expired), the app shows:

> *"No data. Hold MENU for options."*

Long-press MENU, choose **Station Data → Get Data** or confirm the download prompt that appears automatically. The app fetches data for the current station immediately.

You can also trigger a manual refresh for all stations via the menu at any time.

### Data window fetched

Each API call to Stormglass requests:

| Boundary | Value |
|----------|-------|
| Start | 14 hours before today's midnight (captures overnight tides) |
| End | 7 days + 6 hours from now |

This gives roughly **7 days of tide extremes** per station per fetch. The data is stored on-device and survives app restarts.

### Stormglass API usage

Each refresh fetches one request per configured station (up to 3). The free Stormglass tier allows **10 requests per day**, so daily auto-refresh of 3 stations uses 3 of those 10 requests.

---

## Setup

### 1. Get a Stormglass API key

Create a free account at [stormglass.io](https://stormglass.io) and copy your API key.

### 2. Configure the app in Garmin Connect

Open the **GarTides** widget settings in the Garmin Connect app (or Garmin Express) and set:

- **Stormglass API Key** — paste your key here
- **Station 1–3 Name** — display name shown on the watch
- **Station 1–3 Latitude / Longitude** — decimal degrees (e.g. `48.4284`, `-123.3656`)
- **Station 1–3: Use GPS** — enable to use your watch's current GPS position instead of fixed coordinates
- **Units** — System / Metric / Imperial
- **Auto-Update Data** — enable for daily background refresh (recommended)

### 3. Download data

Open the widget on the watch. If no data is present you will be prompted to download it. Confirm to fetch tide data for the current station.

### Optional: build with your own defaults (sideloading)

If you sideload builds instead of installing from the store, you can bake your API key and stations into the build so you don't have to enter them in Garmin Connect. Create `resources-local/properties.xml` (it is git-ignored, so it never gets committed) and override any property from `resources/properties.xml`:

```xml
<resources>
    <properties>
        <property id="apiKey" type="string">YOUR_STORMGLASS_KEY</property>
        <property id="station1Name" type="string">My Beach</property>
        <property id="station1Lat" type="string">48.4284</property>
        <property id="station1Lng" type="string">-123.3656</property>
    </properties>
</resources>
```

`monkey.jungle` layers this folder over `resources/`; without it the build uses the blank defaults.

---

## Permissions

| Permission | Purpose |
|------------|---------|
| **Background** | Daily automatic tide data refresh at ~2am |
| **Communications** | HTTP requests to the Stormglass API |
| **Positioning** | GPS-based station coordinates (when "Use GPS" is enabled) |

---

## Device Support

Primarily developed and tested on the **Garmin Instinct 3 Solar 45mm** (176×176 px octagonal display). The app makes use of the top-right circle area of that display for the moon phase indicator.

Other devices listed in `manifest.xml` may work but the layout is not optimised for them.

---

## Language Support

- **English** (primary)
- **French** (settings labels, partial — machine translated)

Moon phase labels on the watch are displayed in **Portuguese**: Nova, Cresc, Q.Cr, G.Cr, Cheia, G.Mg, Q.Mg, Ming.

---

## Data Source

Tide predictions are provided by the **Stormglass API**:

- Endpoint: `https://api.stormglass.io/v2/tide/extremes/point`
- Documentation: https://docs.stormglass.io

---

## Disclaimer

This project is not affiliated with, sponsored by, or endorsed by Garmin or Stormglass.

Tide predictions are provided for informational purposes only. Do not rely solely on this app for navigation, diving, or any activity where tidal information is safety-critical. Always verify tide data with official sources.

This code and application are provided "as is" without warranty of any kind, express or implied.
