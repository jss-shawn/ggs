# ============================================================================
# Gises PlanView Module
# ============================================================================

set(CUSTOM_SOURCES ${CUSTOM_SOURCES}
    ${CMAKE_CURRENT_SOURCE_DIR}/tuningControl.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/tuningControl.h
    CACHE STRING "" FORCE)

set(CUSTOM_INCLUDE_DIRECTORIES ${CUSTOM_INCLUDE_DIRECTORIES}
    ${CMAKE_CURRENT_SOURCE_DIR}
    CACHE INTERNAL "" FORCE
)


# ----------------------------------------------------------------------------
# QML Controls Module
# ----------------------------------------------------------------------------
qt_add_library(VehicleModule STATIC
    #${CMAKE_CURRENT_SOURCE_DIR}/geoTool.cc
    #${CMAKE_CURRENT_SOURCE_DIR}/geoTool.h
)

qgc_set_qt_resource_alias(
    ${CMAKE_CURRENT_SOURCE_DIR}/VehicleConfig.qml
)

qt_add_qml_module(VehicleModule
    URI Gises.Vehicle
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/VehicleConfig.qml
        SOURCES
    NO_PLUGIN
)

target_link_libraries(VehicleModule
    PRIVATE
    GeographicLib::GeographicLib
)

set(CUSTOM_LIBRARIES ${CUSTOM_LIBRARIES}
    VehicleModule
    CACHE STRING "" FORCE)

# # ----------------------------------------------------------------------------
# # Control Configuration Resources
# # ----------------------------------------------------------------------------
# qgc_add_json_resources(json_controls)

# qt_add_resources(QGroundControlControlsModule qmlcontrols_resources
#     PREFIX "/res"
#     BASE "${CMAKE_SOURCE_DIR}/resources"
#     FILES
#         "${CMAKE_SOURCE_DIR}/resources/ArrowRight.svg"
#         "${CMAKE_SOURCE_DIR}/resources/buttonRight.svg"
#         "${CMAKE_SOURCE_DIR}/resources/chevron-down.svg"
#         "${CMAKE_SOURCE_DIR}/resources/chevron-up.svg"
#         "${CMAKE_SOURCE_DIR}/resources/clockwise-arrow.svg"
#         "${CMAKE_SOURCE_DIR}/resources/counter-clockwise-arrow.svg"
#         "${CMAKE_SOURCE_DIR}/resources/JoystickBezelLight.png"
# )

# # subMenuButtonImage.png aliases the shared CogWheels.png at the repo root.
# set_source_files_properties("${CMAKE_SOURCE_DIR}/resources/CogWheels.png"
#     PROPERTIES QT_RESOURCE_ALIAS "subMenuButtonImage.png")

# qt_add_resources(QGroundControlControlsModule qmlcontrols_qmlimages
#     PREFIX "/qmlimages"
#     BASE "${CMAKE_CURRENT_SOURCE_DIR}"
#     FILES
#         "${CMAKE_CURRENT_SOURCE_DIR}/arrow-down.png"
#         "${CMAKE_CURRENT_SOURCE_DIR}/checkbox-check.svg"
#         "${CMAKE_SOURCE_DIR}/resources/CogWheels.png"
# )

# # Globbed because FactValueGrid enumerates :/InstrumentValueIcons/ at runtime
# # to build the icon picker — every SVG in the directory must be embedded.
# file(GLOB INSTRUMENT_VALUE_ICONS CONFIGURE_DEPENDS
#     "${CMAKE_SOURCE_DIR}/resources/InstrumentValueIcons/*.svg"
# )
# qt_add_resources(QGroundControlControlsModule instrument_value_icons
#     PREFIX "/InstrumentValueIcons"
#     BASE "${CMAKE_SOURCE_DIR}/resources/InstrumentValueIcons"
#     FILES ${INSTRUMENT_VALUE_ICONS}
# )
