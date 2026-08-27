
#include "TerrainQuery.h"
#include "waypoint.h"
#include "surveyArea.h"
#include "geoLine.h"

GeoLine::GeoLine(QObject* parent)
    :QObject(parent)
    ,_color(0x00, 0x00, 0x00)
{
}

GeoLine::GeoLine(GeoPoint* from, GeoPoint* to, QObject* parent)
    :QObject(parent)
    ,_fromPoint(from)
    ,_toPoint(to)
    ,_color(0x00, 0x00, 0x00)
    ,_nodeLine(false)
{
    connect(_fromPoint, &GeoPoint::coordChanged, this, &GeoLine::updatePath);
    connect(_fromPoint, &GeoPoint::amslChanged, this, &GeoLine::updateSafety);
    connect(_toPoint, &GeoPoint::coordChanged, this, &GeoLine::updatePath);
    connect(_toPoint, &GeoPoint::amslChanged, this, &GeoLine::updateSafety);
    init();
}

GeoLine::GeoLine(MissionNode* from, MissionNode* to, QObject* parent)
    :QObject(parent)
    ,_fromNode(from)
    ,_toNode(to)
    ,_color(0x00, 0x00, 0x00)
    ,_nodeLine(true)
{
    connect(_fromNode, &MissionNode::nodeChanged, this, &GeoLine::updatePath);
    connect(_fromNode, &MissionNode::amslChanged, this, &GeoLine::updateSafety);
    connect(_toNode, &MissionNode::nodeChanged, this, &GeoLine::updatePath);
    connect(_toNode, &MissionNode::amslChanged, this, &GeoLine::updateSafety);
    init();
}

// GeoLine& GeoLine::operator=(const GeoLine& other)
//     if(this == &other)
//         return *this;
//     }
//     _color = other._color;
//     return *this;
// }

void GeoLine::init()
{
    updatePath();
}

void GeoLine::setColor(QColor color)
{
    if (_color != color) {
        _color = color;
        emit colorChanged();
    }
}

void GeoLine::setFromNode(MissionNode* node)
{
    if(_fromNode != node) {
        disconnect(_fromNode, &MissionNode::nodeChanged, this, &GeoLine::updatePath);
        disconnect(_fromNode, &MissionNode::amslChanged, this, &GeoLine::updatePath);
        _fromNode = node;
        connect(_fromNode, &MissionNode::nodeChanged, this, &GeoLine::updatePath);
        connect(_fromNode, &MissionNode::amslChanged, this, &GeoLine::updatePath);
        updatePath();
    }
}

void GeoLine::setToNode(MissionNode* node)
{
    if(_toNode != node)
{
        disconnect(_toNode, &MissionNode::nodeChanged, this, &GeoLine::updatePath);
        disconnect(_toNode, &MissionNode::amslChanged, this, &GeoLine::updatePath);
        _toNode = node;
        connect(_toNode, &MissionNode::nodeChanged, this, &GeoLine::updatePath);
        connect(_toNode, &MissionNode::amslChanged, this, &GeoLine::updatePath);
        updatePath();
    }
}

int GeoLine::lastIndex()
{
    if (_nodeLine) {
        return _toNode->first()->index();
    }
    return _toPoint->index();
}

double GeoLine::distance()
{
    if (_path.size()) {
        QGeoCoordinate from = qvariant_cast<QGeoCoordinate>(_path.first());
        QGeoCoordinate to = qvariant_cast<QGeoCoordinate>(_path.last());
        return from.distanceTo(to);
    }
    return 0;
}

void GeoLine::reverse()
{
    if (_nodeLine) {
        MissionNode* tmp = _fromNode;
        _fromNode = _toNode;
        _toNode = tmp;
    } else {
        GeoPoint* tmp = _fromPoint;
        _fromPoint = _toPoint;
        _toPoint = tmp;
    }
    updatePath();
}

//SLOTS
void GeoLine::updatePath()
{
    QGeoCoordinate fst;
    QGeoCoordinate sec;
    if (_nodeLine) {
        fst = _fromNode->last()->coord();
        sec = _toNode->first()->coord();
    } else {
        fst = _fromPoint->coord();
        sec = _toPoint->coord();
    }

    if (fst.isValid() && sec.isValid()) {
        _path.clear();
        _path.append(QVariant::fromValue(fst));
        _path.append(QVariant::fromValue(sec));
        emit pathChanged();

        _query = new TerrainPathQuery(true);
        connect(_query, &TerrainPathQuery::terrainDataReceived, this, &GeoLine::onRecvCheck);
        _query->requestData(fst, sec);
    }
}

void GeoLine::updateSafety()
{
    double beg = 0;
    double end = 0;
    double dist = 0;
    if (_nodeLine) {
        beg = _fromNode->last()->amsl();
        end = _toNode->first()->amsl();
        dist = (_fromNode->last()->coord().distanceTo(_toNode->first()->coord()));
    } else {
        beg = _fromPoint->amsl();
        end = _toPoint->amsl();
        dist = (_fromPoint->coord().distanceTo(_toPoint->coord()));
    }

    double altDiff = (end - beg);
    double slope = altDiff / dist;
    double yIntercept = beg;

    double x = 0;
    for (int i=0; i<_altitudes.count(); i++) {
        double y = _altitudes[i].value<double>();
        if (y > (slope * x) + yIntercept) {
            _safety = 0;
            break;
        }
        if (i == _altitudes.count() - 2) {
            x += _finalInterval;
        } else {
            x += _checkInterval;
        }
    }
    emit safetyChanged();
}

void GeoLine::onRecvCheck(bool success, const TerrainPathHeightInfo& info)
{
    if (sender() == _query) {
        disconnect(_query, &TerrainPathQuery::terrainDataReceived, this, &GeoLine::onRecvCheck);
        _query = nullptr;
    }
    if (success) {
        _safety = 1;
        _altitudes.clear();

        _checkInterval = info.distanceBetween;
        _finalInterval = info.finalDistanceBetween;
        for (const double& height : info.heights) {
            _altitudes.append(height);
        }
        updateSafety();
    }else{
        _safety = -1;
        emit safetyChanged();
    }
}
