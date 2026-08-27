
# ----------------------------------------------------------------------------
# QML Controls Module
# ----------------------------------------------------------------------------
qt_add_library(PanelModule STATIC)

#set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/CustomArtificialHorizon.qml PROPERTIES QT_RESOURCE_ALIAS CustomArtificialHorizon.qml)

qgc_set_qt_resource_alias(
    ${CMAKE_CURRENT_SOURCE_DIR}/AppLayerBackground.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/AppLayerMainUi.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/AppLayerNotice.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/AppLayerVideo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/AppLayerWidget.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/AppOptions.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/GeneralSet.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LeftOption.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LinkSet.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/MapSet.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/VideoSet.qml
)

qt_add_qml_module(PanelModule
    URI Gises.Panel
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/AppLayerBackground.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/AppLayerMainUi.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/AppLayerNotice.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/AppLayerVideo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/AppLayerWidget.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/AppOptions.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/GeneralSet.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LeftOption.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LinkSet.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/MapSet.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/VideoSet.qml
    NO_PLUGIN
)

set(CUSTOM_LIBRARIES ${CUSTOM_LIBRARIES}
    PanelModule
    CACHE STRING "" FORCE)
