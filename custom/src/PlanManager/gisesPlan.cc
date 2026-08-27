
#include <QObject>
#include <QQueue>
#include <QRect>
#include <QStack>
#include <QtQml/qqml.h>
#include <QGCApplication.h>
#include "AppSettings.h"
#include "JsonParsing.h"
#include "MissionItem.h"
#include "MissionManager.h"
#include "MultiVehicleManager.h"
#include "SettingsManager.h"
#include "TerrainQuery.h"
#include "Vehicle.h"
#include "FirmwarePlugin.h"
#include "geoPoint.h"
#include "geoLine.h"
#include "geoShape.h"
#include "geoPolygon.h"
#include "geoCorridor.h"
#include "polygonArea.h"
#include "corridorArea.h"
#include "surveySetup.h"
#include "waypoint.h"
#include "landNode.h"
#include "planSummary.h"
#include "gisesPlan.h"
#include "gisesManager.h"

Q_LOGGING_CATEGORY(GisesPlanLog, "GisesPlanLog")

GisesPlan::GisesPlan(QObject* parent)
    :QObject(parent)
    ,_summary(new PlanSummary(this))
    , _land(new LandNode(_defaultAlt, this))
    ,_planModel(this)
    ,_nodeSequence(this)
    ,_surveyAreaModel(this)
    ,_waypointModel(this)
    ,_flightPathModel(this)
{
    _gises = qobject_cast<GisesManager*>(parent);
    if (nullptr == _gises) {
        qCCritical(GisesPlanLog) << "critical plan error";
    }
}

void GisesPlan::init(){
    _land->init();
    _vehicle = _gises->vehicle();
    connect(_gises, &GisesManager::vehicleChanged, this, &GisesPlan::onVehicleChanged);
    if(!_vehicle->isOfflineEditingVehicle()){
        connect(_vehicle, &Vehicle::homePositionChanged, this, &GisesPlan::setHome);
    }
    //connect(this, &GisesPlan::currentIndexChanged, this, &GisesPlan::adjustFlightPath);
    //connect(this, &GisesPlan::currentIndexChanged, this, &GisesPlan::updateInformation);
    connect(this, &GisesPlan::initChartData, this, &GisesPlan::updateInformation);
    connect(this, &GisesPlan::validChanged, this, &GisesPlan::onLandModeChanged);
    connect(_land, &LandNode::landModeChanged, this, &GisesPlan::onLandModeChanged);
    loadPlans();
}

FactMetaData* GisesPlan::commandMetaData()
{
    return _gises->commandMetaData();
}

FactMetaData* GisesPlan::defaultParamMetaData()
{
    return _gises->defaultParamMetaData();
}

FactMetaData* GisesPlan::frameMetaData()
{
    return _gises->frameMetaData();
}

FactMetaData* GisesPlan::simpleMetaData()
{
    return _gises->simpleMetaData();
}

