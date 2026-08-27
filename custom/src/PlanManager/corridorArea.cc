
#include <QLineF>
#include <QPolygonF>
#include "TerrainQuery.h"
#include "corridorArea.h"
#include "geoLine.h"

CorridorArea::CorridorArea(QObject *parent)
    :SurveyArea(parent)
    ,_tool(this)
    ,_corridor("Corridor", this)
{
    init();
}

CorridorArea::CorridorArea(QString name, QObject *parent)
    :SurveyArea(parent)
    ,_tool(this)
    ,_corridor(name, this)
{
    init();
}

void CorridorArea::init()
{
    connect(&_setup, &SurveySetup::setupChanged, this, &CorridorArea::genRealPath);
    connect(&_corridor, &GeoCorridor::pathChanged, this, &CorridorArea::genRealPath);
    connect(&_corridor, &GeoCorridor::centerOffset, this, &CorridorArea::dragPath);
    connect(_setup.camera()->distanceToSurface(), &Fact::rawValueChanged, this, &CorridorArea::checkSafety);
    connect(_setup.camera()->altMode(), &Fact::rawValueChanged, this, &CorridorArea::checkSafety);
    connect(this, &CorridorArea::showAllWaypointChanged, this, &CorridorArea::updateWaypoint);
}

void CorridorArea::save(QJsonArray& array, const QString& suffix)
{
    QJsonObject item;
    if ("jplan" == suffix) {
        QJsonArray coords;
        QmlObjectListModel* model = _corridor.keypointModel();
        GeoPoint* point = nullptr;
        for (int i=0; i<model->count(); ++i) {
            point = qobject_cast<GeoPoint*>(model->get(i));
            QJsonArray coord;
            coord.append(point->coord().latitude());
            coord.append(point->coord().longitude());
            coords.append(coord);
        }
        item["coords"] = coords;
        item["leftWidth"] = _corridor.leftWidth();
        item["rightWidth"] = _corridor.rightWidth();
        item["frontDistance"] = _setup.camera()->adjustedFootprintFrontal()->rawValue().toDouble();
        item["sideDistance"] = _setup.camera()->adjustedFootprintSide()->rawValue().toDouble();
        array.append(item);
    } else {
        saveWaypoint(array);
    }
}
void CorridorArea::load(const QJsonObject& node)
{
    QList<QGeoCoordinate> coords;
    const QJsonArray& array = node["coords"].toArray();
    for (int i=0; i<array.size(); ++i) {
        coords.append(QGeoCoordinate(array[i][0].toDouble(), array[i][1].toDouble()));
    }
    _setup.camera()->adjustedFootprintFrontal()->setRawValue(node["frontDistance"].toDouble());
    _setup.camera()->adjustedFootprintSide()->setRawValue(node["sideDistance"].toDouble());
    _corridor.setLeftWidth(node["leftWidth"].toDouble());
    _corridor.setRightWidth(node["rightWidth"].toDouble());
    _corridor.set(coords);
}

void CorridorArea::clear()
{
    if (_showInfoModel.count()) {
        _showInfoModel.clear();
    }
    _notEmpty = false;
    _valid = false;
    _pathSize = 0;
    _path.clear();
    _realPath.clear();
    _checkPath.clear();
    _srcIndex.clear();
    emit pathChanged();
    emit validChanged();
}

void CorridorArea::genFlightPath()
{
    _path.clear();
    QList<GeoPoint> list;
    if (_realPath.size()) {
        GeoPoint point(this);
        for (int i=0; i<_realPath.size(); ++i) {
            point.setAction(GeoPoint::start);
            if (i%2) {
                for (int j=_realPath[i].size()-1; j>=0; --j) {
                    point.setCoord(_realPath[i][j]);
                    _path.append(QVariant::fromValue(_realPath[i][j]));
                    list.append(point);
                    point.setAction(GeoPoint::none);
                }
            } else {
                for (int j=0; j<_realPath[i].size(); ++j) {
                    point.setCoord(_realPath[i][j]);
                    _path.append(QVariant::fromValue(_realPath[i][j]));
                    list.append(point);
                    point.setAction(GeoPoint::none);
                }
            }
            list.last().setAction(GeoPoint::stop);
        }
    }
    _pathSize = _path.size();
    int index = 0;
    _pathDistance = 0;
    if (_pathSize) {
        //更新航点和内部序号
        list[0].setIndex(index);
        for (int i=1; i<_pathSize; ++i) {
            index = index + 1 + list[i-1].action();
            list[i].setIndex(index);
            _pathDistance += list[i].coord().distanceTo(list[i-1].coord());
        }
        //GeoPoint* ptr = nullptr;
        for (int i=0; i<_pathSize; ++i) {
            if (i<_waypoints.size()) {
                *(_waypoints[i]) = list[i];
            } else {
                _waypoints.append(new GeoPoint(list[i]));
            }
        }
    }
    updateWaypoint();
    updateLines();
    _notEmpty = true;
    emit pathChanged();
    //更新有效性
    bool valid = _pathSize;
    if (valid != _valid) {
        _valid = valid;
        emit validChanged();
    }
}

