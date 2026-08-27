
#include "FactMetaData.h"
#include "FirmwarePlugin.h"
#include "MissionItem.h"
#include "MultiVehicleManager.h"
#include "Vehicle.h"
#include "gisesPlugin.h"
#include "waypointCamera.h"
#include "gisesManager.h"

QMap<QString, FactMetaData*> WaypointCamera::_metaDataMap;

WaypointCamera::WaypointCamera(QObject* parent)
    :QObject(parent)
{
    if(_metaDataMap.isEmpty()){
        _metaDataMap = FactMetaData::createMapFromJsonFile(QStringLiteral(":/json/CameraSection.FactMetaData.json"), Q_NULLPTR /* metaDataParent */);
    }
}
WaypointCamera::WaypointCamera(const WaypointCamera& other, QObject* parent)
    :QObject(parent)
    ,_actionIndex(other._actionIndex)
    ,_actionTime(other._actionTime)
    ,_actionDistance(other._actionDistance)
    ,_specifyCameraMode(other._specifyCameraMode)
    ,_cameraMode(other._cameraMode)
    ,_gimbalAdjust(other._gimbalAdjust)
    ,_gimbalYaw(other._gimbalYaw)
    ,_gimbalPitch(other._gimbalPitch)
    ,_actionValue(other._actionValue)
    ,_actionName(other._actionName)
{
    if(_metaDataMap.isEmpty()){
        _metaDataMap = FactMetaData::createMapFromJsonFile(QStringLiteral(":/json/CameraSection.FactMetaData.json"), Q_NULLPTR /* metaDataParent */);
    }
}
WaypointCamera& WaypointCamera::operator=(const WaypointCamera& right)
{
    _actionIndex = right._actionIndex;
    _actionTime = right._actionTime;
    _actionDistance = right._actionDistance;
    _specifyCameraMode = right._specifyCameraMode;
    _cameraMode = right._cameraMode;
    _gimbalAdjust = right._gimbalAdjust;
    _gimbalYaw = right._gimbalYaw;
    _gimbalPitch = right._gimbalPitch;
    if(_metaDataMap.isEmpty()){
        _metaDataMap = FactMetaData::createMapFromJsonFile(QStringLiteral(":/json/CameraSection.FactMetaData.json"), Q_NULLPTR /* metaDataParent */);
    }
    return *this;
}
bool WaypointCamera::cameraModeSupported() const{
    GisesPlugin* plugin = qobject_cast<GisesPlugin*>(GisesPlugin::instance());
    return _specifyCameraMode || plugin->gises()->vehicle()->firmwarePlugin()->supportedMissionCommands(QGCMAVLink::VehicleClassGeneric).contains(MAV_CMD_SET_CAMERA_MODE);
}
void WaypointCamera::reset(){
    _reset = true;
    setActionIndex(0);
    setActionTime(1);
    setActionDistance(1.0);
    setSpecifyCameraMode(false);
    setCameraMode(0);
    setGimbalYaw(0.0);
    setGimbalPitch(0.0);
    setGimbalAdjust(false);
    _reset = false;
    emit allActionChanged();
}
int WaypointCamera::allActions(){
    int count = 0;
    switch(_actionValue[_actionIndex]){
    case CameraActionNone:
        break;
    case StopTakingPhotos:
        count = 2;
        break;
    default:
        count = 1;
    }

    return _specifyCameraMode + _gimbalAdjust + count;
}
QStringList WaypointCamera::modeName(){
    return _metaDataMap["CameraMode"]->enumStrings();
}
void WaypointCamera::setAction(CameraAction action){
    switch(action){
    case TakePhotosIntervalTime:
        setActionIndex(1);
        break;
    case TakePhotosIntervalDistance:
        setActionIndex(2);
        break;
    case TakePhoto:
        setActionIndex(3);
        break;
    case StopTakingPhotos:
        setActionIndex(4);
        break;
    case TakeVideo:
        setActionIndex(5);
        break;
    case StopTakingVideo:
        setActionIndex(6);
        break;
    default:
        setActionIndex(0);
    }
}
void WaypointCamera::setActionIndex(int index){
    if(_actionIndex != index){
        bool flag = (_actionIndex <= TakePhoto || index <= TakePhoto);
        _actionIndex = index;
        emit actionIndexChanged();
        if(flag)
            emit takePhotoChanged();
        if(!_reset)
            emit allActionChanged();
    }
}

