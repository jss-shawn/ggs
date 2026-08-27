
#pragma once

#include <QObject>
#include <QPointF>
#include <QtPositioning/QGeoCoordinate>
#include <QtQmlIntegration/QtQmlIntegration>

class GeoPoint: public QObject{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    enum PointType{
        normal = 0,
        enter,
        leave,
        turn,
    };

    enum CamAct{
        none = 0,
        start,
        stop,
    };

    GeoPoint(QObject* parent = nullptr);
    GeoPoint(QGeoCoordinate coord, QObject* parent = nullptr);
    GeoPoint(const GeoPoint& other);
    ~GeoPoint();
    GeoPoint& operator=(const GeoPoint& other);

    bool operator==(const GeoPoint& other) const;
    bool operator!=(const GeoPoint& other) const;

    Q_PROPERTY(int index READ index NOTIFY indexChanged FINAL)
    Q_PROPERTY(QGeoCoordinate coord READ coord WRITE setCoord NOTIFY coordChanged FINAL)
    Q_PROPERTY(double terrain READ terrain NOTIFY terrainChanged FINAL)
    Q_PROPERTY(double amsl READ amsl NOTIFY amslChanged FINAL)
    Q_PROPERTY(double distance READ distance NOTIFY distanceChanged FINAL)

    int index() { return _index; }
    QGeoCoordinate coord() { return _coord; }
    double terrain() { return _coord.altitude(); }
    PointType type() { return _type; }
    int action() { return _action; }
    double amsl() { return _amsl; }
    double distance() { return _distance; }

    QPointF nedPoint() { return _nedPoint; }
    int sideId() { return _sideId; }
    int pathId() { return _pathId; }

    void setIndex(int index);
    void setCoord(const QGeoCoordinate& coord);
    void setTerrain(double terrain);
    void setType(PointType type);
    void setAction(int act);
    void setAmsl(double amsl);
    void setDistance(double distance);

    void setNedPoint(QPointF pt);
    void setSideId(int id);
    void setPathId(int id);
signals:
    void indexChanged();
    void coordChanged();
    void terrainChanged();
    void amslChanged();
    void distanceChanged();
protected:
    //基础属性
    QGeoCoordinate _coord;
    //图标属性
    int _index = 0;
    PointType _type = PointType::normal;
    int _action = 0;
    double _amsl = 0;
    double _distance = 0;
    //辅助计算
    QPointF _nedPoint;
    int _sideId = -1;
    int _pathId = -1;
};
