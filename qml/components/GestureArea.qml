import QtQuick 2.0
import Sailfish.Silica 1.0

MultiPointTouchArea {

    // we want to get a signal when a two finger gesture is started
    // and still allow other items to also get touch events

    minimumTouchPoints: 2
    maximumTouchPoints: 2

    signal doubleGestureStarted()

    onGestureStarted: doubleGestureStarted()

    onDoubleGestureStarted: app.setMenuAsAttachedPage()
    onCanceled: app.setPlayingAsAttachedPage()
}
