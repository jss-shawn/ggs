
#include <QCoreApplication>
#include <QQmlContext>
#include <QQuickWindow>
#include <QtCore/qapplicationstatic.h>
#include <QtQml/QQmlApplicationEngine>
#include "QGCApplication.h"
#include "FirmwarePlugin.h"
#include "JsonHelper.h"
#include "Vehicle.h"
#include "MultiVehicleManager.h"
#include "MissionCommandUIInfo.h"
#include "MissionCommandTree.h"
#include "MissionManager.h"
#include "GeoFenceManager.h"
#include "RallyPointManager.h"
#include "SettingsManager.h"
#include "AppSettings.h"
#include "GCSNtrip.h"
#include "GCSCameraInfo.h"
#include "GCSManager.h"
#include "GCSGuideAction.h"
#include "gcsVehicleMissionItem.h"
#include "gcsTuningControl.h"
#include "gcsSkydroidGimbal.h"
#include "gModuleControl.h"

Q_LOGGING_CATEGORY(GCSMangerLog,"GCSManagerLog")

Q_APPLICATION_STATIC(GCSManager, _gcsManager);

GCSManager::GCSManager(QObject* parent)
    :QObject(parent)
    ,_vehicleManager(MultiVehicleManager::instance())
    ,_vehicle(MultiVehicleManager::instance()->offlineEditingVehicle())
    ,_ntrip(new GCSNtrip(this))
    ,_skyGimbal(new GCSSkydroidGimbal(this))
    ,_moduleControl(new GModuleControl(this))
    ,_color(this)
    ,_planManager(this)
    ,_geoFenceManager(this)
    ,_rallyPointManager(this)
    ,_replayManager(this)
    ,_simpleMetaData(new FactMetaData(FactMetaData::valueTypeUint32))
    ,_commandMetaData(new FactMetaData(FactMetaData::valueTypeUint32))
    ,_frameMetaData(new FactMetaData(FactMetaData::valueTypeDouble))
    ,_defaultParamMetaData(new FactMetaData(FactMetaData::valueTypeDouble))
{
    _defaultParamMetaData->setDecimalPlaces(7);
}

GCSManager::GCSManager(int firmwareType, int vehicleType, QObject* parent)
    :QObject(parent)
    ,_vehicleManager(MultiVehicleManager::instance())
    ,_vehicle(new Vehicle((MAV_AUTOPILOT)firmwareType, (MAV_TYPE)vehicleType, this))
    ,_ntrip(new GCSNtrip(this))
    ,_moduleControl(new GModuleControl(this))
    ,_color(this)
    ,_planManager(this)
    ,_geoFenceManager(this)
    ,_rallyPointManager(this)
    ,_simpleMetaData(new FactMetaData(FactMetaData::valueTypeUint32))
    ,_commandMetaData(new FactMetaData(FactMetaData::valueTypeUint32))
    ,_frameMetaData(new FactMetaData(FactMetaData::valueTypeDouble))
    ,_defaultParamMetaData(new FactMetaData(FactMetaData::valueTypeDouble))
{
    _defaultParamMetaData->setDecimalPlaces(7);
}

GCSManager::~GCSManager(){

}

GCSManager* GCSManager::instance(){
    return _gcsManager;
}

void GCSManager::registerQmlTypes(){
    qmlRegisterUncreatableType<GCSManager>("gises", 1, 0, "GCSManager", "Reference only");
    qmlRegisterUncreatableType<GCSColorConfig>("gises", 1, 0, "GCSColorConfig", "Reference only");
    qmlRegisterUncreatableType<GCSCameraInfo>("gises", 1, 0, "GCSCameraInfo", "Reference only");
    qmlRegisterUncreatableType<GCSNtrip>("gises", 1, 0, "GCSNtrip", "Reference only");
    qmlRegisterUncreatableType<GCSGuideAction>("gises", 1, 0, "GCSGuideAction", "Reference only");
    qmlRegisterUncreatableType<GCSReplayManager>("gises", 1, 0, "GCSReplayManager", "Reference only");
    qmlRegisterUncreatableType<GCSVehicleMissionItem>("gises", 1, 0, "GCSVehicleMissionItem", "Reference only");
    qmlRegisterUncreatableType<GCSSkydroidGimbal>("gises", 1, 0, "GCSSkydroidGimbal", "Reference only");
    qmlRegisterType<GCSTunningControl>("gises", 1, 0, "GCSTunningControl");
    GCSPlanManager::registerQmlTypes();
    GCSGeoFenceManager::registerQmlTypes();
    GCSRallyPointManager::registerQmlTypes();
    GModuleControl::registerQmlTypes();
}

