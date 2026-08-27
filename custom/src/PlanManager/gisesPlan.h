#pragma once

#include <QObject>
#include <QtCore/QLoggingCategory>
#include <QtPositioning/QGeoCoordinate>
#include <QtQmlIntegration/QtQmlIntegration>
#include <QLineSeries>
#include "TerrainQuery.h"
#include "QmlObjectListModel.h"
Q_MOC_INCLUDE("waypoint.h")
Q_MOC_INCLUDE("landNode.h")
Q_MOC_INCLUDE("surveyArea.h")
Q_MOC_INCLUDE("planSummary.h")

class FactMetaData;
class GeoPoint;
class GisesManager;
class LandNode;
class MissionItem;
class MissionNode;
class PlanSummary;
class SurveyArea;
class Vehicle;
class Waypoint;

Q_DECLARE_LOGGING_CATEGORY(GisesPlanLog)

class GisesPlan : public QObject{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    enum PlanMode{
        WAYPOINT = 0,
        PLANAR,
        ROAD,
        WALL,
        STRUCTURE,
        MIXED,
    };
    Q_ENUM(PlanMode)
    enum NodeAction{
        Remove = 0,
        Alter,
        Add,
    };
    GisesPlan(QObject* parent = nullptr);

    void init();

    FactMetaData* commandMetaData();
    FactMetaData* defaultParamMetaData();
    FactMetaData* frameMetaData();
    FactMetaData* simpleMetaData();

    Q_PROPERTY(QmlObjectListModel* planModel READ planModel CONSTANT)
    Q_PROPERTY(PlanSummary* summary READ summary CONSTANT)
    Q_PROPERTY(LandNode* land READ land CONSTANT)
    Q_PROPERTY(Waypoint* takeoff READ takeoff NOTIFY takeoffChanged FINAL)
    Q_PROPERTY(QGeoCoordinate home READ home WRITE setHome NOTIFY homeChanged FINAL)
    Q_PROPERTY(QmlObjectListModel* surveyAreaModel READ surveyAreaModel CONSTANT)
    Q_PROPERTY(QmlObjectListModel* waypointModel READ waypointModel CONSTANT)
    Q_PROPERTY(QmlObjectListModel* flightPathModel READ flightPathModel CONSTANT)
    Q_PROPERTY(SurveyArea* currentArea READ currentArea NOTIFY currentNodeChanged FINAL)
    Q_PROPERTY(Waypoint* currentWp READ currentWp NOTIFY currentNodeChanged FINAL)
    Q_PROPERTY(LandNode* currentLand READ currentLand NOTIFY currentNodeChanged FINAL)
    Q_PROPERTY(QObject* currentNode READ currentNode WRITE setCurrentNode NOTIFY currentNodeChanged FINAL)
    Q_PROPERTY(PlanMode planMode READ planMode WRITE setPlanMode NOTIFY planModeChanged FINAL)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged FINAL)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged FINAL)

    Q_PROPERTY(double maxAlt READ maxAlt NOTIFY maxChanged FINAL)
    Q_PROPERTY(double maxDist READ maxDist NOTIFY maxChanged FINAL)
    Q_PROPERTY(QLineSeries* waypointSeries MEMBER _waypointSeries NOTIFY waypointSeriesChanged FINAL)
    Q_PROPERTY(QLineSeries* checkSeries MEMBER _checkSeries NOTIFY checkSeriesChanged FINAL)

    const QList<QPointF>& waypointLine() { return _waypointLine; }
    const QList<QPointF>& checkLine() { return _checkLine; }
    QLineSeries* waypointSeries() { return _waypointSeries; }
    QLineSeries* checkSeries() { return _checkSeries; }
    double maxAlt() { return _maxAlt; }
    double maxDist() { return _maxDist; }

    Q_INVOKABLE void initHome(QGeoCoordinate coord);
    Q_INVOKABLE void onMapClicked(QGeoCoordinate coord);
    Q_INVOKABLE void onNodeClicked(QObject* node);
    Q_INVOKABLE void addPolygon(const QList<QGeoCoordinate>& coords);
    Q_INVOKABLE void addCicle(QGeoCoordinate center);
    Q_INVOKABLE void addCorridor(const QList<QGeoCoordinate>& coords);
    Q_INVOKABLE void getNode(int step);
    Q_INVOKABLE void moveTo(bool front);
    Q_INVOKABLE void removeNode();
    Q_INVOKABLE void clear();
    Q_INVOKABLE void loadPlans();
    Q_INVOKABLE void removePlan(int index);
    Q_INVOKABLE bool sendToVehicle();

    QmlObjectListModel* planModel() { return &_planModel; }
    PlanSummary* summary() { return _summary; }
    LandNode* land() { return _land; }
    Waypoint* takeoff() { return _takeOff; }
    QGeoCoordinate home();
    QmlObjectListModel* surveyAreaModel() { return &_surveyAreaModel; }
    QmlObjectListModel* waypointModel() { return &_waypointModel; }
    QmlObjectListModel* flightPathModel() { return &_flightPathModel; }
    SurveyArea* currentArea();
    Waypoint* currentWp();
    LandNode* currentLand();
    QObject* currentNode() { return _currentNode; }
    PlanMode planMode() { return _planMode; }
    int currentIndex();
    bool valid();

    void setCurrentNode(QObject* node);
    void setPlanMode(PlanMode mode);
    void setSuffix(QString suffix);

    void generateItems(QList<MissionItem*>& items, QObject* parent);
    void saveAsJson(QJsonObject& object);
    void loadFromJson(const QJsonObject& mission, const QString& fileName);
    void loadFromVehicle(QList<MissionItem*>& items);
