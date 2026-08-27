# ============================================================================
# Gises FlightView Module
# ============================================================================

set(CUSTOM_SOURCES ${CUSTOM_SOURCES}
    CACHE STRING "" FORCE)

set(CUSTOM_INCLUDE_DIRECTORIES ${CUSTOM_INCLUDE_DIRECTORIES}
    ${CMAKE_CURRENT_SOURCE_DIR}
    CACHE INTERNAL "" FORCE
)

# ----------------------------------------------------------------------------
# QML Controls Module
# ----------------------------------------------------------------------------
qt_add_library(FlyModule STATIC)

qgc_set_qt_resource_alias(
    ${CMAKE_CURRENT_SOURCE_DIR}/FlyView.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/VehicleMissionItem.qml
)

qt_add_qml_module(FlyModule
    URI Gises.Fly
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/FlyView.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/VehicleMissionItem.qml
    NO_PLUGIN
)

set(CUSTOM_LIBRARIES ${CUSTOM_LIBRARIES}
    FlyModule
    CACHE STRING "" FORCE)