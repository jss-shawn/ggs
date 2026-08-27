
#include "JsonParsing.h"
#include "QGroundControlQmlGlobal.h"
#include "MissionCommandTree.h"
#include "MissionCommandUIInfo.h"
#include "MultiVehicleManager.h"
#include "TerrainQuery.h"
#include "Vehicle.h"
#include "MissionItem.h"
#include "landNode.h"
#include "gisesPlan.h"

LandNode::LandNode(double altitude, QObject* parent)
    :MissionNode(land, parent)
    ,_loiterPoint(new GeoPoint(this))
    ,_landPoint(new GeoPoint(this))
    ,_enterAltitude(altitude)
{
    _active = false;
}
LandNode::LandNode(QGeoCoordinate coordinate, double altitude, QObject* parent)
    :MissionNode(land, parent)
    ,_loiterPoint(new GeoPoint(this))
    ,_landPoint(new GeoPoint(coordinate, this))
    ,_enterAltitude(altitude)
{
}

void LandNode::init() {
    _deg = qAtan((_enterAltitude - _landAltitude) / _distance) * 180 / M_PI;
    //FactMetaData* cmd = _plan->frameMetaData();
    //connect(this, &LandNode::coordChanged, this, &LandNode::reqTerrainAlt);
    //connect(this, &LandNode::altitudeChanged, this, &LandNode::updateAmsl);
    //connect(&_altModeFact, &Fact::rawValueChanged, this, &LandNode::updateAmsl);
    //connect(&_loiterPoint, &GeoPoint::coordChanged, this, &LandNode::onPreCoordChanged);
    connect(_landPoint, &GeoPoint::coordChanged, this, &LandNode::calcPreCoord);
    connect(this, &LandNode::relativeAltChanged, this, &LandNode::checkEnterSafety);
    connect(this, &LandNode::relativeAltChanged, this, &LandNode::checkLandSafety);
    connect(this, &LandNode::useLoiterChanged, this, &LandNode::calcPreCoord);
    connect(this, &LandNode::clockwiseChanged, this, &LandNode::calcPreCoord);
    connect(this, &LandNode::radiusChanged, this, &LandNode::calcPreCoord);
    connect(this, &LandNode::headChanged, this, &LandNode::calcPreCoord);
    connect(this, &LandNode::enterAltitudeChanged, this, &LandNode::updateDeg);
    connect(this, &LandNode::landAltitudeChanged, this, &LandNode::updateDeg);
    connect(this, &LandNode::distanceChanged, this, &LandNode::updateDeg);
    connect(this, &LandNode::degChanged, this, &LandNode::updateDist);
}

void LandNode::reset()
{

}

void LandNode::calcHead(QGeoCoordinate coord)
{
    if (coord != _loiterPoint->coord()) {
        double offset = 0, head = 0, azi = _landPoint->coord().azimuthTo(coord);
        if (_useLoiter && _radius > 1.0) {
            offset = qAtan(_radius / _distance) * 180 / M_PI;
        }
        head = azi + (_clockwise ? offset : -offset);
        setHead(head);
    }
}

bool LandNode::valid()
{
    return false;
}

void LandNode::save(QJsonArray& array, const QString& suffix)
{
    Q_UNUSED(suffix);
    QJsonObject item;
    item["type"] = _nodeType;
    item["landMode"] = _landMode;
    QJsonArray landArray;
    landArray.append(_landPoint->coord().latitude());
    landArray.append(_landPoint->coord().longitude());
    QJsonArray loiterArray;
    loiterArray.append(_loiterPoint->coord().latitude());
    loiterArray.append(_loiterPoint->coord().longitude());
    if (2 == _landMode) {
        item["relativeAlt"] = _relativeAlt;
        item["useLoiter"] = _useLoiter;
        item["clockwise"] = _clockwise;
        item["preAlt"] = _enterAltitude;
        item["landAlt"] = _landAltitude;
        item["head"] = _head;
        item["radius"] = _radius;
        item["distance"] = _distance;
    }
    item["land"] = landArray;
    item["loiter"] = loiterArray;
    array.append(item);
}

void LandNode::load(const QJsonObject& node)
{
    if (2 == node["landMode"].toInt()) {
        setRelativeAlt(node["relativeAlt"].toBool());
        setUseLoiter(node["useLoiter"].toBool());
        setClockwise(node["clockwise"].toBool());
        setPreAltitude(node["preAlt"].toDouble());
        setLandAltitude(node["landAlt"].toDouble());
        setHead(node["head"].toInt());
        setRadius(node["radius"].toDouble());
        setDistance(node["distance"].toDouble());
    }
    double lat = node["land"].toArray()[0].toDouble();
    double lon = node["land"].toArray()[1].toDouble();
    _landPoint->setCoord(QGeoCoordinate(lat,lon));
    lat = node["loiter"].toArray()[0].toDouble();
    lon = node["loiter"].toArray()[1].toDouble();
    _loiterPoint->setCoord(QGeoCoordinate(lat,lon));
}

