
#pragma once

#include <mavlink.h>
#include <QObject>
#include <QtQmlIntegration/QtQmlIntegration>
#include "colorConfig.h"

Q_DECLARE_LOGGING_CATEGORY(GCSManagerLog)

class ColorConfig;
class FactMetaData;
class FenceManager;
class GisesPlan;
class QmlObjectListModel;
class RallyManager;
class Vehicle;
class VehicleMissionItem;

class GisesManager : public QObject{

    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
    Q_MOC_INCLUDE("Vehicle.h")
    Q_MOC_INCLUDE("fenceManager.h")
    Q_MOC_INCLUDE("gisesPlan.h")
    Q_MOC_INCLUDE("rallyManager.h")
    Q_MOC_INCLUDE("colorConfig.h")
public:

    explicit GisesManager(QObject* parent = nullptr);

    void init();

    Q_PROPERTY(ColorConfig* colorConfig READ colorConfig CONSTANT)
    Q_PROPERTY(Vehicle* vehicle READ vehicle NOTIFY vehicleChanged)
    Q_PROPERTY(FenceManager* fenceManager READ fenceManager CONSTANT)
    Q_PROPERTY(GisesPlan* planManager READ planManager CONSTANT)
    Q_PROPERTY(RallyManager* rallyManager READ rallyManager CONSTANT)
    Q_PROPERTY(QmlObjectListModel* missionModel READ missionModel CONSTANT)
    Q_PROPERTY(QVariantList missionPath READ missionPath NOTIFY missionPathChanged FINAL)
    Q_PROPERTY(QObject* currentManager READ currentManager WRITE setCurrentManager NOTIFY currentManagerChanged)

    ColorConfig* colorConfig() { return _colorConfig; }
    Vehicle* vehicle() { return _vehicle; }
    FenceManager* fenceManager() { return _fence; }
    GisesPlan* planManager() { return _plan; }
    RallyManager* rallyManager() { return _rally; }
    QmlObjectListModel* missionModel() { return _missionModel; }
    QVariantList missionPath() { return _missionPath; }
    QObject* currentManager() { return _currentManager; }

    void setCurrentManager(QObject* manager);

    // Q_INVOKABLE void updateActionList();
    // Q_INVOKABLE void doAction(GCSGuideAction* act);
    Q_INVOKABLE void saveToFile(const QString& fullPath);
    Q_INVOKABLE void loadFromFile(const QString& fileName);
    Q_INVOKABLE void sendToVehicle();

    FactMetaData* commandMetaData() { return  _commandMetaData; }
    FactMetaData* defaultParamMetaData() { return _defaultParamMetaData; }
    FactMetaData* frameMetaData() { return _frameMetaData; }
    FactMetaData* simpleMetaData() { return _simpleMetaData;}

    void sendFences();
    void sendMissions();
    void sendRallys();

    void updateVehicleCommandList();
signals:
    void currentManagerChanged();
    void vehicleCompleted();
    void currentMissionIndexChanged();
    void processChanged();
    void processNameChanged();
    void vehicleMissionCountChanged();
    void missionPathChanged();
    void vehicleChanged();
public slots:
    void updateVehicle(Vehicle* vehicle);
    void loadMissions();
    void loadGeoFences();
    void loadRallyPoints();
    void onSendMissionComplete();
    void onSendFenceComplete();
    void onSendRallyComplete();
    void onRemoveAll(bool success);
    void updateInProcess(bool in);
    void updateProcess(double ps);
    void updateCurrentMission(int index);

private:
    ColorConfig* _colorConfig = nullptr;
    Vehicle* _vehicle = nullptr;
    FenceManager* _fence = nullptr;
    GisesPlan* _plan = nullptr;
    RallyManager* _rally = nullptr;
    QObject* _currentManager = nullptr;
    double _process = 0;
    QString _processName;

    FactMetaData* _simpleMetaData = nullptr;
    FactMetaData* _commandMetaData = nullptr;
    FactMetaData* _frameMetaData = nullptr;
    FactMetaData* _defaultParamMetaData = nullptr;

    QmlObjectListModel* _missionModel = nullptr;
    int _currentMissionIndex = 0;
    QList<VehicleMissionItem*> _missionList;
    QVariantList _missionPath;

    struct EnumInfo_s {
        const char *    label;
        MAV_FRAME       frame;
    };
    static constexpr const struct EnumInfo_s _rgMavFrameInfo[] =
        {
          { "MAV_FRAME_GLOBAL",                   MAV_FRAME_GLOBAL },
          { "MAV_FRAME_LOCAL_NED",                MAV_FRAME_LOCAL_NED },
          { "MAV_FRAME_MISSION",                  MAV_FRAME_MISSION },
          { "MAV_FRAME_GLOBAL_RELATIVE_ALT",      MAV_FRAME_GLOBAL_RELATIVE_ALT },
          { "MAV_FRAME_LOCAL_ENU",                MAV_FRAME_LOCAL_ENU },
          { "MAV_FRAME_GLOBAL_INT",               MAV_FRAME_GLOBAL_INT },
          { "MAV_FRAME_GLOBAL_RELATIVE_ALT_INT",  MAV_FRAME_GLOBAL_RELATIVE_ALT_INT },
          { "MAV_FRAME_LOCAL_OFFSET_NED",         MAV_FRAME_LOCAL_OFFSET_NED },
          { "MAV_FRAME_BODY_NED",                 MAV_FRAME_BODY_NED },
          { "MAV_FRAME_BODY_OFFSET_NED",          MAV_FRAME_BODY_OFFSET_NED },
          { "MAV_FRAME_GLOBAL_TERRAIN_ALT",       MAV_FRAME_GLOBAL_TERRAIN_ALT },
          { "MAV_FRAME_GLOBAL_TERRAIN_ALT_INT",   MAV_FRAME_GLOBAL_TERRAIN_ALT_INT },
        };
};