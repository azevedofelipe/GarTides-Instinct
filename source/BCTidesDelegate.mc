import Toybox.Lang;

using Toybox.WatchUi;

class BCTidesDelegate extends WatchUi.BehaviorDelegate {
    var view as BCTidesView;

    function initialize(associatedView as BCTidesView) {
        view = associatedView;
        WatchUi.BehaviorDelegate.initialize();
    }

    function onNextPage() as Boolean {
        view.nextPage();
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        view.prevPage();
        WatchUi.requestUpdate();
        return true;
    }

    function onMenu() as Boolean {
        MainMenu.pushMenu();
        return true;
    }

    function onStateUpdated(state) as Void {
        WatchUi.requestUpdate();
    }

    // Station cycling is available via Menu > Next Station
    function onSelect() as Boolean {
        view.toggleView();
        WatchUi.requestUpdate();
        return true;
    }

}
