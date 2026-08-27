
import QtQuick
import QtQuick.Controls

import QGroundControl

import Gises.Widget

CCMouseArea{
    id: root
    height: brand.height + (cmode ? camera.height : base.height)
    width: parent.width

    property ColorConfig cc: clcfg
    property CameraInfo cameraInfo: null
    property bool cmode: cameraInfo ? cameraInfo.brandIndex : 0
    property string altModeName: ""

    LabelComboBox {
        id: brand
        title: qsTr("Camera")
        model: cameraInfo ? cameraInfo.brandList : ["None"]
        currentIndex: cameraInfo ? cameraInfo.brandIndex : 0
        onUpdateResult:
            (index)=>{
                if(cameraInfo){
                    cameraInfo.brandIndex = index;
                }
            }
    }
    Column{
        id: base
        width: parent.width
        anchors.top: brand.bottom
        visible: !cmode
        LabelTextField {
            id: altValue
            title: qsTr("Altitude")
            fact: cameraInfo ? cameraInfo.distanceToSurface : null
        }
        LabelTextField{
            id: trigger
            title: qsTr("Trigger Dist")
            fact: cameraInfo ? cameraInfo.adjustedFootprintFrontal : null
        }
        LabelTextField{
            id: sideSpacing
            title: qsTr("Side Spacing")
            fact: cameraInfo ? cameraInfo.adjustedFootprintSide : null
        }
    }

    Column{
        id: camera
        width: parent.width
        anchors.top: brand.bottom
        visible: cmode
        LabelComboBox {
            id: mod
            title: qsTr("Model")
            model: cameraInfo ? cameraInfo.modelList : ["None"]
            currentIndex: cameraInfo ? cameraInfo.modelIndex: 0
            visible: brand.currentIndex > 1
            onCurrentIndexChanged:{
                if(cameraInfo){
                    cameraInfo.modelIndex = currentIndex
                }
            }
        }
        LabelSwitchButton {
            id: landscape
            title: "Landscape Mode"
            stateOn: cameraInfo ? cameraInfo.landscape.value : 0
            visible: cmode
            onStateChanged: {
                if(cameraInfo)
                    cameraInfo.landscape.value = !cameraInfo.landscape.value
            }
        }
        Item{
            id: lens
            width: parent.width
            height: wth.height + sensor.height + image.height + focalLength.height
            property bool enable: true
            visible: 1 === brand.currentIndex
            CCText{
                id: wth
                width: ui.fontWidth * 12
                text: qsTr("Width")
                alignMid: true
                anchors.right: hei.left
                anchors.rightMargin: ui.margin
            }
            CCText{
                id: hei
                width: ui.fontWidth * 12
                text: qsTr("Height")
                alignMid: true
                anchors.right: parent.right
            }
            CCText{
                id: sensor
                width: ui.fontWidth * 12
                height: contentHeight + ui.x2margin
                text: qsTr("Sensor")
                anchors.top: wth.bottom
            }
            CCTextField{
                id: swidth
                width: ui.fontWidth * 12
                text: cameraInfo ? cameraInfo.sensorWidth.value : ""
                unit: cameraInfo ? cameraInfo.sensorWidth.units : ""
                inputMethodHints: Qt.ImhDigitsOnly
                anchors.verticalCenter: sensor.verticalCenter
                anchors.right: sheight.left
                anchors.rightMargin: ui.margin
                onEditingFinished: {
                    var error = cameraInfo.sensorWidth.validate(text, false)
                    if(error === ""){
                        cameraInfo.sensorWidth.rawValue = text
                    }else{
                        text = cameraInfo.sensorWidth.valueString
                    }
                }
            }
            CCTextField{
                id: sheight
                width: ui.fontWidth * 12
                text: cameraInfo ? cameraInfo.sensorHeight.value : ""
                unit: cameraInfo ? cameraInfo.sensorHeight.units : ""
                inputMethodHints: Qt.ImhDigitsOnly
                anchors.verticalCenter: sensor.verticalCenter
                anchors.right: parent.right
                onEditingFinished: {
                    var error = cameraInfo.sensorHeight.validate(text, false)
                    if(error === ""){
                        cameraInfo.sensorHeight.rawValue = text
                    }else{
                        text = cameraInfo.sensorHeight.valueString
                    }
                }
            }
            CCText{
                id: image
                width: ui.fontWidth * 12
                height: contentHeight + ui.x2margin
                text: qsTr("Image")
                anchors.top: sensor.bottom
            }
            CCTextField{
                id: iwidth
                width: ui.fontWidth * 12
                text: cameraInfo ? cameraInfo.imageWidth.value : ""
                unit: cameraInfo ? cameraInfo.imageWidth.units : ""
                inputMethodHints: Qt.ImhDigitsOnly
                anchors.verticalCenter: image.verticalCenter
                anchors.right: iheight.left
                anchors.rightMargin: ui.margin
                onEditingFinished: {
                    var error = cameraInfo.imageWidth.validate(text, false)
                    if(error === ""){
                        cameraInfo.imageWidth.rawValue = text
                    }else{
                        text = cameraInfo.imageWidth.valueString
                    }
                }
            }
            CCTextField{
                id: iheight
                width: ui.fontWidth * 12
                text: cameraInfo ? cameraInfo.imageHeight.value : ""
                unit: cameraInfo ? cameraInfo.imageHeight.units : ""
                inputMethodHints: Qt.ImhDigitsOnly
                anchors.verticalCenter: image.verticalCenter
                anchors.right: parent.right
                onEditingFinished: {
                    var error = cameraInfo.imageHeigth.validate(text, false)
                    if(error === ""){
                        cameraInfo.imageHeigth.rawValue = text
                    }else{
                        text = cameraInfo.imageHeigth.valueString
                    }
                }
            }
            LabelComboBox{
                id: focalLength
                title: qsTr("Focal Length")
                fact: cameraInfo ? cameraInfo.focalLength : null
                anchors.top: image.bottom
            }
        }
        CCText{
            id: overlap
            text: qsTr("Overlap")
        }
        LabelComboBox{
            id: frontlap
            title: qsTr("Front Lap")
            fact: cameraInfo ? cameraInfo.frontalOverlap: null
        }
        LabelComboBox{
            id: sidelap
            title: qsTr("Side Lap")
            fact: cameraInfo ? cameraInfo.sideOverlap: null
        }
        CCMultiSwitch{
            id: switchAlt
            model: ["Ground resolution", "Altitude"]
            selectIndex: cameraInfo ? cameraInfo.valueSetIsDistance.rawValue: 0
            onSwitchTo:
                (index)=>{
                    if(cameraInfo){
                        cameraInfo.valueSetIsDistance.rawValue = index
                    }
                }
        }
        LabelComboBox{
            id: altParam
            title: qsTr("Image Density")
            fact: cameraInfo ? cameraInfo.imageDensity : null
            visible: cameraInfo && false === cameraInfo.valueSetIsDistance.value
        }
        LabelComboBox{
            id: grndParam
            title: qsTr(altModeName)
            fact: cameraInfo ? cameraInfo.distanceToSurface : null
            visible: cameraInfo && cameraInfo.valueSetIsDistance.value
        }
    }
}
