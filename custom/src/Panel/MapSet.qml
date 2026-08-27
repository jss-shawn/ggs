
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls

import Gises.Widget

CCMouseArea{
    id: root
    width: ui.fontWidth * 50
    height: head.height + col.height

    property Ui ui: Ui
    property string title: qsTr("Map Settings")
    property var mapEngine: QGroundControl.mapEngineManager
    property var settingsManager: QGroundControl.settingsManager
    property var appSettings: settingsManager.appSettings
    property var mapsSettings: settingsManager.mapsSettings

    property Fact mapProviderFact: settingsManager.flightMapSettings.mapProvider
    property Fact mapTypeFact: settingsManager.flightMapSettings.mapType
    property Fact elevationProviderFact: settingsManager.flightMapSettings.elevationMapProvider
    property Fact mapboxFact: settingsManager ? settingsManager.appSettings.mapboxToken : null
    property Fact mapboxAccountFact: settingsManager ? settingsManager.appSettings.mapboxAccount : null
    property Fact mapboxStyleFact: settingsManager ? settingsManager.appSettings.mapboxStyle : null
    property Fact esriFact: settingsManager ? settingsManager.appSettings.esriToken : null
    property Fact customURLFact: settingsManager ? settingsManager.appSettings.customURL : null
    property Fact vworldFact: settingsManager ? settingsManager.appSettings.vworldToken : null

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
            id: provider
            title: qsTr("Provider")
            model: mapEngine.mapProviderList
            onUpdateResult:
                (index)=>{
                    mapProviderFact.rawValue = mapEngine.mapProviderList[index]
                    mapTypeFact.rawValue = mapEngine.mapTypeList(mapEngine.mapProviderList[index])[0]
                }
            Component.onCompleted: {
                var idx = mapEngine.mapProviderList.indexOf(mapProviderFact.rawValue)
                if(idx !== -1){
                    currentIndex = idx
                }
            }
        }
        LabelComboBox{
            id: type
            title: qsTr("Type")
            model: mapEngine.mapTypeList(mapProviderFact.rawValue)
            onUpdateResult:
                (index)=>{
                    mapTypeFact.rawValue = mapEngine.mapTypeList(mapProviderFact.rawValue)[index]
                }
            Component.onCompleted: {
                var idx = mapEngine.mapTypeList(mapProviderFact.rawValue).indexOf(mapTypeFact.rawValue)
                if(idx !== -1){
                    currentIndex = idx
                }
            }
        }
        LabelComboBox{
            id: elevation
            title: qsTr("Elevation")
            model: mapEngine.elevationProviderList
            onUpdateResult:
                (index)=>{
                    elevationProviderFact.rawValue = mapEngine.elevationProviderList[index]
                }
            Component.onCompleted: {
                var idx = mapEngine.elevationProviderList.indexOf(elevationProviderFact.rawValue)
                if(idx !== -1){
                    currentIndex = idx
                }
            }
        }
    }
}
