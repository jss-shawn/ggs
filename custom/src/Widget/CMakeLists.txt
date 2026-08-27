
# ----------------------------------------------------------------------------
# QML Controls Module
# ----------------------------------------------------------------------------
qt_add_library(WidgetModule STATIC)

#set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/CustomArtificialHorizon.qml PROPERTIES QT_RESOURCE_ALIAS CustomArtificialHorizon.qml)

set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/Ui.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE)

qgc_set_qt_resource_alias(
    ${CMAKE_CURRENT_SOURCE_DIR}/BatteryInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCButton.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCComboBox.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCFlickable.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCMouseArea.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCMultiSwitch.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCSeparator.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCSlider.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCSwitchButton.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCText.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCTextField.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CCValueBox.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/CriticalStatusBar.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/ForwardInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/GimbalInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/GpsInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LabelComboBox.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LabelMultiSwitch.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LabelSlider.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LabelSwitchButton.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LabelTextField.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LabelValueBox.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/LinkInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/MapTool.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/MessageInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/RCInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/RemoteIDInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/TelemetryRSSIInfo.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/Ui.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/VideoDisplay.qml
)

qt_add_qml_module(WidgetModule
    URI Gises.Widget
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/CCButton.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/BatteryInfo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CCComboBox.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CCFlickable.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CCMouseArea.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CCMultiSwitch.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CCSeparator.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CCSlider.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CCSwitchButton.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CCText.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CCTextField.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CCValueBox.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/CriticalStatusBar.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/ForwardInfo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/GimbalInfo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/GpsInfo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LabelComboBox.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LabelMultiSwitch.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LabelSlider.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LabelSwitchButton.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LabelTextField.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LabelValueBox.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/LinkInfo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/MapTool.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/MessageInfo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/RCInfo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/RemoteIDInfo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/TelemetryRSSIInfo.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/Ui.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/VideoDisplay.qml
    NO_PLUGIN
)

set(CUSTOM_LIBRARIES ${CUSTOM_LIBRARIES}
    WidgetModule
    CACHE STRING "" FORCE)
