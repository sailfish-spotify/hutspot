import QtQuick 2.1
import Sailfish.Silica 1.0

Rectangle {
    property alias source: backgroundImage.source
    property alias sourceSize: backgroundImage.sourceSize
    property real dimmedOpacity: 0.15
    color: app.lightTheme ? "#fff" : "#000"

    Image {
        id: backgroundImage
        cache: true
        smooth: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        anchors.fill: parent
        visible: parent.visible
        opacity: dimmedOpacity
    }

    Image {
        anchors.fill: parent
        fillMode:  Image.Tile
        source: "image://theme/graphic-shader-texture"
        opacity: 0.1
        visible: parent.visible
    }
}
