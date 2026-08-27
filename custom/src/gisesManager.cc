
#include "AppSettings.h"
#include "FactMetaData.h"
#include "FirmwarePlugin.h"
#include "GeoFenceManager.h"
#include "JsonParsing.h"
#include "MissionCommandTree.h"
#include "MissionCommandUIInfo.h"
#include "MissionManager.h"
#include "MultiVehicleManager.h"
#include "QmlObjectListModel.h"
#include "QmlObjectTreeModel.h"
#include "RallyPointManager.h"
#include "SettingsManager.h"
#include "Vehicle.h"
#include "colorConfig.h"
#include "fenceManager.h"
#include "gisesManager.h"
#include "gisesPlan.h"
#include "rallyManager.h"
#include "vehicleMissionItem.h"

Q_LOGGING_CATEGORY(GisesManagerLog,"GisesManagerLog")

GisesManager::GisesManager(QObject* parent)
    : QObject(parent)
    , _colorConfig(new ColorConfig(this))
    , _fence(new FenceManager(this))
    , _plan(new GisesPlan(this))
    , _rally(new RallyManager(this))
    , _simpleMetaData(new FactMetaData(FactMetaData::valueTypeUint32))
    , _commandMetaData(new FactMetaData(FactMetaData::valueTypeUint32))
    , _frameMetaData(new FactMetaData(FactMetaData::valueTypeDouble))
    , _defaultParamMetaData(new FactMetaData(FactMetaData::valueTypeDouble))
    , _missionModel(new QmlObjectListModel(this))
{
    _defaultParamMetaData->setDecimalPlaces(7);
}

void GisesManager::init()
{
    _vehicle = MultiVehicleManager::instance()->offlineEditingVehicle();
    connect(MultiVehicleManager::instance(), &MultiVehicleManager::activeVehicleChanged, this, &GisesManager::updateVehicle);
    updateVehicleCommandList();
    _plan->init();
}

// void GisesManager::updateActionList(){
//     _actionList.clear();
//     for(int i=0; i<_allList.size(); ++i){
//         _allList[i]->updateVisible();
//         if(_allList[i]->visible()){
//             _actionList.append(_allList[i]);
//         }
//     }
//     emit actionListChanged();
// }
// void GCSManager::doAction(GCSGuideAction* act){
//     switch(act->action()){
//     case GCSGuideAction::Rtl:
//         _vehicle->guidedModeRTL(false);
//         break;
//     case GCSGuideAction::Land:
//         _vehicle->guidedModeLand();
//         break;
//     case GCSGuideAction::Takeoff:
//         _vehicle->guidedModeTakeoff(50);
//         break;
//     case GCSGuideAction::Arm:
//         _vehicle->setArmed(act->value(), true);
//         break;
//     case GCSGuideAction::Disarm:
//         break;
//     case GCSGuideAction::EmergencyStop:
//     case GCSGuideAction::ChangeAlt:
//         break;
//     case GCSGuideAction::Goto:
//         _vehicle->guidedModeGotoLocation(act->coor());
//         break;
//     case GCSGuideAction::SetWaypoint:
//     case GCSGuideAction::Orbit:
//     case GCSGuideAction::LandAbort:
//         break;
//     case GCSGuideAction::StartMission:
//     case GCSGuideAction::ContinueMission:
//         _vehicle->startMission();
//         break;
//     case GCSGuideAction::ResumeMission:{
//         int resumeIndex = _vehicle->missionManager()->lastCurrentIndex() + (_vehicle->firmwarePlugin()->sendHomePositionToVehicle() ? 0 : 1);
//         if(resumeIndex > 1 && resumeIndex < _missionModel.count()){
//             _vehicle->missionManager()->generateResumeMission(--resumeIndex);
//         }else{
//             _vehicle->missionManager()->generateResumeMission(0);
//         }
//         break;
//     }
//     case GCSGuideAction::nUnused:
//     case GCSGuideAction::ResumeMissionUploadFail:
//         break;
//     case GCSGuideAction::Pause:
//         _vehicle->pauseVehicle();
//         break;
//     case GCSGuideAction::MVPause:
//     case GCSGuideAction::MVStartMission:
//     case GCSGuideAction::VtolTransitionToFwdFlight:
//     case GCSGuideAction::VtolTransitionToMRFlight:
//     case GCSGuideAction::ROI:
//     case GCSGuideAction::ActionList:
//     case GCSGuideAction::ForceArm:
//     case GCSGuideAction::ChangeSpeed:
//     case GCSGuideAction::Gripper:
//         break;
//     case GCSGuideAction::SetHome:
//         _vehicle->doSetHome(act->coor());
//         break;
//     case GCSGuideAction::SetEstimatorOrigin:
//     case GCSGuideAction::SetFlightMode:
//         break;
//     case GCSGuideAction::ChangeHeading:
//         _vehicle->guidedModeChangeHeading(act->coor());
//         break;
//     defalut:
//         break;
//     }
// }