void GCSManager::init(){
    updateVehicleCommandList();
    qgcApp()->qmlAppEngine()->rootContext()->setContextProperty("gcsManager", _gcsManager);
    _planManager.init();
    _moduleControl->init();
    connect(qgcApp(), &QGCApplication::showMessage, this, &GCSManager::onShowMessage);
    connect(_vehicleManager, &MultiVehicleManager::activeVehicleChanged, this, &GCSManager::updateVehicle);

    _allList.append(new GCSGuideAction(GCSGuideAction::Goto, "Go to loaction", "", this));
    _allList.append(new GCSGuideAction(GCSGuideAction::Orbit, "Orbit at location", "", this));
    _allList.append(new GCSGuideAction(GCSGuideAction::ROI, "ROI at location", "", this));
    _allList.append(new GCSGuideAction(GCSGuideAction::SetHome, "Set home here", "", this));
    _allList.append(new GCSGuideAction(GCSGuideAction::SetEstimatorOrigin, "Set Estimator Origin", "", this));
    _allList.append(new GCSGuideAction(GCSGuideAction::ChangeHeading, "Set Heading", "", this));
    for(int i=0; i<_allList.size(); ++i){
        if(_allList[i]->visible()){
            _actionList.append(_allList[i]);
        }
    }
    emit actionListChanged();
}

void GCSManager::updateActionList(){
    _actionList.clear();
    for(int i=0; i<_allList.size(); ++i){
        _allList[i]->updateVisible();
        if(_allList[i]->visible()){
            _actionList.append(_allList[i]);
        }
    }
    emit actionListChanged();
}
void GCSManager::doAction(GCSGuideAction* act){
    switch(act->action()){
    case GCSGuideAction::Rtl:
        _vehicle->guidedModeRTL(false);
        break;
    case GCSGuideAction::Land:
        _vehicle->guidedModeLand();
        break;
    case GCSGuideAction::Takeoff:
        _vehicle->guidedModeTakeoff(50);
        break;
    case GCSGuideAction::Arm:
        _vehicle->setArmed(act->value(), true);
        break;
    case GCSGuideAction::Disarm:
        break;
    case GCSGuideAction::EmergencyStop:
    case GCSGuideAction::ChangeAlt:
        break;
    case GCSGuideAction::Goto:
        _vehicle->guidedModeGotoLocation(act->coor());
        break;
    case GCSGuideAction::SetWaypoint:
    case GCSGuideAction::Orbit:
    case GCSGuideAction::LandAbort:
        break;
    case GCSGuideAction::StartMission:
    case GCSGuideAction::ContinueMission:
        _vehicle->startMission();
        break;
    case GCSGuideAction::ResumeMission:{
        int resumeIndex = _vehicle->missionManager()->lastCurrentIndex() + (_vehicle->firmwarePlugin()->sendHomePositionToVehicle() ? 0 : 1);
        if(resumeIndex > 1 && resumeIndex < _missionModel.count()){
            _vehicle->missionManager()->generateResumeMission(--resumeIndex);
        }else{
            _vehicle->missionManager()->generateResumeMission(0);
        }
        break;
    }
    case GCSGuideAction::nUnused:
    case GCSGuideAction::ResumeMissionUploadFail:
        break;
    case GCSGuideAction::Pause:
        _vehicle->pauseVehicle();
        break;
    case GCSGuideAction::MVPause:
    case GCSGuideAction::MVStartMission:
    case GCSGuideAction::VtolTransitionToFwdFlight:
    case GCSGuideAction::VtolTransitionToMRFlight:
    case GCSGuideAction::ROI:
    case GCSGuideAction::ActionList:
    case GCSGuideAction::ForceArm:
    case GCSGuideAction::ChangeSpeed:
    case GCSGuideAction::Gripper:
        break;
    case GCSGuideAction::SetHome:
        _vehicle->doSetHome(act->coor());
        break;
    case GCSGuideAction::SetEstimatorOrigin:
    case GCSGuideAction::SetFlightMode:
        break;
    case GCSGuideAction::ChangeHeading:
        _vehicle->guidedModeChangeHeading(act->coor());
        break;
    defalut:
        break;
    }
}
void GCSManager::saveToFile(const QString& fullPath){
    QFile file(fullPath);
    if(!file.open(QIODevice::WriteOnly | QIODevice::Text)){
        qDebug()<<"Open File failed";
        return;
    }
    QFileInfo info(file);
    QJsonObject json;
    QJsonObject missions;
    _planManager.setSuffix(info.suffix());
    _planManager.saveAsJson(missions);
    QJsonObject fences;
    _geoFenceManager.saveAsJson(fences);
    QJsonObject rallys;
    _rallyPointManager.saveAsJson(rallys);
    json["groundStation"] = "gcs";
    json["mission"] = missions;
    json["geoFence"] = fences;
    json["rallyPoints"] = rallys;
    file.write(QJsonDocument(json).toJson());
}
void GCSManager::loadFromFile(const QString& fileName){
    QFile file(SettingsManager::instance()->appSettings()->missionSavePath()+"/"+fileName);
    QString errorString;

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        errorString = file.errorString() + QStringLiteral(" ") + fileName;
        qDebug()<<"Load Plan File "<<fileName<<"failed, Error:"<<errorString;
        return;
    }
    QString errorStr;
    QString errorMessage = tr("Mission: %1");
    QJsonDocument jsonDoc;
    QByteArray bytes = file.readAll();

    if (!JsonHelper::isJsonFile(bytes, jsonDoc, errorStr)) {
        errorString = errorMessage.arg(errorStr);
        qDebug()<<"Load json failed: "<<errorString;
    }

    QJsonObject json = jsonDoc.object();
    QJsonObject mission = json["mission"].toObject();
    QJsonObject geoFence = json["geoFence"].toObject();
    QJsonObject rallys = json["rallyPoints"].toObject();
    _planManager.loadFromJson(mission, fileName);
    _geoFenceManager.loadFromJson(geoFence);
    _rallyPointManager.loadFromJson(rallys);
}
void GCSManager::sendToVehicle(){
    sendMissions();
}

