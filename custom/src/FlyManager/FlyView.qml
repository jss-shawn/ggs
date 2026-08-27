import QtQuick
import QtLocation

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

import Gises.Widget

Item{
    id: root

    property bool isMain: true
    property Vehicle vehicle: QGroundControl.multiVehicleManager.activeVehicle

    Component.onCompleted: {
        mainWindow.flyMap = flyMap
    }

    FlightMap{
        id: flyMap
        anchors.fill: parent
        zoomLevel: QGroundControl.flightMapZoom
        center: QGroundControl.flightMapPosition
        // The code below enables SSAA
        layer.enabled: true
        layer.smooth: true
        property int w : width
        property int h : height
        property int pr: Screen.devicePixelRatio
        layer.textureSize: Qt.size(w  * 2 * pr, h * 2 * pr)

        onZoomLevelChanged:{
            QGroundControl.flightMapZoom = flyMap.zoomLevel
        }
        onCenterChanged:{
            QGroundControl.flightMapPosition = flyMap.center
        }
        onMapClicked:
            (position)=>{
            }

        // Add trajectory lines to the flyMap
        MapPolyline {
            id:         trajectoryPolyline
            line.width: 2
            line.color: "red"
            z: QGroundControl.zOrderTrajectoryLines

            Connections {
                target: QGroundControl.multiVehicleManager
                function onActiveVehicleChanged(activeVehicle) {
                    trajectoryPolyline.path = activeVehicle ? activeVehicle.trajectoryPoints.list() : []
                }
            }

            Connections {
                target: vehicle ? vehicle.trajectoryPoints : null
                onPointAdded: (coordinate) => trajectoryPolyline.addCoordinate(coordinate)
                onUpdateLastPoint: (coordinate) => trajectoryPolyline.replaceCoordinate(trajectoryPolyline.pathLength() - 1, coordinate)
                onPointsCleared: trajectoryPolyline.path = []
            }
        }
        MapPolyline{
            line.width: 2
            line.color: "yellow"
            path: gises.missionPath
        }
        Repeater{
            model: gises.missionModel
            delegate: VehicleMissionItem{
                map: flyMap
                item: object
            }
        }
        // Add the vehicles to the flyMap
        MapItemView {
            model: QGroundControl.multiVehicleManager.vehicles
            delegate: VehicleMapItem {
                vehicle: object
                coordinate: object.coordinate
                map: flyMap
                size: ui.fontHeight * (isMain ? 2.5 : 1)
                z: QGroundControl.zOrderVehicles
            }
        }
        // Add distance sensor view
        MapItemView{
            model: QGroundControl.multiVehicleManager.vehicles
            delegate: ProximityRadarMapView {
                vehicle: object
                coordinate: object.coordinate
                map: flyMap
                z: QGroundControl.zOrderVehicles
            }
        }
        // Add ADSB vehicles to the flyMap
        MapItemView {
            model: QGroundControl.adsbVehicleManager.adsbVehicles
            delegate: ADSBVehicleMapItem {
                coordinate: object.coordinate
                altitude: object.altitude
                callsign: object.callsign
                heading: object.heading
                alert: object.alert
                map: flyMap
                size: ui.fontHeight * (isMain ? 2.5 : 1)
                z: QGroundControl.zOrderVehicles
            }
        }
    }
    MapTool{
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        zoomLevel: flyMap.zoomLevel
        visible: isMain
    }
    // VehicleActionMenu{
    //     id: menu
    // }
}
