import QtQuick
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.FlightMap

import Gises.Widget

Item{
    id: root

    property Ui ui: Ui
    property bool isMain: true
    property GisesPlan plan: gises.planManager
    property GeoFence fence: gises.fenceManager.currentFence
    property RallyManager rally: gises.rallyManager

    Component.onCompleted: {
        mainWindow.planMap = planMap
    }

    FlightMap{
        id: planMap
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

        property bool touchable: true

        onMapClicked:
            (position)=>{
                var coordinate = toCoordinate(Qt.point(position.x, position.y), false /* clipToViewPort */)
                if (gises.currentManager === plan) {
                    plan.onMapClicked(coordinate)
                } else if (fence && gises.currentManager === gises.fenceManager) {
                    fence.addPoint(coordinate)
                } else if (gises.currentManager === rally) {
                    rally.addPoint(coordinate)
                }
            }
        onZoomLevelChanged: {
            QGroundControl.flightMapZoom = planMap.zoomLevel
        }
        onCenterChanged: {
            QGroundControl.flightMapPosition = planMap.center
        }

        // Add the vehicles to the planMap
        MapItemView {
            model: QGroundControl.multiVehicleManager.vehicles
            delegate: VehicleMapItem {
                vehicle: object
                coordinate: object.coordinate
                map: planMap
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
                map: planMap
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
                map: planMap
                size: ui.fontHeight * (isMain ? 2.5 : 1)
                z: QGroundControl.zOrderVehicles
            }
        }

        Repeater{
            id: polygonFence
            model: gises.fenceManager.polygonFenceModel
            delegate: MapPolygon{
                color: object.inner ? cc.none : "red"
                border.color: object.inner ? "lime" : "red"
                border.width: 1
                path: object.polygon
                opacity: object.inner ? 1 : 0.2
                Component.onCompleted: {
                    planMap.addMapItem(this)
                }
            }
        }
        Repeater{
            id: cycleFence
            model: gises.fenceManager.circleFenceModel
            delegate: MapCircle{
                color: object.inner ? cc.none : "red"
                border.color: object.inner ? "lime" : "red"
                border.width: 1
                center: object.centerPoint.coord
                radius: object.radius
                opacity: object.inner ? 1 : 0.2
                Component.onCompleted: {
                    planMap.addMapItem(this)
                }
            }
        }
        Repeater{
            id: fenceVertex
            model: fence ? fence.points : 0
            delegate: WaypointItem{
                map: planMap
                coordinate: modelData.coord
                geoPoint: modelData
                sign: modelData.index
                active: modelData === fence.current
                onCoordinateChanged: {
                    modelData.coord = coordinate
                }
                onClicked: {
                    fence.current = modelData
                }
            }
        }
        WaypointItem{
            id: circleCenter
            map: planMap
            coordinate: fence ? fence.centerPoint.coord : QtPositioning.coordinate()
            geoPoint: fence ? fence.centerPoint : null
            sign: "C"
            onCoordinateChanged: {
                if(fence){
                    fence.centerPoint.coord = coordinate
                    fence.radiusPoint.coord = coordinate.atDistanceAndAzimuth(fence.radius, 90)
                }
            }
        }
        WaypointItem{
            id: circleRadius
            map: planMap
            coordinate: fence ? fence.radiusPoint.coord : QtPositioning.coordinate()
            geoPoint: fence ? fence.radiusPoint : null
            sign: "R"
            disYChange: true
            onCoordinateChanged: {
                if(fence){
                    var diff = coordinate.longitude - fence.radiusPoint.coord.longitude
                    var lon = fence.radiusPoint.coord
                    lon.longitude += diff
                    fence.radiusPoint.coord = lon
                }
            }
        }
        Repeater{
            id: rallys
            model: rally.points
            delegate: WaypointItem{
                map: planMap
                coordinate: modelData.coord
                geoPoint: modelData
                sign: "R"
                active: modelData === rally.current
                onCoordinateChanged: {
                    modelData.coord = coordinate
                }
                onClicked: {
                    rally.current = modelData
                }
            }
        }
        WaypointItem{
            map: planMap
            coordinate:2 === plan.land.landMode ? plan.land.first.coord : QtPositioning.coordinate()
            sign: qsTr("LTA")
            isLoiter: 2 === plan.land.landMode && plan.land.useLoiter
            loiterRadius: 2 === plan.land.landMode && plan.land.useLoiter ? plan.land.radius : 0
            recalc: true
            lotCoord: plan.land.first.coord
            active: plan.land.active
            onTmpCoordChanged: {
                plan.land.calcHead(tmpVisual.coordinate)
            }
            onClicked: {
                plan.onNodeClicked(plan.land)
            }
        }
        LandItem{
            id: land
            map: planMap
            landNode: plan.land
            onCoordinateChanged: {
                plan.land.last.coord = coordinate
            }
        }

        //测区多边形
        Repeater{
            model: plan.surveyAreaModel
            MapPolygon{
                property SurveyArea area: object
                path: area.shape.path
                color: area === plan.currentNode ? "#160000ff" : "#200000ff"
                border.color: area.shape.valid ? cc.selected : cc.error
                Component.onCompleted: {
                    planMap.addMapItem(this)
                }
            }
        }
        //测区多边形外框
        // Repeater{
        //     model: plan.surveyAreaModel
        //     MapPolygon{
        //         property SurveyArea area: object
        //         path: area.shape.type === GeoShape.POLYGON ? area.shape.frame : []
        //         border.color: "yellow"
        //         Component.onCompleted: {
        //             root.addMapItem(this)
        //         }
        //     }
        // }
        //带状航线主干
        Repeater{
            model: plan.surveyAreaModel
            delegate: MapPolyline{
                property SurveyArea area: object
                path: area.shape.type === GeoShape.CORRIDOR ? area.shape.mids : []
                line.color: "pink"
                line.width: 3
                Component.onCompleted: {
                   planMap.addMapItem(this)
                }
            }
        }
        //测区航线(多点)
        Repeater{
            model: plan.surveyAreaModel
            delegate: MapPolyline{
                path: object.path
                line.width: 2
                line.color: -1 === object.safety ? cc.disabled : object.safety ? cc.good : cc.error
                Component.onCompleted: {
                   planMap.addMapItem(this)
                }
            }
        }
        //普通航线(两点)
        Repeater{
            model: plan.flightPathModel
            delegate: MapPolyline{
                path: object.path
                line.color: -1 === object.safety ? cc.disabled : object.safety ? cc.good : cc.error
                Component.onCompleted: {
                   planMap.addMapItem(this)
                }
            }
        }
        //航点标识
        Repeater{
            model: plan.waypointModel
            delegate: WaypointItem{
                map: planMap
                coordinate: object.first.coord
                node: object
                waypoint: object
                geoPoint: object.first
                active: object.active
                onClicked:{
                    plan.onNodeClicked(object)
                }
                onCoordinateChanged: {
                    object.coord = coordinate
                }
            }
        }
        //测区出入口标识
        Repeater{
            model: plan.surveyAreaModel
            Repeater{
                id: surveyAreaIoRep
                property SurveyArea surveyArea: object
                property int infoSize: surveyArea.showInfoModel.count
                property bool showAll: false
                model: surveyArea.showInfoModel//infoSize ? showAll ? surveyArea.infos : [surveyArea.infos[0], surveyArea.infos[infoSize -1]] : 0
                delegate: WaypointItem{
                    id: wp
                    map: planMap
                    coordinate: object.coord
                    geoPoint: object
                    node: surveyAreaIoRep.surveyArea
                    canDrag: false
                }
            }
        }
        //测区顶点标识
        Repeater{
            model: plan.currentArea ? plan.currentArea.shape.keypointModel : 0
            delegate: VertexItem{
                map: planMap
                shape: plan.currentArea.shape
                shapeActive: plan.currentArea.active
                geoPoint: object
            }
        }
        //测区中心标识
        Repeater{
            model: plan.surveyAreaModel
            PolygonCenter{
                map: planMap
                area: object
            }
        }
    }
}