
#include "JsonParsing.h"
#include "QGroundControlQmlGlobal.h"
#include "MissionCommandTree.h"
#include "MissionCommandUIInfo.h"
#include "MultiVehicleManager.h"
#include "TerrainQuery.h"
#include "Vehicle.h"
#include "VehicleSupports.h"
#include "MissionItem.h"
#include "waypoint.h"
#include "gisesPlugin.h"
#include "gisesPlan.h"
#include "gisesManager.h"

Waypoint::Waypoint(double altitude, QObject* parent)
    :MissionNode(waypoint, parent)
    , _autoContinueFact (0, "AutoContinue", FactMetaData::valueTypeUint32)
    , _commandFact      (0, "",             FactMetaData::valueTypeUint32)
    , _frameFact        (0, "",             FactMetaData::valueTypeUint32)
    , _p1Fact           (0, "Param1:",      FactMetaData::valueTypeDouble)
    , _p2Fact           (0, "Param2:",      FactMetaData::valueTypeDouble)
    , _p3Fact           (0, "Param3:",      FactMetaData::valueTypeDouble)
    , _p4Fact           (0, "Param4:",      FactMetaData::valueTypeDouble)
    , _p5Fact           (0, "Latitude:",    FactMetaData::valueTypeDouble)
    , _p6Fact           (0, "Longitude:",   FactMetaData::valueTypeDouble)
    , _p7Fact           (0, "Altitude:",    FactMetaData::valueTypeDouble)
    ,_altitude(altitude)
    ,_altModeFact		(0, "Altitude Mode",FactMetaData::valueTypeInt32)
    ,_camera(this)
    ,_point(this)
{
    _commandFact.setRawValue(MAV_CMD_NAV_WAYPOINT);
    _frameFact.setRawValue(MAV_FRAME_GLOBAL_RELATIVE_ALT);
    _autoContinueFact.setRawValue(true);
    _altModeFact.setMetaData(new FactMetaData(FactMetaData::valueTypeInt32, &_altModeFact));
    _altModeFact.setRawValue(MAV_FRAME_GLOBAL_RELATIVE_ALT);
    init();
}

Waypoint::Waypoint(QGeoCoordinate coordinate, double altitude, QObject* parent)
    :MissionNode(waypoint, parent)
    , _autoContinueFact (0, "AutoContinue", FactMetaData::valueTypeUint32)
    , _commandFact      (0, "",             FactMetaData::valueTypeUint32)
    , _frameFact        (0, "",             FactMetaData::valueTypeUint32)
    , _p1Fact           (0, "Param1:",      FactMetaData::valueTypeDouble)
    , _p2Fact           (0, "Param2:",      FactMetaData::valueTypeDouble)
    , _p3Fact           (0, "Param3:",      FactMetaData::valueTypeDouble)
    , _p4Fact           (0, "Param4:",      FactMetaData::valueTypeDouble)
    , _p5Fact           (0, "Latitude:",    FactMetaData::valueTypeDouble)
    , _p6Fact           (0, "Longitude:",   FactMetaData::valueTypeDouble)
    , _p7Fact           (0, "Altitude:",    FactMetaData::valueTypeDouble)
    ,_altitude(altitude)
    ,_altModeFact		(0, "Altitude Mode",FactMetaData::valueTypeInt32)
    ,_camera(this)
    ,_point(coordinate, this)
{
    _commandFact.setRawValue(MAV_CMD_NAV_WAYPOINT);
    _frameFact.setRawValue(MAV_FRAME_GLOBAL_RELATIVE_ALT);
    _autoContinueFact.setRawValue(true);
    _altModeFact.setMetaData(new FactMetaData(FactMetaData::valueTypeDouble, &_altModeFact));
    _altModeFact.setRawValue(MAV_FRAME_GLOBAL_RELATIVE_ALT);
    _p5Fact.setRawValue(coordinate.latitude());
    _p6Fact.setRawValue(coordinate.longitude());
    init();
    reqTerrainAlt();
}

