
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl

import QGroundControl

ComboBox{
    id: root

    implicitWidth: ui.fontWidth * 8
    height: contentItem.height

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property int fontSize: ui.fontSize

    background: Rectangle{
        radius: ui.radius
        color: cc.none
        border.color: cc.border
    }
    //选项结果
    contentItem: CCText{
        width: root.width - height
        height: contentHeight + ui.x2margin
        leftPadding: ui.margin
        rightPadding: ui.margin
        text: currentText
        elide: Text.ElideRight
        alignMid: true
        font.pointSize: fontSize
    }
    //下拉指示资源
    indicator: IconLabel{
        width: root.height
        height: width
        icon.source: "/icon/arrow_down.svg"
        defaultIconColor: cc.normal
        anchors.right: parent.right
    }
    //下拉列表填充控件
    delegate: ItemDelegate{
        id: dlg
        width: root.width
        height: root.contentItem.height
        contentItem: CCText{
            anchors.fill: parent
            text: textRole ? (Array.isArray(model) ? model[textRole] : modelData[textRole]) : modelData
            color: index === currentIndex ? cc.selected : cc.enabled
            alignMid: true
            elide: Text.ElideRight
            font.pointSize: fontSize
        }
    }
    //下拉列表
    popup: Popup{
        y: root.height
        width: root.width
        height: root.contentItem.height * (model.length > 4 ? 4.5 : model.length)
        padding: 0
        background: Rectangle{
            radius: ui.radius
            color: cc.normalBg
            border.color: cc.border
        }
        contentItem: ListView{
            model: delegateModel
            currentIndex: root.highlightedIndex
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            highlight: Rectangle{
                radius: ui.radius
                color: cc.none
                border.color: cc.selected
            }
        }
    }
}
