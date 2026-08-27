import QtQuick
import QtQuick.Controls

import QGroundControl

Rectangle {
    id: root

    border.color: clcfg.border
    color: clcfg.normalBg
    height: ui.fontHeight * 12
    width: linkTitle.width + (infoArea.visible ? infoArea.width : 0)

    property Ui ui: Ui
    property Vehicle vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property LinkManager linkManager: QGroundControl.linkManager
    property int fmIndex: vehicle ? vehicle.flightModes.indexOf(vehicle.flightMode) : 0

    FactPanelController {
        id: ctrl
    }

    CCText {
        id: linkTitle

        alignMid: true
        font.pointSize: ui.lFontSize
        height: contentHeight + ui.x2margin
        text: "All Links"
        width: ui.fontWidth * 24
    }

    Item {
        anchors.bottom: parent.bottom
        height: parent.height - linkTitle.height + ui.margin
        width: linkTitle.width

        CCFlickable {
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true

            CCMouseArea {
                height: children[0].height
                width: parent.width

                Column {
                    spacing: ui.margin
                    width: parent.width

                    Repeater {
                        model: root.linkManager.linkConfigurations

                        CCButton {
                            border.color: object.link ? clcfg.good : clcfg.enabled
                            text: object.name
                            width: parent.width

                            onClicked: {
                                if (object.link) {
                                    object.link.disconnect();
                                    object.linkChanged();
                                } else {
                                    linkManager.createConnectedLink(object);
                                }
                                statusPanel.close();
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: infoArea

        anchors.right: parent.right
        height: parent.height
        visible: vehicle && (vehicle.px4Firmware || vehicle.apmFirmware)
        width: ui.fontWidth * 42

        CCSeparator {
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - ui.x2margin
        }

        CCFlickable {
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true

            CCMouseArea {
                height: children[0].height
                width: parent.width

                Column {
                    width: parent.width

                    CCMultiSwitch {
                        id: armSwitch

                        model: ["Disarmed", "Armed"]
                        selectIndex: vehicle ? vehicle.armed : 0

                        onSwitchTo: index => {
                            if (vehicle) {
                                if (vehicle.flying) {
                                    vehicle.emergencyStop();
                                } else {
                                    vehicle.armed = index;
                                }
                            }
                        }
                    }

                    LabelComboBox {
                        id: flightMode

                        currentIndex: fmIndex
                        model: vehicle ? vehicle.flightModes : []
                        title: qsTr("Flight Mode")

                        onUpdateResult: index => {
                            if (vehicle)
                                vehicle.flightMode = vehicle.flightModes[index];
                        }
                    }

                    Loader {
                        id: loader

                        sourceComponent: vehicle ? (vehicle.px4Firmware ? px4 : vehicle.apmFirmware ? apm : null) : null
                        width: parent.width
                    }
                }
            }
        }
    }

    // Rectangle{
    //     anchors.fill: parent
    //     color: clcfg.none
    //     border.color: clcfg.border
    // }
    Component {
        id: px4

        Column {
            FactPanelController {
                id: ctrl
            }

            LabelComboBox {
                id: failsafe

                fact: ctrl.getParameterFact(-1, "NAV_DLL_ACT")
                title: qsTr("Failsafe Action")
            }

            LabelSlider {
                id: timeout

                fact: ctrl.getParameterFact(-1, "COM_DL_LOSS_T")
                realTime: false
                title: qsTr("Data Link Loss Timeout")
            }
        }
    }

    Component {
        id: apm

        Column {
            id: apmCol

            property Fact optFact: ctrl.getParameterFact(-1, "FS_OPTIONS")

            FactPanelController {
                id: ctrl
            }

            LabelTextField {
                id: rtlAlt

                fact: ctrl.getParameterFact(-1, "RTL_ALT")
                title: qsTr("RTL at altitude")
            }

            CCText {
                id: title1

                font.pointSize: ui.lFontSize
                height: contentHeight + ui.x2margin
                text: qsTr("GCS Failsafe")
            }

            LabelComboBox {
                id: apmAction

                fact: ctrl.getParameterFact(-1, "FS_GCS_ENABLE")
                title: qsTr("Action")
            }

            LabelSlider {
                id: apmTimeout

                fact: ctrl.getParameterFact(-1, "FS_GCS_TIMEOUT")
                title: qsTr("Timeout")
            }

            CCText {
                id: title2

                font.pointSize: ui.lFontSize
                height: contentHeight + ui.x2margin
                text: qsTr("Failsafe Options")
            }

            Repeater {
                id: repeater

                model: apmCol.optFact ? apmCol.optFact.bitmaskStrings : []

                LabelSwitchButton {
                    stateOn: apmCol.optFact.value & apmCol.optFact.bitmaskValues[index]
                    title: modelData

                    onStateChanged: {
                        if (stateOn) {
                            apmCol.optFact.value &= ~apmCol.optFact.bitmaskValues[index];
                        } else {
                            apmCol.optFact.value |= apmCol.optFact.bitmaskValues[index];
                        }
                    }
                }
            }
        }
    }
}
