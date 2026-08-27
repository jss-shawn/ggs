
import QtQuick
import QtQuick.Controls

Text{
    id: root

    property Ui ui: Ui
    property bool alignMid: false
    property bool alignRight: false

    antialiasing: true
    color: enabled ? clcfg.enabled : clcfg.disabled
    font.family: ui.fontFamily
    font.pointSize: ui.fontSize

    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: alignMid ? Text.AlignHCenter : (alignRight ? Text.AlignRight : Text.AlignLeft)
}
