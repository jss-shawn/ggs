#pragma once

#include <QObject>
#include <QElapsedTimer>
#include "geoTool.h"
#include "geoPolygon.h"
#include "surveyArea.h"

class PolygonArea : public SurveyArea{
    Q_OBJECT
public:
    PolygonArea(QObject *parent = nullptr);
    PolygonArea(QString name, QObject *parent = nullptr);
    ~PolygonArea();

    void init();

    void save(QJsonArray& array, const QString& suffix) final;
    void load(const QJsonObject& node) final;
    GeoShape* shape() final { return &_polygon; }
    void checkSafety() final;
    bool valid() final { return _path.size(); }//_polygon.valid(); }
    double shapeArea() final { return _polygon.area(); }
private:
    void clear();
    QPolygonF boundRect(const QPolygonF &polygon, double expand);
    void genRealPath();
    void genFlightPath();
    void appendPoint(GeoPoint& pt, GeoPoint::CamAct act);
    void findWay(int from, int to, QList<GeoPoint> &path);
    void updateLines();
private slots:
    void genVirtualPath();
    void dragPath(double dist, double azim);
    void updateWaypoint();
    void onRecvCheck(bool success, QList<double> altList);
private:
    GeoTool _tool;
    GeoPolygon _polygon;
    //support
    bool _notEmpty = false;
    QList<GeoPoint> _frameVertexs;
    QList<QGeoCoordinate> _framePolygon;
    QList<QList<QGeoCoordinate>> _virtualPath;
    QList<QList<GeoPoint>> _realPath;
    QList<GeoPoint> _keyPoints;
    //QElapsedTimer _elapsed;
    //QElapsedTimer _allElapsed;
};
