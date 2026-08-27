
#include "planSummary.h"

PlanSummary::PlanSummary(QObject* parent)
    :QObject(parent)
    ,_name("New Plan")
    ,_suffix("jplan")
{
}

void PlanSummary::setName(const QString& name){
    if(_name != name){
        _name = name;
        emit nameChanged();
    }
}

void PlanSummary::setSuffix(const QString& suffix){
    if(_suffix != suffix){
        _suffix = suffix;
        emit suffixChanged();
    }
}

void PlanSummary::setFirmware(const QString& firmware){
    if(_firmware != firmware){
        _firmware = firmware;
        emit firmwareChanged();
    }
}

void PlanSummary::setTotalDistance(double distance){
    if(_distance != distance){
        _distance = distance;
        emit totalDistanceChanged();
    }
}

void PlanSummary::setTotalArea(double area){
    if(_area != area){
        _area = area;
        emit totalAreaChanged();
    }
}

void PlanSummary::setFlyTime(int time){
    if(_flyTime != time){
        _flyTime = time;
        emit flyTimeChanged();
    }
}

void PlanSummary::setPhotoShot(int shot){
    if(_photoShot != shot){
        _photoShot = shot;
        emit photoShotChanged();
    }
}
