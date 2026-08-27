
import QtQuick
import QtLocation
import QtPositioning

import QGroundControl

import qgc
import gises
import gises.widget

FlightMap{
    id: root
    objectName: "defaultMap"
    x: pos === win.main ? 0 : (pos === win.left ? ui.margin : parent.width - width - ui.margin)
    y: pos === win.main ? 0 : parent.height - height - ui.margin
    width: pos === win.main ? parent.width : parent.width * 0.25
    height: pos === win.main ? parent.height : parent.height * 0.25
    z: pos === win.main ? -1 : 0

    zoomLevel: QGroundControl.flightMapZoom
    center: QGroundControl.flightMapPosition
    // The code below enables SSAA
    layer.enabled: true
    layer.smooth: true
    property int pr: Screen.devicePixelRatio
    layer.textureSize: Qt.size(width  * 2 * pr, height * 2 * pr)

    property GCSPlanManager plan: gcsManager.planManager
    property GeoFence currentFence: gcsManager.geoFenceManager.currentFence
    property int pos: win.main
    property bool touchable: true
    property int vertexOrder: 5
    property int pinOrder: 4
    property int arrowOrder: 3
    property int flightPathOrder: 2
    property int polygonFrame: 1
    property int polygonOrder: 0
    onMapClicked:
        (position)=>{
            if(mainContent !== root){
                switchWindow(root, pos)
            }else{
                root.focus = true
                var coordinate = root.toCoordinate(Qt.point(position.x, position.y), false /* clipToViewPort */)
                if(gcsManager.state === GCSManager.Normal){
                    console.log("lat:",coordinate.latitude.toFixed(9), "lot:", coordinate.longitude.toFixed(9))
                }else if(gcsManager.state === GCSManager.Flying){
                    menu.coord = map.toCoordinate(Qt.point(position.x, position.y), false)
                    menu.check(position)
                }else if(gcsManager.state === GCSManager.Planning){
                    if(touchable){
                        plan.onMapClicked(coordinate)
                    }
                }else if(gcsManager.state === GCSManager.Fence){
                    if(touchable && currentFence){
                        currentFence.addPoint(coordinate)
                    }
                }else if(gcsManager.state === GCSManager.Rally){
                    if(touchable){
                        gcsManager.rallyPointManager.addPoint(coordinate)
                    }
                }
            }
        }
    onBearingChanged:{
        if(mainContent !== defaultMap){
            return
        }
        gcsManager.mapBearing = map.bearing
        //gcsManager.refreshPin()
    }
    onZoomLevelChanged:{
        if(mainContent !== defaultMap){
            return
        }
        QGroundControl.flightMapZoom = map.zoomLevel
        //gcsManager.refreshPin()
    }
    onCenterChanged:{
        if(mainContent !== defaultMap){
            return
        }
        QGroundControl.flightMapPosition = map.center
        //gcsManager.refreshPin()
    }
    // Add trajectory lines to the map
    MapPolyline {
        id:         trajectoryPolyline
        line.width: 2
        line.color: "red"
        z:          QGroundControl.zOrderTrajectoryLines
        visible:    mainContent === defaultMap

        Connections {
            target:                 QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) {
                trajectoryPolyline.path = activeVehicle ? activeVehicle.trajectoryPoints.list() : []
            }
        }

        Connections {
            target:                             activeVehicle ? activeVehicle.trajectoryPoints : null
            onPointAdded: (coordinate) =>       trajectoryPolyline.addCoordinate(coordinate)
            onUpdateLastPoint: (coordinate) =>  trajectoryPolyline.replaceCoordinate(trajectoryPolyline.pathLength() - 1, coordinate)
            onPointsCleared:                    trajectoryPolyline.path = []
        }
    }
    MapPolyline{
        line.width: 2
        line.color: "yellow"
        path: gcsManager.missionPath
    }
    Repeater{
        model: gcsManager.missionModel
        delegate: CCVehicleMissionItem{
            item: object
        }
    }
    // Add the vehicles to the map
    MapItemView {
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: VehicleMapItem {
            vehicle: object
            coordinate: object.coordinate
            map: defaultMap
            size: mainContent !== defaultMap ? ui.fontHeight : ui.fontHeight * 3
            z: QGroundControl.zOrderVehicles
        }
    }
    // Add distance sensor view
    MapItemView{
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: ProximityRadarMapView {
            vehicle: object
            coordinate: object.coordinate
            map: defaultMap
            z: QGroundControl.zOrderVehicles
        }
    }
    // Add ADSB vehicles to the map
    MapItemView {
        model: QGroundControl.adsbVehicleManager.adsbVehicles
        delegate: VehicleMapItem {
            coordinate: object.coordinate
            altitude: object.altitude
            callsign: object.callsign
            heading: object.heading
            alert: object.alert
            map: defaultMap
            size: mainContent !== defaultMap ? ui.fontHeight : ui.fontHeight * 3
            z: QGroundControl.zOrderVehicles
        }
    }
    Repeater{
        id: polygonFence
        model: gcsManager.geoFenceManager.polygonFenceModel
        delegate: MapPolygon{
            color: object.inner ? cc.none : "red"
            border.color: object.inner ? "lime" : "red"
            border.width: 1
            path: object.polygon
            opacity: object.inner ? 1 : 0.2
            Component.onCompleted: {
                root.addMapItem(this)
            }
        }
    }
    Repeater{
        id: cycleFence
        model: gcsManager.geoFenceManager.circleFenceModel
        delegate: MapCircle{
            color: object.inner ? cc.none : "red"
            border.color: object.inner ? "lime" : "red"
            border.width: 1
            center: object.centerPoint.coord
            radius: object.radius
            opacity: object.inner ? 1 : 0.2
            Component.onCompleted: {
                root.addMapItem(this)
            }
        }
    }
    Repeater{
        id: fenceVertex
        model: currentFence ? currentFence.points : 0
        delegate: CCWaypoint{
            coordinate: modelData.coord
            geoPoint: modelData
            sign: modelData.index
            active: modelData === currentFence.current
            onCoordinateChanged: {
                modelData.coord = coordinate
            }
            onClicked: {
                currentFence.current = modelData
            }
        }
    }
    CCWaypoint{
        id: circleCenter
        coordinate: currentFence ? currentFence.centerPoint.coord : QtPositioning.coordinate()
        geoPoint: currentFence ? currentFence.centerPoint : null
        sign: "C"
        onCoordinateChanged: {
            if(currentFence){
                currentFence.centerPoint.coord = coordinate
                currentFence.radiusPoint.coord = coordinate.atDistanceAndAzimuth(currentFence.radius, 90)
            }
        }
    }
    CCWaypoint{
        id: circleRadius
        coordinate: currentFence ? currentFence.radiusPoint.coord : QtPositioning.coordinate()
        geoPoint: currentFence ? currentFence.radiusPoint : null
        sign: "R"
        disYChange: true
        onCoordinateChanged: {
            if(currentFence){
                var diff = coordinate.longitude - currentFence.radiusPoint.coord.longitude
                var lon = currentFence.radiusPoint.coord
                lon.longitude += diff
                currentFence.radiusPoint.coord = lon
            }
        }
    }
    Repeater{
        id: rally
        model: gcsManager.rallyPointManager.points
        delegate: CCWaypoint{
            coordinate: modelData.coord
            geoPoint: modelData
            sign: "R"
            active: modelData === gcsManager.rallyPointManager.current
            onCoordinateChanged: {
                modelData.coord = coordinate
            }
            onClicked: {
                gcsManager.rallyPointManager.current = modelData
            }
        }
    }
    CCWaypoint{
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
    CCLand{
        id: land
        landNode: plan.land
        onCoordinateChanged: {
            plan.land.last.coord = coordinate
        }
    }

    //测区多边形
    Repeater{
        model: plan.surveyAreaModel
        MapPolygon{
            property GCSSurveyArea area: object
            path: area.shape.path
            color: area === plan.currentNode ? "#160000ff" : "#200000ff"
            border.color: area.shape.valid ? cc.selected : cc.error
            Component.onCompleted: {
                root.addMapItem(this)
            }
        }
    }
    //测区多边形外框
    // Repeater{
    //     model: plan.surveyAreaModel
    //     MapPolygon{
    //         property GCSSurveyArea area: object
    //         path: area.shape.type === GCSGeoShape.POLYGON ? area.shape.frame : []
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
            property GCSSurveyArea area: object
            path: area.shape.type === GCSGeoShape.CORRIDOR ? area.shape.mids : []
            line.color: "pink"
            line.width: 3
            Component.onCompleted: {
               root.addMapItem(this)
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
               root.addMapItem(this)
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
               root.addMapItem(this)
            }
        }
    }
    //航点标识
    Repeater{
        model: plan.waypointModel
        delegate: CCWaypoint{
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
            property GCSSurveyArea surveyArea: object
            property int infoSize: surveyArea.showInfoModel.count
            property bool showAll: false
            model: surveyArea.showInfoModel//infoSize ? showAll ? surveyArea.infos : [surveyArea.infos[0], surveyArea.infos[infoSize -1]] : 0
            delegate: CCWaypoint{
                id: wp
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
        delegate: CCGeoVertex{
            shape: plan.currentArea.shape
            shapeActive: plan.currentArea.active
            geoPoint: object
        }
    }
    //测区中心标识
    Repeater{
        model: plan.surveyAreaModel
        CCGeoPolygonCenter{
            area: object
        }
    }
    CCVehicleActionMenu{
        id: menu
    }
}
