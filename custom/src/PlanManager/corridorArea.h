#pragma once

#include <QObject>
#include "geoTool.h"
#include "geoCorridor.h"
#include "surveyArea.h"

class CorridorArea : public SurveyArea{
    Q_OBJECT
public:
    CorridorArea(QObject *parent = nullptr);
    CorridorArea(QString name, QObject *parent = nullptr);

    void init();

    void save(QJsonArray& array, const QString& suffix) final;
    void load(const QJsonObject& node) final;
    GeoShape* shape() final { return &_corridor; }
    double shapeArea() final { return _corridor.area(); }
    bool valid() final { return _valid; }
    void checkSafety() final;

private:
    void clear();
    void genFlightPath();
    void cutPath();
    void reqCheckAlts();
    void updateLines();
private slots:
    void updateWaypoint();
    void genRealPath();
    void dragPath(double dist, double azim);
    void onRecvCheck(bool success, QList<double> heights);
private:
    GeoTool _tool;
    GeoCorridor _corridor;
    //surpport
    bool _notEmpty = false;
    QList<QList<QGeoCoordinate>> _realPath;
};
