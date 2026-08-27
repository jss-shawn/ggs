
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

import Gises.Widget

CCMouseArea{
    id: root
    width: parent.width
    height: head.height + col1.height

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property var settingsManager: QGroundControl.settingsManager
    property var appSettings: settingsManager.appSettings
    //property GCSNtrip rip: gcsManager.ntrip
    property string title: qsTr("General Settings")

    function reset(){

    }
    Component.onCompleted: {

    }

    CCText{
        id: head
        width: parent.width
        text: title
        alignMid: true
        font.pointSize: ui.llFontSize
    }
    Column{
        id: col1
        width: parent.width
        anchors.top: head.bottom
        LabelComboBox{
            id: language
            title: qsTr("Language")
            fact: appSettings.qLocaleLanguage
            visible: appSettings.qLocaleLanguage.userVisible
        }
        LabelComboBox{
            id: follow
            title: qsTr("Stream GCS Position")
            fact: appSettings.followTarget
            visible: appSettings.followTarget.userVisible
        }
        LabelSwitchButton{
            id: savdToSDCard
            title: qsTr("Save application to SD Card")
            fact: appSettings.androidDontSaveToSDCard
            visible: ui.isMobile && appSettings.androidDontSaveToSDCard.userVisible
            onSwitched: {
                appSettings.androidDontSaveToSDCard.value ? appSettings.androidDontSaveToSDCard.value = 0 : appSettings.androidDontSaveToSDCard.value = 1
            }
        }
        Item{
            id: saveAndLoadPath
            width: parent.width
            height: slTitle.height + slPath.height
            visible: appSettings.savePath.userVisible && !ui.isMobile
            CCText{
                id: slTitle
                text: qsTr("Application Save Path")
            }
            CCText{
                id: slPath
                height: ui.fontHeight
                font.pointSize: slTitle.font.pointSize - 2
                text: appSettings.savePath.rawValue
                anchors.top: slTitle.bottom
            }
            CCButton{
                height: ui.fontHeight * 2
                width: ui.fontWidth * 10
                text: qsTr("Browse")
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                onClicked: {
                    folderDlg.open()
                }
            }
            FolderDialog{
                id: folderDlg
                title: qsTr("Choose Application Save Path")
                currentFolder: "file:///" + appSettings.savePath.rawValue
                onAccepted:{
                    appSettings.savePath.rawValue = selectedFolder.toString().replace("file:///", "")
                }
            }
        }
        LabelSwitchButton{
            id: clear
            title: qsTr("Clear all settings on next start")
            stateOn: false
            onSwitched: {
                stateOn = !stateOn
                if(stateOn){
                    QGroundControl.deleteAllSettingsNextBoot()
                }
            }
        }
        // Column{
        //     id: ntrip
        //     width: parent.width
        //     CCText{
        //         id: ripTitle
        //         text: qsTr("Ntrip")
        //         font.pointSize: ui.lFontSize
        //     }
        //     LabelTextField{
        //         id: host
        //         title: qsTr("Host")
        //         text: rip.host
        //         onValueChanged:
        //             (value)=>{
        //                 rip.host = value
        //             }
        //     }
        //     LabelTextField{
        //         id: port
        //         title: qsTr("Port")
        //         text: rip.port
        //         onlyNumber: true
        //         onValueChanged:
        //             (value)=>{
        //                 rip.port = value
        //             }
        //     }
        //     LabelTextField{
        //         id: account
        //         title: qsTr("Account")
        //         text: rip.account
        //         onValueChanged:
        //             (value)=>{
        //                 rip.account = value
        //             }
        //     }
        //     LabelTextField{
        //         id: password
        //         title: qsTr("Password")
        //         text: rip.password
        //         onValueChanged:
        //             (value)=>{
        //                 rip.password = value
        //             }
        //     }
        //     LabelMultiSwitch{
        //         id: acquireMode
        //         title: qsTr("MountPoint")
        //         model: ["Manual Input", "Network Request"]
        //         selectIndex: rip.acquire
        //         anchors.right: parent.right
        //         onSwitchTo:
        //             (index)=>{
        //                 rip.acquire = index
        //             }
        //     }
        //     LabelTextField{
        //         id: mpInput
        //         title: qsTr("")
        //         text: rip.mountPoint
        //         visible: 0 === rip.acquire
        //         onValueChanged:
        //             (value)=>{
        //                 rip.mountPoint = value
        //             }
        //     }
        //     LabelComboBox{
        //         id: mpBox
        //         title: qsTr("")
        //         model: rip.mountPointList
        //         currentIndex: 0
        //         visible: rip.acquire === 1
        //         onUpdateResult:
        //             (index)=>{
        //                 rip.mountPoint = rip.mountPointList[index]
        //             }
        //         CCButton{
        //             id: request
        //             width: ui.fontWidth * 8
        //             text: qsTr("Request")
        //             anchors.verticalCenter: parent.verticalCenter
        //             onClicked: {
        //                 rip.getMountPoint()
        //             }
        //         }
        //     }
        //     Item{
        //         id: connection
        //         width: connect.width * 2 + ui.fontWidth * 4
        //         height: ui.fontHeight * 2 + ui.x2margin
        //         anchors.horizontalCenter: parent.horizontalCenter
        //         CCButton{
        //             id: connect
        //             width: ui.fontWidth * 10
        //             height: ui.fontHeight * 2
        //             enabled: !rip.connected
        //             text: qsTr("Connect")
        //             anchors.verticalCenter: parent.verticalCenter
        //             onClicked: {
        //                 rip.connectToNtripServer()
        //             }
        //         }
        //         CCButton{
        //             id: disconnect
        //             width: ui.fontWidth * 10
        //             height: ui.fontHeight * 2
        //             enabled: rip.connected
        //             text: qsTr("Disconnect")
        //             anchors.right: parent.right
        //             anchors.verticalCenter: parent.verticalCenter
        //             onClicked: {
        //                 rip.disconnect()
        //             }
        //         }
        //     }
        // }
    }
}
