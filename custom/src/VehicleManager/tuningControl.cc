
#include <QtQml/qqml.h>
#include <QPointF>
#include <QDateTime>

#include "Vehicle.h"
#include "VehicleSetpointFactGroup.h"
#include "VehicleLocalPositionFactGroup.h"
#include "VehicleLocalPositionSetpointFactGroup.h"
#include "tuningControl.h"

Q_LOGGING_CATEGORY(TunningControlLog, "TunningControlLog")

TunningControl::TunningControl(QObject* parent)
    :QObject(parent)
    ,_timer(this)
{
    _timer.setInterval(10);
    connect(&_timer, &QTimer::timeout, this, &TunningControl::updateSeries);
}

void TunningControl::init(){
    //固件类型
    VehicleSetpointFactGroup* setpoint = qobject_cast<VehicleSetpointFactGroup*>(_vehicle->setpointFactGroup());
    VehicleLocalPositionFactGroup* localPos = qobject_cast<VehicleLocalPositionFactGroup*>(_vehicle->localPositionFactGroup());
    VehicleLocalPositionSetpointFactGroup* localSet = qobject_cast<VehicleLocalPositionSetpointFactGroup*>(_vehicle->localPositionSetpointFactGroup());
    if(_vehicle->apmFirmware()){

    }else{
        if(_vehicle->fixedWing()){
            _groupName.resize(2);
            _resFact.resize(2);
            _setFact.resize(2);
            _groupName[Rate] = { tr("Roll"), tr("Pitch"), tr("Yaw") };
            _groupName[Altitude] = { tr("Roll"), tr("Pitch") };
            _resFact[Rate]= { _vehicle->rollRate(), _vehicle->pitchRate(), _vehicle->yawRate() };
            _resFact[Altitude] = { _vehicle->roll(), _vehicle->pitch() };

            _setFact[Rate] = { setpoint->rollRate(), setpoint->pitchRate(), setpoint->yawRate() };
            _setFact[Altitude] = { setpoint->roll(), setpoint->pitch() };
        }else{
            _groupName.resize(4);
            _resFact.resize(4);
            _setFact.resize(4);
            _groupName[Rate] = { tr("Roll"), tr("Pitch"), tr("Yaw") };
            _groupName[Altitude] = { tr("Roll"), tr("Pitch"), tr("Yaw") };
            _groupName[Velocity] = { tr("Horizontal"), tr("Vertical") };
            _groupName[Position] = { tr("Horizontal"), tr("Vertical") };
            _resFact[Rate]= { _vehicle->rollRate(), _vehicle->pitchRate(), _vehicle->yawRate() };
            _resFact[Altitude] = { _vehicle->roll(), _vehicle->pitch(), _vehicle->heading() };
            _resFact[Velocity] = { localPos->vy(), localPos->vz() };
            _resFact[Position] = { localPos->y(), localPos->z() };

            _setFact[Rate] = { setpoint->rollRate(), setpoint->pitchRate(), setpoint->yawRate() };
            _setFact[Altitude] = { setpoint->roll(), setpoint->pitch(), setpoint->yaw() };
            _setFact[Velocity] = { localSet->vy(), localSet->vz() };
            _setFact[Position] = { localSet->y(), localSet->z() };
        }
    }
}

void TunningControl::start(){
    _timer.start();
    if(0 == _startTime){
        _startTime = QDateTime::currentMSecsSinceEpoch();
    }
    emit activeChanged();
}

void TunningControl::stop(){
    _timer.stop();
    emit activeChanged();
}

void TunningControl::clear(){
    _timer.isActive() ? _startTime = QDateTime::currentMSecsSinceEpoch() : _startTime = 0;
    setXMin(0);
    setXMax(0.01);
    setYMin(-0.1);
    setYMax(0.1);
    _resSrc.clear();
    _setSrc.clear();
    _redLine->clear();
    _greenLine->clear();
    _blueLine->clear();
}

void TunningControl::setVehicle(Vehicle* vehicle){
    if(_vehicle != vehicle){
        _vehicle = vehicle;
        init();
    }
}

void TunningControl::setRedLine(QLineSeries* line){
    if(_redLine != line){
        _redLine = line;
        emit redLineChanged();
    }
}

void TunningControl::setGreenLine(QLineSeries* line){
    if(_greenLine != line){
        _greenLine = line;
        emit greenLineChanged();
    }
}

void TunningControl::setBlueLine(QLineSeries* line){
    if(_blueLine != line){
        _blueLine = line;
        emit blueLineChanged();
    }
}

void TunningControl::setGroup(uint8_t group){
    if(_group != group){
        _group = (DataGroup)group;
        onGroupChanged();
        emit groupChanged();
    }
}

void TunningControl::setIndex(uint8_t index){
    if(_index != index){
        _index = index;
        onIndexChanged();
        emit indexChanged();
    }
}

void TunningControl::setXMin(double min){
    if(_xMin != min){
        _xMin = min;
        emit xMinChanged();
    }
}

void TunningControl::setXMax(double max){
    if(_xMax != max){
        _xMax = max;
        emit xMaxChanged();
    }
}

void TunningControl::setYMin(double min){
    if(_yMin != min){
        _yMin = min;
        emit yMinChanged();
    }
}

void TunningControl::setYMax(double max){
    if(_yMax != max){
        _yMax = max;
        emit yMaxChanged();
    }
}
//SLOTS
void TunningControl::onGroupChanged(){
    if(_index){
        setIndex(0);
    }else{
        onIndexChanged();
    }
}
void TunningControl::onIndexChanged(){
    const int cac = 3 == _index ? 50 : 3;
    if(cac != _cacheSec) _cacheSec = cac;
    stop();
    clear();
    start();
}
void TunningControl::updateSeries(){
    qint64 currentMEpoch = QDateTime::currentMSecsSinceEpoch();
    double msec = currentMEpoch - _startTime;
    double sec = msec / 1000.0;
    double resValue = _resFact[_group][_index]->rawValue().toDouble();
    double setValue = _setFact[_group][_index]->rawValue().toDouble();
    if(_xMin < (sec - (3 == _index ? 50 : 3))) setXMin(sec - (3 == _index ? 50 : 3));
    setXMax(sec);
    if(!qIsNaN(resValue)){
        _resSrc.append({sec, resValue});
        _greenLine->append(QPointF(sec, resValue));
        if(resValue < _yMin) setYMin(resValue * 1.1);
        if(resValue > _yMax) setYMax(resValue * 1.1);
        if(_resSrc.first().x() < sec - 3 * 60) _resSrc.removeFirst();
        if(_greenLine->at(0).x() < sec - _cacheSec - 1) _greenLine->remove(0);
    }
    if(!qIsNaN(setValue)){
        _setSrc.append({sec, setValue});
        _blueLine->append(QPointF(sec, setValue));
        if(setValue < _yMin) setYMin(setValue * 1.1);
        if(setValue > _yMax) setYMax(setValue * 1.1);
        if(_setSrc.first().x() < sec - 3 * 60) _setSrc.removeFirst();
        if(_blueLine->at(0).x() < sec - _cacheSec - 1) _blueLine->remove(0);
    }
}