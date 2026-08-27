#pragma once

#include <QObject>
#include <QtQmlIntegration/QtQmlIntegration>

class PlanSummary : public QObject{

    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")

public:
    PlanSummary(QObject* parent);

    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged FINAL)
    Q_PROPERTY(QString suffix READ suffix NOTIFY suffixChanged FINAL)
    Q_PROPERTY(QString firmware READ firmware NOTIFY firmwareChanged FINAL)
    Q_PROPERTY(double totalDistance READ totalDistance NOTIFY totalDistanceChanged FINAL)
    Q_PROPERTY(double totalArea READ totalArea NOTIFY totalAreaChanged FINAL)
    Q_PROPERTY(int flyTime READ flyTime NOTIFY flyTimeChanged FINAL)
    Q_PROPERTY(int photoShot READ photoShot NOTIFY photoShotChanged FINAL)

    QString name() { return _name; }
    QString suffix() { return _suffix; }
    QString firmware() { return _firmware; }
    double totalDistance() { return _distance; }
    double totalArea() { return _area; }
    int flyTime() { return _flyTime; }
    int photoShot() { return _photoShot; }

    void setName(const QString& name);
    void setSuffix(const QString& suffix);
    void setFirmware(const QString& firmware);
    void setTotalDistance(double distance);
    void setTotalArea(double area);
    void setFlyTime(int time);
    void setPhotoShot(int shot);

signals:
    void nameChanged();
    void suffixChanged();
    void firmwareChanged();
    void totalDistanceChanged();
    void totalAreaChanged();
    void flyTimeChanged();
    void photoShotChanged();
private:
    QString _name;
    QString _suffix;
    QString _firmware;
    double _distance = 0;
    double _area = 0;
    int _flyTime = 0;
    int _photoShot = 0;
};
