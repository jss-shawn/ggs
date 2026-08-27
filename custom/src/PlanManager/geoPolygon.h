#pragma once

#include <QObject>
#include <QtCore/QLoggingCategory>
#include "geoShape.h"

Q_DECLARE_LOGGING_CATEGORY(GeoPolygonLog)

class GeoPolygon : public GeoShape{
    Q_OBJECT
public:
    GeoPolygon(QString name, QObject* parent = nullptr);

    void init();

    void insert(QGeoCoordinate coord) final;
    void remove(GeoPoint* point) final;

    Q_PROPERTY(double expand READ expand WRITE setExpand NOTIFY expandChanged FINAL)
    //Q_PROPERTY(QList<QGeoCoordinate> frame READ frame NOTIFY frameChanged FINAL)

    double expand() const { return _expand; }
    const QList<QGeoCoordinate>& frame() { return _frame; }

    void setExpand(double expand);

    void set(const QList<QGeoCoordinate>& vertexs);
    void set(GeoPolygon* polygon);
private:
    void genFramePolygon();
    void updatePointNed(GeoPoint *point);
    void calcCenter();
    void checkValid();
signals:
    void expandChanged();
    //void frameChanged();
public slots:
    void onKeyCoordChanged();
    void onCenterOffset(double dist, double azim);
    void onDragingChanged();
private:
    double _expand = 0;
    QList<QGeoCoordinate> _frame;
};
