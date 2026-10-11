import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.System;

(:background)
module PropUtil {
    public enum unitsPropSettings {
        UNITS_PROP_SYSTEM,
        UNITS_PROP_METRIC,
        UNITS_PROP_IMPERIAL
    }

    public enum datumPropSettings {
        DATUM_PROP_MSL,
        DATUM_PROP_MLLW
    }

    function getDatum() as String {
        var setting = Properties.getValue("datumProp") as Number;
        return (setting == DATUM_PROP_MLLW) ? "MLLW" : "MSL";
    }

    (:glance)
    function getUnits() as System.UnitsSystem {
        var setting = Properties.getValue("unitsProp");
        if (setting == UNITS_PROP_SYSTEM) {
            return System.getDeviceSettings().elevationUnits;
        } else if (setting == UNITS_PROP_METRIC) {
            return System.UNIT_METRIC;
        } else {
            return System.UNIT_STATUTE;
        }
    }

    (:glance)
    function units() as String {
        if (getUnits() == System.UNIT_STATUTE) {
            return "ft";
        }
        return "m";
    }

    (:glance)
    function heightMultiplier() as Float {
        if (getUnits() == System.UNIT_STATUTE) {
            return 3.28084;
        }
        return 1.0f;
    }

    function getBackgroundDownload() as Boolean {
        return Properties.getValue("backgroundDownloadProp");
    }

    function getApiKey() as String? {
        var key = Properties.getValue("apiKey") as String?;
        if (key == null || key.length() == 0) { return null; }
        return key;
    }
}
