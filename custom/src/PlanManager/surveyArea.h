#pragma once

#include <QObject>
#include <QtQmlIntegration/QtQmlIntegration>
#include "QmlObjectListModel.h"
#include "geoPoint.h"
#include "surveySetup.h"
#include "missionNode.h"

class GeoShape;

class SurveyArea : public MissionNode{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SurveyArea(QObject *parent = nullptr);

    Q_PROPERTY(SurveySetup* setup READ setup CONSTANT)
    Q_PROPERTY(GeoShape* shape READ shape CONSTANT)
    Q_PROPERTY(QVariantList path READ path NOTIFY pathChanged FINAL)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged FINAL)
    Q_PROPERTY(bool showAllWaypoint READ showAllWaypoint WRITE setShowAllWaypoint NOTIFY showAllWaypointChanged FINAL)
    Q_PROPERTY(bool safety READ safety NOTIFY safetyChanged FINAL)
    Q_PROPERTY(QmlObjectListModel* showInfoModel READ showInfoModel CONSTANT)
    Q_PROPERTY(QmlObjectListModel* lines READ lines CONSTANT)

    virtual GeoShape* shape() = 0;
    virtual double shapeArea() = 0;

    GeoPoint* first() final;
    GeoPoint* last() final;
    void genMissionItem(QList<MissionItem*>& list, QObject* parent) final;
    QVariantList& path() { return _path; }
    SurveySetup *setup() { return &_setup; }
    const QList<GeoPoint*>& waypoints() { return _waypoints; }
    bool showAllWaypoint() { return _showAllWaypoint; }
    int safety() { return _safety; }
    QmlObjectListModel* showInfoModel() { return &_showInfoModel; }
    QmlObjectListModel* lines() { return &_lines; }
    const QList<QGeoCoordinate>& checkPath() { return _checkPath; }

    double pathDistance() { return _pathDistance; }
    void saveWaypoint(QJsonArray& node);

    void setPath(const QVariantList& path);
    void setShowAllWaypoint(bool show);
    void setSettup(SurveySetup *setup);

    void updateAmsls();
signals:
    void pathChanged();
    void validChanged();
    void showAllWaypointChanged();
    void safetyChanged();
    void simpleInfoChanged();
public slots:
    virtual void checkSafety() = 0;
protected:
    SurveySetup _setup;
    QVariantList _path;
    QList<GeoPoint*> _waypoints;
    //大量绘制航点导致拖动时频繁销毁创建对象
    QmlObjectListModel _showInfoModel;
    QmlObjectListModel _lines;
    QList<int> _srcIndex;
    QList<QGeoCoordinate> _checkPath;
    int _safety = -1;
    int _startVertex = 0;
    int _pathSize = 0;
    double _pathDistance = 0;
    double _checkMeter = 30.0;
    bool _valid = false;
    bool _recvVertex = false;
    bool _recvReal = false;
    bool _showAllWaypoint = false;
};