void Waypoint::init(){
    _gises = qobject_cast<GisesPlugin*>(GisesPlugin::instance())->gises();
    _paramsMeta.resize(7,FactMetaData(FactMetaData::valueTypeDouble, this));
    _paramsUiType.resize(7);
    updateUiData();
    FactMetaData* cmd = _plan->frameMetaData();
    _frameFact.setEnumInfo(cmd->enumStrings(), cmd->enumValues());
    connect(&_commandFact, &Fact::rawValueChanged, this, &Waypoint::updateUiData);
    connect(_gises, &GisesManager::vehicleChanged, this, &Waypoint::updateUiData);
    connect(_gises->vehicle(), &Vehicle::firmwareTypeChanged, this, &Waypoint::updateUiData);
    connect(this, &Waypoint::coordChanged, this, &Waypoint::reqTerrainAlt);
    connect(this, &Waypoint::altitudeChanged, this, &Waypoint::updateAmsl);
    connect(&_altModeFact, &Fact::rawValueChanged, this, &Waypoint::updateAmsl);
    connect(&_camera, &WaypointCamera::allActionChanged, this, &Waypoint::updatePoint);
}
void Waypoint::save(QJsonArray& array, const QString& suffix){
    Q_UNUSED(suffix)
    QJsonObject item;
    item["type"] = _nodeType;
    if(showAlt()){
        item["Altitude"] = _altitude;
        int mode = 0;
        switch(_altModeFact.rawValue().toInt()){
        case -1:{
            mode = QGroundControlQmlGlobal::AltitudeFrameCalcAboveTerrain;
            break;
        }
        case MAV_FRAME_GLOBAL_RELATIVE_ALT:{
            mode = QGroundControlQmlGlobal::AltitudeFrameRelative;
            break;
        }
        case MAV_FRAME_GLOBAL:{
            mode = QGroundControlQmlGlobal::AltitudeFrameAbsolute;
            break;
        }
        case MAV_FRAME_GLOBAL_TERRAIN_ALT:{
            mode = QGroundControlQmlGlobal::AltitudeFrameTerrain;
            break;
        }
        }
        item["AltitudeMode"] = mode;
        if(-1 == _altModeFact.rawValue().toInt() ||
            MAV_FRAME_GLOBAL_TERRAIN_ALT == _altModeFact.rawValue().toInt()){
            item["AMSLAltAboveTerrain"] = _point.amsl();
        }else{
            item["AMSLAltAboveTerrain"] = qQNaN();
        }
    }
    item["autoContinue"] = _autoContinueFact.rawValue().toBool();
    item["command"] = _commandFact.rawValue().toInt();
    item["doJumpId"] = _sequence;
    item["frame"] = _frameFact.rawValue().toInt();
    QJsonArray param;
    param.append(_p1Fact.rawValue().toDouble());
    param.append(_p2Fact.rawValue().toDouble());
    param.append(_p3Fact.rawValue().toDouble());
    param.append(_p4Fact.rawValue().toDouble());
    param.append(_p5Fact.rawValue().toDouble());
    param.append(_p6Fact.rawValue().toDouble());
    param.append(_p7Fact.rawValue().toDouble());
    item["params"] = param;
    array.append(item);
}
void Waypoint::load(const QJsonObject& node){
    Vehicle* vehicle = _gises->vehicle();
    bool supportTerrain = vehicle->supports()->terrainFrame();
    if(node.contains("Altitude")){
        _altitude = node["Altitude"].toDouble();
    }
    if(node.contains("AltitudeMode")){
        switch(node["AltitudeMode"].toInt()){
        case QGroundControlQmlGlobal::AltitudeFrameCalcAboveTerrain:{
            if(supportTerrain){
                _altModeFact.setEnumIndex(3);
            }else{
                _altModeFact.setEnumIndex(1);
            }
            break;
        }
        case QGroundControlQmlGlobal::AltitudeFrameRelative:{
            _altModeFact.setEnumIndex(0);
            break;
        }
        case QGroundControlQmlGlobal::AltitudeFrameAbsolute:{
            _altModeFact.setEnumIndex(1);
            break;
        }
        case QGroundControlQmlGlobal::AltitudeFrameTerrain:{
            _altModeFact.setEnumIndex(2);
            break;
        }
        }
    }
    if(node.contains("AMSLAltAboveTerrain")){
        double amsl = JsonParsing::possibleNaNJsonValue(node["AMSLAltAboveTerrain"]);
        if(!qIsNaN(amsl) && supportTerrain && MAV_FRAME_GLOBAL == node["frame"].toInt()){
            _altModeFact.setRawValue(-1);
        }
    }
    _autoContinueFact.setRawValue(node["autoContinue"].toBool());
    _commandFact.setRawValue(node["command"].toInt());
    _frameFact.setRawValue(node["frame"].toInt());
    _sequence = node["doJumpId"].toInt();
    const QJsonArray& array = node["params"].toArray();
    _p1Fact.setRawValue(array[0].toDouble());
    _p2Fact.setRawValue(array[1].toDouble());
    _p3Fact.setRawValue(array[2].toDouble());
    _p4Fact.setRawValue(array[3].toDouble());
    _p5Fact.setRawValue(array[4].toDouble());
    _p6Fact.setRawValue(array[5].toDouble());
    _p7Fact.setRawValue(array[6].toDouble());
    const MissionCommandUIInfo* uiInfo = MissionCommandTree::instance()->getUIInfo(vehicle, vehicle->vehicleClass(), (MAV_CMD)_commandFact.rawValue().toInt());
    if(uiInfo->specifiesCoordinate()){
        _point.setCoord(QGeoCoordinate(array[4].toDouble(), array[5].toDouble()));
        emit coordChanged();
    }
    emit sequenceChanged();
    reqTerrainAlt();
}
void Waypoint::genMissionItem(QList<MissionItem*>& list, QObject* parent){
    MissionItem* item = nullptr;
    int seqNum = list.size() + 1;
    item = new MissionItem(seqNum++,
                           (MAV_CMD)_commandFact.rawValue().toInt(),
                           (MAV_FRAME)_frameFact.rawValue().toInt(),
                           _p1Fact.rawValue().toDouble(),
                           _p2Fact.rawValue().toDouble(),
                           _p3Fact.rawValue().toDouble(),
                           _p4Fact.rawValue().toDouble(),
                           _p5Fact.rawValue().toDouble(),
                           _p6Fact.rawValue().toDouble(),
                           _p7Fact.rawValue().toDouble(),
                           _autoContinueFact.rawValue().toBool(),
                           _isCurrentItem,
                           parent);
    list.append(item);
    if(MAV_CMD_NAV_WAYPOINT == _commandFact.rawValue().toInt()){
        list.append(_camera.genMissionItem(seqNum, parent));
    }
}
bool Waypoint::loadAction(const QJsonObject& act){
    const QJsonArray& params = act["params"].toArray();
    int cmd = act["command"].toInt();
    //bool result = true;
    if(MAV_CMD_SET_CAMERA_MODE == cmd){
        if(!_camera.cameraModeSupported() || _camera.specifyCameraMode()){
            return false;
        }
        _camera.setSpecifyCameraMode(true);
        _camera.setCameraMode(params[1].toInt());
    }else if(MAV_CMD_DO_MOUNT_CONTROL == cmd){
        if(_camera.specifyCameraMode()){
            return false;
        }
        _camera.setGimbalAdjust(true);
        _camera.setGimbalPitch(params[0].toDouble());
        _camera.setGimbalYaw(params[2].toDouble());
    }else{
        if(_camera.actionIndex()){
            return 4 == _camera.actionIndex() && MAV_CMD_IMAGE_STOP_CAPTURE == cmd;
        }else{
            if(MAV_CMD_IMAGE_START_CAPTURE == cmd){
                int time = params[1].toInt();
                if(time){
                    _camera.setActionIndex(1);
                    _camera.setActionTime(time);
                }else{
                    _camera.setActionIndex(3);
                }
            }else if(MAV_CMD_DO_SET_CAM_TRIGG_DIST == cmd){
                double dist = params[0].toDouble();
                if(dist > 0.0001){
                    _camera.setActionIndex(2);
                    _camera.setActionDistance(dist);
                }else{
                    _camera.setActionIndex(4);
                }
            }else if(MAV_CMD_VIDEO_START_CAPTURE == cmd){
                _camera.setActionIndex(5);
            }else if(MAV_CMD_VIDEO_STOP_CAPTURE == cmd){
                _camera.setActionIndex(6);
            }else if(MAV_CMD_IMAGE_STOP_CAPTURE == cmd){
                if(4 != _camera.actionIndex()){
                    return false;
                }
            }else{
                return false;
            }
        }
    }
    return true;
}

