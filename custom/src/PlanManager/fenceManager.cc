
#include <QtQml/qqml.h>
#include "MissionItem.h"
#include "geoPoint.h"
#include "fenceManager.h"
#include "gisesManager.h"

Q_LOGGING_CATEGORY(FenceManagerLog, "FenceManagerLog")

GeoFence::GeoFence(QObject* parent)
    :QObject(parent)
    ,_centerPoint(new GeoPoint(this))
    ,_radiusPoint(new GeoPoint(this))
{

}
GeoFence::GeoFence(const QList<QGeoCoordinate>& coords, QObject* parent)
    :QObject(parent)
    ,_centerPoint(new GeoPoint(this))
    ,_radiusPoint(new GeoPoint(this))
{
    for(int i = 0; i<coords.size(); i++){
        addPoint(coords[i]);
    }
}
GeoFence::GeoFence(QGeoCoordinate center, QGeoCoordinate radius, QObject* parent)
    :QObject(parent)
    ,_centerPoint(new GeoPoint(center, this))
    ,_radiusPoint(new GeoPoint(radius, this))
{
    _radius = _radiusPoint->coord().distanceTo(_centerPoint->coord());
    connect(this, &GeoFence::radiusChanged, this, &GeoFence::updateRadiusPoint);
    connect(_radiusPoint, &GeoPoint::coordChanged, this, &GeoFence::updateRadius);
}

void GeoFence::addPoint(QGeoCoordinate coord){
    //convert to ned
    if(_radius < 0.01){
        if(_points.size()){
            if(nullptr == _current){
                _current = _points.last();
            }
            int index = _current->index();
            _current = new GeoPoint(coord, this);
            _points.insert(index + 1, _current);
            _polygon.insert(index + 1, coord);
            _current->setIndex(index + 1);
        }else{
            _current = new GeoPoint(coord, this);
            _polygon.append(coord);
            _points.append(_current);
        }
        connect(_current, &GeoPoint::coordChanged, this, &GeoFence::updateVertex);
        emit pointsChanged();
        emit polygonChanged();
    }
}
void GeoFence::setCircleCenter(QGeoCoordinate coord){
    Q_UNUSED(coord);
}
void GeoFence::setCircleRadius(QGeoCoordinate coord){
    Q_UNUSED(coord);
}
bool GeoFence::removeOne(){
    if(_radius > 0.01 || _points.size() <= 0){
        return true;
    }
    if(_points.size() > 1){
        if(nullptr == _current){
            _current = _points.last();
        }
        int all = _points.size();
        int ndx = _current->index();
        _polygon.removeAt(ndx);
        if(ndx == all - 1){
            ndx -= 1;
        }
        _current->deleteLater();
        _points.removeOne(_current);
        GeoPoint* next = _points.at(ndx);
        _current = next;
    }else{
        _current = nullptr;
        _points.first()->deleteLater();
        _points.clear();
        _polygon.clear();
    }
    for(int i=0; i<_points.size(); ++i){
        _points[i]->setIndex(i);
    }
    emit pointsChanged();
    emit polygonChanged();
    return true;
}
bool GeoFence::clearAll(){
    if(_points.size()){
        qDeleteAll(_points.begin(), _points.end());
        _points.clear();
        _polygon.clear();
        emit pointsChanged();
        emit polygonChanged();
    }
    return true;
}
void GeoFence::refreshPoint(){
    if(_radius < 0.01){
        for(int i=0; i<_points.size(); ++i){
            //_points[i]->setPoint(Manager::instance()->convertCoordinate(_points[i]->coord()));
        }
    }else{
        //_centerPoint->setPoint(Manager::instance()->convertCoordinate(_centerPoint->coord()));
        //_radiusPoint->setPoint(Manager::instance()->convertCoordinate(_radiusPoint->coord()));
    }
}
void GeoFence::updateVertex(){
    GeoPoint* point = qobject_cast<GeoPoint*>(sender());
    if(point){
        int index = _points.indexOf(point);
        _polygon[index] = point->coord();
        emit polygonChanged();
    }
}
void GeoFence::updateRadius(){
    if(_deloop){
        _deloop = false;
        return;
    }
    _radius = _radiusPoint->coord().distanceTo(_centerPoint->coord());
    emit radiusChanged();
}
void GeoFence::updateRadiusPoint(){
    _deloop = true;
    _radiusPoint->setCoord(_centerPoint->coord().atDistanceAndAzimuth(_radius, 90));
}


FenceManager::FenceManager(QObject* parent)
    :QObject(parent)
    ,_polygonFenceModel(this)
{
    _gises = qobject_cast<GisesManager*>(parent);
    if (nullptr == _gises) {
        qCCritical(FenceManagerLog) << "critical fence error";
    }
}
FenceManager::~FenceManager(){
}

