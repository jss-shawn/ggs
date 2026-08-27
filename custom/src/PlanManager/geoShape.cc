
#include <QLineF>
#include <QPolygonF>
#include "geoShape.h"
#include "geoPoint.h"

GeoShape::GeoShape(QString name, ShapeType type, QObject *parent)
    :QObject(parent)
    ,_tool(this)
    ,_keypointModel(this)
    ,_name(qMove(name))
    ,_type(type)
{
}

void GeoShape::setName(QString name){
    _name = qMove(name);
    emit nameChanged();
}
void GeoShape::setCurrent(GeoPoint *pt){
    if(_current != pt){
        if(_current)
            _current = pt;
        emit currentChanged();
    }
}
void GeoShape::setCenter(QGeoCoordinate center){
    if(_center != center){
        double dist = 0, azim = 0;
        if(_center.isValid() && center.isValid()){
            dist = _center.distanceTo(center);
            azim = _center.azimuthTo(center);
        }
        _center = center;
        emit centerChanged();
        emit centerOffset(dist, azim);
    }
}
void GeoShape::setDraging(bool drag){
    if(_draging != drag){
        _draging = drag;
        emit dragingChanged();
    }
}
void GeoShape::setValid(bool valid){
    if(_valid != valid){
        _valid = valid;
        emit validChanged();
    }
}
void GeoShape::setCanUpdate(bool can){
    _canUpdate = can;
    if(can && _needUpdate){
        _needUpdate = false;
        emit pathChanged();
    }
}
void GeoShape::updateArea(){
    _area = 0;
    if(_valid){
        QPointF last = qobject_cast<GeoPoint*>(_keypointModel.get(_keypointModel.count()-1))->nedPoint();
        GeoPoint* point = nullptr;
        for(int i=0; i<_keypointModel.count(); ++i){
            point = qobject_cast<GeoPoint*>(_keypointModel.get(i));
            if(point){
                _area += last.x() * point->nedPoint().y() - point->nedPoint().x() * last.y();
                last = point->nedPoint();
            }
        }
        _area = 0.5 * fabs(_area);
    }
}
