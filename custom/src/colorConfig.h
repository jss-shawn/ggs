
#pragma once

#include <QObject>
#include <QtGui/QColor>
#include <QtCore/QHash>
#include <QtCore/QLoggingCategory>
#include <QtQmlIntegration/QtQmlIntegration>

Q_DECLARE_LOGGING_CATEGORY(ColorConfigLog)

#define DEFINE_CC_COLOR(NAME) \
public: \
Q_PROPERTY(QColor NAME READ NAME WRITE NAME##Set NOTIFY NAME##Changed) \
    QColor NAME(); \
    void NAME##Set(const QColor& color);

class ColorConfig:public QObject{

    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")

public:
    enum Theme{
        Light = 0,
        Dark,
        ThemeSize
    };
    Q_ENUM(Theme)

    ColorConfig(QObject* parent = nullptr);

    Q_PROPERTY(Theme theme READ theme WRITE setTheme NOTIFY themeChanged FINAL)
    Q_PROPERTY(QStringList nameList READ nameList NOTIFY nameListChanged FINAL)

    Theme theme() { return _theme; }
    QStringList nameList() { return _allName; }
    void setTheme(const Theme& theme);

    Q_PROPERTY(QColor none READ none CONSTANT)
    const QColor& none() const { return _none; }

    void initAllColor();

    DEFINE_CC_COLOR(good)
    DEFINE_CC_COLOR(normal)
    DEFINE_CC_COLOR(warnning)
    DEFINE_CC_COLOR(error)
    DEFINE_CC_COLOR(normalBg)
    DEFINE_CC_COLOR(border)
    DEFINE_CC_COLOR(separator)
    DEFINE_CC_COLOR(enabled)
    DEFINE_CC_COLOR(disabled)
    DEFINE_CC_COLOR(pressed)
    DEFINE_CC_COLOR(selected)
    DEFINE_CC_COLOR(modified)
    DEFINE_CC_COLOR(dark)

signals:
    void themeChanged();
    void nameListChanged();
    void goodChanged();
    void normalChanged();
    void warnningChanged();
    void errorChanged();
    void normalBgChanged();
    void borderChanged();
    void separatorChanged();
    void enabledChanged();
    void disabledChanged();
    void pressedChanged();
    void selectedChanged();
    void modifiedChanged();
    void darkChanged();
private:
    QHash<QString, QList<QColor>> _allColor;
    QStringList _allName;
    Theme _theme = Theme::Dark;
    QColor _none = "transparent";
};
