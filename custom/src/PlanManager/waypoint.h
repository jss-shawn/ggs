#pragma once

#include <QVariantList>
#include <QtPositioning/QGeoCoordinate>
#include <QtQmlIntegration/QtQmlIntegration>
#include "Fact.h"
#include "missionNode.h"
#include "geoPoint.h"
#include "waypointCamera.h"

class GisesManager;
class TerrainAtCoordinateQuery;

class Waypoint: public MissionNode{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:

    enum UIType{
        TextField = 0,
        Slider,
        Switch,
        Valuebox,
        Combobox
    };
    Q_ENUM(UIType)

    Waypoint(double altitude, QObject* parent = nullptr);
    Waypoint(QGeoCoordinate coordinate, double altitude, QObject* parent = nullptr);

    void init();

    Q_PROPERTY(Fact* commandFact READ commandFact CONSTANT)
    Q_PROPERTY(Fact* frameFact READ frameFact CONSTANT)
    Q_PROPERTY(Fact* autoFact READ autoFact CONSTANT)
    Q_PROPERTY(Fact* p1Fact READ p1Fact CONSTANT)
    Q_PROPERTY(Fact* p2Fact READ p2Fact CONSTANT)
    Q_PROPERTY(Fact* p3Fact READ p3Fact CONSTANT)
    Q_PROPERTY(Fact* p4Fact READ p4Fact CONSTANT)
    Q_PROPERTY(Fact* p5Fact READ p5Fact CONSTANT)
    Q_PROPERTY(Fact* p6Fact READ p6Fact CONSTANT)
    Q_PROPERTY(Fact* p7Fact READ p7Fact CONSTANT)
    Q_PROPERTY(bool isLoiter READ isLoiter NOTIFY isLoiterChanged FINAL)
    Q_PROPERTY(double loiterRadius READ loiterRadius WRITE setLoiterRadius NOTIFY loiterRadiusChanged FINAL)
    Q_PROPERTY(QGeoCoordinate coord READ coord WRITE setCoord NOTIFY coordChanged FINAL)
    Q_PROPERTY(double altitude READ altitude WRITE setAltitude NOTIFY altitudeChanged FINAL)
    Q_PROPERTY(bool isCurrentItem READ isCurrentItem WRITE setIsCurrentItem NOTIFY isCurrentItemChanged FINAL)
    Q_PROPERTY(bool rawMode READ rawMode WRITE setRawMode NOTIFY rawModeChanged FINAL)

    Q_PROPERTY(Fact* altModeFact READ altModeFact CONSTANT)
    Q_PROPERTY(WaypointCamera* camera READ camera CONSTANT)
    Q_PROPERTY(GeoPoint* first READ first CONSTANT)
    Q_PROPERTY(QList<Fact*> allParams READ allParams NOTIFY missionUiChanged FINAL)
    Q_PROPERTY(QList<int> paramsUiType READ paramsUiType NOTIFY missionUiChanged FINAL)
    Q_PROPERTY(bool showFriendly READ showFriendly NOTIFY missionUiChanged FINAL)
    Q_PROPERTY(bool showCoord READ showCoord NOTIFY missionUiChanged FINAL)
    Q_PROPERTY(bool showAlt READ showAlt NOTIFY missionUiChanged FINAL)

    Q_PROPERTY(bool calcAboveTerrain READ calcAboveTerrain WRITE setCalcAboveTerrain NOTIFY calcAboveTerrainChanged FINAL)

    //基础参数
    Fact* commandFact() { return &_commandFact; }
    Fact* frameFact() { return &_frameFact; }
    Fact* autoFact() { return &_autoContinueFact; }
    Fact* p1Fact() { return &_p1Fact; }
    Fact* p2Fact() { return &_p2Fact; }
    Fact* p3Fact() { return &_p3Fact; }
    Fact* p4Fact() { return &_p4Fact; }
    Fact* p5Fact() { return &_p5Fact; }
    Fact* p6Fact() { return &_p6Fact; }
    Fact* p7Fact() { return &_p7Fact; }
    Fact* altModeFact() { return &_altModeFact; }
    WaypointCamera* camera() { return &_camera; }
    bool valid() final { return showCoord(); }
    GeoPoint* first() final { return &_point; }
    GeoPoint* last() final { return &_point; }
    void save(QJsonArray& array, const QString& suffix) final;
    void load(const QJsonObject& node) final;
    void genMissionItem(QList<MissionItem*>& list, QObject* parent) final;
    bool isTakeoff() final;
    bool isHome() final { return _isHome; }
    bool loadAction(const QJsonObject& act);
    bool isLoiter();
    double loiterRadius();
    void setLoiterRadius(double raidus);
    //快捷读写
    QGeoCoordinate coord(void);
    double altitude() { return _altitude; }
    bool isCurrentItem() { return _isCurrentItem; }
    bool rawMode() { return _rawMode; }
    //地形辅助
    bool calcAboveTerrain() { return _calcAboveTerrain; }
    void setIsHome(bool isHome);
    void setCoord(QGeoCoordinate coord);
    void setAltitude(double alt);
    void setIsCurrentItem(bool isCurrent);
    void setRawMode(bool raw);
    void setCalcAboveTerrain(bool calc);

    const QList<Fact*>& allParams() { return _allParams; }
    const QList<int>& paramsUiType() { return _paramsUiType; }

    bool showFriendly();
    bool showCoord();
    bool showAlt();
signals:
    void isLoiterChanged();
    void loiterRadiusChanged();
    void coordChanged();
    void altitudeChanged();
    void isCurrentItemChanged();
    void rawModeChanged();
    void calcAboveTerrainChanged();
    void missionUiChanged();
public slots:
    void updateUiData();
    void updateAmsl();
    void updatePoint();
    void reqTerrainAlt();
    void onRecvTerrainAlt(bool success, QList<double> alt);
private:
    bool _isCurrentItem = false;
    GisesManager* _gises = nullptr;

    Fact _autoContinueFact;
    Fact _commandFact;
    Fact _frameFact;
    Fact _p1Fact;
    Fact _p2Fact;
    Fact _p3Fact;
    Fact _p4Fact;
    Fact _p5Fact;
    Fact _p6Fact;
    Fact _p7Fact;
    //地图显示用
    double _altitude = 0;
    Fact _altModeFact;
    WaypointCamera _camera;
    GeoPoint _point;
    QList<Fact*> _allParams;
    QList<FactMetaData> _paramsMeta;
    QList<int> _paramsUiType;
    QVariantList _missionCommandList;
    bool _rawMode = false;
    bool _isHome = false;
    //航线计算用
    TerrainAtCoordinateQuery* _query = nullptr;
    bool _calcAboveTerrain = false;
};
