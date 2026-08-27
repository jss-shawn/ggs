
#include "surveySetup.h"

SurveySetup::SurveySetup(QString setupName, QObject* parent)
    :QObject(parent)
    ,_camera(setupName, this)
{
    init();
}

SurveySetup::~SurveySetup(){
}

void SurveySetup::init(){
    connect(_camera.adjustedFootprintFrontal(), &Fact::rawValueChanged, this, &SurveySetup::setupChanged);
    connect(_camera.adjustedFootprintSide(), &Fact::rawValueChanged, this, &SurveySetup::setupChanged);
    connect(_camera.distanceToSurface(), &Fact::rawValueChanged, this, &SurveySetup::setupChanged);
}

void SurveySetup::clear(){

}

void SurveySetup::setExpandDistance(double dist){
    if(dist > 0 && qAbs(_expandDistance - dist) > 0.1){
        _expandDistance = dist;
    }
    emit expandDistanceChanged();
    emit setupChanged();
}

void SurveySetup::setRouteAzimuth(double azi){
    if(azi > 0 && qAbs(_routeAzimuth - azi) > 0.1){
        _routeAzimuth = azi;
    }
    emit routeAzimuthChanged();
    emit setupChanged();
}

void SurveySetup::setStructHeight(double height){
    if(height > 1.0 && qAbs(_structHeight - height) > 0.1){
        _structHeight = height;
    }
    emit structHeightChanged();
    emit setupChanged();
}

void SurveySetup::setScanTop(bool scan){
    if(_scanTop != scan){
        _scanTop = scan;
    }
    emit scanTopChanged();
    emit setupChanged();
}

void SurveySetup::set(SurveySetup* setup){
    setExpandDistance(setup->_expandDistance);
    setRouteAzimuth(setup->_routeAzimuth);
    setStructHeight(setup->_structHeight);
    setScanTop(setup->_scanTop);
    _camera.set(setup->camera());
}