bool Waypoint::isTakeoff(){
    return MAV_CMD_NAV_TAKEOFF == _commandFact.rawValue().toInt();
}
bool Waypoint::isLoiter(){
    int cmd = _commandFact.rawValue().toInt();
    switch((MAV_CMD)cmd){
    case MAV_CMD_NAV_LOITER_TO_ALT:{
        connect(&_p2Fact, &Fact::rawValueChanged, this, &Waypoint::loiterRadiusChanged, Qt::UniqueConnection);
        return true;
    }
    case MAV_CMD_NAV_LOITER_TIME:
    case MAV_CMD_NAV_LOITER_UNLIM:
    case MAV_CMD_NAV_LOITER_TURNS:{
        connect(&_p3Fact, &Fact::rawValueChanged, this, &Waypoint::loiterRadiusChanged, Qt::UniqueConnection);
        return true;
    }
    default:{
        disconnect(&_p2Fact, &Fact::rawValueChanged, this, &Waypoint::loiterRadiusChanged);
        disconnect(&_p3Fact, &Fact::rawValueChanged, this, &Waypoint::loiterRadiusChanged);
        return false;
    }
    }
}
double Waypoint::loiterRadius(){
    int cmd = _commandFact.rawValue().toInt();
    switch((MAV_CMD)cmd){
    case MAV_CMD_NAV_LOITER_TO_ALT:
        return _p2Fact.rawValue().toDouble();
    case MAV_CMD_NAV_LOITER_TIME:
    case MAV_CMD_NAV_LOITER_UNLIM:
    case MAV_CMD_NAV_LOITER_TURNS:{
        return _p3Fact.rawValue().toDouble();
    }
    default:
        return 0;
    }
}
void Waypoint::setLoiterRadius(double radius){
    int cmd = _commandFact.rawValue().toInt();
    switch((MAV_CMD)cmd){
    case MAV_CMD_NAV_LOITER_TO_ALT:
        if(qAbs(radius - _p2Fact.rawValue().toDouble()) > 0.001){
            _p2Fact.setRawValue(radius);
        }
        break;
    case MAV_CMD_NAV_LOITER_TIME:
    case MAV_CMD_NAV_LOITER_UNLIM:
    case MAV_CMD_NAV_LOITER_TURNS:{
        if(qAbs(radius - _p3Fact.rawValue().toDouble()) > 0.001){
            _p3Fact.setRawValue(radius);
        }
        break;
    }
    default:
        return;
    }
}
QGeoCoordinate Waypoint::coord(){
    if(!std::isfinite(_p5Fact.rawValue().toDouble()) || !std::isfinite(_p6Fact.rawValue().toDouble())) {
        //-- If either of these are NAN, return an invalid (QGeoCoordinate::isValid() == false) coordinate
        return QGeoCoordinate();
    }
    //return QGeoCoordinate(_p5Fact.rawValue().toDouble(), _p6Fact.rawValue().toDouble(), _p7Fact.rawValue().toDouble());
    return _point.coord();
}
void Waypoint::setIsHome(bool isHome){
    if(_isHome != isHome){
        _isHome = isHome;
        emit isHomeChanged();
    }
}
void Waypoint::setCoord(QGeoCoordinate coord){
    if(_p5Fact.rawValue().toDouble() != coord.latitude() || _p6Fact.rawValue().toDouble() != coord.longitude()){
        _p5Fact.setRawValue(coord.latitude());
        _p6Fact.setRawValue(coord.longitude());
        _point.setCoord(coord);
        emit coordChanged();
    }
}
void Waypoint::setAltitude(double alt){
    if(qAbs(alt - _altitude) > 0.01){
        _altitude = alt;
        emit altitudeChanged();
    }
}
void Waypoint::setIsCurrentItem(bool isCurrent){
    if(_isCurrentItem != isCurrent){
        _isCurrentItem = isCurrent;
        emit isCurrentItemChanged();
    }
}
void Waypoint::setRawMode(bool raw){
    if(_rawMode != raw){
        _rawMode = raw;
        emit rawModeChanged();
        updateUiData();
    }
}
void Waypoint::setCalcAboveTerrain(bool above){
    if(_calcAboveTerrain != above){
        _calcAboveTerrain = above;
        emit calcAboveTerrainChanged();
    }
}
bool Waypoint::showFriendly(){
    Vehicle* vehicle = _gises->vehicle();
    QGCMAVLink::VehicleClass_t type = QGCMAVLink::VehicleClassGeneric;
    vehicle->fixedWing() ? type = QGCMAVLink::VehicleClassFixedWing : type = QGCMAVLink::VehicleClassMultiRotor;
    const MissionCommandUIInfo* uiInfo = MissionCommandTree::instance()->getUIInfo(vehicle, type, (MAV_CMD)_commandFact.rawValue().toInt());
    if (uiInfo && uiInfo->friendlyEdit()) {
        if (!_autoContinueFact.rawValue().toBool()) {
            return false;
        }

        if (showAlt()) {
            MAV_FRAME frame = (MAV_FRAME)_frameFact.rawValue().toInt();
            switch (frame) {
            case MAV_FRAME_GLOBAL:
            case MAV_FRAME_GLOBAL_RELATIVE_ALT:
            case MAV_FRAME_GLOBAL_TERRAIN_ALT:
                return true;
            default:
                return false;
            }
        }
        return true;
    }
    return false;
}

