
#pragma once

#include <QObject>

//#include "MAVLinkLib.h"
#include <mavlink.h>
#include "GCSPlanManager.h"
#include "gcsGeoFenceManager.h"
#include "gcsRallyPointManager.h"
#include "gcsReplayManger.h"
#include "GCSColorConfig.h"

class FactMetaData;
class Vehicle;
class MultiVehicleManager;
class GCSGuideAction;
class GCSNtrip;
class GCSSkydroidGimbal;
class GModuleControl;
class GCSVehicleMissionItem;

Q_DECLARE_LOGGING_CATEGORY(GCSManagerLog)

class GCSManager:public QObject{
    Q_OBJECT
public:
    Q_MOC_INCLUDE("Vehicle.h")
    Q_MOC_INCLUDE("GCSNtrip.h")
    Q_MOC_INCLUDE("gcsVehicleMissionItem.h")
    Q_MOC_INCLUDE("gcsSkydroidGimbal.h")
    Q_MOC_INCLUDE("gModuleControl.h")

    enum State{
        Normal = 0,
        Replay,
        Flying,
        Planning,
        Fence,
        Rally,
    };
    Q_ENUM(State)
    enum UIType{
        TextField = 0,
        Slider,
        Switch,
        Valuebox,
        Combobox
    };
    Q_ENUM(UIType)

    GCSManager(QObject *parent = nullptr);
    GCSManager(int firmwareType, int vehicleType, QObject* parent = nullptr);
    ~GCSManager();

    Q_PROPERTY(QString message READ message NOTIFY messageChanged FINAL)
    Q_PROPERTY(QString vmessage READ vmessage NOTIFY messageChanged FINAL)
    Q_PROPERTY(QString msgTitle READ msgTitle NOTIFY messageChanged FINAL)
    Q_PROPERTY(Vehicle* vehicle READ vehicle NOTIFY vehicleChanged FINAL)
    Q_PROPERTY(GCSNtrip* ntrip READ ntrip NOTIFY ntripChanged FINAL)
    Q_PROPERTY(GCSSkydroidGimbal* skyGimbal READ skyGimbal CONSTANT)
    Q_PROPERTY(GModuleControl* moduleControl READ moduleControl NOTIFY moduleControlChanged FINAL)
    Q_PROPERTY(GCSPlanManager* planManager READ planManager CONSTANT)
    Q_PROPERTY(GCSGeoFenceManager* geoFenceManager READ geoFenceManager CONSTANT)
    Q_PROPERTY(GCSRallyPointManager* rallyPointManager READ rallyPointManager CONSTANT)
    Q_PROPERTY(GCSReplayManager* replayManager READ replayManager CONSTANT)
    Q_PROPERTY(GCSColorConfig* colorConfig READ colorConfig CONSTANT)
    Q_PROPERTY(QString processName READ processName NOTIFY processNameChanged FINAL)
    Q_PROPERTY(double process READ process NOTIFY processChanged FINAL)
    Q_PROPERTY(int vehicleMissionCount READ vehicleMissionCount NOTIFY vehicleMissionCountChanged FINAL)
    Q_PROPERTY(int currentMissionIndex READ currentMissionIndex NOTIFY currentMissionIndexChanged FINAL)
    Q_PROPERTY(QmlObjectListModel* missionModel READ missionModel CONSTANT)
    Q_PROPERTY(QVariantList missionPath READ missionPath NOTIFY missionPathChanged FINAL)
    Q_PROPERTY(QList<GCSGuideAction*> actionList READ actionList NOTIFY actionListChanged FINAL)
    Q_PROPERTY(State state READ state WRITE setState NOTIFY stateChanged FINAL)
    Q_PROPERTY(double mapBearing READ mapBearing WRITE setMapBearing NOTIFY mapBearingChanged FINAL)

    Q_INVOKABLE void refreshPin();
    Q_INVOKABLE void setScreenPixed(qreal pixed) { _screenPixed = pixed; }
    Q_INVOKABLE void connectToNtripServer();
    Q_INVOKABLE void updateActionList();
    Q_INVOKABLE void doAction(GCSGuideAction* act);
    Q_INVOKABLE void saveToFile(const QString& fullPath);
    Q_INVOKABLE void loadFromFile(const QString& fileName);
    Q_INVOKABLE void sendToVehicle();
    Q_INVOKABLE void clearMessage(int v);

    static GCSManager* instance();
    static void registerQmlTypes();

    void init();
    const QString& message() { return _message; }
    const QString& vmessage() { return _vmessage; }
    const QString& msgTitle() { return _msgTitle; }
    Vehicle* vehicle() { return _vehicle; }
    State state() { return _state; }
    double mapBearing() { return _mapBearing; }