void LandNode::genMissionItem(QList<MissionItem*>& list, QObject* parent)
{
    MissionItem* item = nullptr;
    int seqNum = list.size() + 1;
    item = new MissionItem(seqNum++,                            // sequence number
                           MAV_CMD_DO_LAND_START,               // MAV_CMD
                           MAV_FRAME_MISSION,                   // MAV_FRAME
                           0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,   // param 1-7
                           true,                                // autoContinue
                           false,                               // isCurrentItem
                           parent);
    list.append(item);
    if (2 == _landMode) {
        if (_useLoiter) {
            item = new MissionItem(seqNum++,
                                   MAV_CMD_NAV_LOITER_TO_ALT,
                                   _relativeAlt ? MAV_FRAME_GLOBAL_RELATIVE_ALT : MAV_FRAME_GLOBAL,
                                   1.0,             // Heading required = true
                                   _radius * (_clockwise ? 1.0 : -1.0),
                                   0.0,             // param 3 - unused
                                   1.0,             // Exit crosstrack - tangent of loiter to land point
                                   _loiterPoint->coord().latitude(),
                                   _loiterPoint->coord().longitude(),
                                   _enterAltitude,
                                   true,            // autoContinue
                                   false,           // isCurrentItem
                                   parent);
        } else {
            item = new MissionItem(seqNum++,
                                   MAV_CMD_NAV_WAYPOINT,
                                   _relativeAlt ? MAV_FRAME_GLOBAL_RELATIVE_ALT : MAV_FRAME_GLOBAL,
                                   0,             // Heading required = true
                                   0,
                                   0.0,             // param 3 - unused
                                   qQNaN(),             // Exit crosstrack - tangent of loiter to land point
                                   _loiterPoint->coord().latitude(),
                                   _loiterPoint->coord().longitude(),
                                   _enterAltitude,
                                   true,            // autoContinue
                                   false,           // isCurrentItem
                                   parent);
        }
        list.append(item);
    } else {
    }
    Vehicle* vehicle = MultiVehicleManager::instance()->activeVehicle();
    if (vehicle->vtol()) {
        item = new MissionItem(seqNum,
                               MAV_CMD_NAV_VTOL_LAND,
                               _relativeAlt ? MAV_FRAME_GLOBAL_RELATIVE_ALT : MAV_FRAME_GLOBAL,
                               0.0, 0.0, 0.0,
                               qQNaN(),         // Yaw - not specified
                               _landPoint->coord().latitude(),
                               _landPoint->coord().longitude(),
                               _landAltitude,
                               true,            // autoContinue
                               false,           // isCurrentItem
                               parent);
    } else {
        item = new MissionItem(seqNum,
                               MAV_CMD_NAV_LAND,
                               _relativeAlt ? MAV_FRAME_GLOBAL_RELATIVE_ALT : MAV_FRAME_GLOBAL,
                               0.0, 0.0, 0.0, 0.0,
                               _landPoint->coord().latitude(),
                               _landPoint->coord().longitude(),
                               _landAltitude,
                               true,                               // autoContinue
                               false,                              // isCurrentItem
                               parent);
    }
    list.append(item);
}

void LandNode::setLandMode(int mode)
{
    if (_landMode != mode) {
        _landMode = mode;
        emit landModeChanged();
    }
}

void LandNode::setRelativeAlt(bool relative)
{
    if (_relativeAlt != relative) {
        _relativeAlt = relative;
        emit relativeAltChanged();
    }
}

void LandNode::setUseLoiter(bool use)
{
    if (_useLoiter != use) {
        _useLoiter = use;
        emit useLoiterChanged();
    }
}

void LandNode::setClockwise(bool clockwise)
{
    if (_clockwise != clockwise) {
        _clockwise = clockwise;
        emit clockwiseChanged();
    }
}

void LandNode::setUseDeg(bool useDeg)
{
    if (_useDeg != useDeg) {
        _useDeg = useDeg;
        emit useDegChanged();
    }
}

void LandNode::setPreAltitude(double alt)
{
    if (_enterAltitude != alt) {
        _enterAltitude = alt;
        emit enterAltitudeChanged();
    }
}

void LandNode::setRadius(double radius)
{
    if (_radius != radius) {
        _radius = radius;
        emit radiusChanged();
    }
}

void LandNode::setHead(int head)
{
    if (_head != head) {
        _head = head % 360;
        emit headChanged();
    }
}