void GisesPlan::loadPlans(){
    // Load plans from the default path
    QString planPath = SettingsManager::instance()->appSettings()->missionSavePath();
    QDir fileDir(planPath);
    QStringList list;
    QStringList planList;
    if(fileDir.exists()){
        planList = fileDir.entryList(list<<"*.plan"<<"*.sp"<<"*.jplan"<<"*.mission", QDir::Files, QDir::Name);
    }
    if(_planModel.count()){
        _planModel.clearAndDeleteContents();
    }
    QString errorStr;
    PlanSummary* summary = nullptr;
    for(int i=0; i<planList.size(); ++i){
        QFile file(planPath+"/"+planList[i]);
        QFileInfo info(file);
        QString suf = "." + info.suffix();
        if(file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)){
            summary = new PlanSummary(this);
            summary->setName(planList[i].replace(suf, ""));
            summary->setSuffix(suf);
            QByteArray bytes = file.readAll();
            QJsonDocument jsonDoc;
            if (!JsonParsing::isJsonFile(bytes, jsonDoc, errorStr)) {
                qDebug()<<"Load json failed: "<<errorStr;
            }
            QJsonObject json = jsonDoc.object();
            QStringList firmString = SettingsManager::instance()->appSettings()->offlineEditingFirmwareClass()->enumStrings();
            QVariantList firmValue = SettingsManager::instance()->appSettings()->offlineEditingFirmwareClass()->enumValues();
            QJsonObject source;
            if(!json.contains("groundStation")){
                qDebug()<<"load plan error";
                return;
            }
            QString gs = json["groundStation"].toString();
            if(gs == "QGroundControl"){
                source = json["mission"].toObject();
            }else if(gs == "MissionPlanner"){
                source = json["mission"].toObject();
            }else{
                source = json["mission"].toObject();
            }
            if(source.contains("firmwareType")){
                for(int j=0; j<firmValue.count(); ++j){
                    if(source["firmwareType"].toInt() == firmValue[j].toInt()){
                        summary->setFirmware(firmString[j]);
                        break;
                    }
                }
            }else{
                summary->setFirmware("Error");
            }
            if(source.contains("totalDistance")){
                summary->setTotalDistance(source["totalDistance"].toDouble());
            }
            if(source.contains("totalArea")){
                summary->setTotalArea(source["routeArea"].toDouble());
            }
            if(source.contains("flyTime")){
                summary->setFlyTime(source["flyTime"].toInt());
            }
            if(source.contains("photoShot")){
                summary->setPhotoShot(source["photoShot"].toInt());
            }
            _planModel.append(summary);
        }
    }
}
void GisesPlan::removePlan(int index){
    PlanSummary* plan = qobject_cast<PlanSummary*>(_planModel.get(index));
    _planModel.removeAt(index);
    if(plan){
        QString planPath = SettingsManager::instance()->appSettings()->missionSavePath();
        QFile file(planPath+"/"+plan->name()+".plan");
        if(file.exists()){
            file.remove();
        }
        plan->deleteLater();
    }
}
bool GisesPlan::sendToVehicle(){
    _gises->sendMissions();
    return true;
}
void GisesPlan::generateItems(QList<MissionItem*>& items, QObject* parent){
    if(_geoPoints.size()){
        if(_vehicle->firmwarePlugin()->sendHomePositionToVehicle()){
            MissionItem* item = new MissionItem(1,
                                                MAV_CMD_NAV_WAYPOINT,
                                                MAV_FRAME_GLOBAL,
                                                0, 0, 0, 0,
                                                _home.latitude(),
                                                _home.longitude(),
                                                _home.altitude() + _defaultAlt,
                                                true,
                                                false,
                                                parent);
            items.append(item);
        }
        for(int i=0; i<_nodeSequence.count(); ++i){
            MissionNode* node = qobject_cast<MissionNode*>(_nodeSequence.get(i));
            node->genMissionItem(items, parent);
        }
        if(_land->landMode()){
            _land->genMissionItem(items, parent);
        }
    }
}
void GisesPlan::saveAsJson(QJsonObject& mission){
    if(_geoPoints.size()){
        mission["planMode"] = _planMode;
        mission["firmwareType"] = _vehicle->firmwareType();
        mission["vehicleType"] = _vehicle->vehicleType();
        mission["cruiseSpeed"] = _vehicle->defaultCruiseSpeed();
        mission["hoverSpeed"] = _vehicle->defaultHoverSpeed();

        mission["totalDistance"] = _summary->totalDistance();
        mission["totalArea"] = _summary->totalArea();
        mission["flyTime"] = _summary->flyTime();
        mission["photoShot"] = _summary->photoShot();
        if(_home.isValid()){
            QJsonArray home;
            home = { _home.latitude(),
                    _home.longitude(),
                    _home.altitude() };
            mission["plannedHomePosition"] = home;
        }
        QJsonArray array;
        for(int i=0; i<_nodeSequence.count(); ++i){
            MissionNode* node = qobject_cast<MissionNode*>(_nodeSequence.get(i));
            node->save(array, _summary->suffix());
        }
        if(_land->landMode()){
            _land->save(array, _summary->suffix());
        }
        if("jplan" == _summary->suffix()){
            //保存节点数据
            mission["nodes"] = array;
        }else if("plan" == _summary->suffix()){
            //保存航点信息
            mission["items"] = array;
        }
    }
}
void GisesPlan::loadFromJson(const QJsonObject& mission, const QString& fileName){
    MissionNode *node = nullptr;
    Waypoint *point = nullptr;
    QString name, suffix;
    name = fileName.left(fileName.lastIndexOf("."));
    suffix = fileName.right(fileName.size() - name.size() - 1);
    _summary->setName(name);
    clear();
    if(suffix == "jplan"){
        setPlanMode((PlanMode)mission["planMode"].toInt());
        const QJsonArray& nodeArray = mission["nodes"].toArray();
        for(int i=0; i<nodeArray.size(); ++i){
            const QJsonObject& json = nodeArray[i].toObject();
            if(MissionNode::waypoint == json["type"].toInt()){
                int cmd = json["command"].toInt();
                if(point && point->loadAction(json)){
                    continue;
                }
                node = new Waypoint(_defaultAlt, this);
                if(MAV_CMD_NAV_WAYPOINT == cmd) point = qobject_cast<Waypoint*>(node);
                if((MAV_CMD_NAV_VTOL_TAKEOFF == cmd || MAV_CMD_NAV_TAKEOFF == cmd) && !_takeOff){
                    _takeOff = point = qobject_cast<Waypoint*>(node);
                    _takeOff->setCoord(_home);
                    _takeOff->setIsHome(true);
                }
                _waypointModel.append(node);
            }else{
                point = nullptr;
                if(json.contains("leftWidth") && json.contains("rightWidth")){
                    node = new CorridorArea(this);
                }else{
                    node = new PolygonArea(this);
                }
                _surveyAreaModel.append(node);
            }
            node->load(json);
            node->setActive(false);
            _nodeSequence.append(node);
            adjustFlightPath(Add, node);
            if(MissionNode::waypoint == json["type"].toInt()){
                if(node->isHome()){
                    connect((Waypoint*)node, &Waypoint::coordChanged, this, &GisesPlan::onHomeChanged);
                    connect((Waypoint*)node, &Waypoint::amslChanged, this, &GisesPlan::updateRelative);
                }else{
                    if(node->valid() && MissionNode::waypoint == node->nodeType() &&
                        MAV_FRAME_GLOBAL_RELATIVE_ALT == qobject_cast<Waypoint*>(node)->altModeFact()->rawValue()){
                        _loadingList.append(node);
                    }
                    connect((Waypoint*)node, &Waypoint::amslChanged, this, &GisesPlan::updateFlightPath);
                }
            }else{
                if(node->valid() && MissionNode::surveyArea == node->nodeType() &&
                    MAV_FRAME_GLOBAL_RELATIVE_ALT == qobject_cast<SurveyArea*>(node)->setup()->camera()->altMode()->rawValue()){
                    _loadingList.append(node);
                }
                connect(this, &GisesPlan::homeChanged, (SurveyArea*)node, &SurveyArea::checkSafety);
                connect((SurveyArea*)node, &SurveyArea::validChanged, this, &GisesPlan::onAreaValidChanged);
                connect((SurveyArea*)node, &SurveyArea::pathChanged, this, &GisesPlan::updateFlightPath);
            }
        }
    }else if(suffix == "plan"){
        const QJsonArray& nodeArray = mission["items"].toArray();
        for(int i=0; i<nodeArray.size(); ++i){
            const QJsonObject& json = nodeArray[i].toObject();
            int cmd = json["command"].toInt();
            if(point && point->loadAction(json)){
                continue;
            }
            node = new Waypoint(_defaultAlt, this);
            if(!_takeOff){
                if(MAV_CMD_NAV_VTOL_TAKEOFF == cmd || MAV_CMD_NAV_TAKEOFF == cmd){
                    _takeOff = qobject_cast<Waypoint*>(node);
                    _takeOff->setCoord(_home);
                    _takeOff->setIsHome(true);
                }else{
                    insertTakeoff();
                }
            }
            node->load(json);
            node->setActive(false);
            if(MAV_CMD_NAV_WAYPOINT == cmd) point = qobject_cast<Waypoint*>(node);
            _waypointModel.append(node);
            _nodeSequence.append(node);
            adjustFlightPath(Add, node);
            if(node->isHome()){
                connect((Waypoint*)node, &Waypoint::coordChanged, this, &GisesPlan::onHomeChanged);
                connect((Waypoint*)node, &Waypoint::amslChanged, this, &GisesPlan::updateRelative);
            }else{
                if(node->valid() && MissionNode::waypoint == node->nodeType() &&
                    MAV_FRAME_GLOBAL_RELATIVE_ALT == qobject_cast<Waypoint*>(node)->altModeFact()->rawValue()){
                    _loadingList.append(node);
                }
                connect((Waypoint*)node, &Waypoint::amslChanged, this, &GisesPlan::updateFlightPath);
            }
        }
    }
    _currentNode = _nodeSequence.get(_nodeSequence.count()-1);
    if(_currentNode){
        qobject_cast<MissionNode*>(_currentNode)->setActive(true);
    }
    updateInformation();
    emit takeoffChanged();
    emit validChanged();
    emit currentNodeChanged();
    emit currentIndexChanged();
    AppSettings* apps = SettingsManager::instance()->appSettings();
    if(_vehicle->isOfflineEditingVehicle()){
        apps->offlineEditingFirmwareClass()->setRawValue(QGCMAVLink::firmwareClass(static_cast<MAV_AUTOPILOT>(mission["firmwareType"].toInt())));
        apps->offlineEditingVehicleClass()->setRawValue(QGCMAVLink::vehicleClass(static_cast<MAV_TYPE>(mission["vehicleType"].toInt())));
        apps->offlineEditingCruiseSpeed()->setRawValue(mission["cruiseSpeed"].toDouble());
        apps->offlineEditingHoverSpeed()->setRawValue(mission["hoverSpeed"].toDouble());
    }
}
void GisesPlan::loadFromVehicle(QList<MissionItem*>& items){
    Q_UNUSED(items);
}

