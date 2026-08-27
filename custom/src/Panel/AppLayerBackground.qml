
import QtQuick

import QGroundControl
import QGroundControl.FlightMap

import Gises.Widget

Item{
    id: root

    anchors.fill: parent

    property ColorConfig cc: clcfg
    property Ui ui: Ui

    property var videoLayer
    property bool showMap: children[0] === wg

    AppLayerWidget{
        id: wg
        bgLayer: root
    }
}
