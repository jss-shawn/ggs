
#pragma once

#include <QObject>
#include <QPointF>
#include <QtPositioning/QGeoCoordinate>
#include "cameraInfo.h"

class SurveySetup : public QObject{
    Q_OBJECT
public:
    SurveySetup(QString setupName, QObject* parent = nullptr);
    ~SurveySetup();

    void init();

    Q_PROPERTY(CameraInfo* camera READ camera CONSTANT)
    Q_PROPERTY(double expandDistance READ expandDistance WRITE setExpandDistance NOTIFY expandDistanceChanged FINAL)
    Q_PROPERTY(double routeAzimuth READ routeAzimuth WRITE setRouteAzimuth NOTIFY routeAzimuthChanged FINAL)
    Q_PROPERTY(double structHeight READ structHeight WRITE setStructHeight NOTIFY structHeightChanged FINAL)
    Q_PROPERTY(bool scanTop READ scanTop WRITE setScanTop NOTIFY scanTopChanged FINAL)

    Q_INVOKABLE void clear();

    CameraInfo* camera() { return &_camera; }
    double expandDistance() { return _expandDistance; }
    double routeAzimuth() { return _routeAzimuth; }
    double structHeight() { return _structHeight; }
    bool scanTop() { return _scanTop; }

    void setExpandDistance(double dist);
    void setRouteAzimuth(double azi);
    void setStructHeight(double height);
    void setScanTop(bool scan);

    void set(SurveySetup* setup);
signals:
    void expandDistanceChanged();
    void routeAzimuthChanged();
    void structHeightChanged();
    void scanTopChanged();
    void setupChanged();
private:
    CameraInfo _camera;
    double _expandDistance = 0.0;
    double _routeAzimuth = 0.0;
    double _structHeight = 10.0;
    bool _scanTop = true;
};