bool Waypoint::showCoord(){
    Vehicle* vehicle = _gises->vehicle();
    const MissionCommandUIInfo* uiInfo = MissionCommandTree::instance()->getUIInfo(vehicle, vehicle->vehicleClass(), (MAV_CMD)_commandFact.rawValue().toInt());
    bool show = false;
    show = uiInfo && (uiInfo->specifiesCoordinate() || MAV_CMD_NAV_TAKEOFF == _commandFact.rawValue().toInt());
    if(show){
        _p5Fact.metaData()->setDecimalPlaces(7);
        _p6Fact.metaData()->setDecimalPlaces(7);
    }else{
        _p5Fact.metaData()->setDecimalPlaces(3);
        _p6Fact.metaData()->setDecimalPlaces(3);
    }
    return show;
}
bool Waypoint::showAlt(){
    Vehicle* vehicle = _gises->vehicle();
    const MissionCommandUIInfo* uiInfo = MissionCommandTree::instance()->getUIInfo(vehicle, vehicle->vehicleClass(), (MAV_CMD)_commandFact.rawValue().toInt());
    bool show = false;
    if (uiInfo)
        show = uiInfo->specifiesCoordinate() || uiInfo->specifiesAltitudeOnly();
    if(!show){
        _altitude = 0;
        _p7Fact.setRawValue(0.0);
    }
    return show;
}

