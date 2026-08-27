
#include <QLineF>
#include <QPolygonF>
#include <QMetaMethod>
#include "MissionItem.h"
#include "surveyArea.h"
#include "gisesPlan.h"

SurveyArea::SurveyArea(QObject *parent)
    :MissionNode(surveyArea, parent)
    ,_setup("default", this)
    ,_path()
    ,_waypoints()
{
}

GeoPoint* SurveyArea::first(){
    if(_waypoints.size()){
        return _waypoints.first();
    }
    return nullptr;
}
GeoPoint* SurveyArea::last(){
    if(_waypoints.size()){
        return _waypoints[_pathSize-1];
    }
    return nullptr;
}
void SurveyArea::genMissionItem(QList<MissionItem*>& list, QObject* parent){
    MissionItem* item = nullptr;
    int seqNum = list.size() + 1;
    MAV_FRAME frame;
    double alt = _setup.camera()->distanceToSurface()->rawValue().toDouble();
    bool above = false;
    if(-1 == _setup.camera()->altMode()->rawValue().toInt()){
        frame = MAV_FRAME_GLOBAL;
        above = true;
    }else{
        frame = (MAV_FRAME)_setup.camera()->altMode()->rawValue().toInt();
    }
    if(_waypoints.size()){
        for(int i=0; i<_waypoints.size(); ++i){
            //航点
            item = new MissionItem(seqNum++,
                                   MAV_CMD_NAV_WAYPOINT,
                                   frame,
                                   0,
                                   0,
                                   0,
                                   0,
                                   _waypoints[i]->coord().latitude(),
                                   _waypoints[i]->coord().longitude(),
                                   (above ? alt + _waypoints[i]->coord().altitude() : alt),
                                   false,
                                   parent);
            list.append(item);
            //相机动作
            if(_waypoints[i]->action() == GeoPoint::start){
                item = new MissionItem(seqNum++,
                                       MAV_CMD_DO_SET_CAM_TRIGG_DIST,
                                       MAV_FRAME_MISSION,
                                       _setup.camera()->adjustedFootprintFrontal()->rawValue().toDouble(),			// Trigger distance
                                       0,									// No shutter integartion
                                       1,									// Trigger immediately
                                       0, 0, 0, 0,						// param 4-7 not used
                                       true,								// autoContinue
                                       false,								// isCurrentItem
                                       parent);
                list.append(item);
            }else if(_waypoints[i]->action() == GeoPoint::stop){
                item = new MissionItem(seqNum++,
                                       MAV_CMD_DO_SET_CAM_TRIGG_DIST,
                                       MAV_FRAME_MISSION,
                                       0,                               // Trigger distance = 0 means stop
                                       0, 0, 0, 0, 0, 0,                // param 2-7 not used
                                       true,                            // autoContinue
                                       false,                           // isCurrentItem
                                       parent);
                list.append(item);
                item = new MissionItem(seqNum++,
                                         MAV_CMD_IMAGE_STOP_CAPTURE,
                                         MAV_FRAME_MISSION,
                                         0, 0, 0, 0, 0, 0, 0,                                     // Reserved (Set to 0)
                                         //qQNaN(), qQNaN(), qQNaN(), qQNaN(), qQNaN(), qQNaN(),    // reserved
                                         true,                                                    // autoContinue
                                         false,                                                   // isCurrentItem
                                         parent);
                list.append(item);
            }
        }
    }
}
void SurveyArea::saveWaypoint(QJsonArray& array){
    double altitude = _setup.camera()->distanceToSurface()->rawValue().toDouble();
    int altMode = _setup.camera()->altMode()->rawValue().toInt();
    int seqNum = array.size() + 1;
    for(int i=0; i<_waypoints.size(); ++i){
        QJsonObject item;
        item["type"] = MissionNode::waypoint;
        item["Altitude"] = altitude;
        int mode = 0;
        switch(altMode){
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
        if(-1 == altMode || MAV_FRAME_GLOBAL_TERRAIN_ALT == altMode){
            item["AMSLAltAboveTerrain"] = _waypoints[i]->amsl();
        }else{
            item["AMSLAltAboveTerrain"] = qQNaN();
        }
        item["autoContinue"] = true;
        item["command"] = MAV_CMD_NAV_WAYPOINT;
        item["doJumpId"] = seqNum++;
        item["frame"] = -1 == altMode ? 0 : altMode;
        QJsonArray param({0, 0, 0, 0});
        param.append(_waypoints[i]->coord().latitude());
        param.append(_waypoints[i]->coord().longitude());
        param.append(altitude + (-1 == altMode ? _waypoints[i]->coord().altitude() : 0));
        item["params"] = param;
        array.append(item);
        //相机动作
        if(_waypoints[i]->action() == GeoPoint::start){
            double trigger = _setup.camera()->adjustedFootprintFrontal()->rawValue().toDouble();
            QJsonObject cam;
            cam["type"] = MissionNode::waypoint;
            cam["autoContinue"] = true;
            cam["command"] = MAV_CMD_DO_SET_CAM_TRIGG_DIST;
            cam["doJumpId"] = seqNum++;
            cam["frame"] = MAV_FRAME_MISSION;
            QJsonArray pm({trigger, 0, 1, 0, 0, 0, 0});
            cam["params"] = pm;
            array.append(cam);
        }else if(_waypoints[i]->action() == GeoPoint::stop){
            QJsonObject cam1;
            cam1["type"] = MissionNode::waypoint;
            cam1["autoContinue"] = true;
            cam1["command"] = MAV_CMD_DO_SET_CAM_TRIGG_DIST;
            cam1["doJumpId"] = seqNum++;
            cam1["frame"] = MAV_FRAME_MISSION;
            QJsonArray pm1({0, 0, 0, 0, 0, 0, 0});
            cam1["params"] = pm1;
            array.append(cam1);

            QJsonObject cam2;
            cam2["type"] = MissionNode::waypoint;
            cam2["autoContinue"] = true;
            cam2["command"] = MAV_CMD_IMAGE_STOP_CAPTURE;
            cam2["doJumpId"] = seqNum++;
            cam2["frame"] = MAV_FRAME_MISSION;
            QJsonArray pm2({0, 0, 0, 0, 0, 0, 0});
            cam2["params"] = pm2;
            array.append(cam2);
        }
    }
}
void SurveyArea::setPath(const QVariantList& path){
    if(_path != path){
        _path = path;
        emit pathChanged();
    }
}
void SurveyArea::setShowAllWaypoint(bool show){
    if(_showAllWaypoint != show){
        _showAllWaypoint = show;
        emit showAllWaypointChanged();
    }
}

void SurveyArea::setSettup(SurveySetup *setup){
    _setup.set(setup);
}

void SurveyArea::updateAmsls(){
    //更新源坐标高度值
    double homeAlt = 0;
    double alt = _setup.camera()->distanceToSurface()->rawValue().toDouble();
    switch(_setup.camera()->altMode()->rawValue().toInt()){
    case MAV_FRAME_GLOBAL:{
        for(int i=0; i<_waypoints.size(); ++i){
            _waypoints[i]->setAmsl(alt);
        }
        break;
    }
    case MAV_FRAME_GLOBAL_RELATIVE_ALT:{
        QGeoCoordinate home = _plan->home();
        if(home.isValid()){
            homeAlt = home.altitude();
        }
        for(int i=0; i<_waypoints.size(); ++i){
            _waypoints[i]->setAmsl(alt + homeAlt);
        }
        break;
    }
    case -1:
    case MAV_FRAME_GLOBAL_TERRAIN_ALT:{
        for(int i=0; i<_waypoints.size(); ++i){
            _waypoints[i]->setAmsl(alt + _waypoints[i]->coord().altitude());
        }
        break;
    }
    default:{}
    }
}
