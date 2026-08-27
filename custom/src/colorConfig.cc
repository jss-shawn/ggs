
#include "colorConfig.h"

Q_LOGGING_CATEGORY(ColorConfigLog, "ColorConfigLog")

#define DECLARE_CC_COLOR(NAME) \
QColor ColorConfig::NAME() \
    { \
        QColor color(0x00, 0x00, 0x00); \
        if (_allColor.contains(#NAME)) { \
            color = _allColor.value(#NAME).at(_theme); \
        } \
        return color; \
    } \
    void ColorConfig::NAME##Set(const QColor& color) \
    { \
        if (_allColor.contains(#NAME) && _allColor.value(#NAME).at(_theme) != color) { \
            _allColor.value(#NAME).replace(_theme, color); \
            emit NAME##Changed(); \
        } \
    }

ColorConfig::ColorConfig(QObject* parent)
    :QObject(parent)
{
    if (_allColor.empty()) {
        initAllColor();
    }
}

void ColorConfig::initAllColor()
{
    //         Name                 Light                     Dark
    _allColor.insert("good",      { QColor(0x00, 0x00, 0x00), QColor(0x00, 0xff, 0x00) }); //QColor("#00ff00") QColor("#000000")
    _allColor.insert("normal",    { QColor(0x00, 0x00, 0x00), QColor(0xff, 0xff, 0xff) }); //QColor("#000000") QColor("#000000")
    _allColor.insert("warnning",  { QColor(0x00, 0x00, 0x00), QColor(0xff, 0xbb, 0x00) }); //QColor("#ffbb00") QColor("#000000")
    _allColor.insert("error",     { QColor(0x00, 0x00, 0x00), QColor(0xff, 0x00, 0x00) }); //QColor("#ff0000") QColor("#000000")
    _allColor.insert("normalBg",  { QColor(0x00, 0x00, 0x00), QColor(0x22, 0x22, 0x22) }); //QColor("#222222") QColor("#000000")
    _allColor.insert("border",    { QColor(0x00, 0x00, 0x00), QColor(0xdc, 0xdc, 0xdc) }); //QColor("#dcdcdc") QColor("#000000")
    _allColor.insert("separator", { QColor(0x00, 0x00, 0x00), QColor(0xcb, 0xcb, 0xcb) }); //QColor("#cbcbcb") QColor("#000000")
    _allColor.insert("enabled",   { QColor(0x00, 0x00, 0x00), QColor(0xff, 0xff, 0xff) }); //QColor("#ffffff") QColor("#000000")
    _allColor.insert("disabled",  { QColor(0x00, 0x00, 0x00), QColor(0x5e, 0x5e, 0x5e) }); //QColor("#5e5e5e") QColor("#000000")
    _allColor.insert("pressed",   { QColor(0x00, 0x00, 0x00), QColor(0xff, 0xff, 0x66) }); //QColor("#44fff6") QColor("#000000")
    _allColor.insert("selected",  { QColor(0x00, 0x00, 0x00), QColor(0x00, 0xff, 0xee) }); //QColor("#00ffee") QColor("#000000")
    _allColor.insert("modified",  { QColor(0x00, 0x00, 0x00), QColor(0xff, 0x6e, 0x4b) }); //QColor("#ff6e4b") QColor("#000000")
    _allColor.insert("dark",      { QColor(0x00, 0x00, 0x00), QColor(0x33, 0x33, 0x33) }); //QColor("#ff6e4b") QColor("#000000")

    QHash<QString, QList<QColor>>::iterator itor = _allColor.begin();
    for(; itor != _allColor.end(); ++itor) {
        _allName.append(itor.key());
    }
    emit nameListChanged();
}

void ColorConfig::setTheme(const Theme& theme)
{
    if (theme < Theme::ThemeSize && _theme != theme) {
        _theme = theme;
        emit themeChanged();
    }
}

DECLARE_CC_COLOR(good)
DECLARE_CC_COLOR(normal)
DECLARE_CC_COLOR(warnning)
DECLARE_CC_COLOR(error)
DECLARE_CC_COLOR(normalBg)
DECLARE_CC_COLOR(border)
DECLARE_CC_COLOR(separator)
DECLARE_CC_COLOR(enabled)
DECLARE_CC_COLOR(disabled)
DECLARE_CC_COLOR(pressed)
DECLARE_CC_COLOR(selected)
DECLARE_CC_COLOR(modified)
DECLARE_CC_COLOR(dark)