//SLOTS
void Waypoint::updateUiData(){
    Vehicle* vehicle = _gises->vehicle();
    const MissionCommandUIInfo* uiInfo = MissionCommandTree::instance()->getUIInfo(vehicle, vehicle->vehicleClass(), (MAV_CMD)_commandFact.rawValue().toInt());
    FactMetaData* defaultMeta = _plan->defaultParamMetaData();
    QStringList frameStrings;
    QVariantList frameValues;
    frameStrings << "Relative To Launch" << "AMSL" << "Terrain Frame";
    frameValues << MAV_FRAME_GLOBAL_RELATIVE_ALT << MAV_FRAME_GLOBAL << MAV_FRAME_GLOBAL_TERRAIN_ALT;
    if(vehicle->supports()->terrainFrame()){
        frameStrings << "Calculated Above Terrain";
        frameValues << -1;
    }
    _altModeFact.setEnumInfo(frameStrings, frameValues);
    _allParams.clear();
    FactMetaData* meta = _plan->simpleMetaData();
    if(showFriendly() && !_rawMode){
        Fact* paramFacts[7] = { &_p1Fact, &_p2Fact, &_p3Fact, &_p4Fact, &_p5Fact, &_p6Fact, &_p7Fact };
        FactMetaData* paramMetaData[7] = { &_paramsMeta[0], &_paramsMeta[1], &_paramsMeta[2], &_paramsMeta[3], &_paramsMeta[4], &_paramsMeta[5], &_paramsMeta[6] };
        if (uiInfo) {
            if(uiInfo->specifiesCoordinate())
            for (int i=1; i<=7; i++) {
                bool showUI;
                const MissionCmdParamInfo* paramInfo = uiInfo->getParamInfo(i, showUI);

                if (showUI && paramInfo) {
                    _paramsUiType[i-1] = 0;
                    Fact*               paramFact =     paramFacts[i-1];
                    FactMetaData*       paramMeta = paramMetaData[i-1];

                    paramFact->setName(paramInfo->label());
                    paramMeta->setDecimalPlaces(paramInfo->decimalPlaces());
                    paramMeta->setEnumInfo(paramInfo->enumStrings(), paramInfo->enumValues());
                    paramMeta->setRawUnits(paramInfo->units());
                    paramMeta->setRawDefaultValue(paramInfo->defaultValue());
                    paramMeta->setRawMin(paramInfo->min());
                    paramMeta->setRawMax(paramInfo->max());
                    paramFact->setMetaData(paramMeta, true);
                    if(paramFact->name().contains("speed")){
                        _paramsUiType[i-1] = Slider;
                    }
                    if(paramMeta->name().contains("altitude")){
                        _paramsUiType[i-1] = Valuebox;
                    }
                    if(paramMeta->enumStrings().count()){
                        _paramsUiType[i-1] = Combobox;
                    }
                    _allParams.append(paramFact);
                }
            }
        }
    }else{
        _p1Fact.setName("Param1");
        _p1Fact.setMetaData(defaultMeta);
        _allParams.append(&_p1Fact);
        _p2Fact.setName("Param2");
        _p2Fact.setMetaData(defaultMeta);
        _allParams.append(&_p2Fact);
        _p3Fact.setName("Param3");
        _p3Fact.setMetaData(defaultMeta);
        _allParams.append(&_p3Fact);
        _p4Fact.setName("Param4");
        _p4Fact.setMetaData(defaultMeta);
        _allParams.append(&_p4Fact);
        _p5Fact.setName("Lat/X");
        _p5Fact.setMetaData(defaultMeta);
        _allParams.append(&_p5Fact);
        _p6Fact.setName("Lon/Y");
        _p6Fact.setMetaData(defaultMeta);
        _allParams.append(&_p6Fact);
        _p7Fact.setName("Alt/Z");
        _p7Fact.setMetaData(defaultMeta);
        _allParams.append(&_p7Fact);
        meta = _plan->commandMetaData();
    }
    _commandFact.setEnumInfo(meta->enumStrings(), meta->enumValues());
    emit _commandFact.valueChanged(_commandFact.rawValue());
    emit missionUiChanged();
    emit isTakeoffChanged();
    emit isLoiterChanged();
    emit loiterRadiusChanged();
}


