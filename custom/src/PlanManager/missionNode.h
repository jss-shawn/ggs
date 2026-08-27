#pragma once

#include <QObject>
#include <QtPositioning/QGeoCoordinate>
#include <QtQmlIntegration/QtQmlIntegration>

class GeoPoint;
class GisesPlan;
class MissionItem;

class MissionNode: public QObject{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    enum NodeType{
        none = 0,
        land,
        waypoint,
        surveyArea,
    };

    MissionNode(NodeType type, QObject* parent = nullptr);

    Q_PROPERTY(bool isHome READ isHome NOTIFY isHomeChanged FINAL)
    Q_PROPERTY(bool isTakeoff READ isTakeoff NOTIFY isTakeoffChanged FINAL)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged FINAL)
    Q_PROPERTY(int sequence READ sequence NOTIFY sequenceChanged FINAL)

    virtual bool valid() = 0;
    virtual GeoPoint* first() = 0;
    virtual GeoPoint* last() = 0;
    virtual void save(QJsonArray& array, const QString& suffix) = 0;
    virtual void load(const QJsonObject& node) = 0;
    virtual void genMissionItem(QList<MissionItem*>& list, QObject* parent) = 0;

    virtual bool isTakeoff() { return false; }
    virtual bool isHome() { return false; }
    int nodeType() const { return _nodeType; }
    int sequence() const { return _sequence; }
    bool active() const { return _active; }

    void setActive(bool active);
    void setSequence(int seq);

signals:
    void nodeChanged();
    void amslChanged();
    void isHomeChanged();
    void isTakeoffChanged();
    void activeChanged();
    void sequenceChanged();
protected:
    GisesPlan* _plan = nullptr;
    int _nodeType = NodeType::none;
    int _sequence = 0;
    bool _isTakeoff = false;
    bool _active = true;
};
