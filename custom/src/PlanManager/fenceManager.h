
#pragma once

#include <QObject>
#include <QtCore/QLoggingCategory>
#include <QtPositioning/QGeoCoordinate>
#include <QtQmlIntegration/QtQmlIntegration>
#include "QmlObjectListModel.h"

Q_DECLARE_LOGGING_CATEGORY(FenceManagerLog)

class GeoPoint;
class GisesManager;
class MissionItem;

class GeoFence: public QObject{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    GeoFence(QObject* parent);
    GeoFence(const QList<QGeoCoordinate>& coords, QObject* parent);
    GeoFence(QGeoCoordinate center, QGeoCoordinate radius, QObject* parent);

    Q_PROPERTY(bool inner MEMBER _inner NOTIFY innerChanged FINAL)
    Q_PROPERTY(GeoPoint* centerPoint MEMBER _centerPoint CONSTANT)
    Q_PROPERTY(GeoPoint* radiusPoint MEMBER _radiusPoint CONSTANT)
    Q_PROPERTY(double radius MEMBER _radius NOTIFY radiusChanged FINAL)
    Q_PROPERTY(GeoPoint* current MEMBER _current NOTIFY currentChanged FINAL)
    Q_PROPERTY(QList<GeoPoint*> points MEMBER _points NOTIFY pointsChanged FINAL)
    Q_PROPERTY(QList<QGeoCoordinate> polygon MEMBER _polygon NOTIFY polygonChanged FINAL)

    Q_INVOKABLE void addPoint(QGeoCoordinate coord);
    Q_INVOKABLE void setCircleCenter(QGeoCoordinate coord);
    Q_INVOKABLE void setCircleRadius(QGeoCoordinate coord);
    Q_INVOKABLE bool removeOne();
    Q_INVOKABLE bool clearAll();

    bool isCircle() { return _radius > 0.01; }
    void refreshPoint();

    bool _inner = true;
    bool _deloop = false;
    double _radius = 0.0;
    GeoPoint* _current = nullptr;
    GeoPoint* _centerPoint = nullptr;
    GeoPoint* _radiusPoint = nullptr;
    QList<GeoPoint*> _points;
    QList<QGeoCoordinate> _polygon;
signals:
    void innerChanged();
    void radiusChanged();
    void centerChanged();
    void pointsChanged();
    void polygonChanged();
    void currentChanged();
public slots:
    void updateVertex();
    void updateRadius();
    void updateRadiusPoint();
};

class FenceManager: public QObject{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    FenceManager(QObject* parent);
    ~FenceManager();

    Q_PROPERTY(QmlObjectListModel* polygonFenceModel READ polygonFenceModel CONSTANT)
    Q_PROPERTY(QmlObjectListModel* circleFenceModel READ circleFenceModel CONSTANT)
    Q_PROPERTY(GeoFence* currentFence MEMBER _currentFence NOTIFY currentFenceChanged FINAL)

    Q_INVOKABLE void addCustom();
    Q_INVOKABLE void addSimpleRect(QGeoCoordinate center, QGeoCoordinate lt, QGeoCoordinate lb, QGeoCoordinate rb, QGeoCoordinate rt);
    Q_INVOKABLE void addCircle(QGeoCoordinate center, QGeoCoordinate radius);
    Q_INVOKABLE void removeFence(GeoFence* remove);
    Q_INVOKABLE bool sendToVehicle();

    QmlObjectListModel* polygonFenceModel() { return &_polygonFenceModel; }
    QmlObjectListModel* circleFenceModel() { return &_circleFenceModel; }
    void refreshPoint();

    void saveAsJson(QJsonObject& json);
    void loadFromJson(const QJsonObject& json);
    void generateItems(QList<MissionItem*>& items, QObject* parent);
    void loadFromVehicle(const QList<MissionItem*>& items);
signals:
    void currentFenceChanged();
private:
    GisesManager* _gises = nullptr;
    GeoFence* _currentFence = nullptr;
    QmlObjectListModel _polygonFenceModel;
    QmlObjectListModel _circleFenceModel;
};
