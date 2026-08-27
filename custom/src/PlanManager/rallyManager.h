
#pragma once

#include <QObject>
#include <QtCore/QLoggingCategory>
#include <QtPositioning/QGeoCoordinate>
#include <QtQmlIntegration/QtQmlIntegration>

class GeoPoint;
class GisesManager;
class MissionItem;

Q_DECLARE_LOGGING_CATEGORY(RallyManagerLog)

class RallyManager: public QObject{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    RallyManager(QObject* parent);

    Q_PROPERTY(GeoPoint* current MEMBER _current NOTIFY currentChanged FINAL)
    Q_PROPERTY(QList<GeoPoint*> points READ points NOTIFY pointsChanged FINAL)

    Q_INVOKABLE void addPoint(QGeoCoordinate coord);
    Q_INVOKABLE bool saveToFile();
    Q_INVOKABLE bool sendToVehicle();
    Q_INVOKABLE bool switchEditable();
    Q_INVOKABLE bool removePoint(GeoPoint* point);
    Q_INVOKABLE bool clear();

    const QList<GeoPoint*>& points() { return _points; }

    void refreshPoint();

    void saveAsJson(QJsonObject& json);
    void loadFromJson(const QJsonObject& json);
    void loadFromVehicle(const QList<QGeoCoordinate>& points);
    void generateItems(QList<MissionItem*>& items, QObject* parent);

    void onPointClicked(GeoPoint* point);
signals:
    void currentChanged();
    void pointsChanged();
private:
    GisesManager* _gises = nullptr;
    GeoPoint* _current = nullptr;
    QList<GeoPoint*> _points;
};
