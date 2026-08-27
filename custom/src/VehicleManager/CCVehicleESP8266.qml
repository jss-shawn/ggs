
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl

import gises.base
import gises.widget

MouseArea{
    id:             root
    width: ui.fontWidth * 50
    height: content.height

    property string title: qsTr("Video Settings")
    property var settingsManager: QGroundControl.settingsManager
    property var videoManager: QGroundControl.videoManager
    property var videoSettings: settingsManager.videoSettings
    property string videoSource: videoSettings.videoSource.rawValue
    property bool isGST: videoManager.gstreamerEnabled
    property bool isStreamSource: videoManager.isStreamSource
    property bool isUDP264: isStreamSource && (videoSource === videoSettings.udp264VideoSource)
    property bool isUDP265: isStreamSource && (videoSource === videoSettings.udp265VideoSource)
    property bool isRTSP: isStreamSource && (videoSource === videoSettings.rtspVideoSource)
    property bool isTCP: isStreamSource && (videoSource === videoSettings.tcpVideoSource)
    property bool isMPEGTS: isStreamSource && (videoSource === videoSettings.mpegtsVideoSource)
    property bool videoAutoStreamConfig: videoManager.autoStreamConfigured
    property bool requiresUDPPort: isUDP264 || isUDP265 || isMPEGTS

    function reset(){

    }
    onClicked: {
        focus = true
    }
    Column{
        id: content
        width: parent.width
        height: source.height +
                (url1.visible ? url1.height : 0) +
                (url2.visible ? url2.height : 0) +
                (aspectRatio.visible ? aspectRatio.height : 0) +
                (dis.visible ? dis.height : 0) +
                (lowLatency.visible ? lowLatency.height : 0) +
                decode.height + record.height + auto.height + storageUsage.height

        CCComboBoxEditor{
            id: source
            title: qsTr("Video Source")
            fact: videoSettings.videoSource
        }
        Item{
            id: url1
            width: parent.width
            height: rtsp1.height
            visible: !videoAutoStreamConfig && (isTCP || isRTSP | requiresUDPPort)
            CCTextEditor{
                id: rtsp1
                title: qsTr("RTSP URL1:")
                fact: videoSettings.rtspUrl
                visible: isRTSP && videoSettings.rtspUrl.visible
            }
            CCTextEditor{
                id: tcp1
                title: qsTr("TCP URL")
                fact: videoSettings.tcpUrl
                visible: isTCP && videoSettings.tcpUrl.visible
            }
            CCTextEditor{
                id: udp1
                title: qsTr("UDP Port")
                fact: videoSettings.udpPort
                visible: requiresUDPPort && videoSettings.udpPort.visible
            }
        }
        Item{
            id: url2
            width: parent.width
            height: rtsp2.height
            visible: !videoAutoStreamConfig && (isTCP || isRTSP | requiresUDPPort)
            CCTextEditor{
                id: rtsp2
                title: qsTr("RTSP URL2")
                fact: videoSettings.rtspUrl2
                visible: isRTSP && videoSettings.rtspUrl2.visible
            }
        }
        CCTextEditor{
            id: aspectRatio
            title: qsTr("Aspect Ratio")
            fact: videoSettings.aspectRatio
            visible: !videoAutoStreamConfig && isStreamSource && videoSettings.aspectRatio.visible
        }
        CCSwitchEditor{
            id: dis
            title: qsTr("Stop recording when disarmed")
            fact: videoSettings.disableWhenDisarmed
            stateOn: videoSettings.disableWhenDisarmed.rawValue
            visible: !videoAutoStreamConfig && isStreamSource && fact.visible
            onStateChanged: {
                if(fact){
                    fact.rawValue ? fact.rawValue = 0 : fact.rawValue = 1
                }
            }
        }
        CCSwitchEditor {
            id: lowLatency
            title: qsTr("Low Latency Mode")
            fact: videoSettings.lowLatencyMode
            stateOn: videoSettings.lowLatencyMode.rawValue
            visible: !videoAutoStreamConfig && isStreamSource && fact.visible && isGST
            onStateChanged: {
                if(fact){
                    fact.rawValue ? fact.rawValue = 0 : fact.rawValue = 1
                }
            }
        }
        CCComboBoxEditor{
            id: decode
            title: qsTr("Video decode priority")
            fact: videoSettings.forceVideoDecoder
            visible: fact.visible
        }
        CCComboBoxEditor{
            id: record
            title: qsTr("Record File Format")
            fact: videoSettings.recordingFormat
            visible: videoSettings.recordingFormat.visible
        }
        CCSwitchEditor{
            id: auto
            title: qsTr("Auto-Delete Saved Recordings")
            fact: videoSettings.enableStorageLimit
            stateOn: videoSettings.enableStorageLimit.rawValue
            visible: fact.visible
            onStateChanged: {
                if(fact){
                    fact.rawValue ? fact.rawValue = 0 : fact.rawValue = 1
                }
            }
        }
        CCTextEditor{
            id: storageUsage
            title: qsTr("Max Storage Usage")
            fact: videoSettings.maxVideoSize
            visible: fact.visible
            enabled: videoSettings.enableStorageLimit.rawValue
        }
    }
}