void GCSManager::clearMessage(int all){
    _vmessage = "";
    if(all){
        _message = "";
        _msgTitle = "";
    }
    emit messageChanged();
}

void GCSManager::initMap(){
    if(nullptr == _map){
        QQuickWindow *const root = qgcApp()->mainRootWindow();
        if (root) {
            _map = root->findChild<QObject*>("defaultMap");
            if(nullptr == _map){
                qDebug()<<"empty map";
            }
        }else{
            qDebug() << "mainRootWindow() failed. No root window";
        }
    }
}
void GCSManager::sendMissions(){
    if(_vehicle->isOfflineEditingVehicle()){
        return;
    }
    QList<MissionItem*> missions;
    _planManager.generateItems(missions, _vehicle);
    //save plan
    // _planManager.saveToFile();
    _vehicle->missionManager()->writeMissionItems(missions);
}
void GCSManager::sendGeoFences(){
    if(_vehicle->isOfflineEditingVehicle()){
        return;
    }

    QList<MissionItem*> fences;
    _geoFenceManager.generateItems(fences, _vehicle);
    _vehicle->geoFenceManager()->writeMissionItems(fences);
}
void GCSManager::sendRallyPoints(){
    if(_vehicle->isOfflineEditingVehicle()){
        return;
    }

    QList<MissionItem*> rallys;
    _rallyPointManager.generateItems(rallys, _vehicle);
    _vehicle->rallyPointManager()->writeMissionItems(rallys);
}
void GCSManager::setState(State st){
    if(_state != st){
        _state = st;
        emit stateChanged();
    }
}
void GCSManager::setMapBearing(double bearing){
    double diff = qAbs(_mapBearing - bearing);
    if(diff >= 0.1){
        _mapBearing = bearing;
        emit mapBearingChanged();
    }
}

bool GCSManager::pixedEqual(qreal p1, qreal p2){
    int int1 = p1 * 10, int2 = p2 * 10;
    int pixed = 10.0 / _screenPixed;
    return int1 / pixed == int2 / pixed;
}

