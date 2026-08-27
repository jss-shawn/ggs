
#pragma once

#include <QObject>
#include <QtCore/QLoggingCategory>
#include <QtPositioning/QGeoCoordinate>

class GisesManager;
class Vehicle;

class GuideAction:public QObject{
    Q_OBJECT
public:
    enum Act{
        Rtl,
        Land,
        Takeoff,
        Arm,
        Disarm,
        EmergencyStop,
        ChangeAlt,
        Goto,
        SetWaypoint,
        Orbit,
        LandAbort,
        StartMission,
        ContinueMission,
        ResumeMission,
        nUnused,
        ResumeMissionUploadFail,
        Pause,
        MVPause,
        MVStartMission,
        VtolTransitionToFwdFlight,
        VtolTransitionToMRFlight,
        ROI,
        ActionList,
        ForceArm,
        ChangeSpeed,
        Gripper,
        SetHome,
        SetEstimatorOrigin,
        SetFlightMode,
        ChangeHeading,
    };
    GuideAction(const int act, QString name, QString detail, QObject* parent = nullptr);

    Q_PROPERTY(int action READ action CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString detail READ detail CONSTANT)
    Q_PROPERTY(double value READ value WRITE setValue NOTIFY valueChanged FINAL)
    Q_PROPERTY(QString param READ param WRITE setParam NOTIFY paramChanged FINAL)
    Q_PROPERTY(QGeoCoordinate coor READ coor WRITE setCoor NOTIFY coorChanged FINAL)
    Q_PROPERTY(bool visible READ visible NOTIFY visibleChanged FINAL)

    const int& action() { return _action; }
    const QString& name() { return _name; }
    const QString& detail() { return _detail; }
    const double& value() { return _value; }
    const QString& param() { return _param; }
    const bool& visible() { return _visible; }
    const QGeoCoordinate& coor() { return _coor; }

    void setValue(double value);
    void setParam(QString param);
    void setCoor(QGeoCoordinate coor);
signals:
    void visibleChanged();
    void valueChanged();
    void paramChanged();
    void coorChanged();
public slots:
    void updateVisible();
private:
    GisesManager* _gises = nullptr;
    int _action = 1;
    QString _name;
    QString _detail;
    double _value = 1.0;
    QString _param;
    QGeoCoordinate _coor;
    bool _visible;
};
