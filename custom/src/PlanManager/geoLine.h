
#pragma once

#include <QObject>
#include <QtGui/QColor>
#include <QVariant>
#include <QtPositioning/QGeoCoordinate>
#include <QTimer>
#include "TerrainPathHeightInfo.h"

class GeoPoint;
class MissionNode;
class TerrainPathQuery;

class GeoLine: public QObject{
    Q_OBJECT
public:
    GeoLine(QObject* parent = nullptr);
    GeoLine(GeoPoint* from, GeoPoint* to, QObject* parent = nullptr);
    GeoLine(MissionNode* from, MissionNode* to, QObject* parent = nullptr);

    // GeoLine& operator=(const GeoLine& other);

    void init();

    Q_PROPERTY(QVariantList path READ path NOTIFY pathChanged FINAL)
    Q_PROPERTY(QVariantList altitudes READ altitudes NOTIFY altitudesChanged FINAL)
    Q_PROPERTY(double checkInterval READ checkInterval NOTIFY checkIntervalChanged FINAL)
    Q_PROPERTY(double finalInterval READ finalInterval NOTIFY finalIntervalChanged FINAL)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged FINAL)
    Q_PROPERTY(bool safety READ safety NOTIFY safetyChanged FINAL)

    QVariantList path() { return _path; }
    QVariantList altitudes() { return _altitudes; }
    double checkInterval() { return _checkInterval; }
    double finalInterval() { return _finalInterval; }
    QColor color() { return _color; }
    bool safety() { return _safety; }

    void setColor(QColor color);

    GeoPoint* fromPoint() { return _fromPoint; }
    GeoPoint* toPoint() { return _toPoint; }
    MissionNode* fromNode() { return _fromNode; }
    MissionNode* toNode() { return _toNode; }

    void setFromNode(MissionNode* node);
    void setToNode(MissionNode* node);

    int lastIndex();
    double distance();
    void reverse();
signals:
    void pathChanged();
    void altitudesChanged();
    void checkIntervalChanged();
    void finalIntervalChanged();
    void colorChanged();
    void safetyChanged();
public slots:
    void updatePath();
    void updateSafety();
    void onRecvCheck(bool success, const TerrainPathHeightInfo& info);
protected:
    GeoPoint* _fromPoint = nullptr;
    GeoPoint* _toPoint = nullptr;
    MissionNode* _fromNode = nullptr;
    MissionNode* _toNode = nullptr;
    TerrainPathQuery* _query = nullptr;
    QVariantList _path;
    QVariantList _altitudes;
    double _checkInterval = 0;
    double _finalInterval = 0;
    QColor _color;
    int _safety = -1;
    bool _nodeLine = true;

};
