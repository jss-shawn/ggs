
#include "QGCOptions.h"
#include "QGCCorePlugin.h"
#include "AppSettings.h"
#include "HealthAndArmingCheckReport.h"
#include "MAVLinkEnums.h"
#include "MultiVehicleManager.h"
#include "QmlObjectListModel.h"
#include "SettingsManager.h"
#include "Vehicle.h"
#include "VehicleSupports.h"
#include "MissionManager.h"
#include "guideAction.h"
#include "gisesManager.h"

GuideAction::GuideAction(const int act, QString name, QString detail, QObject* parent)
    :QObject(parent)
    ,_action(act)
    ,_name(name)
    ,_detail(detail)
{
    connect(MultiVehicleManager::instance(), &MultiVehicleManager::activeVehicleChanged, this, &GuideAction::updateVisible);
    updateVisible();
}

void GuideAction::setValue(double value){
    _value = value;
    emit valueChanged();
}
void GuideAction::setParam(QString param){
    _param = param;
    emit paramChanged();
}
void GuideAction::setCoor(QGeoCoordinate coor){
    _coor = coor;
    emit coorChanged();
}
void GuideAction::updateVisible(){
    Vehicle* vehicle = MultiVehicleManager::instance()->activeVehicle();
    AppSettings* appSet = SettingsManager::instance()->appSettings();
    QGCOptions* option = QGCCorePlugin::instance()->options();
#ifdef QT_DEBUG
    bool debug = true;
#else
    bool debug = false;
#endif
    bool useChecklist = (appSet->useChecklist()->rawValue().toBool() && option->preFlightChecklistUrl().toString().size());
    bool forceChecklist = (useChecklist && appSet->enforceChecklist()->rawValue().toBool());
    bool checklistPass = vehicle ? (useChecklist ? (forceChecklist ? vehicle->checkListState() == Vehicle::CheckListPassed : true) : true): true;
    bool canArm = vehicle ? (checklistPass && (!vehicle->healthAndArmingCheckReport()->supported() || vehicle->healthAndArmingCheckReport()->canArm())) : false;
    bool canTakeoff = vehicle ? (checklistPass && (!vehicle->healthAndArmingCheckReport()->supported() || vehicle->healthAndArmingCheckReport()->canTakeoff())) : false;
    bool canStartMission = vehicle ? (checklistPass && (!vehicle->healthAndArmingCheckReport()->supported() || vehicle->healthAndArmingCheckReport()->canStartMission())) : false;
    bool initialConnectComplete = vehicle ? vehicle->isInitialConnectComplete() : false;

    bool rcrssi = QGCCorePlugin::instance()->options()->guidedActionsRequireRCRSSI();
    bool rcRSSIAvailable = vehicle ? vehicle->rcRSSI()->rawValue().toInt() > 0 && vehicle->rcRSSI()->rawValue().toInt() <= 100 : false;
    bool enabled = (!debug && rcrssi && vehicle) ? rcRSSIAvailable : vehicle != nullptr;
    bool armed = vehicle && vehicle->armed();
    bool flying = vehicle && vehicle->flying();
    bool speedLimitsAvailable = vehicle && ((vehicle->fixedWing() && vehicle->haveFWSpeedLimits()) || (!vehicle->fixedWing() && vehicle->haveMRSpeedLimits()));
    bool missionActive = vehicle && armed &&
                         (vehicle->flightMode() == vehicle->landFlightMode() ||
                          vehicle->flightMode() == vehicle->rtlFlightMode() ||
                          vehicle->flightMode() == vehicle->missionFlightMode());
    _visible = false;
    switch(_action){
    case Rtl:
        _visible = enabled && armed && vehicle->supports()->guidedMode() && flying && vehicle->flightMode() != vehicle->rtlFlightMode();
        break;
    case Land:
        _visible = enabled && vehicle->supports()->guidedMode() && armed && !vehicle->fixedWing() && vehicle->flightMode() != vehicle->landFlightMode();
        break;
    case Takeoff:
        _visible = enabled && vehicle->supports()->takeoffMissionCommand() && !flying && canTakeoff;
        break;
    case Arm:
        _visible = enabled && !armed && canArm;
        break;
    case Disarm:
        _visible = enabled && armed && !flying;
        break;
    case EmergencyStop:
        _visible = enabled && armed && flying;
        break;
    case ChangeAlt:
        _visible = enabled && flying && vehicle->supports()->guidedMode() && armed && !missionActive;
        break;
    case Goto:
        _visible = enabled && flying;
        break;
    case SetWaypoint:
        break;
    case Orbit:
        _visible = enabled && flying && vehicle->supports()->orbitMode() && !missionActive;
        break;
    case LandAbort:
        _visible = enabled && flying && vehicle->fixedWing() && vehicle->flightMode() == vehicle->landFlightMode();
        break;
    case StartMission:
        _visible = enabled && _gises->missionModel()->count() && !missionActive && !flying && canStartMission;
        break;
    case ContinueMission:
        _visible = enabled && _gises->missionModel()->count() && !missionActive && armed && flying &&
                   (vehicle->missionManager()->currentIndex() < vehicle->missionManager()->missionItems().size()-1);
        break;
    case ResumeMission:
    case nUnused:
    case ResumeMissionUploadFail:
        break;
    case Pause:
        _visible = enabled && armed && vehicle->supports()->pauseVehicle() && flying && vehicle->flightMode() != vehicle->pauseFlightMode() && !(vehicle->fixedWing() && vehicle->flightMode() == vehicle->landFlightMode());
        break;
    case MVPause:
    case MVStartMission:
    case VtolTransitionToFwdFlight:
    case VtolTransitionToMRFlight:
        break;
    case ROI:
        _visible = enabled && flying && vehicle->supports()->roiMode();
        break;
    case ActionList:
        //_visible = enabled && (showStartMission || showResumeMission || showChangeAlt || showLandAbort || actionList.hasCustomActions);
        //break;
    case ForceArm:
        _visible = enabled && !armed;
        break;
    case ChangeSpeed:
        _visible = enabled && flying && vehicle->supports()->guidedMode() && armed && !missionActive && speedLimitsAvailable;
        break;
    case Gripper:
        _visible = initialConnectComplete ? vehicle->hasGripper() : false;
        break;
    case SetHome:
        _visible = enabled;
        break;
    case SetEstimatorOrigin:
        _visible = vehicle && !(vehicle->sensorsPresentBits() & MAV_SYS_STATUS_SENSOR_GPS);
        break;
    case SetFlightMode:
        _visible = vehicle != nullptr;
        break;
    case ChangeHeading:
        _visible = enabled && flying;
        break;
    default:
        break;
    }
    emit visibleChanged();
}