void GisesManager::setCurrentManager(QObject* manager){
    if (_currentManager != manager) {
        _currentManager = manager;
        emit currentManagerChanged();
    }
}

void GisesManager::saveToFile(const QString& fullPath){
    QFile file(fullPath);
    if(!file.open(QIODevice::WriteOnly | QIODevice::Text)){
        qDebug()<<"Open File failed";
        return;
    }
    QFileInfo info(file);
    QJsonObject json;
    QJsonObject missions;
    _plan->setSuffix(info.suffix());
    _plan->saveAsJson(missions);
    QJsonObject fences;
    _fence->saveAsJson(fences);
    QJsonObject rallys;
    _rally->saveAsJson(rallys);
    json["groundStation"] = "gcs";
    json["mission"] = missions;
    json["geoFence"] = fences;
    json["rallyPoints"] = rallys;
    file.write(QJsonDocument(json).toJson());
}
void GisesManager::loadFromFile(const QString& fileName){
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

    if (!JsonParsing::isJsonFile(bytes, jsonDoc, errorStr)) {
        errorString = errorMessage.arg(errorStr);
        qDebug()<<"Load json failed: "<<errorString;
    }

    QJsonObject json = jsonDoc.object();
    QJsonObject mission = json["mission"].toObject();
    QJsonObject geoFence = json["geoFence"].toObject();
    QJsonObject rallys = json["rallyPoints"].toObject();
    _plan->loadFromJson(mission, fileName);
    _fence->loadFromJson(geoFence);
    _rally->loadFromJson(rallys);
}
void GisesManager::sendToVehicle(){
    sendMissions();
}

void GisesManager::sendFences()
{
    if (_vehicle->isOfflineEditingVehicle()) {
        return;
    }

    QList<MissionItem*> fences;
    _fence->generateItems(fences, _vehicle);
    _vehicle->geoFenceManager()->writeMissionItems(fences);
}

void GisesManager::sendMissions()
{
    if (_vehicle->isOfflineEditingVehicle()) {
        return;
    }
    QList<MissionItem*> missions;
    _plan->generateItems(missions, _vehicle);
    //save plan
    // _planManager.saveToFile();
    _vehicle->missionManager()->writeMissionItems(missions);
}

void GisesManager::sendRallys()
{
    if (_vehicle->isOfflineEditingVehicle()) {
        return;
    }

    QList<MissionItem*> rallys;
    _rally->generateItems(rallys, _vehicle);
    _vehicle->rallyPointManager()->writeMissionItems(rallys);
}

void GisesManager::updateVehicleCommandList()
{
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

    //QGCMAVLink::FirmwareClass_t firmwareClass;
    //QGCMAVLink::VehicleClass_t vehicleClass;
    QVariantList list = MissionCommandTree::instance()->getCommandsForCategory(_vehicle, "All commands", true);
    for (int i=0;i<list.size();++i) {
        MissionCommandUIInfo* info = list[i].value<MissionCommandUIInfo*>();
        enumStrings.append(info->friendlyName());
        enumValues.append(QVariant((int)info->command()));
    }
    _simpleMetaData->setEnumInfo(enumStrings, enumValues);
}

//SLOTS
void GisesManager::updateVehicle(Vehicle* vehicle)
{
    if (_vehicle == vehicle) {
        return;
    }
    //qCDebug(GCSManagerLog) << "_vehicleChanged" << _vehicle;

    if (_vehicle) {
        // Disconnect old vehicle. Be careful of wildcarding disconnect too much since _vehicle may equal _simulateVehicle
        disconnect(_vehicle->missionManager(),       nullptr, this, nullptr);
        disconnect(_vehicle->geoFenceManager(),      nullptr, this, nullptr);
        disconnect(_vehicle->rallyPointManager(),    nullptr, this, nullptr);
    }

    if (vehicle == nullptr) {
        // Since there is no longer an active vehicle we use the offline controller vehicle as the manager vehicle
        _vehicle = MultiVehicleManager::instance()->offlineEditingVehicle();
    } else {
        _vehicle = vehicle;

        connect(_vehicle, &Vehicle::initialConnectComplete, this, &GisesManager::vehicleCompleted);
        // Update simulateVehicle to the currently connected vehicle
        AppSettings* appSettings = SettingsManager::instance()->appSettings();
        appSettings->offlineEditingFirmwareClass()->setRawValue(QGCMAVLink::firmwareClass(_vehicle->firmwareType()));
        appSettings->offlineEditingVehicleClass()->setRawValue(QGCMAVLink::vehicleClass(_vehicle->vehicleType()));

        // We use these signals to sequence upload and download to the multiple controller/managers
        connect(_vehicle->missionManager(),      &MissionManager::newMissionItemsAvailable,  this, &GisesManager::loadMissions);
        connect(_vehicle->geoFenceManager(),     &GeoFenceManager::newMissionItemsAvailable, this, &GisesManager::loadGeoFences);
        connect(_vehicle->rallyPointManager(),   &RallyPointManager::loadComplete,           this, &GisesManager::loadRallyPoints);
        connect(_vehicle->missionManager(),      &MissionManager::sendComplete,              this, &GisesManager::onSendMissionComplete);
        connect(_vehicle->geoFenceManager(),     &GeoFenceManager::sendComplete,             this, &GisesManager::onSendFenceComplete);
        connect(_vehicle->rallyPointManager(),   &RallyPointManager::sendComplete,           this, &GisesManager::onSendRallyComplete);

        MissionManager* mission = vehicle->missionManager();
        connect(mission, &MissionManager::removeAllComplete,        this, &GisesManager::onRemoveAll);
        connect(mission, &MissionManager::inProgressChanged,        this, &GisesManager::updateInProcess);
        connect(mission, &MissionManager::progressPctChanged,       this, &GisesManager::updateProcess);
        connect(mission, &MissionManager::currentIndexChanged,      this, &GisesManager::updateCurrentMission);
        //connect(mission, &MissionManager::resumeMissionUploadFail,  this, &GisesManager::resumeMissionUploadFail);
    }
    loadMissions();
    updateVehicleCommandList();
    emit vehicleChanged();
}

