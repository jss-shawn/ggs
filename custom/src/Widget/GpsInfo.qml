
import QtQuick
import QtQuick.Controls

import QGroundControl

Rectangle{
    width: leftArea.width + rightArea.width
    height: leftArea.height
    color: clcfg.normalBg
    border.color: clcfg.border

    property Vehicle vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var rtkConnected: QGroundControl.gpsRtk.connected.value
    property var gps: vehicle ? vehicle.gps : undefined
    property var rtkSettings: QGroundControl.settingsManager.rtkSettings
    property bool useFixedPosition: rtkSettings.useFixedBasePosition.rawValue
    property string na: qsTr("N/A")
    property string valueNA: qsTr("--.--")

    Item{
        id: leftArea
        width: ui.fontWidth * 30 + ui.x2margin
        height: ui.fontHeight * 20 + ui.x2margin
        CCFlickable{
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true
            CCMouseArea{
                width: parent.width
                height: children[0].height
                Column{
                    width: parent.width
                    spacing: ui.margin
                    Rectangle{
                        width: parent.width
                        height: title1.height + grid1.height
                        radius: ui.radius
                        color: clcfg.none
                        border.color: clcfg.border
                        CCText{
                            id: title1
                            height: contentHeight + ui.x2margin
                            text: qsTr("Vehicle GPS Status")
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Grid{
                            id: grid1
                            width: parent.width - ui.x2margin
                            columns: 2
                            anchors.top: title1.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            CCText{
                                width: parent.width/2
                                text: qsTr("Satellites")
                            }
                            CCText{
                                width: parent.width/2
                                text: vehicle ? vehicle.gps.count.valueString : na
                                alignRight: true
                            }
                            CCText {
                                width: parent.width/2
                                text: qsTr("GPS Lock")
                            }
                            CCText {
                                width: parent.width/2
                                text:  vehicle ? vehicle.gps.lock.enumStringValue : na
                                alignRight: true
                            }
                            CCText {
                                width: parent.width/2
                                text: qsTr("HDOP")
                            }
                            CCText {
                                width: parent.width/2
                                text: vehicle ? vehicle.gps.hdop.valueString : valueNA
                                alignRight: true
                            }
                            CCText {
                                width: parent.width/2
                                text: qsTr("VDOP")
                            }
                            CCText {
                                width: parent.width/2
                                text: vehicle ? vehicle.gps.vdop.valueString : valueNA
                                alignRight: true
                            }
                            CCText {
                                width: parent.width/2
                                text: qsTr("Course Over Ground")
                            }
                            CCText {
                                width: parent.width/2
                                text: vehicle ? vehicle.gps.courseOverGround.valueString : valueNA
                                alignRight: true
                            }
                        }
                    }
                    Rectangle{
                        width: parent.width
                        height: title2.height + grid2.height
                        radius: ui.radius
                        color: clcfg.none
                        border.color: clcfg.border
                        visible: QGroundControl.gpsRtk.connected.value
                        Rectangle{
                            width: parent.width
                            height: title2.height + grid2.height
                            radius: ui.radius
                            color: clcfg.none
                            border.color: clcfg.border
                            CCText{
                                id: title2
                                height: contentHeight + ui.x2margin
                                text: qsTr("RTK GPS Status")
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            CCText{
                                id: active
                                height: contentHeight + ui.x2margin
                                text: (QGroundControl.gpsRtk.active.value) ? qsTr("Survey-in Active") : qsTr("RTK Streaming")
                                anchors.top: title2.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Grid{
                                id: grid2
                                width: parent.width - ui.x2margin
                                height: (children.length / 2 - (rtkAccuracy ? 0 : 1)) * ui.fontHeight
                                columns: 2
                                anchors.top: active.bottom
                                anchors.horizontalCenter: parent.horizontalCenter

                                property bool rtkAccuracy: QGroundControl.gpsRtk.currentAccuracy.value > 0

                                CCText {
                                    width: parent.width/2
                                    text: qsTr("Satellites")
                                }
                                CCText {
                                    width: parent.width/2
                                    text: QGroundControl.gpsRtk.numSatellites.value
                                    alignRight: true
                                }
                                CCText {
                                    width: parent.width/2
                                    text: qsTr("Duration")
                                }
                                CCText {
                                    width: parent.width/2
                                    text: QGroundControl.gpsRtk.currentDuration.value + ' s'
                                    alignRight: true
                                }
                                CCText {
                                    width: parent.width/2
                                    text: QGroundControl.gpsRtk.valid.value ? qsTr("Accuracy") : qsTr("Current Accuracy")
                                    visible: parent.rtkAccuracy
                                }
                                CCText {
                                    width: parent.width/2
                                    text: QGroundControl.gpsRtk.currentAccuracy.valueString + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
                                    alignRight: true
                                    visible: parent.rtkAccuracy
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Item{
        id: rightArea
        width: ui.fontWidth * 40 + ui.x2margin
        height: ui.fontHeight * 20 + ui.x2margin
        anchors.right: parent.right
        CCSeparator{
            height: parent.height - ui.x2margin
            anchors.verticalCenter: parent.verticalCenter
        }
        CCFlickable{
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true
            CCMouseArea{
                width: parent.width
                height: children[0].height
                Column{
                    width: parent.width
                    CCText{
                        height: contentHeight + ui.x2margin
                        text: qsTr("RTK GPS Settings")
                    }
                    LabelSwitchButton{
                        title: qsTr("AutoConnect")
                        fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectRTKGPS
                        visible: fact.userVisible
                    }
                    LabelMultiSwitch{
                        id: sw
                        model: ["Survey-In", "Specified Position"]
                        selectIndex: rtkSettings.useFixedBasePosition.rawValue
                        onSwitchTo:
                            (index)=>{
                                rtkSettings.useFixedBasePosition.rawValue = index
                            }
                    }
                    LabelSlider{
                        title: rtkSettings.surveyInAccuracyLimit.shortDescription
                        fact: QGroundControl.settingsManager.rtkSettings.surveyInAccuracyLimit
                        visible: rtkSettings.surveyInAccuracyLimit.userVisible &&
                                 !rtkSettings.useFixedBasePosition.rawValue
                    }
                    LabelSlider{
                        title: rtkSettings.surveyInMinObservationDuration.shortDescription
                        fact: rtkSettings.surveyInMinObservationDuration
                        visible: rtkSettings.surveyInMinObservationDuration.userVisible &&
                                 !rtkSettings.useFixedBasePosition.rawValue
                    }
                    LabelTextField{
                        title: rtkSettings.fixedBasePositionLatitude.shortDescription
                        fact: rtkSettings.fixedBasePositionLatitude
                        visible: rtkSettings.fixedBasePositionLatitude.userVisible &&
                                 rtkSettings.useFixedBasePosition.rawValue
                    }
                    LabelTextField {
                        title: rtkSettings.fixedBasePositionLongitude.shortDescription
                        fact: rtkSettings.fixedBasePositionLongitude
                        visible: rtkSettings.fixedBasePositionLongitude.userVisible &&
                                 rtkSettings.useFixedBasePosition.rawValue
                    }
                    LabelTextField {
                        id: fixedBasePositionAltitude
                        title: rtkSettings.fixedBasePositionAltitude.shortDescription
                        fact: rtkSettings.fixedBasePositionAltitude
                        visible: rtkSettings.fixedBasePositionAltitude.userVisible &&
                                 rtkSettings.useFixedBasePosition.rawValue
                    }
                    LabelTextField {
                        title: rtkSettings.fixedBasePositionAccuracy.shortDescription
                        fact: rtkSettings.fixedBasePositionAccuracy
                        visible: rtkSettings.fixedBasePositionAccuracy.userVisible &&
                                 rtkSettings.useFixedBasePosition.rawValue
                    }
                    CCText{
                        width: parent.width
                        height: ui.fontHeight * 2
                        text: qsTr("Current Base Position")
                        enabled: saveBasePositionButton.enabled
                        visible: rtkSettings.useFixedBasePosition.rawValue
                        CCButton{
                            id: saveBasePositionButton
                            width: ui.fontWidth * 15
                            height: parent.height
                            text: enabled ? qsTr("Save") : qsTr("Not Yet Valid")
                            enabled: QGroundControl.gpsRtk.valid.value
                            anchors.right: parent.right
                            onClicked: {
                                rtkSettings.fixedBasePositionLatitude.rawValue  = QGroundControl.gpsRtk.currentLatitude.rawValue
                                rtkSettings.fixedBasePositionLongitude.rawValue = QGroundControl.gpsRtk.currentLongitude.rawValue
                                rtkSettings.fixedBasePositionAltitude.rawValue  = QGroundControl.gpsRtk.currentAltitude.rawValue
                                rtkSettings.fixedBasePositionAccuracy.rawValue  = QGroundControl.gpsRtk.currentAccuracy.rawValue
                            }
                        }
                    }
                }
            }
        }
    }
}