void FenceManager::addCustom(){
    _currentFence = new GeoFence(this);
    _polygonFenceModel.append(_currentFence);
    emit currentFenceChanged();
}
void FenceManager::addSimpleRect(QGeoCoordinate center, QGeoCoordinate lt, QGeoCoordinate lb, QGeoCoordinate rb, QGeoCoordinate rt){
    Q_UNUSED(center)
    QList<QGeoCoordinate> points;
    points.append(lt);
    points.append(lb);
    points.append(rb);
    points.append(rt);
    _currentFence = new GeoFence(points, this);
    _polygonFenceModel.append(_currentFence);
    emit currentFenceChanged();
}
void FenceManager::addCircle(QGeoCoordinate center, QGeoCoordinate radius){
    _currentFence = new GeoFence(center, radius, this);
    _circleFenceModel.append(_currentFence);
    emit currentFenceChanged();
}
void FenceManager::removeFence(GeoFence* remove){
    if(remove){
        QmlObjectListModel* model = &_polygonFenceModel;
        if(remove->_radius > 0.01){
            model = &_circleFenceModel;
        }
        if(1 == model->count()){
            model->removeOne(remove);
            _currentFence = nullptr;
        }else{
            int index = model->indexOf(remove);
            if(_currentFence == remove){
                if(index == model->count() - 1){
                    _currentFence = qobject_cast<GeoFence*>(model->get(index - 1));
                }else{
                    _currentFence = qobject_cast<GeoFence*>(model->get(index + 1));
                }
            }
            model->removeOne(remove);
        }
        remove->deleteLater();
        emit currentFenceChanged();
    }
}
bool FenceManager::sendToVehicle(){
    _gises->sendFences();
    return true;
}
void FenceManager::refreshPoint(){
    if(_polygonFenceModel.count()){
        GeoFence* fence = nullptr;
        for(int i=0; i<_polygonFenceModel.count(); ++i){
            fence = qobject_cast<GeoFence*>(_polygonFenceModel.get(i));
            fence->refreshPoint();
            if(fence == _currentFence){
                emit currentFenceChanged();
            }
        }
    }
}
void FenceManager::saveAsJson(QJsonObject& json){
    GeoFence* fence = nullptr;
    QJsonArray circles, polygons;
    for(int i=0; i<_circleFenceModel.count(); ++i){
        fence = qobject_cast<GeoFence*>(_circleFenceModel.get(i));
        QJsonObject circle, cir;
        circle["inclusion"] = fence->_inner;
        QJsonArray center;
        center.append(fence->_centerPoint->coord().latitude());
        center.append(fence->_centerPoint->coord().longitude());
        cir["center"] = center;
        cir["radius"] = fence->_radius;
        circle["circle"] = cir;
        circles.append(circle);
    }
    json["circles"] = circles;
    for(int i=0; i<_polygonFenceModel.count(); ++i){
        fence = qobject_cast<GeoFence*>(_polygonFenceModel.get(i));
        QJsonObject polygon;
        polygon["inclusion"] = fence->_inner;
        QJsonArray plg;
        for(int j=0; j<fence->_points.size(); ++j){
            QJsonArray coord;
            coord.append(fence->_points[j]->coord().latitude());
            coord.append(fence->_points[j]->coord().longitude());
            plg.append(coord);
        }
        polygon["polygon"] = plg;
        polygons.append(polygon);
    }
    json["polygons"] = polygons;
}

