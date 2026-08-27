
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl

import Gises.Widget

CCMouseArea{
    id: root
    width: parent.width
    height: col.height

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property WaypointCamera camera: null
    property bool showParam: camera && (camera.actionIndex === 1 || camera.actionIndex === 2)
    property bool showMode: camera && camera.cameraModeSupported

    Column{
        id: col
        width: parent.width
        LabelComboBox {
            id: cameraAction
            title: "Camera Mode"
            model: camera ? camera.actionName : ["cm1","cm2"]
            currentIndex: camera ? camera.actionIndex : 0
            onCurrentIndexChanged: {
                if(camera)
                    camera.actionIndex = currentIndex
            }
        }
        LabelTextField {
            id: cameraParam
            title: camera ? (camera.actionIndex === 1 ? "Time" : "Distance") : "~"
            unit: camera ? (camera.actionIndex === 1 ? "secs" : "m") : "-"
            text: camera ? (camera.actionIndex === 1 ? camera.actionTime : camera.actionDistance) : 0
            onlyNumber: true
            visible: showParam
            onValueChanged:
                (value)=>{
                    if(camera){
                        if(camera.actionIndex === 1){
                            camera.actionTime = value
                        }else{
                            camera.actionDistance = value
                        }
                    }
                }
        }
        LabelSwitchButton {
            id: modeCheck
            title: "Mode"
            stateOn: camera ? camera.specifyCameraMode : false
            visible: showMode
            onStateChanged: {
                if(camera){
                    camera.specifyCameraMode = !camera.specifyCameraMode
                }
            }
        }
        CCMultiSwitch{
            id: cameraMode
            model: camera ? camera.modeName : [0, 1]
            selectIndex: camera ? camera.cameraMode : 0
            enabled: camera && camera.specifyCameraMode
            visible: showMode
            onSwitchTo:
                (idx)=>{
                    camera.cameraMode = idx
                }
        }

        LabelSwitchButton {
            id: gimbalCheck
            title: "Gimbal"
            stateOn: camera ? camera.gimbalAdjust : false
            enabled: camera
            onStateChanged: {
                if(camera)
                    camera.gimbalAdjust = !camera.gimbalAdjust
            }
        }
        LabelTextField {
            id:pitch
            title: "Gimbal pitch"
            onlyNumber: true
            text: camera ? camera.gimbalPitch : 0
            unit: "deg"
            enabled: camera && camera.gimbalAdjust
            onValueChanged:
                (value)=>{
                    if(camera){
                        camera.gimbalPitch = value
                    }
                }
        }
        LabelTextField {
            id: yaw
            title: "Gimbal yaw"
            onlyNumber: true
            text: camera ? camera.gimbalYaw : 0
            unit: "deg"
            enabled: camera && camera.gimbalAdjust
            onValueChanged:
                (value)=>{
                    if(camera){
                        camera.gimbalYaw = value
                    }
                }
        }
    }
}