void Waypoint::updateAmsl(){
    double alt = _altitude;
    //RoutePlan* plan = qobject_cast<RoutePlan*>(Manager::instance()->planManager()->routePlan());
    _frameFact.setRawValue(_altModeFact.rawValue().toInt());
    _p7Fact.setRawValue(_altitude);
    switch(_altModeFact.rawValue().toInt()){
    case MAV_FRAME_GLOBAL:{
        break;
    }
    case MAV_FRAME_GLOBAL_RELATIVE_ALT:{
        if(!qIsNaN(_plan->home().altitude()))
            alt += _plan->home().altitude();
        break;
    }
    case -1:{
        alt += _point.coord().altitude();
        _frameFact.setRawValue(MAV_FRAME_GLOBAL);
        _p7Fact.setRawValue(alt);
        break;
    }
    case MAV_FRAME_GLOBAL_TERRAIN_ALT:
    {
        alt += _point.coord().altitude();
        break;
    }
    }
    _point.setAmsl(alt);
    emit amslChanged();
}

void Waypoint::updatePoint(){
    _point.setAction(_camera.allActions());
}

void Waypoint::reqTerrainAlt(){
    if(showCoord()){
        _query = new TerrainAtCoordinateQuery(true);
        connect(_query, &TerrainAtCoordinateQuery::terrainDataReceived, this, &Waypoint::onRecvTerrainAlt);
        QGeoCoordinate coordinate = coord();
        if (coordinate.isValid()) {
            QList<QGeoCoordinate> list;
            list.append(coordinate);
            _query->requestData(list);
        } else {
            qDebug() << "地理坐标异常";
        }
    }
}

void Waypoint::onRecvTerrainAlt(bool success, QList<double> heights){
    double terrain = -1;
    if(success){
        terrain = heights.first();
    }
    _point.setTerrain(terrain);
    updateAmsl();
}
