# ============================================================================
# Gises PlanView Module
# ============================================================================

set(CUSTOM_SOURCES ${CUSTOM_SOURCES}
    ${CMAKE_CURRENT_SOURCE_DIR}/gisesPlan.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/gisesPlan.h
    ${CMAKE_CURRENT_SOURCE_DIR}/cameraInfo.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/cameraInfo.h
    ${CMAKE_CURRENT_SOURCE_DIR}/clipper.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/clipper.h
    ${CMAKE_CURRENT_SOURCE_DIR}/corridorArea.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/corridorArea.h
    ${CMAKE_CURRENT_SOURCE_DIR}/fenceManager.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/fenceManager.h
    ${CMAKE_CURRENT_SOURCE_DIR}/geoCorridor.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/geoCorridor.h
    ${CMAKE_CURRENT_SOURCE_DIR}/geoLine.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/geoLine.h
    ${CMAKE_CURRENT_SOURCE_DIR}/geoPoint.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/geoPoint.h
    ${CMAKE_CURRENT_SOURCE_DIR}/geoPolygon.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/geoPolygon.h
    ${CMAKE_CURRENT_SOURCE_DIR}/geoShape.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/geoShape.h
    ${CMAKE_CURRENT_SOURCE_DIR}/gisesPlan.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/gisesPlan.h
    ${CMAKE_CURRENT_SOURCE_DIR}/guideAction.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/guideAction.h
    ${CMAKE_CURRENT_SOURCE_DIR}/landNode.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/landNode.h
    ${CMAKE_CURRENT_SOURCE_DIR}/missionNode.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/missionNode.h
    ${CMAKE_CURRENT_SOURCE_DIR}/planSummary.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/planSummary.h
    ${CMAKE_CURRENT_SOURCE_DIR}/polygonArea.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/polygonArea.h
    ${CMAKE_CURRENT_SOURCE_DIR}/rallyManager.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/rallyManager.h
    ${CMAKE_CURRENT_SOURCE_DIR}/replayManager.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/replayManger.h
    ${CMAKE_CURRENT_SOURCE_DIR}/skydroidGimbal.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/skydroidGimbal.h
    ${CMAKE_CURRENT_SOURCE_DIR}/surveyArea.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/surveyArea.h
    ${CMAKE_CURRENT_SOURCE_DIR}/surveySetup.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/surveySetup.h
    ${CMAKE_CURRENT_SOURCE_DIR}/vehicleMissionItem.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/vehicleMissionItem.h
    ${CMAKE_CURRENT_SOURCE_DIR}/waypoint.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/waypoint.h
    ${CMAKE_CURRENT_SOURCE_DIR}/waypointCamera.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/waypointCamera.h
    CACHE STRING "" FORCE)

set(CUSTOM_INCLUDE_DIRECTORIES ${CUSTOM_INCLUDE_DIRECTORIES}
    ${CMAKE_CURRENT_SOURCE_DIR}
    CACHE INTERNAL "" FORCE
)


# ----------------------------------------------------------------------------
# QML Controls Module
# ----------------------------------------------------------------------------
qt_add_library(PlanModule STATIC
    ${CMAKE_CURRENT_SOURCE_DIR}/geoTool.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/geoTool.h
)

qgc_set_qt_resource_alias(
    ${CMAKE_CURRENT_SOURCE_DIR}/CameraParamSettings.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/FenceSettings.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LandItem.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LandSettings.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/PlanPanel.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/PlanSettings.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/PlanView.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/PolygonCenter.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/RallySettings.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/RouteLibrary.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/ShapeSettings.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/VehicleInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/VertexItem.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/WaypointCameraSettings.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/WaypointItem.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/WaypointSettings.qml
)

qt_add_qml_module(PlanModule
    URI Gises.Plan
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/CameraParamSettings.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/FenceSettings.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LandItem.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LandSettings.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/PlanPanel.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/PlanSettings.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/PlanView.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/PolygonCenter.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/RallySettings.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/RouteLibrary.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/ShapeSettings.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/VehicleInfo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/VertexItem.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/WaypointCameraSettings.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/WaypointItem.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/WaypointSettings.qml
        SOURCES
    NO_PLUGIN
)

target_link_libraries(PlanModule
    PRIVATE
    GeographicLib::GeographicLib
)

set(CUSTOM_LIBRARIES ${CUSTOM_LIBRARIES}
    PlanModule
    CACHE STRING "" FORCE)


