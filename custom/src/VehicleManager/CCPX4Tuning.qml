import QtQuick
import QtQuick.Controls

import QGroundControl.Controllers
import QGroundControl.FactSystem

import gises
import gises.base
import gises.data
import gises.widget

CCVehicleSetupContainer {
    id: root

    titleText: qsTr("Vehicle PID Tuning")

    property var autotuneManager: vehicle.autotune
    //property var fixedWingViews: [qsTr("Rate"), qsTr("Altitude")]
    //property var multirotorViews: [qsTr("Rate"), qsTr("Altitude"), qsTr("Velocity"), qsTr("Position")]
    property bool armed: vehicle.armed
    property bool showAutoSwitch: !vehicle.fixedWing && gcsCtrl.group < 2
    property bool showAutoTuning: !vehicle.fixedWing && gcsCtrl.group < 2
    property int tickCountX: 5
    property int tickCountY: 4
    property int valueInterval: 5

    property Fact mcPosMode: ctrl.getParameterFact(-1, "MPC_POS_MODE", false)
    property Fact airmode: ctrl.getParameterFact(-1, "MC_AIRMODE", false)
    property Fact thrustModelFactor: ctrl.getParameterFact(-1, "THR_MDL_FAC", false)
    property var tuningParamValues: []

    property var tuneModel: datas.viewModel[gcsCtrl.group]
    property var tuneData: datas.viewModel[gcsCtrl.group].dataModel[gcsCtrl.index]

    Component.onDestruction: vehicle.setPIDTuningTelemetryMode(vehicle.ModeDisabled)
    Component.onCompleted: {
        vehicle.setPIDTuningTelemetryMode(views.mode)
        saveTuningParamValues()
    }
    onArmedChanged: {
        if(armed && !gcsCtrl.active){
            gcsCtrl.start()
        }
    }

    function adjustYAxisMin(yAxis, newValue) {
        var newMin = Math.min(yAxis.min, newValue)
        if (newMin % valueInterval != 0) {
            newMin -= valueInterval
            newMin = Math.floor(newMin / valueInterval) * valueInterval
        }
        yAxis.min = newMin
    }
    function adjustYAxisMax(yAxis, newValue) {
        var newMax = Math.max(yAxis.max, newValue)
        if (newMax %  valueInterval!= 0) {
            newMax += valueInterval
            newMax = Math.floor(newMax / valueInterval) * valueInterval
        }
        yAxis.max = newMax
    }

    // Save the current set of tuning values so we can reset to them
    function saveTuningParamValues() {
        tuningParamValues = [ ]
        var params = tuneData.params
        for (var i=0; i<params.count; i++) {
            var currentTuneParam = ctrl.getParameterFact(-1, params.get(i).param)
            var str = currentTuneParam ? currentTuneParam.valueString : "Error"
            tuningParamValues.push(str)
        }
        //savedRepeater.model = tuningParamValues
    }
    function resetToSavedTuningParamValues() {
        var params = tuneData.params
        for (var i=0; i<params.count; i++) {
            var currentTuneParam = ctrl.getParameterFact(-1, params.get(i).param)
            if(currentTuneParam){
                currentTuneParam.value = tuningParamValues[i]
            }
        }
    }
    GCSTunningControl{
        id: gcsCtrl
        vehicle: root.vehicle
        redLine: chart.redLine
        greenLine: chart.greenLine
        blueLine: chart.blueLine
    }
    CCPX4TuningData{
        id: datas
        vehicle: root.vehicle
    }
    FactPanelController{ id: ctrl; }

    Item {
        anchors.fill: contentArea
        anchors.margins: ui.margin
        Column {
            anchors.fill: parent
            Row {
                id: head
                spacing: ui.fontWidth * 4
                CCComboBoxEditor{
                    width: ui.fontWidth * 40
                    title: qsTr("Position control mode (set this to 'simple' during tuning):")
                    fact: mcPosMode
                    singleLine: false
                    visible: mcPosMode
                }
                CCComboBoxEditor{
                    width: ui.fontWidth * 40
                    title: qsTr("Airmode (disable during tuning)")
                    fact: airmode
                    visible: airmode
                    CCText{
                        width: ui.fontWidth * 3
                        height: parent.height
                        text: "<b><a href=\"https://docs.px4.io/master/en/config_mc/pid_tuning_guide_multicopter.html#airmode-mixer-saturation\">?</a></b>"
                        alignMid: true
                        textFormat: Text.RichText
                        anchors.left: parent.right
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
                CCTextEditor{
                    width: ui.fontWidth * 24
                    title: qsTr("Thrust curve")
                    fact: thrustModelFactor
                    visible: thrustModelFactor
                    CCText{
                        width: ui.fontWidth * 3
                        height: parent.height
                        text: "<b><a href=\"https://docs.px4.io/master/en/config_mc/pid_tuning_guide_multicopter.html#thrust-curve\">?</a></b>"
                        alignMid: true
                        textFormat: Text.RichText
                        anchors.left: parent.right
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }
            CCMultiSwitch{
                id: views
                width: ui.fontWidth * 10 * model.length
                model: datas.viewModel
                dataName: "name"
                selectIndex: gcsCtrl.group
                property var mode: selectIndex > 1 ? vehicle.ModeVelocityAndPosition : vehicle.ModeRateAndAttitude
                onSwitchTo:
                    (index)=>{
                        gcsCtrl.group = index
                        vehicle.setPIDTuningTelemetryMode(mode)
                    }
            }
            Item{
                id: chartArea
                width: parent.width
                height: parent.height - head.height - views.height - autoArea.height
                CCChart{
                    id: chart
                    width: parent.width - rightArea.width - ui.margin
                    height: parent.height
                    title: tuneData.name + " " + tuneModel.name
                    yUnit: tuneModel.unit//qsTr("deg/s")
                    xUnit: qsTr("sec")
                    xAxis.tickCount: tickCountX + 1
                    yAxis.tickCount: tickCountY + 1
                    xAxis.min: gcsCtrl.xMin
                    xAxis.max: gcsCtrl.xMax
                    yAxis.min: gcsCtrl.yMin
                    yAxis.max: gcsCtrl.yMax
                    greenLine.name: qsTr("Response")
                    blueLine.name: qsTr("Setpoint")
                }
                Item{
                    id: rightArea
                    width: ui.fontWidth * 40
                    height: parent.height
                    anchors.right: parent.right
                    Column{
                        id: topCol
                        width: parent.width
                        spacing: ui.margin
                        CCMultiSwitch{
                            id: autoTune
                            model: [qsTr("Use auto-tuning"), qsTr("Use manual tuning")]
                            visible: showAutoTuning
                            onSwitchTo:
                                (index)=>{
                                    selectIndex = index
                                }
                        }
                        Column{
                            width: parent.width
                            spacing: ui.margin
                            visible: showAutoTuning && !autoTune.selectIndex

                            CCButton{
                                id: autotuneButton
                                width: ui.fontWidth * 18
                                height: ui.fontHeight * 2
                                text: qsTr("Start AutoTune")
                                enabled: vehicle.flying && !vehicle.landing && !autotuneManager.autotuneInProgress
                                onClicked: {
                                    dlg.title = autotuneButton.text
                                    dlg.func = autotuneManager.autotuneRequest
                                    dlg.confirmText = qsTr("Ok")
                                    dlg.info = qsTr("WARNING!\
                            \n\nThe auto-tuning procedure should be executed with caution and requires the vehicle to fly stable enough before attempting the procedure! \
                            \n\nBefore starting the auto-tuning process, make sure that: \
                            \n1. You have read the auto-tuning guide and have followed the preliminary steps \
                            \n2. The current control gains are good enough to stabilize the drone in presence of medium disturbances \
                            \n3. You are ready to abort the auto-tuning sequence by moving the RC sticks, if anything unexpected happens. \
                            \n\nClick Ok to start the auto-tuning process.\n")
                                }
                            }
                            CCText{
                                text: autotuneManager.autotuneStatus
                            }
                            ProgressBar{
                                width: parent.width
                                height: ui.fontHeight
                                value: autotuneManager.autotuneProgress
                            }
                        }
                        Column{
                            width: parent.width
                            spacing: ui.fontHeight
                            visible: !showAutoTuning || autoTune.selectIndex
                            CCMultiSwitchEditor{
                                id: tune
                                title: qsTr("Select Tunning")
                                model: tuneModel.dataModel
                                dataName: "name"
                                selectIndex: gcsCtrl.index
                                onSwitchTo:
                                    (index)=>{
                                        gcsCtrl.index = index
                                    }
                            }
                        }
                    }
                    Rectangle{
                        width: parent.width
                        height: parent.height - topCol.height - botCol.height
                        radius: ui.radius
                        color: cc.none
                        border.color: cc.border
                        anchors.top: topCol.bottom
                        visible: !showAutoTuning || autoTune.selectIndex
                        CCFlickable{
                            anchors.fill: parent
                            anchors.margins: ui.margin
                            fixedWidth: true
                            Column{
                                width: parent.width
                                spacing: ui.margin
                                Repeater{
                                    model: tuneData.params
                                    Column{
                                        width: parent.width
                                        spacing: ui.margin
                                        property var elem: tuneData.params.get(index)
                                        CCSeparator{
                                            width: parent.width
                                            visible: index
                                        }
                                        CCSliderEditor{
                                            title: parent.elem.title
                                            from: parent.elem.min
                                            to: parent.elem.max
                                            value: fc ? fc.value : from
                                            decim: 4
                                            stepSize: parent.elem.step
                                            property Fact fc: ctrl.getParameterFact(-1, parent.elem.param, false)
                                            onUpdateValue:
                                                (val)=>{
                                                    if(fc){
                                                        fc.value = val
                                                    }
                                                }
                                        }
                                        CCText{
                                            width: parent.width
                                            text: parent.elem.description
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Column{
                        id: botCol
                        width: parent.width
                        anchors.bottom: parent.bottom
                        visible: !showAutoTuning || autoTune.selectIndex
                        CCText{
                            text: qsTr("Clipboard Values")
                            font.pointSize: ui.lFontSize
                        }
                        Repeater{
                            model: tuneData.params
                            CCText{
                                text: elem.param + ": " + (fc ? fc.value.toFixed(4) : "")
                                property var elem: tuneData.params.get(index)
                                property Fact fc: ctrl.getParameterFact(-1, elem.param, false)
                            }
                        }
                        Item{
                            width: parent.width
                            height: save.height + ui.x2margin
                            CCButton{
                                id: save
                                width: (parent.width - ui.x2margin) / 2
                                text: qsTr("Save To Clipboard")
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                }
                            }
                            CCButton{
                                width: (parent.width - ui.x2margin) / 2
                                text: qsTr("Restore From Clipboard")
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {

                                }
                            }
                        }
                    }
                }
            }
            Column {
                id: autoArea
                width: parent.width
                spacing: ui.margin
                Row{
                    spacing: ui.fontWidth
                    CCButton{
                        id: clear
                        width: ui.fontWidth * 6
                        text: qsTr("Clear")
                        //onClicked: chart.clean()
                        onClicked: gcsCtrl.clear()
                    }
                    CCButton{
                        id: start
                        width: ui.fontWidth * 6
                        text: gcsCtrl.active ? qsTr("Stop") : qsTr("Start")
                        onClicked: {
                            gcsCtrl.active ? gcsCtrl.stop() : gcsCtrl.start()
                        }
                    }
                }
                Row{
                    spacing: ui.fontHeight
                    CCSwitchEditor{
                        id: autoSw
                        width: ui.fontWidth * 35
                        title: qsTr("Automatic Flight Mode Switching")
                        stateOn: false
                        onStateChanged: {
                            stateOn = !stateOn
                        }
                    }
                    CCText{
                        height: parent.height
                        text: qsTr("(Switches to 'Stabilized' when you click Start, Switches to '") +
                              vehicle.pauseFlightMode + qsTr("' when you click Stop.)")
                        font.pointSize: ui.sFontSize
                        visible: autoSw.stateOn
                    }
                    CCText{
                        height: parent.height
                        font.pointSize: ui.sFontSize
                        visible: autoSw.stateOn
                    }
                }
            }
        }
    }
    CCConfirmDialog{
        id: dlg
    }
}