bool GCSManager::pointfEqual(QPointF p1, QPointF p2){
    return (pixedEqual(p1.x(), p2.x()) && pixedEqual(p1.y(), p2.y()));
}
void GCSManager::refreshPin(){
    //_planManager.route()->refreshPin();
    _geoFenceManager.refreshPoint();
    _rallyPointManager.refreshPoint();
}
void GCSManager::connectToNtripServer(){
    _ntrip->connectToNtripServer();
}
void GCSManager::updateVehicleCommandList(){
    QStringList enumStrings;
    QVariantList enumValues;
    //初始化元数据
    for (const MAV_CMD command: MissionCommandTree::instance()->allCommandIds()) {
        enumStrings.append(MissionCommandTree::instance()->rawName(command));
        enumValues.append(QVariant((int)command));
    }
    _commandMetaData->setEnumInfo(enumStrings, enumValues);

    enumStrings.clear();
    enumValues.clear();
    for (size_t i=0; i<sizeof(_rgMavFrameInfo)/sizeof(_rgMavFrameInfo[0]); i++) {
        const struct EnumInfo_s* mavFrameInfo = &_rgMavFrameInfo[i];

        enumStrings.append(mavFrameInfo->label);
        enumValues.append(QVariant(mavFrameInfo->frame));
    }
    _frameMetaData->setEnumInfo(enumStrings, enumValues);

    enumStrings.clear();
    enumValues.clear();

    QGCMAVLink::FirmwareClass_t firmwareClass;
    QGCMAVLink::VehicleClass_t vehicleClass;
    Vehicle* vehicle = GCSManager::instance()->vehicle();
    QVariantList list = MissionCommandTree::instance()->getCommandsForCategory(vehicle, "All commands", true);
    for(int i=0;i<list.size();++i){
        MissionCommandUIInfo* info = list[i].value<MissionCommandUIInfo*>();
        enumStrings.append(info->friendlyName());
        enumValues.append(QVariant((int)info->command()));
    }
    _simpleMetaData->setEnumInfo(enumStrings, enumValues);
}

QGeoCoordinate GCSManager::convertCoordinate(QPointF point){
    QVariant arg=point;
    QVariant coor;
    if(!_map)
        initMap();
    QMetaObject::invokeMethod(_map, "convertPointToCoordinate",
                              Q_RETURN_ARG(QVariant, coor),
                              Q_ARG(QVariant, arg));
    return coor.value<QGeoCoordinate>();
}

QPointF GCSManager::convertCoordinate(QGeoCoordinate coor){
    QVariant arg=QVariant::fromValue(coor);
    QVariant point;
    if(!_map)
        initMap();
    QMetaObject::invokeMethod(_map, "convertCoordinateToPoint",
                              Q_RETURN_ARG(QVariant, point),
                              Q_ARG(QVariant, arg));
    return point.value<QPointF>();
}

//SLOTS
void GCSManager::onShowMessage(const QString msg, const QString title){
    if(title == "VehicleError"){
        _vmessage = msg;
    }else{
        title.isEmpty() ? _msgTitle = tr("Empty") : _msgTitle = title;
        _message = msg;
    }
    emit messageChanged();
}
void GCSManager::updateVehicle(Vehicle* vehicle){
    if(_vehicle == vehicle){
        return;
    }
    //qCDebug(GCSManagerLog) << "_vehicleChanged" << _vehicle;

    if (_vehicle){
        // Disconnect old vehicle. Be careful of wildcarding disconnect too much since _vehicle may equal _simulateVehicle
        disconnect(_vehicle->missionManager(),       nullptr, this, nullptr);
        disconnect(_vehicle->geoFenceManager(),      nullptr, this, nullptr);
        disconnect(_vehicle->rallyPointManager(),    nullptr, this, nullptr);
    }

    if (vehicle == nullptr){
        // Since there is no longer an active vehicle we use the offline controller vehicle as the manager vehicle
        _vehicle = _vehicleManager->offlineEditingVehicle();
    } else {
        _vehicle = vehicle;

        connect(_vehicle, &Vehicle::initialConnectComplete, this, &GCSManager::vehicleCompleted);
        // Update simulateVehicle to the currently connected vehicle
        AppSettings* appSettings = SettingsManager::instance()->appSettings();
        appSettings->offlineEditingFirmwareClass()->setRawValue(QGCMAVLink::firmwareClass(_vehicle->firmwareType()));
        appSettings->offlineEditingVehicleClass()->setRawValue(QGCMAVLink::vehicleClass(_vehicle->vehicleType()));

        // We use these signals to sequence upload and download to the multiple controller/managers
        connect(_vehicle->missionManager(),      &MissionManager::newMissionItemsAvailable,  this, &GCSManager::loadMissions);
        connect(_vehicle->geoFenceManager(),     &GeoFenceManager::newMissionItemsAvailable, this, &GCSManager::loadGeoFences);
        connect(_vehicle->rallyPointManager(),   &RallyPointManager::loadComplete, this, &GCSManager::loadRallyPoints);
        connect(_vehicle->missionManager(),      &MissionManager::sendComplete,              this, &GCSManager::onSendMissionComplete);
        connect(_vehicle->geoFenceManager(),     &GeoFenceManager::sendComplete,             this, &GCSManager::onSendGeoFenceComplete);
        connect(_vehicle->rallyPointManager(),   &RallyPointManager::sendComplete,           this, &GCSManager::onSendRallyPointsComplete);

        MissionManager* mission = vehicle->missionManager();
        connect(mission, &MissionManager::removeAllComplete,        this, &GCSManager::onRemoveAll);
        connect(mission, &MissionManager::inProgressChanged,        this, &GCSManager::updateInProcess);
        connect(mission, &MissionManager::progressPctChanged,       this, &GCSManager::updateProcess);
        connect(mission, &MissionManager::currentIndexChanged,      this, &GCSManager::updateCurrentMission);
        //connect(mission, &MissionManager::resumeMissionUploadFail,  this, &GCSManager::resumeMissionUploadFail);
    }
    loadMissions();
    updateVehicleCommandList();
    emit vehicleChanged();
}
void GCSManager::loadMissions(){
    _missionPath.clear();
    _missionList.clear();
    if(_missionModel.count()){
        _missionModel.clear();
    }
    GCSVehicleMissionItem* mission = nullptr;
    for(int i=0; i<_missionList.size(); ++i){
        _missionList[i]->deleteLater();
    }
    if(_vehicle && !_vehicle->isOfflineEditingVehicle() && _vehicle->missionManager()->missionItems().size()){
        MissionCommandTree* tree = MissionCommandTree::instance();
        const QList<MissionItem*> items = _vehicle->missionManager()->missionItems();
        int index = _vehicle->firmwarePlugin()->sendHomePositionToVehicle();
        if(index){
            mission = new GCSVehicleMissionItem(items[0], this);
            _missionModel.append(mission);
        }
        bool firstTakeoff = true;
        for(; index<items.size(); ++index){
            mission = new GCSVehicleMissionItem(items[index], this);
            _missionList.append(mission);
            const MissionCommandUIInfo* uiInfo = tree->getUIInfo(_vehicle, _vehicle->vehicleClass(), items[index]->command());
            bool visible = uiInfo->specifiesCoordinate();
            if(MAV_CMD_NAV_TAKEOFF == items[index]->command()){
                visible = true;
                if(firstTakeoff){
                    mission->setCoord(_vehicle->homePosition());
                    firstTakeoff = false;
                }
            }
            //if(uiInfo->specifiesCoordinate()){
            //    mission->setVisible(uiInfo->specifiesCoordinate());
            mission->setVisible(visible);
            if(visible){
                _missionPath.append(QVariant::fromValue(QGeoCoordinate(items[index]->coordinate())));
                _missionModel.append(mission);
            }
        }
    }
    emit vehicleMissionCountChanged();
    emit missionPathChanged();
}

