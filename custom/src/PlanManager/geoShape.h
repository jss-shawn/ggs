#pragma once

#include <QObject>
#include <QtQmlIntegration/QtQmlIntegration>
#include "geoTool.h"
#include "QmlObjectListModel.h"

class GeoPoint;

class GeoShape: public QObject{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:

    enum ShapeType {
        POLYGON = 0,
        CIRCLE,
        CORRIDOR,
    };
    Q_ENUM(ShapeType)

    GeoShape(QString name, ShapeType type, QObject *parent = nullptr);

    Q_PROPERTY(QmlObjectListModel* keypointModel READ keypointModel CONSTANT)
    Q_PROPERTY(QVariantList path READ path NOTIFY pathChanged FINAL)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged FINAL)
    Q_PROPERTY(GeoPoint *current READ current WRITE setCurrent NOTIFY currentChanged FINAL)
    Q_PROPERTY(QGeoCoordinate center READ center WRITE setCenter NOTIFY centerChanged FINAL)
    Q_PROPERTY(ShapeType type MEMBER _type CONSTANT)
    Q_PROPERTY(bool draging READ draging WRITE setDraging NOTIFY dragingChanged FINAL)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged FINAL)

    Q_INVOKABLE virtual void insert(QGeoCoordinate coord) = 0;
    Q_INVOKABLE virtual void remove(GeoPoint *point) = 0;

    bool valid() const { return _valid; }

    QmlObjectListModel* keypointModel() { return &_keypointModel; }
    QVariantList& path()  { return _path; }
    QString name() { return _name; }
    GeoPoint *current() { return _current; }
    QGeoCoordinate center() { return _center; }
    bool draging() const { return _draging; }

    void setName(QString name);
    void setCurrent(GeoPoint* point);
    void setCenter(QGeoCoordinate center);
    void setDraging(bool drag);
    void setValid(bool valid);
    void setCanUpdate(bool can);

    double area() const { return _area; }

    virtual void updateArea();
signals:
    void nameChanged();
    void pathChanged();
    void currentChanged();
    void centerChanged();
    void centerOffset(double dist, double azim);
    void dragingChanged();
    void validChanged();
protected:
    GeoTool _tool;
    QmlObjectListModel _keypointModel;
    QVariantList _path;
    QString _name;
    GeoPoint *_current = nullptr;
    QGeoCoordinate _center;
    QList<QList<double>> _pathRalatives;
    QList<QList<double>> _frameRalatives;
    ShapeType _type = POLYGON;
    double _area = 0;
    bool _valid = false;
    bool _validChanged = false;
    bool _draging = false;
    bool _canUpdate = true;
    bool _needUpdate = false;
};
