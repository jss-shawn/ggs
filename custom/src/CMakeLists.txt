# ============================================================================
# Gises Module Build
# ============================================================================

qt_add_library(GisesModule STATIC)

set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/MainWindow.qml PROPERTIES QT_RESOURCE_ALIAS MainWindow.qml)
set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/WindowState.qml PROPERTIES QT_RESOURCE_ALIAS WindowState.qml)

qt_add_qml_module(GisesModule
    URI Gises
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/MainWindow.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/WindowState.qml
    #IMPORTS
    #    QGC
    NO_PLUGIN
)

# ----------------------------------------------------------------------------
# Source File
# ----------------------------------------------------------------------------

set(CUSTOM_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/colorConfig.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/colorConfig.h
    ${CMAKE_CURRENT_SOURCE_DIR}/gisesManager.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/gisesManager.h
    ${CMAKE_CURRENT_SOURCE_DIR}/gisesPlugin.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/gisesPlugin.h
    CACHE INTERNAL "" FORCE
)

# ----------------------------------------------------------------------------
# Build Configuration
# ----------------------------------------------------------------------------

set(CUSTOM_LIBRARIES
    Qt6::Graphs
    GisesModule
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    ${CMAKE_CURRENT_SOURCE_DIR}
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_DEFINITIONS
    QGC_CUSTOM_BUILD
    CUSTOMHEADER="gisesPlugin.h"
    CUSTOMCLASS=GisesPlugin
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_QT_COMPONENTS
    Core Graphs
    CACHE INTERNAL "" FORCE
)

# ============================================================================
# Subdirectories
# ============================================================================

# Core subsystems
add_subdirectory(AutoPilotPlugin)
add_subdirectory(FirmwarePlugin)
add_subdirectory(FlyManager)
add_subdirectory(MissionManager)
add_subdirectory(Panel)
add_subdirectory(PlanManager)
add_subdirectory(VehicleManager)
add_subdirectory(Widget)