void FenceManager::loadFromJson(const QJsonObject& json){
    if(_circleFenceModel.count()){
        _circleFenceModel.clearAndDeleteContents();
    }
    GeoFence* fence = nullptr;
    const QJsonArray& circles = json["circles"].toArray();
    bool inclusion = false;
    for(int i=0; i<circles.size(); ++i){
        const QJsonObject& circle = circles[i]["circle"].toObject();
        inclusion = circle["inclusion"].toBool();

        const QJsonArray& center = circle["center"].toArray();
        QGeoCoordinate coord(center[0].toDouble(), center[1].toDouble());
        QGeoCoordinate radius = coord.atDistanceAndAzimuth(circle["radius"].toDouble(), 90);

        fence = new GeoFence(coord, radius, this);
        fence->_inner = inclusion;
        _circleFenceModel.insert(i, fence);
    }

    if(_polygonFenceModel.count()){
        _polygonFenceModel.clearAndDeleteContents();
    }
    const QJsonArray& polygons = json["polygons"].toArray();
    for(int i=0; i<polygons.size(); ++i){
        const QJsonObject& polygon = polygons[i].toObject();

        inclusion = polygon["inclusion"].toBool();
        const QJsonArray& array = polygon["polygon"].toArray();

        QList<QGeoCoordinate> coords;
        for(int j=0; j<array.size(); ++j){
            coords.append(QGeoCoordinate(array[j][0].toDouble(), array[j][1].toDouble()));
        }

        fence = new GeoFence(coords, this);
        fence->_inner = inclusion;
        _circleFenceModel.insert(i, fence);
    }
}
void FenceManager::generateItems(QList<MissionItem*>& items, QObject* parent){
    GeoFence* fence = nullptr;
    for(int i=0; i<_circleFenceModel.count(); ++i){
        fence = qobject_cast<GeoFence*>(_circleFenceModel.get(i));
        MissionItem* item = new MissionItem(0,
                                            fence->_inner ? MAV_CMD_NAV_FENCE_CIRCLE_INCLUSION : MAV_CMD_NAV_FENCE_CIRCLE_EXCLUSION,
                                            MAV_FRAME_GLOBAL,
                                            fence->_radius,
                                            0, 0, 0,                    // param 2-4 unused
                                            fence->_centerPoint->coord().latitude(),
                                            fence->_centerPoint->coord().longitude(),
                                            0,                          // param 7 unused
                                            false,                      // autocontinue
                                            false,                      // isCurrentItem
                                            parent);                      // parent
        items.append(item);
        // if (_breachReturnPoint.isValid()) {
        //     MissionItem* item = new MissionItem(0,
        //                                         MAV_CMD_NAV_FENCE_RETURN_POINT,
        //                                         MAV_FRAME_GLOBAL_RELATIVE_ALT,
        //                                         0, 0, 0, 0,                    // param 1-4 unused
        //                                         breachReturn.latitude(),
        //                                         breachReturn.longitude(),
        //                                         breachReturn.altitude(),
        //                                         false,                      // autocontinue
        //                                         false,                      // isCurrentItem
        //                                         this);                      // parent
        //     fenceItems.append(item);
        // }
    }
    for(int i=0; i<_polygonFenceModel.count(); ++i){
        fence = qobject_cast<GeoFence*>(_polygonFenceModel.get(i));
        for (int j=0; j<fence->_polygon.size(); j++) {
            MissionItem* item = new MissionItem(0,
                                                fence->_inner ? MAV_CMD_NAV_FENCE_POLYGON_VERTEX_INCLUSION : MAV_CMD_NAV_FENCE_POLYGON_VERTEX_EXCLUSION,
                                                MAV_FRAME_GLOBAL,
                                                fence->_polygon.size(),    // vertex count
                                                0, 0, 0,            // param 2-4 unused
                                                fence->_polygon[j].latitude(),
                                                fence->_polygon[j].longitude(),
                                                0,                  // param 7 unused
                                                false,              // autocontinue
                                                false,              // isCurrentItem
                                                parent);              // parent
            items.append(item);
        }
        // if (_breachReturnPoint.isValid()) {
        //     MissionItem* item = new MissionItem(0,
        //                                         MAV_CMD_NAV_FENCE_RETURN_POINT,
        //                                         MAV_FRAME_GLOBAL_RELATIVE_ALT,
        //                                         0, 0, 0, 0,                    // param 1-4 unused
        //                                         breachReturn.latitude(),
        //                                         breachReturn.longitude(),
        //                                         breachReturn.altitude(),
        //                                         false,                      // autocontinue
        //                                         false,                      // isCurrentItem
        //                                         this);                      // parent
        //     fenceItems.append(item);
        // }
    }
}
void FenceManager::loadFromVehicle(const QList<MissionItem*>& items){
    if(_polygonFenceModel.count() > 0){
        _polygonFenceModel.clearAndDeleteContents();
        _currentFence = nullptr;
    }
    int count = 0;
    GeoFence* fence = nullptr;
    for(int i=0; i<items.size(); ++i){
        if(items[i]->command() == MAV_CMD_NAV_FENCE_POLYGON_VERTEX_INCLUSION ||
            items[i]->command() == MAV_CMD_NAV_FENCE_POLYGON_VERTEX_EXCLUSION){
            //polygon
            if(fence == nullptr || 0 == count){
                count = items[i]->param1();
                fence = new GeoFence(this);
            }
            QGeoCoordinate coor(items[i]->param5(), items[i]->param6());
            GeoPoint* point = new GeoPoint(coor, this);
            point->setIndex(fence->_points.size());
            fence->_inner = (items[i]->command() == MAV_CMD_NAV_FENCE_POLYGON_VERTEX_INCLUSION);
            fence->_points.append(point);
            fence->_polygon.append(coor);
            --count;
            if(0 == count && fence)
                _polygonFenceModel.append(fence);
        }else if(items[i]->command() == MAV_CMD_NAV_FENCE_CIRCLE_INCLUSION ||
                   items[i]->command() == MAV_CMD_NAV_FENCE_CIRCLE_EXCLUSION){
            //circle
            count = 0;
            double radius = items[i]->param1();
            QGeoCoordinate cen(items[i]->param5(), items[i]->param6());
            QGeoCoordinate rad(cen.atDistanceAndAzimuth(radius, 90));
            fence = new GeoFence(cen, rad, this);
            fence->_inner = (items[i]->command() == MAV_CMD_NAV_FENCE_CIRCLE_INCLUSION);
            _circleFenceModel.append(fence);
        }else{

        }
    }
}
