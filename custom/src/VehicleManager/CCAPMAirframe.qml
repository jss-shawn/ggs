
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.Controllers
import QGroundControl.Vehicle

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Frame")

    property Fact frameClass: ctrl.getParameterFact(-1, "FRAME_CLASS")
    property Fact frameType: ctrl.getParameterFact(-1, "FRAME_TYPE", false)    // FRAME_TYPE is not available on all Rover versions
    property bool frameTypeAvailable: ctrl.vehicle.multiRotor

    APMAirframeComponentController { id: ctrl; }

    CCFlickable{
        id: flk
        anchors.fill: contentArea
        anchors.margins: ui.margin
        fixedWidth: true
        CCMouseArea{
            width: parent.width
            height: children[0].height
            Column{
                width: parent.width
                spacing: ui.margin
                Repeater{
                    model: ctrl.frameClassModel
                    Item{
                        id: frame
                        width: parent.width
                        height: name.height + flow.height
                        visible: object.frameTypeEnumStrings.length
                        property var obj: object
                        property bool isthis: object.frameClass === frameClass.rawValue
                        CCText{
                            id: name
                            text: parent.obj.name
                        }
                        Flow{
                            id: flow
                            width: parent.width
                            spacing: ui.margin
                            anchors.top: name.bottom
                            Repeater{
                                model: frame.obj.frameTypeEnumStrings
                                CCMouseArea{
                                    width: ui.fontWidth * 8
                                    height: ui.fontHeight * 6
                                    property string typeName: modelData
                                    CCImage{
                                        width:parent.width
                                        source: object.sourceList[index]
                                        fillMode: Image.PreserveAspectFit
                                        //smooth: true
                                        //cache: false
                                        anchors.bottom: type.top
                                    }
                                    CCText{
                                        id: type
                                        width: parent.width
                                        text: parent.typeName
                                        alignMid: true
                                        anchors.bottom: parent.bottom
                                    }
                                    Rectangle{
                                        anchors.fill: parent
                                        color: cc.none
                                        border.color: cc.selected
                                        visible: frame.isthis && object.frameTypeEnumValues[index] === frameType.rawValue
                                    }
                                    onClicked: {
                                        frameClass.rawValue = frame.obj.frameClass
                                        frameType.rawValue = object.frameTypeEnumValues[index]
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
