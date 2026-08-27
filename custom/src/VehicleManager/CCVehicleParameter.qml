
import QtQuick
import QtQuick.Controls

import QGroundControl.Controllers
import QGroundControl.FactSystem

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Parameters")
    description: qsTr("Vehicle Parameter Configuration Page")

    ParameterEditorController{ id: ctrl }

    Item{
        id: tab
        anchors.fill: contentArea
        anchors.margins: ui.margin
        Row{
            id: ops
            height: search.height
            z: 1
            Repeater{
                model: ctrl.categories
                Rectangle{
                    width: Math.min(ui.fontWidth * 10, root.width/ctrl.categories.count)
                    height: parent.height
                    color: ctrl.currentCategory === object ? cc.normalBg : cc.disabled
                    border.color: cc.border
                    property var obj: object
                    CCText{
                        anchors.fill: parent
                        text: parent.obj.name
                        alignMid: true
                        color: cc.border
                    }
                    CCMouseArea{
                        anchors.fill: parent
                        onClicked: {
                            ctrl.currentCategory = parent.obj
                            //groupFlk.fixedWidthContent = group
                        }
                    }
                    Rectangle{
                        width: parent
                        height: parent.border.width * 3
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: -parent.border.width * 2
                        color: parent.color
                        visible: parent.obj === ctrl.currentCategory
                    }
                }
            }
        }
        CCTextEditor{
            id: search
            width: Math.min(parent.width - ops.width, ui.fontWidth * 24)
            title: qsTr("Search:")
            text: ctrl.searchText
            anchors.right: parent.right
            onTextChanged: {
                ctrl.currentGroup = null
                ctrl.searchText = text
            }
        }
        Rectangle{
            id: page
            width: parent.width
            color: cc.none
            border.color: cc.separator
            anchors.top: ops.bottom
            anchors.bottom: parent.bottom
            z: 1
        }
        Item{
            id: groupArea
            width: ui.fontWidth * 24
            height: page.height
            anchors.top: page.top
        }
        CCFlickable{
            anchors.fill: groupArea
            anchors.margins: ui.margin
            fixedWidth: true
            Item{
                width: parent.width
                height: children[0].height
                Column{
                    width: parent.width
                    spacing: ui.margin
                    Repeater{
                        model: ctrl.currentCategory ? ctrl.currentCategory.groups : 0
                        CCOptionButton{
                            width: parent.width
                            icon: ""
                            text: object.name
                            selected: ctrl.currentGroup && ctrl.currentGroup === object
                            onClicked: { ctrl.currentGroup = object }
                        }
                    }
                }
            }
        }
        ListView{
            id:view
            height: page.height
            model: ctrl.parameters
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            anchors.top: ops.bottom
            anchors.left: groupArea.right
            anchors.right: parent.right
            clip: true
            delegate: CCMouseArea{
                id: elem
                width: view.width - ui.x2margin
                height: row.height + ui.x2margin
                anchors.horizontalCenter: parent.horizontalCenter
                property int idx: index
                property Fact paramObj: object
                property string value: paramObj.valueString
                property string valueUnit: paramObj.units
                property bool isEnum: paramObj.enumStrings.length
                property bool isBits: paramObj.bitmaskStrings.length
                property bool isCurrent: view.currentIndex === index
                onClicked: {
                    if(view.currentIndex === index){
                        view.currentIndex = -1
                    }else{
                        view.currentIndex = index
                    }
                }
                function bitValue(){
                    var val = 0
                    for(var i=0; i<paramObj.bitmaskStrings.length; ++i){
                        var sw = bits.itemAt(i)
                    }
                }

                Row{
                    id: row
                    width: parent.width
                    height: des.height
                    anchors.verticalCenter: parent.verticalCenter
                    CCText{
                        width: ui.fontWidth * 18
                        height: parent.height
                        text: elem.paramObj.name
                        elide: Text.ElideRight
                        color: elem.isCurrent ? cc.good : cc.enabled
                    }
                    CCText{
                        width: ui.fontWidth * 15
                        height: parent.height
                        text: elem.isEnum ? elem.paramObj.enumStringValue : (elem.paramObj.rawValue + " " + elem.paramObj.units)
                        color: elem.isCurrent ? cc.good : cc.enabled
                        visible: !elem.isCurrent
                    }
                    CCTextField{
                        width: ui.fontWidth * 15
                        height: parent.height
                        text: elem.paramObj.rawValue
                        color: elem.isCurrent ? cc.good : cc.enabled
                        visible: elem.isCurrent && !elem.isEnum && !elem.isBits
                    }
                    CCComboBox{
                        width: ui.fontWidth * 15
                        height: parent.height
                        model: elem.paramObj.enumStrings
                        currentIndex: elem.paramObj.enumIndex
                        visible: elem.isCurrent && elem.isEnum
                        onActivated: {
                            elem.paramObj.enumIndex = currentIndex
                        }
                    }
                    CCFlickable{
                        id: flk
                        width: ui.fontWidth * 15
                        fixedWidth: true
                        visible: elem.isCurrent && elem.isBits
                        Column{
                            width: parent.width
                            Repeater{
                                model: elem.paramObj.bitmaskStrings
                                CCSwitchEditor{
                                    width: parent.width
                                    height: ui.fontHeight
                                    title: modelData
                                    stateOn: elem.paramObj.value & elem.paramObj.bitmaskValues[index]
                                    onStateChanged: {
                                        if(stateOn){
                                            elem.paramObj.value &= ~elem.paramObj.bitmaskValues[index]
                                        }else{
                                            if(index === 0){
                                                elem.paramObj.value = 1
                                            }else{
                                                elem.paramObj.value |= elem.paramObj.bitmaskValues[index]
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    CCMouseArea{
                        width: ui.fontHeight * 3
                        height: elem.height
                        anchors.verticalCenter: parent.verticalCenter
                        Image{
                            width: ui.fontHeight + ui.x2margin
                            height: width
                            source: "/classic/CCDetailInfo.svg"
                            anchors.centerIn: parent
                        }
                    }
                    CCText{
                        id: des
                        width: view.width - ui.fontWidth * 28 - elem.height
                        height: contentHeight + ui.fontHeight
                        text: elem.paramObj.shortDescription
                        color: elem.isCurrent ? cc.good : cc.enabled
                        wrapMode: Text.WordWrap
                    }
                }
                CCSeparator{
                    width: parent.width
                    visible: index
                }
            }
        }
    }
}
