#pragma once

#include <QtCore/QTranslator>
#include <QtQml/QQmlAbstractUrlInterceptor>

#include "QGCCorePlugin.h"
#include "QGCOptions.h"

class ComplexMissionItem;
class PlanCreator;

class GisesManager;
class GisesOptions;
class GisesPlugin;
class GisesSettings;
class QQmlApplicationEngine;

Q_DECLARE_LOGGING_CATEGORY(GisesLog)

class GisesFlyViewOptions : public QGCFlyViewOptions
{
    Q_OBJECT

public:
    explicit GisesFlyViewOptions(GisesOptions *options, QObject *parent = nullptr);

    // Overrides from GisesFlyViewOptions

    /// This custom build has it's own custom instrument panel. Don't show regular one.
    bool showInstrumentPanel() const final { return false; }
    /// This custom build does not support conecting multiple vehicles to it.
    /// This in turn simplifies various parts of the QGC ui.
    bool showMultiVehicleList() const final { return false; }
};

/*===========================================================================*/

class GisesOptions : public QGCOptions
{
    Q_OBJECT

public:
    explicit GisesOptions(GisesPlugin *plugin, QObject *parent = nullptr);

    // Overrides from QGCOptions

    /// Firmware upgrade page is only shown in Advanced Mode.
    bool showFirmwareUpgrade() const final { return _plugin->showAdvancedUI(); }
    QGCFlyViewOptions *flyViewOptions() const final { return _flyViewOptions; }

private:
    QGCCorePlugin *_plugin = nullptr;
    GisesFlyViewOptions *_flyViewOptions = nullptr;
};

/*===========================================================================*/

class GisesPlugin : public QGCCorePlugin
{
    Q_OBJECT
    Q_MOC_INCLUDE("gisesManager.h")

public:
    explicit GisesPlugin(QObject *parent = nullptr);

    static QGCCorePlugin *instance();

    Q_PROPERTY(GisesManager* gises READ gises CONSTANT)

    GisesManager* gises() { return _gises; }
    // Overrides from QGCCorePlugin

    void init() final;
    void cleanup() final;
    QGCOptions *options() final { return _options; }
    /// This allows you to override/hide QGC Application settings
    void adjustSettingMetaData(const QString &settingsGroup, FactMetaData &metaData, bool &userVisible) final;
    /// This modifies QGC colors palette to match possible custom corporate branding
    void paletteOverride(const QString &colorName, QGCPalette::PaletteColorInfo_t &colorInfo) final;
    /// We override this so we can get access to QQmlApplicationEngine and use it to register our qml module
    QQmlApplicationEngine *createQmlApplicationEngine(QObject *parent) final;
    /// Giese root window
    void createRootWindow(QQmlApplicationEngine *qmlEngine) final;

    /// Adds the Perimeter Scan item to the complex-item menu.
    QVariantList complexMissionItemNames(Vehicle *vehicle) final;
    /// Factory: creates PerimeterScanComplexItem for our custom type, falls back to base for built-ins.
    ComplexMissionItem *createComplexMissionItem(const QString &complexItemType,
                                                 PlanMasterController *masterController,
                                                 bool flyView,
                                                 const QString &kmlOrShpFile = QString()) final;
    /// Adds the Perimeter Scan plan creator to the New Plan dialog.
    QList<PlanCreator *> planCreators(PlanMasterController *planMasterController) final;

private slots:
    void _advancedChanged(bool advanced);

private:
    void _addSettingsEntry(const QString& title, const char* qmlFile, const char* iconFile = nullptr);

    GisesManager* _gises = nullptr;
    GisesOptions *_options = nullptr;
    QQmlApplicationEngine *_qmlEngine = nullptr;
    class GisesOverrideInterceptor *_selector = nullptr;
    QVariantList _settingsList; // Not to be mixed up with QGCCorePlugin implementation
};

/*===========================================================================*/

class GisesOverrideInterceptor : public QQmlAbstractUrlInterceptor
{
public:
    GisesOverrideInterceptor();

    QUrl intercept(const QUrl &url, QQmlAbstractUrlInterceptor::DataType type) final;
};
