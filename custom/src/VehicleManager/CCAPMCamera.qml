import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.Vehicle

import gises.base
import gises.widget

CCVehicleSetupContainer {
    id: root

    titleText: qsTr("Vehicle Camera")

    property Fact mountRetractX: ctrl.getParameterFact(-1, "MNT_RETRACT_X")
    property Fact mountRetractY: ctrl.getParameterFact(-1, "MNT_RETRACT_Y")
    property Fact mountRetractZ: ctrl.getParameterFact(-1, "MNT_RETRACT_Z")

    property Fact mountNeutralX: ctrl.getParameterFact(-1, "MNT_NEUTRAL_X")
    property Fact mountNeutralY: ctrl.getParameterFact(-1, "MNT_NEUTRAL_Y")
    property Fact mountNeutralZ: ctrl.getParameterFact(-1, "MNT_NEUTRAL_Z")

    property Fact mountRCInTilt: ctrl.getParameterFact(-1, "MNT_RC_IN_TILT")
    property Fact mountStabTilt: ctrl.getParameterFact(-1, "MNT_STAB_TILT")
    property Fact mountAngMinTilt: ctrl.getParameterFact(-1, "MNT_ANGMIN_TIL")
    property Fact mountAngMaxTilt: ctrl.getParameterFact(-1, "MNT_ANGMAX_TIL")

    property Fact mountRCInRoll: ctrl.getParameterFact(-1, "MNT_RC_IN_ROLL")
    property Fact mountStabRoll: ctrl.getParameterFact(-1, "MNT_STAB_ROLL")
    property Fact mountAngMinRoll: ctrl.getParameterFact(-1, "MNT_ANGMIN_ROL")
    property Fact mountAngMaxRoll: ctrl.getParameterFact(-1, "MNT_ANGMAX_ROL")

    property Fact mountRCInPan: ctrl.getParameterFact(-1, "MNT_RC_IN_PAN")
    property Fact mountStabPan: ctrl.getParameterFact(-1, "MNT_STAB_PAN")
    property Fact mountAngMinPan: ctrl.getParameterFact(-1, "MNT_ANGMIN_PAN")
    property Fact mountAngMaxPan: ctrl.getParameterFact(-1, "MNT_ANGMAX_PAN")

    property Fact rc5Function: ctrl.getParameterFact(-1, "SERVO5_FUNCTION")
    property Fact rc6Function: ctrl.getParameterFact(-1, "SERVO6_FUNCTION")
    property Fact rc7Function: ctrl.getParameterFact(-1, "SERVO7_FUNCTION")
    property Fact rc8Function: ctrl.getParameterFact(-1, "SERVO8_FUNCTION")
    property Fact rc9Function: ctrl.getParameterFact(-1, "SERVO9_FUNCTION")
    property Fact rc10Function: ctrl.getParameterFact(-1, "SERVO10_FUNCTION")
    property Fact rc11Function: ctrl.getParameterFact(-1, "SERVO11_FUNCTION")
    property Fact rc12Function: ctrl.getParameterFact(-1, "SERVO12_FUNCTION")
    property Fact rc13Function: ctrl.getParameterFact(-1, "SERVO13_FUNCTION")
    property Fact rc14Function: ctrl.getParameterFact(-1, "SERVO14_FUNCTION")

    property bool tiltEnabled: false
    property bool panEnabled: false
    property bool rollEnabled: false

    property bool servoReverseIsBool: ctrl.parameterExists(-1, "RC5_REVERSED")

    // Gimbal Settings not available on older firmware
    property bool showGimbaLSettings: ctrl.parameterExists(-1, "MNT_DEFLT_MODE")

    readonly property int rcFunctionDisabled: 0
    readonly property int rcFunctionMountPan: 6
    readonly property int rcFunctionMountTilt: 7
    readonly property int rcFunctionMountRoll: 8
    readonly property int firstGimbalOutChannel: 5
    readonly property int lastGimbalOutChannel: 14
    readonly property int mountDefaultModeRCTargetting: 3

    function calcGimbalOutValues() {
        gimbalTilt.gimbalOutIndex = 0
        gimbalRoll.gimbalOutIndex = 0
        gimbalPan.gimbalOutIndex = 0
        tiltEnabled = false
        panEnabled = false
        rollEnabled = false
        for (var channel = firstGimbalOutChannel; channel <= lastGimbalOutChannel; channel++) {
            var functionFact = controller.getParameterFact(
                        -1, "SERVO" + channel + "_FUNCTION")
            if (functionFact.value === rcFunctionMountTilt) {
                tiltEnabled = true
                setGimbalSettingsServoInfo(gimbalTilt, channel)
            } else if (functionFact.value === rcFunctionMountPan) {
                panEnabled = true
                setGimbalSettingsServoInfo(gimbalPan, channel)
            } else if (functionFact.value === rcFunctionMountRoll) {
                rollEnabled = true
                setGimbalSettingsServoInfo(gimbalRoll, channel)
            }
        }
    }
    function setGimbalSettingsServoInfo(loader, channel) {
        var rcPrefix = "SERVO" + channel + "_"

        loader.gimbalOutIndex = channel - 4
        loader.servoPWMMinFact = controller.getParameterFact(-1,
                                                             rcPrefix + "MIN")
        loader.servoPWMMaxFact = controller.getParameterFact(-1,
                                                             rcPrefix + "MAX")
        loader.servoReverseFact = controller.getParameterFact(
                    -1, rcPrefix + "REVERSED")
    }

    FactPanelController {
        id: ctrl
    }
    CCFlickable {
        id: flk
        anchors.fill: contentArea
        anchors.margins: ui.margin
        fixedWidth: true
        CCMouseArea {
            width: parent.width
            height: children[0].height
            Flow {
                width: parent.width
                spacing: ui.margin
                Loader {
                    id: gimbalTilt
                    sourceComponent: direction

                    property string directionTitle: qsTr("Tilt")
                    property bool directionEnabled: tiltEnabled
                    property int gimbalOutIndex: 0
                    property Fact mountRcInFact: mountRCInTilt
                    property Fact mountStabFact: mountStabTilt
                    property Fact mountAngMinFact: mountAngMinTilt
                    property Fact mountAngMaxFact: mountAngMaxTilt
                    property Fact servoPWMMinFact: Fact {}
                    property Fact servoPWMMaxFact: Fact {}
                    property Fact servoReverseFact: Fact {}
                    property bool servoReverseIsBool: servoReverseIsBool
                    property int rcFunction: rcFunctionMountTilt
                }
                Loader {
                    id: gimbalRoll
                    sourceComponent: direction

                    property string directionTitle: qsTr("Roll")
                    property bool directionEnabled: rollEnabled
                    property int gimbalOutIndex: 0
                    property Fact mountRcInFact: mountRCInRoll
                    property Fact mountStabFact: mountStabRoll
                    property Fact mountAngMinFact: mountAngMinRoll
                    property Fact mountAngMaxFact: mountAngMaxRoll
                    property Fact servoPWMMinFact: Fact {}
                    property Fact servoPWMMaxFact: Fact {}
                    property Fact servoReverseFact: Fact {}
                    property bool servoReverseIsBool: servoReverseIsBool
                    property int rcFunction: rcFunctionMountRoll
                }
                Loader {
                    id: gimbalPan
                    sourceComponent: direction

                    property string directionTitle: qsTr("Pan")
                    property bool directionEnabled: panEnabled
                    property int gimbalOutIndex: 0
                    property Fact mountRcInFact: mountRCInPan
                    property Fact mountStabFact: mountStabPan
                    property Fact mountAngMinFact: mountAngMinPan
                    property Fact mountAngMaxFact: mountAngMaxPan
                    property Fact servoPWMMinFact: Fact {}
                    property Fact servoPWMMaxFact: Fact {}
                    property Fact servoReverseFact: Fact {}
                    property bool servoReverseIsBool: servoReverseIsBool
                    property int rcFunction: rcFunctionMountPan
                }
                Loader {
                    id: gimbal
                    sourceComponent: showGimbaLSettings ? normal : undefined
                }
            }
        }
    }
    // Whenever any SERVO#_FUNCTION parameters changes we need to go looking for gimbal output channels again
    Connections {
        target: rc5Function
        onValueChanged: calcGimbalOutValues()
    }
    Connections {
        target: rc6Function
        onValueChanged: calcGimbalOutValues()
    }
    Connections {
        target: rc7Function
        onValueChanged: calcGimbalOutValues()
    }
    Connections {
        target: rc8Function
        onValueChanged: calcGimbalOutValues()
    }
    Connections {
        target: rc9Function
        onValueChanged: calcGimbalOutValues()
    }
    Connections {
        target: rc10Function
        onValueChanged: calcGimbalOutValues()
    }
    Connections {
        target: rc11Function
        onValueChanged: calcGimbalOutValues()
    }
    Connections {
        target: rc12Function
        onValueChanged: calcGimbalOutValues()
    }
    Connections {
        target: rc13Function
        onValueChanged: calcGimbalOutValues()
    }
    Connections {
        target: rc14Function
        onValueChanged: calcGimbalOutValues()
    }

    // Whenever an MNT_RC_IN_* setting is changed make sure to turn on RC targeting
    Connections {
        target: mountRCInPan
        onValueChanged: mountDefaultMode.value = mountDefaultModeRCTargetting
    }

    Connections {
        target: mountRCInRoll
        onValueChanged: mountDefaultMode.value = mountDefaultModeRCTargetting
    }

    Connections {
        target: mountRCInTilt
        onValueChanged: mountDefaultMode.value = mountDefaultModeRCTargetting
    }
    Component {
        id: normal
        Rectangle {
            id: nor
            width: ui.fontWidth * 25
            height: norcol.height
            color: cc.none
            border.color: cc.border
            property Fact mountDefaultMode: ctrl.getParameterFact(
                                                -1, "MNT_DEFLT_MODE")
            property Fact mountType: ctrl.getParameterFact(-1, "MNT_TYPE")
            Column {
                id: norcol
                width: parent.width - ui.x2margin
                anchors.horizontalCenter: parent.horizontalCenter
                CCText {
                    width: parent.width
                    text: qsTr("Gimbal Settings")
                    alignMid: true
                    font.pointSize: ui.llFontSize
                }
                CCComboBoxEditor {
                    title: qsTr("Type")
                    fact: nor.mountType
                }
                CCText {
                    width: parent.width
                    text: qsTr("Gimbal Type changes takes affect next reboot of autopilot")
                    wrapMode: Text.WordWrap
                }
                CCComboBoxEditor {
                    title: qsTr("Default Mode")
                    fact: nor.mountDefaultMode
                }
            }
        }
    }
    Component {
        id: direction
        Rectangle {
            id: dire
            width: ui.fontWidth * 48
            height: direcol.height + ui.margin
            color: cc.none
            border.color: cc.border
            property var gimbalOutModel: ["Disabled"]
            function update(number) {
                // Not enough channels
                if (number < 6) {
                    return
                }
                for (var i = 5; i <= number; i++) {
                    gimbalOutModel.push((qsTr("Channel ") + i))
                }
            }
            function setRCFunction(channel, rcfunction) {
                // First clear any previous settings for this function
                var functionFact = null
                for (var index = firstGimbalOutChannel; index <= lastGimbalOutChannel; index++) {
                    functionFact = ctrl.getParameterFact(
                                -1, "SERVO" + index + "_FUNCTION")
                    if (functionFact.value !== rcFunctionDisabled
                            && functionFact.value === rcFunction) {
                        functionFact.value = rcFunctionDisabled
                    }
                }

                // Now set the function into the new channel
                if (channel !== 0) {
                    functionFact = ctrl.getParameterFact(
                                -1, "SERVO" + channel + "_FUNCTION")
                    functionFact.value = rcFunction
                }
            }

            Column {
                id: direcol
                width: parent.width - ui.x2margin
                anchors.horizontalCenter: parent.horizontalCenter
                CCText {
                    width: parent.width
                    text: qsTr("Gimbal ") + directionTitle
                    alignMid: true
                    font.pointSize: ui.llFontSize
                }
                Item {
                    width: parent.width
                    height: output.height
                    CCComboBoxEditor {
                        id: output
                        width: ui.fontWidth * 30
                        title: qsTr("Output channel")
                        model: gimbalOutModel
                        currentIndex: gimbalOutIndex
                        Component.onCompleted: {
                            // Number of main outputs
                            var baseValue = 8
                            // Extra outputs
                            // http://ardupilot.org/copter/docs/parameters.html#brd-pwm-count-auxiliary-pin-config
                            var fct = ctrl.getParameterFact(-1, "BRD_PWM_COUNT")
                            if(fct){
                                var brd_pwm_count_value = fct.value
                                //var brd_pwm_count_value = ctrl.getParameterFact(-1, "BRD_PWM_COUNT").value
                                update(8 + (brd_pwm_count_value === 7 ? 3 : brd_pwm_count_value))
                                console.log("suc");
                            }
                        }
                        onUpdateResult:
                            (index) => {
                                var channel = (index === 0 ? 0 : index - 4)
                                dire.setRCFunction(channel, rcFunction)
                            }
                    }
                    CCSwitchEditor {
                        width: ui.fontWidth * 15
                        title: qsTr("Stabilize")
                        stateOn: mountStabFact ? mountStabFact.value === 1 : false
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: directionEnabled
                        onStateChanged: {
                            if (mountStabFact)
                                mountStabFact.value = !mountStabFact.value
                        }
                    }
                }
                Item {
                    width: parent.width
                    height: input.height
                    enabled: directionEnabled
                    CCComboBoxEditor {
                        id: input
                        width: ui.fontWidth * 30
                        title: qsTr("Input channel")
                        fact: mountRcInFact
                        //enabled: parent.enabled
                    }
                    CCSwitchEditor {
                        width: ui.fontWidth * 15
                        title: qsTr("Servo reverse")
                        stateOn: servoReverseIsBool ? servoReverseFact.value
                                                      === 1 : servoReverseFact.value === -1
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        onStateChanged: {
                            if (servoReverseIsBool) {
                                servoReverseFact.value = !servoReverseFact.value
                            } else {
                                if (servoReverseFact.value === -1) {
                                    servoReverseFact.value === 1
                                } else {
                                    servoReverseFact.value === -1
                                }
                            }
                        }
                    }
                }
                Item {
                    width: parent.width
                    height: angleMax.height
                    enabled: directionEnabled
                    CCText {
                        width: ui.fontWidth * 21
                        height: parent.height
                        text: qsTr("Gimbal angle limits:")
                    }
                    CCTextEditor {
                        width: ui.fontWidth * 12
                        title: qsTr("min")
                        fact: mountAngMinFact
                        near: true
                        anchors.right: angleMax.left
                        anchors.rightMargin: ui.margin
                    }
                    CCTextEditor {
                        id: angleMax
                        width: ui.fontWidth * 12
                        title: qsTr("max")
                        fact: mountAngMaxFact
                        near: true
                        anchors.right: parent.right
                    }
                }
                Item {
                    width: parent.width
                    height: pwmMax.height
                    enabled: directionEnabled
                    CCText {
                        width: ui.fontWidth * 21
                        height: parent.height
                        text: qsTr("Servo PWM limits:")
                    }
                    CCTextEditor {
                        width: ui.fontWidth * 12
                        title: qsTr("min")
                        fact: servoPWMMinFact
                        near: true
                        anchors.right: pwmMax.left
                        anchors.rightMargin: ui.margin
                    }
                    CCTextEditor {
                        id: pwmMax
                        width: ui.fontWidth * 12
                        title: qsTr("max")
                        fact: servoPWMMaxFact
                        near: true
                        anchors.right: parent.right
                    }
                }
            }
        }
    }
}
