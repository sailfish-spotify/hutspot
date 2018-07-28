import QtQuick 2.1
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Item {
    property alias source: backgroundImage.source
    property alias sourceSize: backgroundImage.sourceSize
    property real dimmedOpacity: 0.15

    Image {
        id: backgroundImage
        cache: true
        smooth: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        anchors.fill: parent
        visible: false
    }
    BrightnessContrast {
        anchors.fill: backgroundImage
        source: backgroundImage
        brightness: -1 + dimmedOpacity
        contrast: 0
    }

    Image {
        anchors.fill: parent
        fillMode:  Image.Tile
        source: "image://theme/graphic-shader-texture"
        opacity: 0.1
    }
}