void GisesManager::loadMissions()
{
    _missionPath.clear();
    _missionList.clear();
    if (_missionModel->count()) {
        _missionModel->clear();
    }
    VehicleMissionItem* mission = nullptr;
    for (int i=0; i<_missionList.size(); ++i) {
        _missionList[i]->deleteLater();
    }
    if (_vehicle && !_vehicle->isOfflineEditingVehicle() && _vehicle->missionManager()->missionItems().size()) {
        MissionCommandTree* tree = MissionCommandTree::instance();
        const QList<MissionItem*> items = _vehicle->missionManager()->missionItems();
        int index = _vehicle->firmwarePlugin()->sendHomePositionToVehicle();
        if (index) {
            mission = new VehicleMissionItem(items[0], this);
            _missionModel->append(mission);
        }
        bool firstTakeoff = true;
        for (; index<items.size(); ++index) {
            mission = new VehicleMissionItem(items[index], this);
            _missionList.append(mission);
            const MissionCommandUIInfo* uiInfo = tree->getUIInfo(_vehicle, _vehicle->vehicleClass(), items[index]->command());
            bool visible = uiInfo->specifiesCoordinate();
            if (MAV_CMD_NAV_TAKEOFF == items[index]->command()) {
                visible = true;
                if (firstTakeoff) {
                    mission->setCoord(_vehicle->homePosition());
                    firstTakeoff = false;
                }
            }
            //if (uiInfo->specifiesCoordinate()) {
            //    mission->setVisible(uiInfo->specifiesCoordinate());
            mission->setVisible(visible);
            if (visible) {
                _missionPath.append(QVariant::fromValue(QGeoCoordinate(items[index]->coordinate())));
                _missionModel->append(mission);
            }
        }
    }
    emit vehicleMissionCountChanged();
    emit missionPathChanged();
}

void GisesManager::loadGeoFences()
{
    if (_vehicle && !_vehicle->isOfflineEditingVehicle() && _vehicle->geoFenceManager()->missionItems().size()) {
        _fence->loadFromVehicle(_vehicle->geoFenceManager()->missionItems());
    }
}

void GisesManager::loadRallyPoints()
{
    if (_vehicle && !_vehicle->isOfflineEditingVehicle() && _vehicle->rallyPointManager()->points().size()) {
        _rally->loadFromVehicle(_vehicle->rallyPointManager()->points());
    }
}

void GisesManager::onSendMissionComplete()
{
    loadMissions();
}

void GisesManager::onSendFenceComplete()
{
}

void GisesManager::onSendRallyComplete()
{
}

void GisesManager::onRemoveAll(bool succenss)
{
    Q_UNUSED(succenss);
}

void GisesManager::updateInProcess(bool in)
{
    if (_vehicle->isOfflineEditingVehicle()) {
        return;
    }
    QObject* sd = sender();
    if (!in) {
        _processName = "";
        QTimer::singleShot(2000, this, [this]() {
            _process = 0.0;
            emit processChanged();
        });
    }else{
        if (sd == _vehicle->missionManager()) {
            _processName = "Upload Missions";
        }else if (sd == _vehicle->geoFenceManager()) {
            _processName = "Upload Fences";
        }else if (sd == _vehicle->rallyPointManager()) {
            _processName = "Upload Rallys";
        }else{
            _processName = "";
        }
    }
    emit processNameChanged();
}

void GisesManager::updateProcess(double ps)
{
    if (qAbs(ps - _process) > 0.01) {
        _process = ps;
    }
    emit processChanged();
}

void GisesManager::updateCurrentMission(int index)
{
    if (index < 0 || index >= _missionList.size())
        return;
    if (_missionModel->contains(_missionList[index])) {
        _missionList[_currentMissionIndex]->setIsCurrent(false);
        _missionList[index]->setIsCurrent(true);
        _currentMissionIndex = index;
    }
    emit currentMissionIndexChanged();
}