void GisesPlan::initHome(QGeoCoordinate coord){
    if(coord.isValid()){
        _home = coord;
    }
}
void GisesPlan::onMapClicked(QGeoCoordinate coord){
    double lastAltitude = 0;
    if(_waypointModel.count()){
        lastAltitude = qobject_cast<Waypoint*>(_waypointModel.get(_waypointModel.count()-1))->altitude();
    }else{
        insertTakeoff();
    }
    if(_currentNode == _land){
        _currentNode = _nodeSequence.get(_nodeSequence.count() - 1);
    }
    //点击地图
    switch(_planMode){
    case WAYPOINT:{
        Waypoint *node = new Waypoint(coord, lastAltitude, this);
        connect(this, &GisesPlan::homeChanged, node, &Waypoint::updateAmsl);
        insertNode(node);
        break;
    }
    case PLANAR:
    case ROAD:
    case STRUCTURE:{
        SurveyArea* area = qobject_cast<SurveyArea*>(_currentNode);
        if(area && area->active()){
            area->shape()->insert(coord);
        }
        break;
    }
    case WALL:{
        break;
    }
    case MIXED:{
        SurveyArea* area = qobject_cast<SurveyArea*>(_currentNode);
        if(area && area->active()){
            area->shape()->insert(coord);
        }else{
            Waypoint *node = new Waypoint(coord, lastAltitude, this);
            connect(this, &GisesPlan::homeChanged, node, &Waypoint::updateAmsl);
            insertNode(node);
        }
        break;
    }
    }
}

void GisesPlan::onNodeClicked(QObject* node){
    if(node == _land){
        if(_currentNode == _land){
            _land->setActive(!_land->active());
        }else{
            SurveyArea *area = qobject_cast<SurveyArea*>(_currentNode);
            Waypoint *point = qobject_cast<Waypoint*>(_currentNode);
            if(area) area->setActive(false);
            if(point) point->setActive(false);
            _land->setActive(true);
            _currentNode = _land;
            emit currentNodeChanged();
            emit currentIndexChanged();
        }
    }else{
        SurveyArea *area = qobject_cast<SurveyArea*>(_currentNode);
        Waypoint *point = qobject_cast<Waypoint*>(_currentNode);
        if(_currentNode == _land){
            _land->setActive(false);
        }else{
            if(area){
                _currentNode == node ? area->setActive(!area->active()) : area->setActive(false);
            }else{
                _currentNode == node ? point->setActive(!point->active()) : point->setActive(false);
            }
        }
        area = qobject_cast<SurveyArea*>(node);
        point = qobject_cast<Waypoint*>(node);
        if(_currentNode != node){
            if(area) area->setActive(true);
            if(point) point->setActive(true);
            _currentNode = node;
            emit currentNodeChanged();
            emit currentIndexChanged();
        }
    }
}