private:
    void insertTakeoff();
    void insertNode(MissionNode* node);
    void adjustFlightPath(NodeAction act, QObject* node);
    void updateSequence();
signals:
    void planListChanged();
    void currentNodeChanged();
    void planModeChanged();
    void currentIndexChanged();
    void takeoffChanged();
    void homeChanged();
    void validChanged();
    void waypointSeriesChanged();
    void checkSeriesChanged();
    void maxChanged();
    void initChartData();
private slots:
    void updateInformation();
    void onVehicleChanged();
    void onHomeChanged();
    void onLandModeChanged();
    void setHome(QGeoCoordinate home);
    void updateFlightPath();
    void onAreaValidChanged();
    void updateSeries();
    void updateRelative();
    void reqHomeTerrain();
    void onRecvHomeTerrain(bool success, QList<double> heights);
private:
    GisesManager* _gises = nullptr;
    //默认高度
    double _defaultAlt = 100;
    //载具对象
    Vehicle* _vehicle = nullptr;
    //当前计划概要
    PlanSummary* _summary = nullptr;
    //地形请求对象指针
    TerrainAtCoordinateQuery* _query = nullptr;
    //当前节点
    QObject* _currentNode = nullptr;
    //结束动作
    LandNode* _land = nullptr;
    //起飞点
    Waypoint* _takeOff = nullptr;
    //家坐标
    QGeoCoordinate _home;
    //已保存计划概要
    QmlObjectListModel _planModel;
    //混合序列
    QmlObjectListModel _nodeSequence;
    //测区模型
    QmlObjectListModel _surveyAreaModel;
    //航点模型
    QmlObjectListModel _waypointModel;
    //普通航线模型
    QmlObjectListModel _flightPathModel;
    //所有航点
    QList<GeoPoint*> _allPoints;
    //规划模式
    PlanMode _planMode = WAYPOINT;
    //任务信息
    QList<GeoPoint*> _geoPoints;
    //检查点高度
    QList<QGeoCoordinate> _checkPath;
    //图表数据
    QLineSeries* _waypointSeries = nullptr;
    QLineSeries* _checkSeries = nullptr;
    QList<QPointF> _waypointLine;
    QList<QPointF> _checkLine;
    double _maxAlt = 0;
    double _maxDist = 0;
    //减少更新图标次数
    QList<MissionNode*> _loadingList;
    // QStringList _planNames;
    // QStringList _planFirmwares;
    // QVariantList _planDistances;
    // QVariantList _planAreas;
    // QVariantList _planFlyTimes;
    // QVariantList _planPhotoShots;
    //需要处理哪些变化
    //当节点改变时",更新航线;当测区变化时
    QStringList _planModeName = {"Waypoint",
        "Plannar",
        "Road",
        "Wall",
        "Structure",
        "Mixed",};
};