void WaypointCamera::setActionTime(int time){
    if(time < 0)
        return;
    if(_actionTime != time){
        _actionTime = time;
        emit actionTimeChanged();
        emit takePhotoChanged();
    }
}

void WaypointCamera::setActionDistance(double distance){
    if(distance < 0.0){
        return;
    }
    if(_actionDistance - distance > 0.01 || distance - _actionDistance > 0.01){
        _actionDistance = distance;
        emit actionDistanceChanged();
        emit takePhotoChanged();
    }
}
void WaypointCamera::setSpecifyCameraMode(bool spe){
    if(spe != _specifyCameraMode){
        _specifyCameraMode = spe;
        emit specifyCameraModeChanged();
        if(!_reset)
            emit allActionChanged();
    }
}
void WaypointCamera::setCameraMode(int mode){
    if(mode != _cameraMode){
        _cameraMode = mode;
        emit cameraModeChanged();
    }
}
void WaypointCamera::setGimbalYaw(double yaw){
    if(yaw < -180.0 || yaw > 180.0){
        return;
    }
    if(_gimbalYaw - yaw > 0.0 || yaw - _gimbalYaw > 0.0){
        _gimbalYaw = yaw;
        emit gimbalYawChanged();
    }
}

void WaypointCamera::setGimbalPitch(double pitch){
    if(qAbs(pitch) > 90.0){
        pitch = 90.0;
    }
    if(_gimbalPitch - pitch > 0.0 || pitch - _gimbalPitch > 0.0){
        _gimbalPitch = pitch;
        emit gimbalPitchChanged();
    }
}

void WaypointCamera::setGimbalAdjust(bool adjust){
    if(_gimbalAdjust != adjust){
        _gimbalAdjust = adjust;
        emit gimbalAdjustChanged();
        if(!_reset)
            emit allActionChanged();
    }
}