void GisesPlan::addPolygon(const QList<QGeoCoordinate>& coords){
    if(!_waypointModel.count()){
        insertTakeoff();
    }
    PolygonArea* area = new PolygonArea("Polygon " + QString::number(_surveyAreaModel.count()+1), this);
    if(coords.size()){
        qobject_cast<GeoPolygon*>(area->shape())->set(coords);
    }
    insertNode(area);
}

void GisesPlan::addCicle(QGeoCoordinate center){
    Q_UNUSED(center);
    if(!_waypointModel.count()){
        insertTakeoff();
    }
}

void GisesPlan::addCorridor(const QList<QGeoCoordinate>& coords){
    if(!_waypointModel.count()){
        insertTakeoff();
    }
    CorridorArea* area = new CorridorArea("Corridor " + QString::number(_surveyAreaModel.count()+1), this);
    for(int i=0; i<coords.size(); ++i){
        area->shape()->insert(coords[i]);
    }
    insertNode(area);
}

void GisesPlan::getNode(int step){
    int index = _nodeSequence.indexOf(_currentNode) + step;
    if(_currentNode == _land){
        index = _nodeSequence.count() - 1;
    }
    if(0 <= index && index < _nodeSequence.count()){
        onNodeClicked(_nodeSequence.get(index));
    }else if(index == _nodeSequence.count()){
        onNodeClicked(_land);
    }
}

void GisesPlan::moveTo(bool front){
    int index = _nodeSequence.indexOf(_currentNode);
    if((front && index) || (!front && index < _nodeSequence.count()-1)){
        _nodeSequence.removeAt(index);
        if(front){
            _nodeSequence.insert(index-1, _currentNode);
        }else{
            _nodeSequence.insert(index+1, _currentNode);
        }
    }
    adjustFlightPath(Alter, _currentNode);
    updateInformation();
    emit currentIndexChanged();
}

void GisesPlan::removeNode(){
    QObject* removeNode = nullptr;
    int size = _nodeSequence.count();
    if(size){
        if(1 == size){
            if(_nodeSequence.count()) _nodeSequence.clearAndDeleteContents();
            if(_surveyAreaModel.count()) _surveyAreaModel.clearAndDeleteContents();
            if(_waypointModel.count()) _waypointModel.clearAndDeleteContents();
            if(_flightPathModel.count()) _flightPathModel.clearAndDeleteContents();
            _currentNode = nullptr;
            _takeOff = nullptr;
        }else{
            int index = _nodeSequence.indexOf(_currentNode);
            if(!_currentNode){
                index = _nodeSequence.count() - 1;
            }
            removeNode = _nodeSequence.get(index);
            if(index == size - 1){
                _currentNode = _nodeSequence.get(index - 1);
            }else{
                _currentNode = _nodeSequence.get(index + 1);
            }
            qobject_cast<MissionNode*>(_currentNode)->setActive(true);
            if(qobject_cast<SurveyArea*>(removeNode)){
                _surveyAreaModel.removeOne(removeNode);
            }else{
                _waypointModel.removeOne(removeNode);
            }
            _nodeSequence.removeOne(removeNode);
        }
    }
    adjustFlightPath(Remove, removeNode);
    updateInformation();
    emit takeoffChanged();
    emit validChanged();
    emit currentNodeChanged();
    emit currentIndexChanged();
    if(removeNode) removeNode->deleteLater();
}

void GisesPlan::clear(){
    _takeOff = nullptr;
    _currentNode = nullptr;
    if(_nodeSequence.count()) _nodeSequence.clearAndDeleteContents();
    if(_surveyAreaModel.count()) _surveyAreaModel.clearAndDeleteContents();
    if(_waypointModel.count()) _waypointModel.clearAndDeleteContents();
    if(_flightPathModel.count()) _flightPathModel.clearAndDeleteContents();
    if(_waypointSeries && _waypointSeries->count()) _waypointSeries->clear();
    if(_checkSeries && _checkSeries->count()) _checkSeries->clear();
    _loadingList.clear();
    _geoPoints.clear();
    // if(PLANAR == _planMode || STRUCTURE == _planMode){
    //     addPolygon({});
    // }
    // if(ROAD == _planMode){
    //     addCorridor({});
    // }
    //_summary->setName("New " + _planModeName[_planMode] + " Plan");
    _summary->setFlyTime(0);
    _summary->setTotalDistance(0);
    _summary->setTotalArea(0);
    _summary->setPhotoShot(0);

    emit takeoffChanged();
    emit validChanged();
    emit currentNodeChanged();
    emit currentIndexChanged();
}
QGeoCoordinate GisesPlan::home(){
    if(_takeOff){
        return _takeOff->coord();
    }
    return _home;
}
SurveyArea* GisesPlan::currentArea(){
    return qobject_cast<SurveyArea*>(_currentNode);
}

Waypoint* GisesPlan::currentWp(){
    return qobject_cast<Waypoint*>(_currentNode);
}

LandNode* GisesPlan::currentLand(){
    return qobject_cast<LandNode*>(_currentNode);
}
int GisesPlan::currentIndex(){
    if(_currentNode == _land)
        return _nodeSequence.count();
    else
        return _nodeSequence.indexOf(_currentNode);
}
bool GisesPlan::valid(){
    return _geoPoints.size();
    if(_waypointModel.count()){
        return true;
    }
    for(int i=0; i<_surveyAreaModel.count(); ++i){
        SurveyArea *area = qobject_cast<SurveyArea*>(_surveyAreaModel.get(i));
        if(area && area->valid()){
            return true;
        }
    }
    return false;
}


