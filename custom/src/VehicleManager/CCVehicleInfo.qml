
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Vehicle
import QGroundControl.SettingsManager

import gises
import gises.base
import gises.widget

CCMouseArea{
    id:    root
    height: col.height

    property AppSettings appsettings: QGroundControl.settingsManager.appSettings
    property GCSColorConfig cc: gcsManager.colorConfig
    property Vehicle vehicle: gcsManager.vehicle
    property var ui: CCUiTool
    property GCSPlanManager plan: gcsManager.planManager
    property string info: "Vehicle Info"
    property bool vehicleFirmware: !QGroundControl.singleFirmwareSupport
    property bool vehicleTypes: !QGroundControl.singleVehicleSupport
    property bool alterable: !plan.valid && activeVehicle === null
    property bool showImage: true

    Column{
        id: col
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        CCComboBoxEditor{
            id: firmware
            title: qsTr("Firmware")
            fact: QGroundControl.settingsManager.appSettings.offlineEditingFirmwareClass
            visible: vehicleFirmware && alterable
        }
        CCComboBoxEditor{
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
        CCTextEditor{
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
        CCTextEditor{
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
        CCMultiSwitchEditor{
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