QList<MissionItem*> WaypointCamera::genMissionItem(int seqNum, QObject* parent){
    QList<MissionItem*> list;
    //only waypoint item can add camera setting item
    if (_specifyCameraMode){
        MissionItem* camera = new MissionItem(seqNum++,
                                              MAV_CMD_SET_CAMERA_MODE,
                                              MAV_FRAME_MISSION,
                                              0,                                              // Reserved (Set to 0)
                                              _cameraMode,
                                              qQNaN(), qQNaN(), qQNaN(), qQNaN(), qQNaN(),    // reserved
                                              true,                                           // autoContinue
                                              false,                                          // isCurrentItem
                                              parent);
        list.append(camera);
    }
    if (_gimbalAdjust) {
        double pitch = _gimbalPitch;
        pitch > 0.0 ? pitch = -pitch : pitch;
        MissionItem* gimbal = new MissionItem(seqNum++,
                                              MAV_CMD_DO_MOUNT_CONTROL,
                                              MAV_FRAME_MISSION,
                                              pitch,
                                              0,                                      // Gimbal roll
                                              _gimbalYaw,
                                              0, 0, 0,                                // param 4-6 not used
                                              MAV_MOUNT_MODE_MAVLINK_TARGETING,
                                              true,                                   // autoContinue
                                              false,                                  // isCurrentItem
                                              parent);
        list.append(gimbal);
    }
    MissionItem* action = nullptr;

    switch (_actionValue[_actionIndex]){
    case WaypointCamera::CameraActionNone:
        break;
    case WaypointCamera::TakePhotosIntervalTime:
        action = new MissionItem(seqNum++,
                                 MAV_CMD_IMAGE_START_CAPTURE,
                                 MAV_FRAME_MISSION,
                                 0,                                               // Reserved (Set to 0)
                                 _actionTime,							// Interval
                                 0,                                               // Unlimited photo count
                                 0,
                                 qQNaN(), qQNaN(), qQNaN(),              // reserved
                                 //qQNaN(), qQNaN(), qQNaN(), qQNaN(),              // reserved
                                 true,                                            // autoContinue
                                 false,                                           // isCurrentItem
                                 parent);
        break;

    case WaypointCamera::TakePhotosIntervalDistance:
        action = new MissionItem(seqNum++,
                                 MAV_CMD_DO_SET_CAM_TRIGG_DIST,
                                 MAV_FRAME_MISSION,
                                 _actionDistance,			// Trigger distance
                                 0,									// No shutter integartion
                                 1,									// Trigger immediately
                                 0, 0, 0, 0,						// param 4-7 not used
                                 true,								// autoContinue
                                 false,								// isCurrentItem
                                 parent);
        break;
    case WaypointCamera::TakeVideo:
        action = new MissionItem(seqNum++,
                                 MAV_CMD_VIDEO_START_CAPTURE,
                                 MAV_FRAME_MISSION,
                                 0,                                               // Reserved (Set to 0)
                                 0.2,                   // CAMERA_CAPTURE_STATUS (default to every 5 seconds)
                                 qQNaN(), qQNaN(), qQNaN(), qQNaN(),  qQNaN(),    // reserved
                                 true,                                            // autoContinue
                                 false,                                           // isCurrentItem
                                 parent);
        break;
    case WaypointCamera::StopTakingVideo:
        action = new MissionItem(seqNum++,
                                 MAV_CMD_VIDEO_STOP_CAPTURE,
                                 MAV_FRAME_MISSION,
                                 0,                                                       // Reserved (Set to 0)
                                 qQNaN(), qQNaN(), qQNaN(), qQNaN(), qQNaN(), qQNaN(),    // reserved
                                 true,                                                    // autoContinue
                                 false,                                                   // isCurrentItem
                                 parent);
        break;
    case WaypointCamera::StopTakingPhotos:{
        MissionItem* dist = new MissionItem(seqNum++,
                                            MAV_CMD_DO_SET_CAM_TRIGG_DIST,
                                            MAV_FRAME_MISSION,
                                            0,                               // Trigger distance = 0 means stop
                                            0, 0, 0, 0, 0, 0,                // param 2-7 not used
                                            true,                            // autoContinue
                                            false,                           // isCurrentItem
                                            parent);
        list.append(dist);
        action = new MissionItem(seqNum++,
                                 MAV_CMD_IMAGE_STOP_CAPTURE,
                                 MAV_FRAME_MISSION,
                                 0, 0, 0, 0, 0, 0, 0,                                     // Reserved (Set to 0)
                                 //qQNaN(), qQNaN(), qQNaN(), qQNaN(), qQNaN(), qQNaN(),    // reserved
                                 true,                                                    // autoContinue
                                 false,                                                   // isCurrentItem
                                 parent);
    }
    break;

    case WaypointCamera::TakePhoto:
        action = new MissionItem(seqNum++,
                                 MAV_CMD_IMAGE_START_CAPTURE,
                                 MAV_FRAME_MISSION,
                                 0,                           // Reserved (Set to 0)
                                 0,                           // Interval (none)
                                 1,                           // Take 1 photo
                                 0,                           // No sequence number specified
                                 qQNaN(), qQNaN(), qQNaN(),   // reserved
                                 true,                        // autoContinue
                                 false,                       // isCurrentItem
                                 parent);
        break;
    }
    if (action){
        list.append(action);
    }
    return list;
}