void GisesPlan::setCurrentNode(QObject* node){
    if(_currentNode != node){
        _currentNode = node;
        emit currentNodeChanged();
    }
}

void GisesPlan::setPlanMode(PlanMode mode){
    if(_planMode != mode){
        _planMode = mode;
        clear();
        emit planModeChanged();
    }
}
void GisesPlan::setSuffix(QString suffix){
    _summary->setSuffix(suffix);
}

void GisesPlan::insertTakeoff(){
    if(!_takeOff){
        _takeOff = new Waypoint(_home, _defaultAlt, this);
        _vehicle->vtol() ?
            _takeOff->commandFact()->setRawValue(MAV_CMD_NAV_VTOL_TAKEOFF) :
            _takeOff->commandFact()->setRawValue(MAV_CMD_NAV_TAKEOFF);
        _takeOff->setIsHome(true);
        _takeOff->updateAmsl();
        _waypointModel.insert(0, _takeOff);
        _nodeSequence.insert(0, _takeOff);
        _currentNode = _takeOff;
        adjustFlightPath(Add, _currentNode);
        updateSequence();
        connect((Waypoint*)_takeOff, &Waypoint::coordChanged, this, &GisesPlan::onHomeChanged);
        connect((Waypoint*)_takeOff, &Waypoint::amslChanged, this, &GisesPlan::updateRelative);
        emit takeoffChanged();
    }
}
void GisesPlan::insertNode(MissionNode* node){
    Waypoint *point = qobject_cast<Waypoint*>(node);
    SurveyArea *current = qobject_cast<SurveyArea*>(_currentNode);
    if(MissionNode::waypoint == node->nodeType()){
        if(node->isHome()){
            connect((Waypoint*)node, &Waypoint::coordChanged, this, &GisesPlan::onHomeChanged);
            connect((Waypoint*)node, &Waypoint::amslChanged, this, &GisesPlan::updateRelative);
        }else{
            connect((Waypoint*)node, &Waypoint::amslChanged, this, &GisesPlan::updateFlightPath);
        }
    }else{
        connect(this, &GisesPlan::homeChanged, (SurveyArea*)node, &SurveyArea::checkSafety);
        connect((SurveyArea*)node, &SurveyArea::validChanged, this, &GisesPlan::onAreaValidChanged);
        connect((SurveyArea*)node, &SurveyArea::pathChanged, this, &GisesPlan::updateFlightPath);
    }
    if(_nodeSequence.count()){
        int index = _nodeSequence.indexOf(_currentNode);
        QObject* last = nullptr;
        if(_currentNode){
            if(current){
                current->setActive(false);
            }else{
                qobject_cast<Waypoint*>(_currentNode)->setActive(false);
            }
            if(point){
                //添加航点
                if(current){
                    //查找新航点位置
                    for(int i=0; i<index; ++i){
                        if(_nodeSequence.value<Waypoint*>(i))
                            last = _nodeSequence.get(i);
                    }
                    _waypointModel.insert(_waypointModel.indexOf(last) + 1, node);
                }else{
                    _waypointModel.insert(_waypointModel.indexOf(_currentNode) + 1, node);
                }
            }else{
                //添加测区
                if(current){
                    _surveyAreaModel.insert(_surveyAreaModel.indexOf(_currentNode) + 1, node);
                }else{
                    //查找新测区位置
                    for(int i=0; i<index; ++i){
                        if(_nodeSequence.value<SurveyArea*>(i))
                            last = _nodeSequence.get(i);
                    }
                    _surveyAreaModel.insert(_surveyAreaModel.indexOf(last) + 1, node);
                }
            }
        }else{
            _currentNode = _nodeSequence.get(_nodeSequence.count()-1);
            if(point){
                _waypointModel.append(node);
            }else{
                _surveyAreaModel.append(node);
            }
        }
        _nodeSequence.insert(_nodeSequence.indexOf(_currentNode) + 1, node);
    }
    _currentNode = node;
    adjustFlightPath(Add, _currentNode);
    updateInformation();
    emit takeoffChanged();
    emit validChanged();
    emit currentNodeChanged();
    emit currentIndexChanged();
}

