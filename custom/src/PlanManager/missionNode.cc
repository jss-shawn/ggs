
#include "missionNode.h"
#include "gisesPlan.h"

MissionNode::MissionNode(NodeType type, QObject *parent)
    :QObject(parent)
    ,_nodeType(type)
{
    _plan = qobject_cast<GisesPlan*>(parent);
    if (nullptr == _plan) {
        qCritical() << "critical Node error";
    }
}
void MissionNode::setSequence(int seq){
    if(_sequence != seq){
        _sequence = seq;
        emit sequenceChanged();
    }
}
void MissionNode::setActive(bool active){
    if(_active != active){
        _active = active;
        emit activeChanged();
    }
}
