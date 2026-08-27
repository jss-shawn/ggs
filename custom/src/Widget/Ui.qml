pragma Singleton

import QtQuick
import QtQuick.Window

import QGroundControl

Item{
    id: root

    property bool isAndroid:                        ScreenToolsController.isAndroid
    property bool isiOS:                            ScreenToolsController.isiOS
    property bool isMobile:                         ScreenToolsController.isMobile
    property bool isFakeMobile:                     ScreenToolsController.fakeMobile
    property bool isWindows:                        ScreenToolsController.isWindows
    property bool isDebug:                          ScreenToolsController.isDebug
    property bool isMac:                            ScreenToolsController.isMacOS
    property bool isLinux:                          ScreenToolsController.isLinux
    //property bool isTinyScreen:                     (Screen.width / realPixelDensity) < 120 // 120mm
    //property bool isShortScreen:                    ((Screen.height / realPixelDensity) < 120) || (ScreenToolsController.isMobile && ((Screen.height / Screen.width) < 0.6))
    //property bool isHugeScreen:                     (Screen.width / realPixelDensity) >= (23.5 * 25.4) // 27" monitor
    property bool isSerialAvailable: ScreenToolsController.isSerialAvailable
    property double defaultFontDescent: ScreenToolsController.defaultFontDescent(fontSize)
    // property double widthMM: ScreenToolsController.widthMM
    // property double heightMM: ScreenToolsController.heightMM
    // property double phydpi: ScreenToolsController.phydpi
    // property double phydpix: ScreenToolsController.phydpix
    // property double phydpiy: ScreenToolsController.phydpiy
    // property double lgidpi: ScreenToolsController.lgidpi
    // property double lgidpix: ScreenToolsController.lgidpix
    // property double lgidpiy: ScreenToolsController.lgidpiy

    //Physical Screen Info
    property real serialNumber: Screen.serialNumber
    property real manufacturer: Screen.manufacturer
    property real model: Screen.model
    property real name: Screen.name
    property real orientation: Screen.orientation
    property real primaryOrientation: Screen.primaryOrientation
    property real desktopAvailableWidth: Screen.desktopAvailableWidth
    property real desktopAvailableHeight: Screen.desktopAvailableHeight
    property real virtualX: Screen.virtualX
    property real virtualY: Screen.virtualY
    property real pixelDensity: Screen.pixelDensity
    property real logicalPixelDensity: Screen.logicalPixelDensity
    property real devicePixelRatio: Screen.devicePixelRatio

    //screen info of qt got
    property real screenRatio: Screen.devicePixelRatio
    property real logicalWidth:  isFakeMobile ? 853 : Screen.width
    property real logicalHeight: isFakeMobile ? 533 : Screen.height
    property real physicalWidth:  Math.ceil(logicalWidth * screenRatio / 10) * 10
    property real physicalHeight:  Math.ceil(logicalHeight * screenRatio / 10) * 10
    //标准应用尺寸设置
    //将标准应用宽度设置为至少填充140个大写字符C
    //安卓字体,全体字符宽高一致,高度 ≈ 宽 * 3
    property string fontFamily: siyuan.name		//字体:思源黑体
    property int minimCharCount: physicalWidth < 1024 ? 90 : physicalWidth > 1920 ? 150 : 120

    property real defaultFontPointSize: defaultFont.font.pointSize
    property real defaultFontPixelSize: defaultFont.font.pixelSize
    property real defaultFontWidth: defaultFont.width
    property real defaultFontHeight: defaultFont.height
    property string defaultFontFamily: defaultFont.font.family

    property font font: siyuan.font
    property real fontPointSize: defaultFontPointSize
    property real fontPixelSize: defaultFontPixelSize
    property real ssFontSize: fontSize - 2
    property real sFontSize: fontSize - 1
    property real fontSize: fontPointSize
    property real lFontSize: fontSize + 1
    property real llFontSize: fontSize + 2

    property real fontWidth: afont.width.toFixed(2)
    property real fontHeight: afont.height.toFixed(2)
    property real margin: Math.ceil(afont.width / 2)
    property real x2margin: margin * 2
    property real radius: margin
    property real spacing: Math.ceil(afont.width / 4)

    Component.onCompleted: {
    }

    FontLoader{
        id: siyuan
        source: "/fonts/SourceHanSansCN-Normal.ttf"
    }
    Text{
        id: defaultFont
        text: "0"
    }
    Text{
        id: afont
        text: "0"
        font.pointSize: fontPointSize
    }
}