void LandNode::setLandAltitude(double alt)
{
    if (_landAltitude != alt) {
        _landAltitude = alt;
        emit landAltitudeChanged();
    }
}

void LandNode::setDistance(double dist)
{
    if (qAbs(_distance - dist) > 0.0001) {
        _distance = dist;
        emit distanceChanged();
    }
}

void LandNode::setDeg(double deg)
{
    if (qAbs(_deg - deg) > 0.001) {
        _deg = deg;
        emit degChanged();
    }
}

double LandNode::preAmsl()
{
    if (_relativeAlt) {
        return _enterAltitude + _plan->home().altitude();
    }
    return _enterAltitude;
}

double LandNode::landAmsl()
{
    if (_relativeAlt) {
        return _landAltitude + _plan->home().altitude();
    }
    return _landAltitude;
}

void LandNode::setEnterPoint(GeoPoint* point)
{
    if (point != _enterPoint) {
        if (_enterPoint) {
            disconnect(_enterPoint, &GeoPoint::coordChanged, this, &LandNode::reqEnterPathTerrain);
        }
        _enterPoint = point;
        if (_enterPoint) {
            connect(_enterPoint, &GeoPoint::coordChanged, this, &LandNode::reqEnterPathTerrain);
        }
        reqEnterPathTerrain();
        reqLandPathTerrain();
        emit enterPointChanged();
    }
}

//SLOTS
void LandNode::calcPreCoord()
{
    QGeoCoordinate coord = _landPoint->coord();
    if (2 == _landMode) {
        coord = _landPoint->coord().atDistanceAndAzimuth(_distance, _head);
        if (_useLoiter && _radius > 1.0) {
            coord = coord.atDistanceAndAzimuth(_radius, _head + (_clockwise ? -90 : 90));
        }
    }
    _loiterPoint->setCoord(coord);
    reqEnterPathTerrain();
    reqLandPathTerrain();
}

void LandNode::updateDeg()
{
    double altDiff = _enterAltitude - _landAltitude;
    double deg = qAtan(altDiff / _distance) * 180 / M_PI;
    setDeg(deg);
    calcPreCoord();
}

void LandNode::updateDist()
{
    double altDiff = _enterAltitude - _landAltitude;
    double dist = altDiff / qTan(_deg * M_PI / 180);
    setDistance(dist);
    calcPreCoord();
}

void LandNode::reqEnterPathTerrain()
{
    _enterPathQuery = new TerrainPathQuery(true);
    connect(_enterPathQuery, &TerrainPathQuery::terrainDataReceived, this, &LandNode::onRecvEnterPathTerrain);
    if (_enterPoint->coord().isValid() && _loiterPoint->coord().isValid()) {
        _enterPathQuery->requestData(_enterPoint->coord(), _loiterPoint->coord());
    }
}

void LandNode::reqLandPathTerrain()
{
    _landPathQuery = new TerrainPathQuery(true);
    connect(_landPathQuery, &TerrainPathQuery::terrainDataReceived, this, &LandNode::onRecvLandPathTerrain);
    QGeoCoordinate fst;
    QGeoCoordinate sec;
    if (1 == _landMode) {
        fst = _enterPoint->coord();
        sec = _loiterPoint->coord();
    } else if (2 == _landMode) {
        fst = _loiterPoint->coord();
        sec = _landPoint->coord();
    }
    if (fst.isValid() && sec.isValid()) {
        _enterPathQuery->requestData(fst, sec);
    }
}

void LandNode::onRecvEnterPathTerrain(bool success, const TerrainPathHeightInfo& info)
{
    if (sender() == _enterPathQuery) {
        disconnect(_enterPathQuery, &TerrainPathQuery::terrainDataReceived, this, &LandNode::onRecvEnterPathTerrain);
        _enterPathQuery = nullptr;
    }
    if (success) {
        _enterHeights.clear();
        _enterCheckInterval = info.distanceBetween;
        _enterFinalInterval = info.finalDistanceBetween;
        for (const double& height : info.heights) {
            _enterHeights.append(height);
        }
        checkEnterSafety();
    }
}

void LandNode::onRecvLandPathTerrain(bool success, const TerrainPathHeightInfo& info)
{
    if (sender() == _landPathQuery) {
        disconnect(_landPathQuery, &TerrainPathQuery::terrainDataReceived, this, &LandNode::onRecvLandPathTerrain);
        _landPathQuery = nullptr;
    }
    if (success) {
        _landHeights.clear();
        _landCheckInterval = info.distanceBetween;
        _landFinalInterval = info.finalDistanceBetween;
        for (const double& height : info.heights) {
            _landHeights.append(height);
        }
        checkLandSafety();
    }
}

void LandNode::checkEnterSafety()
{

}

void LandNode::checkLandSafety()
{

}