void GCSManager::loadGeoFences(){
    if(_vehicle && !_vehicle->isOfflineEditingVehicle() && _vehicle->geoFenceManager()->missionItems().size()){
        _geoFenceManager.loadFromVehicle(_vehicle->geoFenceManager()->missionItems());
    }
}

void GCSManager::loadRallyPoints(){
    if(_vehicle && !_vehicle->isOfflineEditingVehicle() && _vehicle->rallyPointManager()->points().size()){
        _rallyPointManager.loadFromVehicle(_vehicle->rallyPointManager()->points());
    }
}
void GCSManager::onSendMissionComplete(){
    loadMissions();
}

void GCSManager::onSendGeoFenceComplete(){

}

void GCSManager::onSendRallyPointsComplete(){

}
void GCSManager::onRemoveAll(bool success){

}
void GCSManager::updateInProcess(bool in){
    if(_vehicle->isOfflineEditingVehicle()){
        return;
    }
    QObject* sd = sender();
    if(!in){
        _prosessName = "";
        QTimer::singleShot(2000, this, [this](){
            _process = 0.0;
            emit processChanged();
        });
    }else{
        if(sd == _vehicle->missionManager()){
            _prosessName = "Upload Missions";
        }else if(sd == _vehicle->geoFenceManager()){
            _prosessName = "Upload Fences";
        }else if(sd == _vehicle->rallyPointManager()){
            _prosessName = "Upload Rallys";
        }else{
            _prosessName = "";
        }
    }
    emit processNameChanged();
}
void GCSManager::updateProcess(double ps){
    if(qAbs(ps - _process) > 0.01){
        _process = ps;
    }
    emit processChanged();
}

void GCSManager::updateCurrentMission(int index){
    if(index < 0 || index >= _missionList.size())
        return;
    if(_missionModel.contains(_missionList[index])){
        _missionList[_currentMissionIndex]->setIsCurrent(false);
        _missionList[index]->setIsCurrent(true);
        _currentMissionIndex = index;
    }
    emit currentMissionIndexChanged();
}
