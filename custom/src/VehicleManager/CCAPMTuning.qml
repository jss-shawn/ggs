
import QtCharts
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl.Controls
import QGroundControl.FactSystem

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Turning")

    property bool atcInputTCAvailable: ctrl.parameterExists(-1, "ATC_INPUT_TC")
    property Fact atcInputTC: ctrl.getParameterFact(-1, "ATC_INPUT_TC", false)
    property Fact rateRollP: ctrl.getParameterFact(-1, "ATC_RAT_RLL_P")
    property Fact rateRollI: ctrl.getParameterFact(-1, "ATC_RAT_RLL_I")
    property Fact ratePitchP: ctrl.getParameterFact(-1, "ATC_RAT_PIT_P")
    property Fact ratePitchI: ctrl.getParameterFact(-1, "ATC_RAT_PIT_I")
    property Fact rateClimbP: ctrl.getParameterFact(-1, "PSC_ACCZ_P")
    property Fact rateClimbI: ctrl.getParameterFact(-1, "PSC_ACCZ_I")
    property Fact motSpinArm: ctrl.getParameterFact(-1, "MOT_SPIN_ARM")
    property Fact motSpinMin: ctrl.getParameterFact(-1, "MOT_SPIN_MIN")

    property Fact ch7Opt: ctrl.getParameterFact(-1, "r.RC7_OPTION")
    property Fact ch8Opt: ctrl.getParameterFact(-1, "r.RC8_OPTION")
    property Fact ch9Opt: ctrl.getParameterFact(-1, "r.RC9_OPTION")
    property Fact ch10Opt: ctrl.getParameterFact(-1, "r.RC10_OPTION")
    property Fact ch11Opt: ctrl.getParameterFact(-1, "r.RC11_OPTION")
    property Fact ch12Opt: ctrl.getParameterFact(-1, "r.RC12_OPTION")

    readonly property int firstOptionChannel: 7
    readonly property int lastOptionChannel: 12

    property Fact autoTuneAxes: ctrl.getParameterFact(-1, "AUTOTUNE_AXES")
    property int autoTuneSwitchChannelIndex: 0
    readonly property int autoTuneOption: 17

    FactPanelController { id: ctrl; }

    CCSwitchEditor{
        id: swAdvance
        x: ui.margin
        width: ui.fontWidth * 20
        title: qsTr("Advanced")
        stateOn: false
        anchors.top: contentArea.top
        onStateChanged: {
            stateOn = !stateOn
        }
    }
    Item{
        id: area
        width: parent.width
        anchors.top: swAdvance.bottom
        anchors.bottom: contentArea.bottom
    }
    CCFlickable{
        anchors.fill: area
        anchors.margins: ui.margin
        fixedWidth: true
        CCMouseArea{
            width: parent.width
            height: children[0].height
            Loader{
                width: parent.width
                sourceComponent: swAdvance.stateOn ? advance : normal
            }
        }
    }
    Component{
        id: normal
        Flow{
            id: flow
            spacing: ui.margin
            Rectangle{
                width: parent.width
                height: basiccol.height
                color: cc.none
                border.color: cc.border
                Column{
                    id: basiccol
                    width: parent.width - ui.x2margin
                    anchors.horizontalCenter: parent.horizontalCenter
                    CCText{
                        text: qsTr("Basic Tuning")
                        font.pointSize: ui.llFontSize
                    }
                    CCText{
                        text: qsTr("Roll/Pitch Sensitivity")
                        font.bold: true
                    }
                    CCText{
                        width: parent.width
                        text: qsTr("Slide to the right if the copter is sluggish or slide to the left if the copter is twitchy")
                        wrapMode: Text.WordWrap
                    }
                    CCSlider{
                        width: parent.width
                        from: 0.08
                        to: 0.4
                        stepSize: 0.01
                        value: rateRollP.value
                        live: false
                        onValueChanged: {
                            rateRollP.value = value
                            rateRollI.value = value
                            ratePitchP.value = value
                            ratePitchI.value = value
                        }
                    }
                    CCText{
                        text: qsTr("Climb Sensitivity")
                        font.bold: true
                    }
                    CCText{
                        width: parent.width
                        text: qsTr("Slide to the right to climb more aggressively or slide to the left to climb more gently")
                        wrapMode: Text.WordWrap
                    }
                    CCSlider{
                        width: parent.width
                        from: 0.3
                        to: 1.4
                        stepSize: 0.02
                        value: rateClimbP.value
                        live: false
                        onValueChanged: {
                            rateClimbP.value = value
                            rateClimbI.value = value * 2
                        }
                    }
                    CCText{
                        text: qsTr("RC Roll/Pitch Feel")
                        font.bold: true
                    }
                    CCText{
                        width: parent.width
                        text: qsTr("Slide to the left for soft control, slide to the right for crisp control")
                        wrapMode: Text.WordWrap
                    }
                    CCSlider{
                        width: parent.width
                        from: atcInputTC.min
                        to: atcInputTC.max
                        stepSize: atcInputTC.increment
                        value: atcInputTC.value
                        live: false
                        onValueChanged: {
                            atcInputTC.value = value
                        }
                    }
                    CCText{
                        text:       qsTr("Spin While Armed")
                        font.bold: true
                    }
                    CCText{
                        width: parent.width
                        text: qsTr("Adjust the amount the motors spin to indicate armed")
                        wrapMode: Text.WordWrap
                    }
                    CCSlider{
                        width: parent.width
                        from: 0
                        to: Math.max(0.3, motSpinArm.rawValue)
                        stepSize: 0.01
                        value: motSpinArm.rawValue
                        live: false
                        onValueChanged: {
                            motSpinArm.rawValue = value
                        }
                    }
                    CCText{
                        text: qsTr("Minimum Thrust")
                        font.bold: true
                    }
                    CCText{
                        width: parent.width
                        text: qsTr("Adjust the minimum amount of thrust require for the vehicle to move")
                        wrapMode: Text.WordWrap
                    }
                    CCText{
                        width: parent.width
                        text: qsTr("Warning: This setting should be higher than 'Spin While Armed'")
                        color: cc.error
                        wrapMode: Text.WordWrap
                        visible: motSpinMin.rawValue < motSpinArm.rawValue
                    }
                    CCSlider{
                        width: parent.width
                        from: 0
                        to: Math.max(0.3, motSpinMin.rawValue)
                        stepSize: 0.01
                        value: motSpinMin.rawValue
                        live: false
                        onValueChanged: {
                            motSpinMin.rawValue = value
                        }
                    }
                }
            }
            Rectangle{
                id: autoTune
                width: ui.fontWidth * 30
                height: autocol.height
                color: cc.none
                border.color: cc.border
                Column{
                    id: autocol
                    width: parent.width - ui.x2margin
                    anchors.horizontalCenter: parent.horizontalCenter
                    CCText{
                        text: qsTr("AutoTune")
                        font.pointSize: ui.llFontSize
                    }
                    CCText{
                        text: qsTr("Axes to AutoTune")
                    }
                    Repeater{
                        model: autoTuneAxes.bitmaskStrings
                        CCSwitchEditor{
                            title: modelData
                            stateOn: autoTuneAxes.value & autoTuneAxes.bitmaskValues[index]
                            onStateChanged: {
                                if(stateOn){
                                    autoTuneAxes.value &= ~autoTuneAxes.bitmaskValues[index]
                                }else{
                                    autoTuneAxes.value |= autoTuneAxes.bitmaskValues[index]
                                }
                            }
                        }
                    }
                    CCComboBoxEditor{
                        title: qsTr("Channel for AutoTune switch")
                        model: [qsTr("None"), qsTr("Channel 7"), qsTr("Channel 8"), qsTr("Channel 9"), qsTr("Channel 10"), qsTr("Channel 11"), qsTr("Channel 12") ]
                        currentIndex: lastIndex
                        singleLine: false
                        property var allFact: [null]
                        property int lastIndex: 0
                        Component.onCompleted: {
                            for (var optionChannel=firstOptionChannel; optionChannel<=lastOptionChannel; optionChannel++) {
                                var optionFact = ctrl.getParameterFact(-1, "r.RC" + optionChannel + "_OPTION")
                                allFact.push(optionFact)
                                if (optionFact.value === autoTuneOption) {
                                    lastIndex = optionChannel - firstOptionChannel + 1
                                }
                            }
                        }
                        onUpdateResult:
                            (index)=>{
                                if(index === lastIndex){
                                    if(allFact[index]){
                                        if(allFact[index].value === autoTuneOption){
                                            allFact[index].value = 0
                                        }else{
                                            allFact[index].value = autoTuneOption
                                        }
                                    }
                                }else{
                                    if(allFact[lastIndex]){
                                        allFact.value = 0
                                    }
                                    lastIndex = index
                                    if(allFact[index]){
                                        allFact[index].value = autoTuneOption
                                    }
                                }
                            }
                    }
                }
            }
            Rectangle{
                id: infly
                width: ui.fontWidth * 30
                height: inflycol.height
                color: cc.none
                border.color: cc.border
                Column{
                    id: inflycol
                    width: parent.width - ui.x2margin
                    anchors.horizontalCenter: parent.horizontalCenter
                    CCText{
                        text: qsTr("In Flight Tuning")
                        font.pointSize: ui.llFontSize
                    }
                    CCComboBoxEditor{
                        title: qsTr("RC Channel 6 Option (Tuning)")
                        fact: ctrl.getParameterFact(-1, "TUNE")
                        singleLine: false
                    }
                    CCTextEditor{
                        width: (parent.width - ui.margin) / 2
                        title: qsTr("Min")
                        fact: ctrl.getParameterFact(-1, "r.TUNE_MIN")
                        CCTextEditor{
                            width: parent.width
                            title: qsTr("Max")
                            fact: ctrl.getParameterFact(-1, "r.TUNE_MAX")
                            anchors.left: parent.right
                            anchors.leftMargin: ui.margin
                        }
                    }
                }
            }
        }
    }
    Component{
        id: advance
        Flow{
            id: adv
            spacing: ui.margin
            property real msec: 0
            property int maxcount: 1000
            property var allpam: [roll, pitch, yaw]
            property var target: roll
            QtObject{
                id: roll
                property string name: qsTr("Roll")
                property var datas: [
                    {name: qsTr("Response"), value: vehicle.rollRate.value},
                    {name: qsTr("SetPoint"), value: vehicle.setpoint.rollRate.value}]
                property var params: [
                    {title: qsTr("Roll axis angle controller P gain"), param: "ATC_ANG_RLL_P",
                        description: "", min: 3, max: 12, step: 1, dec: 0},
                    {title: qsTr("Roll axis rate controller P gain"), param: "ATC_RAT_RLL_P",
                        description: "", min: 0.001, max: 0.5, step: 0.025, dec: 3},
                    {title: qsTr("Roll axis rate controller I gain"), param: "ATC_RAT_RLL_I",
                        description: "", min: 0.01, max: 2, step: 0.05, dec: 2},
                    {title: qsTr("Roll axis rate controller D gain"), param: "ATC_RAT_RLL_D",
                        description: "", min: 0.0, max: 0.05, step: 0.001, dec: 1}]
            }
            QtObject{
                id: pitch
                property string name: qsTr("Pitch")
                property var datas: [
                    {name: qsTr("Response"), value: vehicle.pitchRate.value},
                    {name: qsTr("SetPoint"), value: vehicle.setpoint.pitchRate.value}]
                property var params: [
                    {title: qsTr("Pitch axis angle controller P gain"), param: "ATC_ANG_PIT_P",
                        description: "", min: 3, max: 12, step: 1, dec: 0},
                    {title: qsTr("Pitch axis rate controller P gain"), param: "ATC_RAT_PIT_P",
                        description: "", min: 0.001, max: 0.5, step: 0.025, dec: 3},
                    {title: qsTr("Pitch axis rate controller I gain"), param: "ATC_RAT_PIT_I",
                        description: "", min: 0.01, max: 2, step: 0.05, dec: 2},
                    {title: qsTr("Pitch axis rate controller D gain"), param: "ATC_RAT_PIT_D",
                        description: "", min: 0.0, max: 0.05, step: 0.001, dec: 1}]
            }
            QtObject{
                id: yaw
                property string name: qsTr("Yaw")
                property var datas: [
                    {name: qsTr("Response"), value: vehicle.yawRate.value},
                    {name: qsTr("SetPoint"), value: vehicle.setpoint.yawRate.value}]
                property var params: [
                    {title: qsTr("Yaw axis angle controller P gain"), param: "ATC_ANG_RLL_P",
                        description: "", min: 3, max: 12, step: 1, dec: 0},
                    {title: qsTr("Yaw axis rate controller P gain"), param: "ATC_RAT_RLL_P",
                        description: "", min: 0.1, max: 2.5, step: 0.05, dec: 1},
                    {title: qsTr("Yaw axis rate controller I gain"), param: "ATC_RAT_RLL_I",
                        description: "", min: 0.01, max: 1, step: 0.05, dec: 2}]
            }

            onTargetChanged: {
                chart.clean()
            }

            Rectangle{
                width: Math.max(ui.fontWidth * 50, parent.width / 2)
                height: width * 0.6
                color: cc.none
                border.color: cc.border
                Timer{
                    id: timer
                    interval: 10
                    running: true
                    repeat: true
                    onTriggered: {
                        if(chart.redLine.name.length){
                            while(chart.redLine.count >= adv.maxcount){
                                chart.redLine.remove(0)
                            }
                            if(!isNaN(adv.target.datas[0].value)){
                                chart.redLine.append( adv.msec/1000.0, adv.target.datas[0].value)
                            }
                        }
                        if(chart.greenLine.name.length){
                            while(chart.greenLine.count >= adv.maxcount){
                                chart.greenLine.remove(0)
                            }
                            if(!isNaN(adv.target.datas[1].value)){
                                chart.greenLine.append(adv.msec/1000, adv.target.datas[1].value)
                            }
                        }
                        if(chart.blueLine.name.length){
                            while(chart.blueLine.count >= adv.maxcount){
                                chart.blueLine.remove(0)
                            }
                            //chart.blueLine.append(x, y)
                        }
                        adv.msec += interval
                        var last = chart.redLine.at(chart.redLine.count-1).x
                        chart.xAxis.max = last > 3.0 ? last : 3.0
                        chart.xAxis.min = last > 3.0 ? last - 3 : 0
                    }
                }
                CCChart{
                    id: chart
                    anchors.left: parent.left
                    anchors.right: btn.horizontalCenter
                    title: adv.target.name + qsTr(" Rate")
                    yUnit: qsTr("deg/s")
                    xUnit: qsTr("sec")
                    redLine.name: adv.target.datas[0].name
                    greenLine.name: adv.target.datas[1].name
                    function update(){

                    }
                    function clean(){
                        redLine.clear()
                        greenLine.clear()
                        blueLine.clear()
                        xAxis.min = 0
                        xAxis.max = 0
                        yAxis.min = 0
                        yAxis.max = 1
                        adv.msec = 0
                    }
                }
                Column{
                    id: btn
                    width: ui.fontWidth * 8
                    spacing: ui.fontHeight
                    anchors.right: parent.right
                    anchors.rightMargin: ui.margin
                    anchors.verticalCenter: parent.verticalCenter
                    CCButton{
                        id: clear
                        width: parent.width
                        height: ui.fontHeight * 2
                        text: qsTr("Clear")
                        onClicked: {
                            chart.clean()
                        }
                    }
                    CCButton{
                        id: ss
                        width: parent.width
                        height: ui.fontHeight * 2
                        text: timer.running ? qsTr("Stop") : qsTr("Start")
                        onClicked: {
                            if(timer.running){
                                timer.stop()
                            }else{
                                chart.clean()
                                timer.start()
                            }
                        }
                    }
                }
            }
            Column{
                id: pam
                width: ui.fontWidth * 30
                spacing: ui.margin
                Row{
                    height: ui.fontHeight + ui.x2margin
                    spacing: ui.margin
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater{
                        model: adv.allpam
                        CCOptionButton{
                            id: rollbtn
                            icon: ""
                            text: modelData.name
                            selected: adv.target === modelData
                            onClicked: {
                                if(adv.target !== modelData)
                                    adv.target = modelData
                            }
                        }
                    }
                }
                Repeater{
                    model: adv.target.params
                    Rectangle{
                        id: pm
                        width: sld.width + ui.x2margin
                        height: sld.height
                        color: cc.none
                        border.color: cc.border
                        CCSliderEditor{
                            id: sld
                            width: ui.fontWidth * 36
                            title: modelData.title
                            from: modelData.min
                            to: modelData.max
                            stepSize: modelData.step
                            decim: modelData.dec
                            value: fc.value
                            anchors.centerIn: parent
                            onUpdateValue:
                                (val)=>{
                                    fc.value = val
                                }
                            property Fact fc: ctrl.getParameterFact(-1, modelData.param)
                        }
                    }
                }
            }
        }
    }
}
