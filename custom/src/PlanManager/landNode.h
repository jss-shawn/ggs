#pragma once

#include <QVariantList>
#include <QtPositioning/QGeoCoordinate>
#include <QtQmlIntegration/QtQmlIntegration>
#include "TerrainPathHeightInfo.h"
#include "missionNode.h"
#include "geoPoint.h"

class TerrainPathQuery;

class LandNode: public MissionNode{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    LandNode(double altitude, QObject* parent = nullptr);
    LandNode(QGeoCoordinate coordinate, double altitude, QObject* parent = nullptr);

    void init();
    void reset();

    //Q_PROPERTY(QGeoCoordinate coord READ coord WRITE setCoord NOTIFY coordChanged FINAL)
    Q_PROPERTY(GeoPoint* first READ first CONSTANT)
    Q_PROPERTY(GeoPoint* last READ last CONSTANT)

    Q_PROPERTY(GeoPoint* enterPoint READ enterPoint NOTIFY enterPointChanged FINAL)
    Q_PROPERTY(GeoPoint* loiterPoint READ loiterPoint NOTIFY loiterPointChanged FINAL)
    Q_PROPERTY(GeoPoint* landPoint READ landPoint NOTIFY landPointChanged FINAL)
    Q_PROPERTY(int landMode READ landMode WRITE setLandMode NOTIFY landModeChanged FINAL)
    Q_PROPERTY(bool relativeAlt READ relativeAlt WRITE setRelativeAlt NOTIFY relativeAltChanged FINAL)
    Q_PROPERTY(bool useLoiter READ useLoiter WRITE setUseLoiter NOTIFY useLoiterChanged FINAL)
    Q_PROPERTY(bool clockwise READ clockwise WRITE setClockwise NOTIFY clockwiseChanged FINAL)
    Q_PROPERTY(bool useDeg READ useDeg WRITE setUseDeg NOTIFY useDegChanged FINAL)
    Q_PROPERTY(double enterAltitude READ enterAltitude WRITE setPreAltitude NOTIFY enterAltitudeChanged FINAL)
    Q_PROPERTY(double radius READ radius WRITE setRadius NOTIFY radiusChanged FINAL)

    Q_PROPERTY(int head READ head WRITE setHead NOTIFY headChanged FINAL)
    Q_PROPERTY(double landAltitude READ landAltitude WRITE setLandAltitude NOTIFY landAltitudeChanged FINAL)
    Q_PROPERTY(double distance READ distance WRITE setDistance NOTIFY distanceChanged FINAL)
    Q_PROPERTY(double deg READ deg WRITE setDeg NOTIFY degChanged FINAL)

    Q_PROPERTY(int enterPathSafety READ enterPathSafety NOTIFY enterPathSafetyChanged FINAL)
    Q_PROPERTY(int landPathSafety READ landPathSafety NOTIFY landPathSafetyChanged FINAL)

    Q_INVOKABLE void calcHead(QGeoCoordinate coord);

    bool valid() final;
    GeoPoint* first() final { return _loiterPoint; }
    GeoPoint* last() final { return _landPoint; }
    void save(QJsonArray& array, const QString& suffix) final;
    void load(const QJsonObject& node) final;
    void genMissionItem(QList<MissionItem*>& list, QObject* parent) final;

    //快捷读写
    GeoPoint* enterPoint() { return _enterPoint; }
    GeoPoint* loiterPoint() { return _loiterPoint; }
    GeoPoint* landPoint() { return _landPoint; }
    int landMode() { return _landMode; }
    bool relativeAlt() { return _relativeAlt; }
    bool useLoiter() { return _useLoiter; }
    bool clockwise() { return _clockwise; }
    bool useDeg() { return _useDeg; }
    double enterAltitude() { return _enterAltitude; }
    double radius() { return _radius; }
    int head() { return _head; }
    double landAltitude() { return _landAltitude; }
    double distance() { return _distance; }
    double deg() { return _deg; }
    int enterPathSafety() { return _enterPathSafety; }
    int landPathSafety() { return _landPathSafety; }

    void setLandMode(int mode);
    void setRelativeAlt(bool relative);
    void setUseLoiter(bool use);
    void setClockwise(bool clockwise);
    void setUseDeg(bool useDeg);
    void setPreAltitude(double alt);
    void setRadius(double radius);
    void setHead(int head);
    void setLandAltitude(double alt);
    void setDistance(double dist);
    void setDeg(double deg);

    double preAmsl();
    double landAmsl();
    void setEnterPoint(GeoPoint* point);
signals:
    void enterPointChanged();
    void loiterPointChanged();
    void landPointChanged();
    void landModeChanged();
    void relativeAltChanged();
    void useLoiterChanged();
    void clockwiseChanged();
    void useDegChanged();
    void enterAltitudeChanged();
    void radiusChanged();
    void headChanged();
    void landAltitudeChanged();
    void distanceChanged();
    void degChanged();
    void enterPathSafetyChanged();
    void landPathSafetyChanged();
    void safetyChanged();
public slots:
    void calcPreCoord();
    void updateDeg();
    void updateDist();
    void reqEnterPathTerrain();
    void reqLandPathTerrain();
    void onRecvEnterPathTerrain(bool success, const TerrainPathHeightInfo& info);
    void onRecvLandPathTerrain(bool success, const TerrainPathHeightInfo& info);
    void checkEnterSafety();
    void checkLandSafety();
private:
    TerrainPathQuery* _enterPathQuery = nullptr;
    TerrainPathQuery* _landPathQuery = nullptr;
    GeoPoint* _enterPoint = nullptr;
    GeoPoint* _loiterPoint = nullptr;
    GeoPoint* _landPoint = nullptr;
    //0: None	1: Multi-Rotor	2: Fixed-Wing
    int _landMode = 0;
    bool _relativeAlt = true;
    bool _useLoiter = true;
    bool _clockwise = true;
    bool _useDeg = false;
    double _radius = 50;
    int _head = 0;
    double _enterAltitude = 0;
    double _enterCheckInterval = 0;
    double _enterFinalInterval = 0;
    QVariantList _enterHeights;
    double _landAltitude = 0;
    double _landCheckInterval = 0;
    double _landFinalInterval = 0;
    QVariantList _landHeights;
    double _distance = 100;
    double _deg = 0;
    //
    int _enterPathSafety = -1;
    int _landPathSafety = -1;
};
