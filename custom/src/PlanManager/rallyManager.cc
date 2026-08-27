
#include <QtQml/qqml.h>
#include <MissionItem.h>
#include "geoPoint.h"
#include "rallyManager.h"
#include "gisesManager.h"

Q_LOGGING_CATEGORY(RallyManagerLog, "RallyManagerLog")

RallyManager::RallyManager(QObject* parent)
    :QObject(parent)
{
    _gises = qobject_cast<GisesManager*>(parent);
    if (nullptr == _gises) {
        qCCritical(RallyManagerLog) << "critical rally error";
    }
}

void RallyManager::onPointClicked(GeoPoint* point){
    if(_current == point){
        _current = nullptr;
    }else{
        _current = point;
    }
    emit currentChanged();
}

void RallyManager::addPoint(QGeoCoordinate coord){
    _current = new GeoPoint(coord, this);
    _points.append(_current);
    for(int i=0; i<_points.size(); ++i){
        _points[i]->setIndex(i);
    }
    emit currentChanged();
    emit pointsChanged();
}
bool RallyManager::saveToFile(){
    return true;
}
bool RallyManager::sendToVehicle(){
    _gises->sendRallys();
    return true;
}
bool RallyManager::switchEditable(){
    return true;
}
bool RallyManager::removePoint(GeoPoint* point){
    if(_current == point){
        _current = nullptr;
    }
    point->deleteLater();
    _points.removeOne(point);
    for(int i=0; i<_points.size(); ++i){
        _points[i]->setIndex(i);
    }
    emit currentChanged();
    emit pointsChanged();
    return true;
}
bool RallyManager::clear(){
    _current = nullptr;
    for(int i=0; i<_points.size(); ++i){
        _points[i]->deleteLater();
    }
    _points.clear();
    emit currentChanged();
    emit pointsChanged();
    return true;
}

void RallyManager::refreshPoint(){
    if(_points.size()){
        for(int i=0; i<_points.size(); ++i){
            //_points[i]->setPoint(Manager::instance()->convertCoordinate(_points[i]->coordinate()));
        }
        emit pointsChanged();
    }
}
void RallyManager::saveAsJson(QJsonObject& json){
    QJsonArray points;
    for(int i=0; i<_points.size(); ++i){
        QJsonArray point;
        point.append(_points[i]->coord().latitude());
        point.append(_points[i]->coord().longitude());
        points.append(point);
    }
    json["points"] = points;
}

void RallyManager::loadFromJson(const QJsonObject& json){
    if(_points.size()){
        for(int i=0 ;i<_points.size(); ++i){
            _points[i]->deleteLater();
        }
        _points.clear();
    }
    const QJsonArray& points = json["points"].toArray();
    for(int i=0; i<points.size(); ++i){
        QGeoCoordinate coord(points[i][0].toDouble(), points[i][1].toDouble());
        _points.append(new GeoPoint(coord, this));
    }
}

void RallyManager::loadFromVehicle(const QList<QGeoCoordinate>& points){
    clear();
    for (int i=0; i<points.size(); i++) {
        _current = new GeoPoint(points[i], this);
        _points.append(_current);
    }
    _current = nullptr;
    emit pointsChanged();
}

void RallyManager::generateItems(QList<MissionItem*>& items, QObject* parent){
    for (int i=0; i<_points.size(); ++i){
        MissionItem* item = new MissionItem(0,
                                            MAV_CMD_NAV_RALLY_POINT,
                                            MAV_FRAME_GLOBAL_RELATIVE_ALT,
                                            0, 0, 0, 0,                 // param 1-4 unused
                                            _points[i]->coord().latitude(),
                                            _points[i]->coord().longitude(),
                                            _points[i]->coord().altitude(),
                                            false,                      // autocontinue
                                            false,                      // isCurrentItem
                                            parent);                      // parent
        items.append(item);
    }
}
