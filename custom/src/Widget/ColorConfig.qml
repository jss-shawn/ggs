
pragma Singleton

import QtQuick

Item{
    property int abc: 1
    property bool themeDark: true

    property color good: lt.good
    property color normal: "#000000"
    property color warnning: "#000000"
    property color error: "#000000"
    property color normalBg: "#000000"
    property color border: "#000000"
    property color separator: "#000000"
    property color enabled: "#000000"
    property color disabled: "#000000"
    property color pressed: "#000000"
    property color selected: "#000000"
    property color modified: "#000000"
    property color dark: "#000000"

    QtObject{
        id: lt
        property color good: "#000000"
        property color normal: "#000000"
        property color warnning: "#000000"
        property color error: "#000000"
        property color normalBg: "#000000"
        property color border: "#000000"
        property color separator: "#000000"
        property color enabled: "#000000"
        property color disabled: "#000000"
        property color pressed: "#000000"
        property color selected: "#000000"
        property color modified: "#000000"
        property color dark: "#000000"
    }
    QtObject{
        id: dk
        property color good: "#000000"
        property color normal: "#000000"
        property color warnning: "#000000"
        property color error: "#000000"
        property color normalBg: "#000000"
        property color border: "#000000"
        property color separator: "#000000"
        property color enabled: "#000000"
        property color disabled: "#000000"
        property color pressed: "#000000"
        property color selected: "#000000"
        property color modified: "#000000"
        property color dark: "#000000"
    }
}
