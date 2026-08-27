
#pragma once

#include <QObject>
#include <QPointF>
#include <QtPositioning/QGeoCoordinate>
#include "MissionItem.h"

class VehicleMissionItem: public QObject{
    Q_OBJECT
public:
    VehicleMissionItem(MissionItem* item, QObject* parent = nullptr);

    Q_PROPERTY(QGeoCoordinate coord READ coord NOTIFY coordChanged FINAL)
    Q_PROPERTY(int sequence READ sequence NOTIFY sequenceChanged FINAL)
    Q_PROPERTY(bool visible READ visible NOTIFY visibleChanged FINAL)
    Q_PROPERTY(bool isCurrent READ isCurrent NOTIFY isCurrentChanged FINAL)
    Q_PROPERTY(bool isTakeoff READ isTakeoff NOTIFY isTakeoffChanged FINAL)
    Q_PROPERTY(bool isLand READ isLand NOTIFY isLandChanged FINAL)

    Q_INVOKABLE void clicked(){}

    QGeoCoordinate coord() { return _item->coordinate(); }
    int sequence() { return _item->sequenceNumber(); }

    bool visible() { return _visible; }
    bool isCurrent() { return _isCurrent; }
    bool isTakeoff();
    bool isLand();

    void setCoord(QGeoCoordinate coord);
    void setVisible(bool visible) { _visible = visible; emit visibleChanged(); }
    void setIsCurrent(bool current) { _isCurrent = current; emit isCurrentChanged(); }
signals:
    void coordChanged();
    void sequenceChanged();
    void visibleChanged();
    void isCurrentChanged();
    void isTakeoffChanged();
    void isLandChanged();
private:
    MissionItem* _item = nullptr;
    bool _visible = false;
    bool _isCurrent = false;
};
