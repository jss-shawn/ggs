
#pragma once

#include <QObject>
#include <QtCore/QLoggingCategory>
#include <QLineSeries>
#include <QTimer>
#include <QtQmlIntegration/QtQmlIntegration>

Q_DECLARE_LOGGING_CATEGORY(TunningControlLog)

class Vehicle;
class Fact;

class TunningControl: public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
    Q_MOC_INCLUDE("Vehicle.h")
public:
    enum DataGroup{
        Rate = 0,
        Altitude,
        Velocity,
        Position
    };
    TunningControl(QObject* parent = nullptr);

    void init();

    Q_PROPERTY(Vehicle* vehicle READ vehicle CONSTANT)
    Q_PROPERTY(QLineSeries* redLine READ redLine WRITE setRedLine NOTIFY redLineChanged FINAL)
    Q_PROPERTY(QLineSeries* greenLine READ greenLine WRITE setGreenLine NOTIFY greenLineChanged FINAL)
    Q_PROPERTY(QLineSeries* blueLine READ blueLine WRITE setBlueLine NOTIFY blueLineChanged FINAL)
    Q_PROPERTY(uint8_t group READ group WRITE setGroup NOTIFY groupChanged FINAL)
    Q_PROPERTY(uint8_t index READ index WRITE setIndex NOTIFY indexChanged FINAL)
    Q_PROPERTY(double xMin READ xMin NOTIFY xMinChanged FINAL)
    Q_PROPERTY(double xMax READ xMax NOTIFY xMaxChanged FINAL)
    Q_PROPERTY(double yMin READ yMin NOTIFY yMinChanged FINAL)
    Q_PROPERTY(double yMax READ yMax NOTIFY yMaxChanged FINAL)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged FINAL)

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void clear();

    Vehicle* vehicle() { return _vehicle; }
    QLineSeries* redLine() { return _redLine; }
    QLineSeries* greenLine() { return _greenLine; }
    QLineSeries* blueLine() { return _blueLine; }
    uint8_t group() { return _group; }
    uint8_t index() { return _index; }
    double xMin() { return _xMin; }
    double xMax() { return _xMax; }
    double yMin() { return _yMin; }
    double yMax() { return _yMax; }
    bool active() { return _timer.isActive(); }

    void setVehicle(Vehicle* vehicle);
    void setRedLine(QLineSeries* line);
    void setGreenLine(QLineSeries* line);
    void setBlueLine(QLineSeries* line);
    void setGroup(uint8_t group);
    void setIndex(uint8_t index);
    void setXMin(double min);
    void setXMax(double max);
    void setYMin(double min);
    void setYMax(double max);

signals:
    void vehicleChanged();
    void redLineChanged();
    void greenLineChanged();
    void blueLineChanged();
    void groupChanged();
    void indexChanged();
    void xMinChanged();
    void xMaxChanged();
    void yMinChanged();
    void yMaxChanged();
    void activeChanged();
private slots:
    void onGroupChanged();
    void onIndexChanged();
    void updateSeries();
private:
    Vehicle* _vehicle = nullptr;
    DataGroup _group = Rate;
    uint8_t _index = 0;

    QList<QStringList> _groupName;
    QList<QList<Fact*>> _resFact;
    QList<QList<Fact*>> _setFact;

    double _xMin = 0;
    double _xMax = 0.01;
    double _yMin = -1;
    double _yMax = 1;
    double _cacheSec = 3;
    qint64 _startTime = 0;
    QTimer _timer;
    QLineSeries* _redLine = nullptr;
    QLineSeries* _greenLine = nullptr;
    QLineSeries* _blueLine = nullptr;
    QList<QPointF> _resSrc;
    QList<QPointF> _setSrc;
};
