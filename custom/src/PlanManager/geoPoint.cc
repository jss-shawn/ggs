
#include "geoPoint.h"

GeoPoint::GeoPoint(QObject* parent)
    :QObject(parent)
    ,_coord()
    ,_nedPoint(qQNaN(), qQNaN())
{
}
GeoPoint::GeoPoint(QGeoCoordinate coord, QObject* parent)
    :QObject(parent)
    ,_coord(coord)
    ,_nedPoint(qQNaN(), qQNaN())
{
}
GeoPoint::GeoPoint(const GeoPoint& other)
    :QObject(other.parent())
    ,_coord(other._coord)
    ,_index(other._index)
    ,_type(other._type)
    ,_action(other._action)
    ,_amsl(other._amsl)
    ,_distance(other._distance)
    ,_nedPoint(other._nedPoint)
    ,_sideId(other._sideId)
    ,_pathId(other._pathId)
{
}
GeoPoint::~GeoPoint(){
}
GeoPoint& GeoPoint::operator=(const GeoPoint& other){
    if(this == &other){
        return *this;
    }
    setCoord(other._coord);
    setIndex(other._index);
    setType(other._type);
    setAction(other._action);
    setAmsl(other._amsl);
    setDistance(other._distance);
    setNedPoint(other._nedPoint);
    setSideId(other._sideId);
    setPathId(other._pathId);
    return *this;
}

bool GeoPoint::operator==(const GeoPoint& other) const{
    return !(*this != other);
}

bool GeoPoint::operator!=(const GeoPoint& other) const{
    return _coord != other._coord;
}

void GeoPoint::setTerrain(double terrain){
    _coord.setAltitude(terrain);
    emit terrainChanged();
}
void GeoPoint::setCoord(const QGeoCoordinate& coord){
    if(_coord != coord){
        _coord = coord;
        emit coordChanged();
    }
}
void GeoPoint::setIndex(int index){
    if(_index != index){
        _index = index;
        emit indexChanged();
    }
}
void GeoPoint::setType(PointType type){
    if(_type != type){
        _type = type;
    }
}
void GeoPoint::setAction(int action){
    if(_action != action){
        _action = action;
    }
}
void GeoPoint::setAmsl(double amsl){
    if(_amsl != amsl){
        _amsl = amsl;
        emit amslChanged();
    }
}
void GeoPoint::setDistance(double distance){
    if(_distance != distance){
        _distance = distance;
        emit distanceChanged();
    }
}
void GeoPoint::setNedPoint(QPointF pt){
    if(_nedPoint != pt){
        _nedPoint= pt;
    }
}
void GeoPoint::setSideId(int id){
    if(_sideId != id){
        _sideId = id;
    }
}
void GeoPoint::setPathId(int id){
    if(_pathId != id){
        _pathId = id;
    }
}

