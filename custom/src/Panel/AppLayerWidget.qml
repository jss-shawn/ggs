
import QtQuick

import QGroundControl

import Gises.Widget
import Gises.Fly
import Gises.Plan

Item{
    id: root

    anchors.fill: parent

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property var bgLayer

    FlyView{
        id: flyView
        isMain: root.parent === bgLayer
        anchors.fill: parent
        visible: !showPlanView
    }

    PlanView{
        id: planView
        isMain: root.parent === bgLayer
        anchors.fill: parent
        visible: showPlanView
    }
}
