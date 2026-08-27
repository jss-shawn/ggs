
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl

import Gises.Widget

CCMouseArea{
    id: root
    width: ui.fontWidth * 50
    height: head.height + col.height

    property string title: qsTr("Video Settings")
    property Ui ui: Ui
    property var settingsManager: QGroundControl.settingsManager
    property var videoManager: QGroundControl.videoManager
    property var videoSettings: settingsManager.videoSettings
    property string videoSource: videoSettings.videoSource.rawValue
    property bool isStreamSource: videoManager.isStreamSource
    property bool isUDP264: isStreamSource && (videoSource === videoSettings.udp264VideoSource)
    property bool isUDP265: isStreamSource && (videoSource === videoSettings.udp265VideoSource)
    property bool isRTSP: isStreamSource && (videoSource === videoSettings.rtspVideoSource)
    property bool isTCP: isStreamSource && (videoSource === videoSettings.tcpVideoSource)
    property bool isMPEGTS: isStreamSource && (videoSource === videoSettings.mpegtsVideoSource)
    property bool autoStreamConfig: videoManager.autoStreamConfigured
    property bool requiresUDPPort: isUDP264 || isUDP265 || isMPEGTS

    function reset(){

    }
    CCText{
        id: head
        width: parent.width
        text: title
        alignMid: true
        font.pointSize: ui.llFontSize
    }
    Column{
        id: col
        width: parent.width
        anchors.top: head.bottom
        LabelComboBox{
            id: source
            title: qsTr("Video Source")
            fact: videoSettings.videoSource
        }
        Item{
            id: url1
            width: parent.width
            height: rtsp1.height
            visible: !autoStreamConfig && (isTCP || isRTSP | requiresUDPPort)
            LabelTextField{
                id: rtsp1
                title: qsTr("RTSP URL1:")
                fact: videoSettings.rtspUrl
                visible: isRTSP && videoSettings.rtspUrl.userVisible
            }
            LabelTextField{
                id: tcp1
                title: qsTr("TCP URL")
                fact: videoSettings.tcpUrl
                visible: isTCP && videoSettings.tcpUrl.userVisible
            }
            LabelTextField{
                id: udp1
                title: qsTr("UDP Url")
                fact: videoSettings.udpUrl
                visible: requiresUDPPort && videoSettings.udpPort.userVisible
            }
        }
        Item{
            id: url2
            width: parent.width
            height: rtsp2.height
            visible: !autoStreamConfig && (isTCP || isRTSP | requiresUDPPort)
            LabelTextField{
                id: rtsp2
                title: qsTr("RTSP URL2")
                fact: videoSettings.rtspUrl2
                visible: isRTSP && videoSettings.rtspUrl2.userVisible
            }
        }
        LabelTextField{
            id: aspectRatio
            title: qsTr("Aspect Ratio")
            fact: videoSettings.aspectRatio
            visible: !autoStreamConfig && isStreamSource && videoSettings.aspectRatio.userVisible
        }
        LabelSwitchButton{
            id: dis
            title: qsTr("Stop recording when disarmed")
            fact: videoSettings.disableWhenDisarmed
            stateOn: videoSettings.disableWhenDisarmed.rawValue
            visible: !autoStreamConfig && isStreamSource && fact.userVisible
            onStateChanged: {
                if(fact){
                    fact.rawValue ? fact.rawValue = 0 : fact.rawValue = 1
                }
            }
        }
        LabelSwitchButton {
            id: lowLatency
            title: qsTr("Low Latency Mode")
            fact: videoSettings.lowLatencyMode
            stateOn: videoSettings.lowLatencyMode.rawValue
            visible: (!autoStreamConfig && isStreamSource && fact.userVisible) && fact.userVisible
            onStateChanged: {
                if(fact){
                    fact.rawValue ? fact.rawValue = 0 : fact.rawValue = 1
                }
            }
        }
        LabelComboBox{
            id: decode
            title: qsTr("Video decode priority")
            fact: videoSettings.forceVideoDecoder
            visible: fact.userVisible
        }
        LabelComboBox{
            id: record
            title: qsTr("Record File Format")
            fact: videoSettings.recordingFormat
            visible: videoSettings.recordingFormat.userVisible
        }
        LabelSwitchButton{
            id: auto
            title: qsTr("Auto-Delete Saved Recordings")
            fact: videoSettings.enableStorageLimit
            stateOn: videoSettings.enableStorageLimit.rawValue
            visible: fact.userVisible
            onStateChanged: {
                if(fact){
                    fact.rawValue ? fact.rawValue = 0 : fact.rawValue = 1
                }
            }
        }
        LabelTextField{
            id: storageUsage
            title: qsTr("Max Storage Usage")
            fact: videoSettings.maxVideoSize
            visible: fact.userVisible
            enabled: videoSettings.enableStorageLimit.rawValue
        }
    }
}