//SLOTS
void CorridorArea::checkSafety()
{
    //计算安全性
    _safety = 1;
    if (_checkPath.size()) {
        updateAmsls();
        double altDiff = 0, dist = 0, slope = 0, beg = 0;
        for (int i=1; i<_srcIndex.size(); ++i) {
            int fromIndex = _srcIndex[i-1], toIndex = _srcIndex[i];
            beg = _waypoints[i-1]->amsl();
            altDiff = _waypoints[i]->amsl() - beg;
            dist = _checkPath[fromIndex].distanceTo(_checkPath[toIndex]);
            slope = altDiff / dist;
            for (int j=fromIndex; j<=toIndex-1; ++j) {
                if (_checkPath[j].altitude() >= (beg + slope * (j - fromIndex)*_checkMeter)) {
                    _safety = 0;
                    break;
                }
            }
        }
        if (_checkPath.last().altitude() >= _waypoints.last()->amsl()) {
            _safety = 0;
        }
    }
    emit safetyChanged();
}

void CorridorArea::updateLines()
{
    if (_lines.count()) {
        _lines.clearAndDeleteContents();
    }
    GeoPoint* from = nullptr;
    GeoPoint* to = nullptr;
    for (int i=1; i<_waypoints.size(); ++i) {
        from = _waypoints[i-1];
        to = _waypoints[i];
        GeoLine* line = new GeoLine(from, to, this);
        _lines.append(line);
    }
}

void CorridorArea::updateWaypoint()
{
    //更新航点和显示信息
    if (_pathSize) {
        GeoPoint* ptr = nullptr;
        if (_showAllWaypoint) {
            for (int i=0; i<_pathSize; ++i) {
                ptr = qobject_cast<GeoPoint*>(_showInfoModel.get(i));
                if (i<_showInfoModel.count()) {
                    if (ptr != _waypoints[i]) {
                        _showInfoModel.removeAt(i);
                        _showInfoModel.insert(i, _waypoints[i]);
                    }
                } else {
                    _showInfoModel.append(_waypoints[i]);
                }
            }
            if (_showInfoModel.count() > _pathSize) {
                while(_showInfoModel.count() > _pathSize) {
                    _showInfoModel.removeAt(_pathSize);
                }
            }
        } else {
            int size = _showInfoModel.count();
            if (size) {
                if (size > 2) {
                    _showInfoModel.clear();
                } else {
                    _showInfoModel.removeAt(0);
                    _showInfoModel.removeAt(0);
                }
            }
            _showInfoModel.append(_waypoints.first());
            _showInfoModel.append(_waypoints.at(_pathSize-1));
        }
    } else if (_showInfoModel.count()) {
        _showInfoModel.clear();
    }
}
void CorridorArea::genRealPath()
{
    _realPath.clear();
    double spacing = _setup.camera()->adjustedFootprintSide()->rawValue().toDouble();
    int i = 1;
    if (_corridor.path().size()) {
        if (!_corridor.draging()) {
            //添加中央航线
            _realPath.append(_corridor.mids());
            //判断两侧宽度是否可生成航线
            while(i*spacing < _corridor.leftWidth() ||
                   i*spacing < _corridor.rightWidth()) {
                QList<QGeoCoordinate> left, right;
                if (i*spacing < _corridor.leftWidth()) {
                    //插入左侧航线
                    _corridor.offsetLine(true, i*spacing, left);
                    _realPath.prepend(left);
                }
                if (i*spacing < _corridor.rightWidth()) {
                    //右侧追加航线
                    _corridor.offsetLine(false, i*spacing, right);
                    _realPath.append(right);
                }
                ++i;
            }
            genFlightPath();
        }
    } else {
        if (_notEmpty) {
            clear();
        }
    }
}
void CorridorArea::dragPath(double dist, double azim)
{
    _path.clear();
    _pathDistance = 0;
    QGeoCoordinate coord = _waypoints[0]->coord().atDistanceAndAzimuth(dist, azim);
    _waypoints[0]->setCoord(coord);
    _path.append(QVariant::fromValue(coord));
    for (int i=1; i<_pathSize; ++i) {
        coord = _waypoints[i]->coord().atDistanceAndAzimuth(dist, azim);
        _waypoints[i]->setCoord(coord);
        _path.append(QVariant::fromValue(coord));
        _pathDistance += coord.distanceTo(_waypoints[i-1]->coord());
    }
    emit pathChanged();
    emit simpleInfoChanged();
    if (_path.size()) {
        updateLines();
    }
}
void CorridorArea::onRecvCheck(bool success, QList<double> heights)
{
    if (success && heights.size() == _checkPath.size()) {
        int index = 0;
        for (int i=0; i<_checkPath.size(); ++i) {
            _checkPath[i].setAltitude(heights[i]);
            //更新航点高度
            if (i == _srcIndex[index]) {
                _waypoints[index]->setTerrain(heights[i]);
                ++index;
            }
        }
        checkSafety();
    }
}
