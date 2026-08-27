#pragma once

#include <QObject>
#include <QtCore/QLoggingCategory>
//#include <QGeoPolygon>
#include "geoShape.h"

Q_DECLARE_LOGGING_CATEGORY(GeoCorridorLog)

class GeoCorridor : public GeoShape{
    Q_OBJECT
public:
    GeoCorridor(QString name, QObject* parent = nullptr);

    Q_PROPERTY(QList<QGeoCoordinate> mids READ mids NOTIFY pathChanged FINAL)
    Q_PROPERTY(double leftWidth READ leftWidth WRITE setLeftWidth NOTIFY leftWidthChanged FINAL)
    Q_PROPERTY(double rightWidth READ rightWidth WRITE setRightWidth NOTIFY rightWidthChanged FINAL)

    void init();

    void insert(QGeoCoordinate coord) final;
    void remove(GeoPoint* point) final;
    void updateArea() final;

    QList<QGeoCoordinate> mids() { return _mids; }
    double leftWidth() { return _leftWidth; }
    double rightWidth() { return _rightWidth; }

    void setLeftWidth(double width);
    void setRightWidth(double width);

    bool offsetLine(bool toLeft, double width, QList<QGeoCoordinate>& list);

    void set(const QList<QGeoCoordinate>& list);
signals:
    void leftWidthChanged();
    void rightWidthChanged();
private:
    void updateCenter();
    void updateRalatives();
    void setPointNed(GeoPoint *pt = nullptr);
public slots:
    void genPath();
    void onCoordChanged();
    void onCenterOffset(double dist, double azim);
    void onDragingChanged();
private:
    //QGeoPolygon _plg;
    QList<QGeoCoordinate> _mids;
    QList<QGeoCoordinate> _leftLines;
    QList<QGeoCoordinate> _rightLines;
    double _leftWidth = 0.0;
    double _rightWidth = 0.0;
};
