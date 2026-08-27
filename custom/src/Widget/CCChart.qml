
import QtCharts
import QtQuick
import QtQuick.Controls

import gises

Item{
    id: root
    width: parent.width
    height: parent.height

    property GCSColorConfig cc: gcsManager.colorConfig
    property alias title: name.text
    property alias yUnit: yunit.text
    property alias xUnit: xunit.text
    property alias yAxis: yaxis
    property alias xAxis: xaxis
    property alias redLine: red
    property alias greenLine: green
    property alias blueLine: blue
    property alias cusLine: cus

    function series(name){
        return chart.series(name)
    }

    Column{
        id: col
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter

        CCText{
            id: name
            alignMid: true
            font.pointSize: ui.lFontSize
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Row{
            height: ui.fontHeight
            spacing: ui.fontHeight
            anchors.horizontalCenter: parent.horizontalCenter
            id: lege
            Row{
                id: lege0
                height: parent.height
                spacing: ui.margin
                Rectangle{
                    width: parent.height
                    height: width
                    color: cus.color
                }
                CCText{
                    text: cus.name
                    anchors.verticalCenter: parent.verticalCenter
                }
                visible: cus.name.length
            }
            Row{
                id: lege1
                height: parent.height
                spacing: ui.margin
                Rectangle{
                    width: parent.height
                    height: width
                    color: red.color
                }
                CCText{
                    text: red.name
                    anchors.verticalCenter: parent.verticalCenter
                }
                visible: red.name.length
            }
            Row{
                id: lege2
                height: parent.height
                spacing: ui.margin
                Rectangle{
                    width: parent.height
                    height: width
                    color: green.color
                }
                CCText{
                    text: green.name
                    anchors.verticalCenter: parent.verticalCenter
                }
                visible: green.name.length
            }
            Row{
                id: lege3
                height: parent.height
                spacing: ui.margin
                Rectangle{
                    width: parent.height
                    height: width
                    color: blue.color
                }
                CCText{
                    text: blue.name
                    anchors.verticalCenter: parent.verticalCenter
                }
                visible: blue.name.length
            }
        }
    }
    CCText{
        id: yunit
        height: contentHeight
        alignMid: true
        anchors.bottom: chart.top
        anchors.margins: -ui.margin
    }
    CCText{
        id: xunit
        y: chart.y + chart.plotArea.y + chart.plotArea.height + 4
        height: ui.fontHeight
        anchors.right: parent.right
    }
    ChartView{
        id: chart
        anchors.top: col.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        margins.top: 0
        margins.bottom: 0
        margins.left: 0
        margins.right: xunit.width
        backgroundColor: cc.none
        antialiasing: true
        legend.visible: false
        ValuesAxis{
            id: yaxis
            min: 0
            max: 1
            tickCount: 5
            labelFormat: "%.2f"
            labelsColor: cc.normal
            color: cc.border
            gridLineColor: cc.border
        }
        ValuesAxis{
            id: xaxis
            min: 0
            max: 0
            tickCount: 6
            labelFormat: "%.2f"
            labelsColor: cc.normal
            color: cc.border
            gridLineColor: cc.border
        }
        LineSeries {
            id: red
            color: "red"
            axisX: xaxis
            axisY: yaxis
        }
        LineSeries {
            id: green
            color: "lime"
            axisX: xaxis
            axisY: yaxis
        }
        LineSeries {
            id: blue
            color: "aqua"
            axisX: xaxis
            axisY: yaxis
        }
        LineSeries {
            id: cus
            color: "aqua"
            axisX: xaxis
            axisY: yaxis
        }
    }
}