void GisesPlan::adjustFlightPath(NodeAction act, QObject* node){
    MissionNode *missionNode = qobject_cast<MissionNode*>(node);
    const int allSize = _nodeSequence.count();
    if(missionNode && allSize){
        if(Remove == act){
            //删除节点
            GeoLine *first = nullptr, *second = nullptr;
            for(int i=0; i<_flightPathModel.count(); ++i){
                if(_flightPathModel.value<GeoLine*>(i)->toNode() == missionNode){
                    first = _flightPathModel.value<GeoLine*>(i);
                }
                if(_flightPathModel.value<GeoLine*>(i)->fromNode() == missionNode){
                    //起点是被移除节点,需要合并
                    second = _flightPathModel.value<GeoLine*>(i);
                }
            }
            //更新包含被移除节点的航线
            if(first && second){
                //合并
                first->setToNode(second->toNode());
                _flightPathModel.removeOne(second);
                second->deleteLater();
            }else if(first){
                //删除
                _flightPathModel.removeOne(first);
                first->deleteLater();
            }else if(second){
                //删除
                _flightPathModel.removeOne(second);
                second->deleteLater();
            }
        }else if(Alter == act){
            //移动节点
            int pathSize = _flightPathModel.count();
            if(pathSize){
                if(1 == pathSize){
                    //只有一条航线
                    _flightPathModel.value<GeoLine*>(0)->reverse();
                }else{
                    //查找对调的航线
                    int index = 0, find = 0;
                    GeoLine *prev = nullptr, *reverse = nullptr, *next = nullptr;
                    MissionNode *from = nullptr, *to = nullptr;
                    for(; index<_flightPathModel.count(); ++index){
                        from = qobject_cast<MissionNode*>(_nodeSequence.get(index));
                        to = qobject_cast<MissionNode*>(_nodeSequence.get(index+1));
                        reverse = _flightPathModel.value<GeoLine*>(index);
                        if(reverse->fromNode() == to && reverse->toNode() == from){
                            find = 1;
                            break;
                        }
                    }
                    if(find){
                        prev = qobject_cast<GeoLine*>(_flightPathModel.get(index-1));
                        next = qobject_cast<GeoLine*>(_flightPathModel.get(index+1));
                        if(prev) prev->setToNode(reverse->toNode());
                        if(next) next->setFromNode(reverse->fromNode());
                        reverse->reverse();
                    }
                }
            }
        }else{
            //插入节点
            if(allSize > 1){
                int nodeIndex = _nodeSequence.indexOf(missionNode);
                MissionNode *fromNode = nullptr, *toNode = nullptr;
                bool fromValid = false, toValid = false, valid = false;
                valid = missionNode && missionNode->valid();
                if(valid){
                    //查找前后有效节点
                    for(int i=nodeIndex-1; i>=0; --i){
                        fromNode = qobject_cast<MissionNode*>(_nodeSequence.get(i));
                        if(fromNode && fromNode->valid()){
                            fromValid = true;
                            break;
                        }
                    }
                    for(int i=nodeIndex+1; i<_nodeSequence.count(); ++i){
                        toNode = qobject_cast<MissionNode*>(_nodeSequence.get(i));
                        if(toNode && toNode->valid()){
                            toValid = true;
                            break;
                        }
                    }
                    GeoLine* line = nullptr;
                    if(fromValid && toValid){
                        //插入中间
                        for(int i=0; i<_flightPathModel.count(); ++i){
                            line = _flightPathModel.value<GeoLine*>(i);
                            if(line->fromNode() == fromNode && line->toNode() == toNode){
                                line->setToNode(missionNode);
                                GeoLine* newline = new GeoLine(missionNode, toNode, this);
                                _flightPathModel.insert(i+1, newline);
                                break;
                            }
                        }
                    }else if(fromValid){
                        //插入尾部
                        GeoLine* newline = new GeoLine(fromNode, missionNode, this);
                        _flightPathModel.append(newline);
                    }else if(toValid){
                        //插入头部
                        GeoLine* newline = new GeoLine(missionNode, toNode, this);
                        _flightPathModel.append(newline);
                        for(int i=0; i<_flightPathModel.count(); ++i){
                            line = _flightPathModel.value<GeoLine*>(i);
                            if(line->fromNode() == toNode){
                                _flightPathModel.insert(i, line);
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
}

void GisesPlan::updateSequence(){
    if(_nodeSequence.count()){
        MissionNode *node = nullptr;
        GeoPoint* lastPoint = nullptr;
        int index = 0, lastSeq = 0;
        //查找第一个有效节点
        for(; index<_nodeSequence.count(); ++index){
            node = qobject_cast<MissionNode*>(_nodeSequence.get(index));
            if(node && node->valid()){
                break;
            }
        }
        if(index < _nodeSequence.count()){
            //设置第一个有效节点序号为1
            node = qobject_cast<MissionNode*>(_nodeSequence.get(index));
            if(node && node->valid()){
                node->setSequence(1);
                lastPoint = node->last();
                lastSeq = node->sequence() + lastPoint->index() + lastPoint->action();
                //_geoPoints.append(area->infos());
                //_checkPath.append(area->checkPath());
            }
            //更新后续节点序号
            for(int i=index+1; i<_nodeSequence.count(); ++i){
                node = qobject_cast<MissionNode*>(_nodeSequence.get(i));
                if(node && node->valid()){
                    node->setSequence(lastSeq + 1);
                    lastPoint = node->last();
                    lastSeq = node->sequence() + lastPoint->index() + lastPoint->action();
                }
            }
        }
    }
}


//SLOTS
void GisesPlan::updateInformation(){
    _geoPoints.clear();
    _checkPath.clear();
    //更新统计信息
    //坐标,航点高度,任务序号,地形高度,离家距离,归属节点,离前个航点距离
    updateSequence();
    //飞行时间,照片数量,区域面积
    //查找第一个有效节点
    MissionNode *node = nullptr;
    SurveyArea* area = nullptr;
    bool firstValid = true;
    double totalDist = 0, totalArea = 0;
    //更新航点折线图,并检查首个有效节点是否为测区,如果是测区还需要将测区内的航线检测点添加到航点列表
    for(int i=0; i<_nodeSequence.count(); ++i){
        node = qobject_cast<MissionNode*>(_nodeSequence.get(i));
        if(node && node->valid()){
            if(MissionNode::waypoint == node->nodeType()){
                _geoPoints.append(node->first());
            }else{
                area = qobject_cast<SurveyArea*>(node);
                _geoPoints.append(area->waypoints().first(area->path().size()));
                if(firstValid){
                    _checkPath.append(area->checkPath());
                    totalDist += area->pathDistance();
                    totalArea += area->shapeArea();
                }
            }
            firstValid = false;
        }
    }
    //更新地形折线图,并判断航线末端是否为测区,是的话需要追加测区航线检测点
    GeoLine* path = nullptr;
    for(int i=0; i<_flightPathModel.count(); ++i){
        //添加航线检测点
        path = qobject_cast<GeoLine*>(_flightPathModel.get(i));
        //abcabc _checkPath.append(path->checkPath());	//每条航线的头尾可能重复
        node = path->toNode();
        totalDist += path->distance();
        //测区航线检测点
        if(MissionNode::surveyArea == node->nodeType() && node->valid()){
            area = qobject_cast<SurveyArea*>(node);
            _checkPath.append(area->checkPath());
            totalDist += area->pathDistance();
            totalArea += area->shapeArea();
        }
    }
    if(_land->landMode()){
        if(2 == _land->landMode()){
            //_checkPath.append(_land->lastCheckPath());
        }
        if(_geoPoints.size() && _land->enterPoint() != _geoPoints.last()){
            _land->setEnterPoint(_geoPoints.last());
        }
    }
    _summary->setTotalDistance(totalDist);
    _summary->setTotalArea(totalArea);
    double dist = 0;
    _maxDist = 0;
    _maxAlt = 0;
    _waypointLine.clear();
    _checkLine.clear();
    if(_waypointSeries && _checkSeries){
        if(_geoPoints.size()){
            _waypointLine.append({dist, _geoPoints[0]->amsl()});
            _maxAlt = _geoPoints[0]->amsl();
            for(int i=1; i<_geoPoints.size(); ++i){
                dist += _geoPoints[i-1]->coord().distanceTo(_geoPoints[i]->coord());
                _waypointLine.append({dist, _geoPoints[i]->amsl()});
                if(_geoPoints[i]->amsl() > _maxAlt){
                    _maxAlt = _geoPoints[i]->amsl();
                }
            }
            if(2 == _land->landMode()){
                dist += _geoPoints.last()->coord().distanceTo(_land->first()->coord());
                _waypointLine.append({dist, _land->preAmsl()});
                if(_land->preAmsl() > _maxAlt){
                    _maxAlt = _land->preAmsl();
                }
                dist += _land->distance();
                _waypointLine.append({dist, _land->landAmsl()});
                if(_land->landAmsl() > _maxAlt){
                    _maxAlt = _land->landAmsl();
                }
            }
        }
        if(_checkPath.size()){
            dist = 0;
            _checkLine.append({dist, _checkPath[0].altitude()});
            if(_checkPath[0].altitude() > _maxAlt){
                _maxAlt = _checkPath[0].altitude();
            }
            for(int i=1; i<_checkPath.size(); ++i){
                dist += _checkPath[i-1].distanceTo(_checkPath[i]);
                _checkLine.append({dist, _checkPath[i].altitude()});
                if(_checkPath[i].altitude() > _maxAlt){
                    _maxAlt = _checkPath[i].altitude();
                }
            }
        }
        if(2 == _land->landMode()){
            QList<QGeoCoordinate> list;//abcabc = _land->landCheckPath();
            for(int i=1; i<list.size(); ++i){
                dist += list[i-1].distanceTo(list[i]);
                _checkLine.append({dist, list[i].altitude()});
                if(list[i].altitude() > _maxAlt){
                    _maxAlt = list[i].altitude();
                }
            }
        }
        _maxDist = dist;
        _waypointSeries->replace(_waypointLine);
        _checkSeries->replace(_checkLine);
    }
    emit maxChanged();
}
void GisesPlan::onVehicleChanged(){
    if(_vehicle != _gises->vehicle()){
        disconnect(_vehicle, &Vehicle::homePositionChanged, this, &GisesPlan::onHomeChanged);
        _vehicle = _gises->vehicle();
        if(_takeOff){
            if(!_vehicle->isOfflineEditingVehicle()){
                _takeOff->setCoord(_home);
                connect(_vehicle, &Vehicle::homePositionChanged, this, &GisesPlan::onHomeChanged);
            }
            _vehicle->vtol() ?
                _takeOff->commandFact()->setRawValue(MAV_CMD_NAV_VTOL_TAKEOFF) :
                _takeOff->commandFact()->setRawValue(MAV_CMD_NAV_TAKEOFF);
        }
    }
}
void GisesPlan::onHomeChanged(){
    Waypoint *takeoff = qobject_cast<Waypoint*>(sender());
    if(takeoff){
        _home = takeoff->coord();
    }else if(_vehicle == qobject_cast<Vehicle*>(sender())){
        _home = _vehicle->homePosition();
        if(_takeOff){
            _takeOff->setCoord(_home);
        }
    }
}
void GisesPlan::onLandModeChanged(){
    if(_land->landMode() > 0){
        if(2 == _land->landMode()){
            connect(_land, &LandNode::safetyChanged, this, &GisesPlan::updateInformation, Qt::UniqueConnection);
        }else{
            disconnect(_land, &LandNode::safetyChanged, this, &GisesPlan::updateInformation);
        }
        if(_geoPoints.size()){
            GeoPoint* lastPoint = nullptr;
            QGeoCoordinate last;
            for(int i=_geoPoints.size()-1; i>=0; --i){
                if(_geoPoints[i]->coord().isValid()){
                    lastPoint = _geoPoints[i];
                    last = lastPoint->coord();
                    break;
                }
            }
            if(0 == _land->landMode()){
                _land->setEnterPoint(lastPoint);
                _land->last()->setCoord(QGeoCoordinate());
                //onNodeClicked(_nodeSequence.get(_nodeSequence.count()-1));
            }else{
                _land->setEnterPoint(lastPoint);
                _land->last()->setCoord(last);
                _land->calcPreCoord();
                //onNodeClicked(_land);
            }
        }else{
            _land->setActive(false);
            _land->setEnterPoint(nullptr);
            _land->last()->setCoord(QGeoCoordinate());
        }
    }
}
void GisesPlan::setHome(QGeoCoordinate home){
    if(home.isValid() && _home != home){
        _home = home;
        emit homeChanged();
    }
}
void GisesPlan::updateFlightPath(){
    QObject* send = sender();
    GeoLine* ptr = nullptr;
    for(int i=0; i<_flightPathModel.count(); ++i){
        if(qobject_cast<GeoLine*>(_flightPathModel.get(i))->fromNode() == send ||
            qobject_cast<GeoLine*>(_flightPathModel.get(i))->toNode() == send){
            ptr = _flightPathModel.value<GeoLine*>(i);
            ptr->updatePath();
        }
    }
    _loadingList.removeOne(send);
    if(!_loadingList.size()){
        updateInformation();
    }
}

void GisesPlan::onAreaValidChanged(){
    SurveyArea* area = qobject_cast<SurveyArea*>(sender());
    if(area){
        if(area->valid()){
            adjustFlightPath(Add, area);
        }else{
            adjustFlightPath(Remove, area);
        }
        updateInformation();
    }
    emit validChanged();
}
void GisesPlan::updateSeries(){
    GeoPoint* point = qobject_cast<GeoPoint*>(sender());
    if(point){
        int index = _geoPoints.indexOf(point);
        double dist = 0;
        if(-1 != index){
            for(int i=0; i<_geoPoints.size(); ++i){
                dist += _geoPoints[i]->coord().distanceTo(_geoPoints[0]->coord());
            }
        }
        if(_waypointSeries->count() == _geoPoints.size()){
            QPointF pf = _waypointSeries->at(index);
            if(qAbs(pf.x() - dist) < 0.1){
                pf.setY(_geoPoints[index]->amsl());
            }
            _waypointSeries->replace(index, pf);
        }
    }
}
void GisesPlan::updateRelative(){
    MissionNode *node = nullptr;
    Waypoint *point = nullptr;
    for(int i=0; i<_nodeSequence.count(); ++i){
        node = qobject_cast<MissionNode*>(_nodeSequence.get(i));
        if(node == sender()) continue;
        if(node && MissionNode::waypoint == node->nodeType() &&
            MAV_FRAME_GLOBAL_RELATIVE_ALT == qobject_cast<Waypoint*>(node)->altModeFact()->rawValue()){
            _loadingList.append(node);
        }else if(node && MissionNode::surveyArea == node->nodeType() &&
                   MAV_FRAME_GLOBAL_RELATIVE_ALT == qobject_cast<SurveyArea*>(node)->setup()->camera()->altMode()->rawValue()){
            _loadingList.append(node);
        }
    }
    node = nullptr;
    point = nullptr;
    for(int i=0; i<_nodeSequence.count(); ++i){
        node = qobject_cast<MissionNode*>(_nodeSequence.get(i));
        if(node == sender()) continue;
        if(node && MissionNode::waypoint == node->nodeType()){
            point = qobject_cast<Waypoint*>(node);
            if(MAV_FRAME_GLOBAL_RELATIVE_ALT == point->altModeFact()->rawValue()){
                point->updateAmsl();
            }
        }else{
            SurveyArea *area = qobject_cast<SurveyArea*>(node);
            if(MAV_FRAME_GLOBAL_RELATIVE_ALT == area->setup()->camera()->altMode()->rawValue()){
                area->updateAmsls();
                area->checkSafety();
            }
        }
    }
}
void GisesPlan::reqHomeTerrain(){
    if(_home.isValid()){
        _query = new TerrainAtCoordinateQuery(true);
        connect(_query, &TerrainAtCoordinateQuery::terrainDataReceived, this, &GisesPlan::onRecvHomeTerrain);
        QList<QGeoCoordinate> list;
        list.append(_home);
        _query->requestData(list);
    }
}
void GisesPlan::onRecvHomeTerrain(bool success, QList<double> heights){
    if(success){
        _home.setAltitude(heights.first());
        if(_takeOff){
            _takeOff->first()->setTerrain(heights.first());
        }
    }
    // MissionNode *node = nullptr;
    // Waypoint *point = nullptr;
    // for(int i=0; i<_nodeSequence.count(); ++i){
    //     node = qobject_cast<MissionNode*>(_nodeSequence.get(i));
    //     if(node && MissionNode::waypoint == node->nodeType() &&
    //         MAV_FRAME_GLOBAL_RELATIVE_ALT == qobject_cast<Waypoint*>(node)->altModeFact()->rawValue()){
    //         _loadingList.append(node);
    //     }else if(node && MissionNode::surveyArea == node->nodeType() &&
    //                MAV_FRAME_GLOBAL_RELATIVE_ALT == qobject_cast<SurveyArea*>(node)->setup()->camera()->altMode()->rawValue()){
    //         _loadingList.append(node);
    //     }
    // }
    // node = nullptr;
    // point = nullptr;
    // for(int i=0; i<_nodeSequence.count(); ++i){
    //     node = qobject_cast<MissionNode*>(_nodeSequence.get(i));
    //     if(node && MissionNode::waypoint == node->nodeType()){
    //         point = qobject_cast<Waypoint*>(node);
    //         if(MAV_FRAME_GLOBAL_RELATIVE_ALT == point->altModeFact()->rawValue()){
    //             point->updateAmsl();
    //         }
    //     }else{
    //         SurveyArea *area = qobject_cast<SurveyArea*>(node);
    //         if(MAV_FRAME_GLOBAL_RELATIVE_ALT == area->setup()->camera()->altMode()->rawValue()){
    //             area->updateAmsls();
    //         }
    //     }
    // }
    emit homeChanged();
}
