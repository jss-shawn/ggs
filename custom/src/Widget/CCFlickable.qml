
import QtQuick
import QtQuick.Controls

Flickable{
    id:	root
    width: parent.width
    height: parent.height
    contentWidth: fixedWidth ? width - ui.margin : contWidth
    contentHeight: fixedHeight ? height - ui.margin : contHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    property bool fixedWidth: false
    property bool fixedHeight: false
    property real contWidth: contentItem.children.length ? contentItem.children[0].width : 0
    property real contHeight: contentItem.children.length ? contentItem.children[0].height : 0

    ScrollIndicator.horizontal: ScrollIndicator{active: true}
    ScrollIndicator.vertical: ScrollIndicator{active: true}
}