    GCSPlanManager* planManager() { return &_planManager; }
    GCSGeoFenceManager* geoFenceManager() { return &_geoFenceManager; }
    GCSRallyPointManager* rallyPointManager() { return &_rallyPointManager; }
    GCSReplayManager* replayManager() { return &_replayManager; }
    GCSColorConfig* colorConfig() { return &_color; }
    GCSNtrip* ntrip() { return _ntrip; }
    GCSSkydroidGimbal* skyGimbal() { return _skyGimbal; }
    GModuleControl* moduleControl() { return _moduleControl; }
    QString processName() { return _prosessName; }
    double process() { return _process; }
    int vehicleMissionCount() { return _missionList.size(); }
    int currentMissionIndex() { return _currentMissionIndex; }
    QmlObjectListModel* missionModel() { return &_missionModel; }
    QVariantList missionPath() { return _missionPath; }
    const QList<GCSGuideAction*>& actionList() { return _actionList; }
    qreal screenPixed() const { return _screenPixed; }

    void initMap();
    void sendMissions();
    void sendGeoFences();
    void sendRallyPoints();
    void setState(State st);
    void setMapBearing(double bearing);
    bool pixedEqual(qreal p1, qreal p2);
    bool pointfEqual(QPointF p1, QPointF p2);
    void updateVehicleCommandList();

    QGeoCoordinate convertCoordinate(QPointF point);
    QPointF convertCoordinate(QGeoCoordinate coor);

    FactMetaData* simpleMetaData() { return _simpleMetaData; }
    FactMetaData* commandMetaData() { return _commandMetaData; }
    FactMetaData* frameMetaData() { return _frameMetaData; }
    FactMetaData* defaultParamMetaData() { return _defaultParamMetaData; }
signals:
    void vehicleChanged();
    void vehicleCompleted();
    void messageChanged();
    void ntripChanged();
    void moduleControlChanged();
    void processNameChanged();
    void processChanged();
    void vehicleMissionCountChanged();
    void currentMissionIndexChanged();
    void missionPathChanged();
    void actionListChanged();
    void stateChanged();
    void mapBearingChanged();
public slots:
    void onShowMessage(const QString msg, const QString title);
    void updateVehicle(Vehicle* vehicle);
    void loadMissions();
    void loadGeoFences();
    void loadRallyPoints();
    void onSendMissionComplete();
    void onSendGeoFenceComplete();
    void onSendRallyPointsComplete();
    void onRemoveAll(bool success);
    void updateInProcess(bool in);
    void updateProcess(double ps);
    void updateCurrentMission(int index);
private:
    MultiVehicleManager* _vehicleManager = nullptr;
    Vehicle* _vehicle = nullptr;
    GCSNtrip* _ntrip = nullptr;
    GCSSkydroidGimbal* _skyGimbal = nullptr;
    GModuleControl* _moduleControl = nullptr;
    QString _message;
    QString _vmessage;
    QString _msgTitle;
    GCSColorConfig _color;
    GCSPlanManager _planManager;
    GCSGeoFenceManager _geoFenceManager;
    GCSRallyPointManager _rallyPointManager;
    GCSReplayManager _replayManager;
    QString _prosessName;
    double _process = 0.0;
    int _currentMissionIndex;
    QList<GCSVehicleMissionItem*> _missionList;
    QmlObjectListModel _missionModel;
    QVariantList _missionPath;
    QList<GCSGuideAction*> _actionList;
    QList<GCSGuideAction*> _allList;
    qreal _screenPixed = 1.0;

    State _state = Normal;
    bool _offline = true;

    QObject* _map = nullptr;
    double _mapBearing = 0.0;

    FactMetaData* _simpleMetaData = nullptr;
    FactMetaData* _commandMetaData = nullptr;
    FactMetaData* _frameMetaData = nullptr;
    FactMetaData* _defaultParamMetaData = nullptr;
    struct EnumInfo_s {
        const char *    label;
        MAV_FRAME       frame;
    };
    static constexpr const struct EnumInfo_s _rgMavFrameInfo[] = {
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

    QString emergencyStopTitle=            "EMERGENCY STOP";
    QString armTitle=                      "Arm";
    QString forceArmTitle=                 "Force Arm";
    QString disarmTitle=                   "Disarm";
    QString rtlTitle=                      "Return";
    QString takeoffTitle=                  "Takeoff";
    QString gripperTitle=                  "Gripper Function";
    QString landTitle=                     "Land";
    QString startMissionTitle=             "Start Mission";
    QString mvStartMissionTitle=           "Start Mission (MV)";
    QString continueMissionTitle=          "Continue Mission";
    QString resumeMissionUploadFailTitle=  "Resume FAILED";
    QString pauseTitle=                    "Pause";
    QString mvPauseTitle=                  "Pause (MV)";
    QString changeAltTitle=                "Change Altitude";
    QString changeCruiseSpeedTitle=        "Change Max Ground Speed";
    QString changeAirspeedTitle=           "Change Airspeed";
    QString orbitTitle=                    "Orbit";
    QString landAbortTitle=                "Land Abort";
    QString setWaypointTitle=              "Set Waypoint";
    QString gotoTitle=                     "Go To Location";
    QString vtolTransitionTitle=           "VTOL Transition";
    QString roiTitle=                      "ROI";
    QString setHomeTitle=                  "Set Home";
    QString actionListTitle=               "Action";
    QString setEstimatorOriginTitle=       "Set Estimator origin";
    QString setFlightMode=                 "Set Flight Mode";
    QString changeHeadingTitle=            "Change Heading";
};
