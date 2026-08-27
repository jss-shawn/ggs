
import QtQuick
import QtQuick.Controls

import QGroundControl

import Gises.Widget

CCMouseArea{
    id:    root
    height: col.height

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property AppSettings appsettings: QGroundControl.settingsManager.appSettings
    property Vehicle vehicle: gises.vehicle
    property GisesPlan plan: gises.planManager
    property string info: "Vehicle Info"
    property bool vehicleFirmware: !QGroundControl.singleFirmwareSupport
    property bool vehicleTypes: !QGroundControl.singleVehicleSupport
    property bool alterable: !plan.valid && activeVehicle === null
    property bool showImage: true

    Column{
        id: col
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        LabelComboBox {
            id: firmware
            title: qsTr("Firmware")
            fact: QGroundControl.settingsManager.appSettings.offlineEditingFirmwareClass
            visible: vehicleFirmware && alterable
        }
        LabelComboBox {
            id: type
            title: qsTr("Vehicle Type")
            fact: QGroundControl.settingsManager.appSettings.offlineEditingVehicleClass
            visible: vehicleTypes && alterable
        }
        CCText{
            width: parent.width
            height: contentHeight + ui.x2margin
            text: qsTr("Firmware")
            visible: !firmware.visible
            CCText{
                height: parent.height
                text: vehicle ? vehicle.firmwareTypeString : ""
                anchors.right: parent.right
            }
        }
        CCText{
            width: parent.width
            height: contentHeight + ui.x2margin
            text: qsTr("Vehicle Type")
            visible: !type.visible
            CCText{
                height: parent.height
                text: vehicle ? vehicle.vehicleTypeString : ""
                anchors.right: parent.right
            }
        }
        LabelTextField {
            id: cruise
            title: qsTr("Cruise Speed")
            //title: qsTr("巡航速度")
            //text: _route.cruiseSpeed
            unit: qsTr("m/s")
            onlyNumber: true
            visible: !vehicle.multiRotor
            onValueChanged:
                (value)=>{
                    //_route.cruiseSpeed = value
                }
        }
        LabelTextField {
            id: hover
            title: qsTr("Hover Speed")
            //title: qsTr("旋翼速度")
            //text: _route.hoverSpeed
            unit: qsTr("m/s")
            onlyNumber: true
            visible: vehicle.multiRotor || vehicle.vtol
            onValueChanged:
                (value)=>{
                    //_route.hoverSpeed = value
                }
        }
        Rectangle{
            id: img
            width: parent.width
            height: showImage ? 120 : 0
            color: cc.none
            border.color: cc.border
            visible: showImage
        }
        LabelMultiSwitch {
            id: sw165
            model: ["1", "2", "3"]
            onSwitchTo:
            (index)=>{
                selectIndex = index
            }
            visible: showImage
        }
    }

}
