
/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "JsonParsing.h"
#include "Vehicle.h"
#include "VehicleSupports.h"
#include "CameraMetaData.h"

#include <QtQml/QQmlEngine>
#include "MultiVehicleManager.h"
#include "gisesPlugin.h"
#include "gisesManager.h"
#include "cameraInfo.h"

CameraInfo::CameraInfo(const QString& settingsGroup, QObject* parent)
    : CameraSpec(settingsGroup, parent)
    //, _distanceMode(masterController->missionController()->globalAltitudeModeDefault())
    ,_cameraBrandList({"Manual (no camera specs)","Custom Camera"})
    , _metaDataMap(FactMetaData::createMapFromJsonFile(QStringLiteral(":/json/CameraCalc.FactMetaData.json"), this))
    , _valueSetIsDistanceFact (settingsGroup, _metaDataMap[valueSetIsDistanceName])
    , _distanceToSurfaceFact  (settingsGroup, _metaDataMap[distanceToSurfaceName])
    , _imageDensityFact       (settingsGroup, _metaDataMap[imageDensityName])
    , _frontalOverlapFact     (settingsGroup, _metaDataMap[frontalOverlapName])
    , _sideOverlapFact        (settingsGroup, _metaDataMap[sideOverlapName])
    , _footprintSideFact      (settingsGroup, _metaDataMap[adjustedFootprintSideName])
    , _footprintFrontalFact   (settingsGroup, _metaDataMap[adjustedFootprintFrontalName])
    ,_altModeFact		(0, "Altitude Mode",FactMetaData::valueTypeInt32)
{
    _gises = qobject_cast<GisesPlugin*>(GisesPlugin::instance())->gises();
    _knownCameraList = _gises->vehicle()->staticCameraList();
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);
    _altModeFact.setMetaData(new FactMetaData(FactMetaData::valueTypeInt32, &_altModeFact));
    _altModeFact.setRawValue(MAV_FRAME_GLOBAL_RELATIVE_ALT);
    QStringList frameStrings;
    QVariantList frameValues;
    frameStrings << "Relative To Launch" << "AMSL" << "Terrain Frame";
    frameValues << MAV_FRAME_GLOBAL_RELATIVE_ALT << MAV_FRAME_GLOBAL << MAV_FRAME_GLOBAL_TERRAIN_ALT;
    if(_gises->vehicle()->supports()->terrainFrame()){
        frameStrings << "Calculated Above Terrain";
        frameValues << -1;
    }
    _altModeFact.setEnumInfo(frameStrings, frameValues);

    connect(_gises, &GisesManager::vehicleChanged, this, &CameraInfo::updateBrandList);
    connect(this, &CameraInfo::brandIndexChanged, this, &CameraInfo::updateModelList);
    connect(this, &CameraInfo::brandIndexChanged, this, &CameraInfo::updateCameraParam);
    connect(this, &CameraInfo::modelIndexChanged, this, &CameraInfo::updateCameraParam);

    connect(&_distanceToSurfaceFact,    &Fact::rawValueChanged, this, &CameraInfo::_recalcTriggerDistance);
    connect(&_imageDensityFact,         &Fact::rawValueChanged, this, &CameraInfo::_recalcTriggerDistance);
    connect(&_frontalOverlapFact,       &Fact::rawValueChanged, this, &CameraInfo::_recalcTriggerDistance);
    connect(&_sideOverlapFact,          &Fact::rawValueChanged, this, &CameraInfo::_recalcTriggerDistance);
    connect(sensorWidth(),              &Fact::rawValueChanged, this, &CameraInfo::_recalcTriggerDistance);
    connect(sensorHeight(),             &Fact::rawValueChanged, this, &CameraInfo::_recalcTriggerDistance);
    connect(imageWidth(),               &Fact::rawValueChanged, this, &CameraInfo::_recalcTriggerDistance);
    connect(imageHeight(),              &Fact::rawValueChanged, this, &CameraInfo::_recalcTriggerDistance);
    connect(focalLength(),              &Fact::rawValueChanged, this, &CameraInfo::_recalcTriggerDistance);
    connect(landscape(),                &Fact::rawValueChanged, this, &CameraInfo::_recalcTriggerDistance);

    // Build the brand list from known cameras
    for (int i=0; i<_knownCameraList.size(); ++i) {
        CameraMetaData* cameraMetaData = _knownCameraList[i].value<CameraMetaData*>();
        if (!_cameraBrandList.contains(cameraMetaData->brand)) {
            _cameraBrandList.append(cameraMetaData->brand);
        }
        if(!_cameraModelList.contains(cameraMetaData->model)){
            _cameraModelList.append(cameraMetaData->model);
        }
    }

    setDirty(false);
}
void CameraInfo::setBrandIndex(int index){
    if(_cameraBrandIndex != index){
        _cameraBrandIndex = index;
        emit brandIndexChanged();
    }
}
void CameraInfo::setModelIndex(int index){
    if(_cameraModelIndex != index){
        _cameraModelIndex = index;
        emit modelIndexChanged();
    }
}

void CameraInfo::save(QJsonObject& json) const
{
    json[brandName] = _cameraBrandList[_cameraBrandIndex];
    if(_cameraModelList.size()){
        json[modelName] = _cameraModelList[_cameraModelIndex];
    }
    json[distanceToSurfaceName] = _distanceToSurfaceFact.rawValue().toDouble();
    json[distanceModeName] = _distanceMode;
    json[adjustedFootprintFrontalName] = _footprintFrontalFact.rawValue().toDouble();
    json[adjustedFootprintSideName] = _footprintSideFact.rawValue().toDouble();
    if (_cameraBrandList[_cameraBrandIndex] == "Custom Camera" || _cameraModelList.size()) {
        CameraSpec::save(json);
        json[valueSetIsDistanceName] = _valueSetIsDistanceFact.rawValue().toBool();
        json[imageDensityName] =       _imageDensityFact.rawValue().toDouble();
        json[frontalOverlapName] =     _frontalOverlapFact.rawValue().toDouble();
        json[sideOverlapName] =        _sideOverlapFact.rawValue().toDouble();
    }
}

bool CameraInfo::load(const QJsonObject& originalJson){
    QJsonObject json = originalJson;
    QString errorString;
    QList<JsonParsing::KeyValidateInfo> check = {
                                                { brandName,                        QJsonValue::String, true },
                                                { adjustedFootprintSideName,        QJsonValue::Double, true },
                                                { adjustedFootprintFrontalName,     QJsonValue::Double, true },
                                                { distanceToSurfaceName,            QJsonValue::Double, true },
                                                { distanceModeName,                 QJsonValue::Double, true },
                                                };
    if (!JsonParsing::validateKeys(json, check, errorString)) {
        return false;
    }

    _disableRecalc = true;

    QString string = json[brandName].toString();
    for(int i=0; i<_cameraBrandList.size(); ++i){
        if(_cameraBrandList[i] == string){
            _cameraBrandIndex = i;
            emit brandIndexChanged();
            break;
        }
    }
    _distanceToSurfaceFact.setRawValue(json[distanceToSurfaceName].toDouble());
    _distanceMode = (QGroundControlQmlGlobal::AltitudeFrame)json[distanceModeName].toInt();
    _footprintFrontalFact.setRawValue(json[adjustedFootprintFrontalName].toDouble());
    _footprintSideFact.setRawValue(json[adjustedFootprintSideName].toDouble());
    if(json.contains(modelName)){
        string = json[modelName].toString();
        for(int i=0; i<_cameraModelList.size(); ++i){
            if(string == _cameraModelList[i]){
                _cameraModelIndex = i;
                emit modelIndexChanged();
                break;
            }
        }
        QList<JsonParsing::KeyValidateInfo> check2 = {
                                                           { valueSetIsDistanceName,   QJsonValue::Bool,   true },
                                                           { imageDensityName,         QJsonValue::Double, true },
                                                           { frontalOverlapName,       QJsonValue::Double, true },
                                                           { sideOverlapName,          QJsonValue::Double, true },
                                                           };
        if (!JsonParsing::validateKeys(json, check2, errorString)) {
            _disableRecalc = false;
            return false;
        }
        CameraSpec::load(json, errorString);
        json[valueSetIsDistanceName] = _valueSetIsDistanceFact.rawValue().toBool();
        json[imageDensityName] =       _imageDensityFact.rawValue().toDouble();
        json[frontalOverlapName] =     _frontalOverlapFact.rawValue().toDouble();
        json[sideOverlapName] =        _sideOverlapFact.rawValue().toDouble();
    }
    _disableRecalc = false;
    _recalcTriggerDistance();
    return true;
}

void CameraInfo::set(CameraInfo* camera){
    _disableRecalc = camera->_disableRecalc;

    _knownCameraList = camera->_knownCameraList;
    _cameraBrandList = camera->_cameraBrandList;
    _cameraModelList = camera->_cameraModelList;
    _cameraBrandIndex = camera->_cameraBrandIndex;
    _cameraModelIndex = camera->_cameraModelIndex;
    _distanceMode = camera->_distanceMode;
    _imageFootprintSide = camera->_imageFootprintSide;
    _imageFootprintFrontal = camera->_imageFootprintFrontal;

    _valueSetIsDistanceFact = camera->_valueSetIsDistanceFact;
    _distanceToSurfaceFact = camera->_distanceToSurfaceFact;
    _imageDensityFact = camera->_imageDensityFact;
    _frontalOverlapFact = camera->_frontalOverlapFact;
    _sideOverlapFact = camera->_sideOverlapFact;
    _footprintSideFact = camera->_footprintSideFact;
    _footprintFrontalFact = camera->_footprintFrontalFact;
    _recalcTriggerDistance();
}

void CameraInfo::setDistanceMode(QGroundControlQmlGlobal::AltitudeFrame altMode)
{
    if (altMode != _distanceMode) {
        _distanceMode = altMode;
        emit distanceModeChanged(_distanceMode);
    }
}

//SLOTS
void CameraInfo::_recalcTriggerDistance(void)
{
    if (_disableRecalc || 0 == _cameraBrandIndex) {
        return;
    }

    _disableRecalc = true;

    double focalLength =    this->focalLength()->rawValue().toDouble();
    double sensorWidth =    this->sensorWidth()->rawValue().toDouble();
    double sensorHeight =   this->sensorHeight()->rawValue().toDouble();
    double imageWidth =     this->imageWidth()->rawValue().toDouble();
    double imageHeight =    this->imageHeight()->rawValue().toDouble();
    double imageDensity =   _imageDensityFact.rawValue().toDouble();

    if (focalLength <= 0 || sensorWidth <= 0 || sensorHeight <= 0 || imageWidth <= 0 || imageHeight <= 0 || imageDensity <= 0) {
        return;
    }

    if (_valueSetIsDistanceFact.rawValue().toBool()) {
        _imageDensityFact.setRawValue((_distanceToSurfaceFact.rawValue().toDouble() * sensorWidth * 100.0) / (imageWidth * focalLength));
    } else {
        _distanceToSurfaceFact.setRawValue((imageWidth * _imageDensityFact.rawValue().toDouble() * focalLength) / (sensorWidth * 100.0));
    }

    imageDensity = _imageDensityFact.rawValue().toDouble();

    if (landscape()->rawValue().toBool()) {
        _imageFootprintSide =       (imageWidth  * imageDensity) / 100.0;
        _imageFootprintFrontal =    (imageHeight * imageDensity) / 100.0;
    } else {
        _imageFootprintSide  =      (imageHeight * imageDensity) / 100.0;
        _imageFootprintFrontal =    (imageWidth  * imageDensity) / 100.0;
    }
    _footprintSideFact.setRawValue      (_imageFootprintSide * ((100.0 - _sideOverlapFact.rawValue().toDouble()) / 100.0));
    _footprintFrontalFact.setRawValue   (_imageFootprintFrontal * ((100.0 - _frontalOverlapFact.rawValue().toDouble()) / 100.0));

    emit imageFootprintSideChanged      (_imageFootprintSide);
    emit imageFootprintFrontalChanged   (_imageFootprintFrontal);

    _disableRecalc = false;
}

void CameraInfo::updateBrandList(void)
{
    _cameraBrandIndex = 0;
    _cameraModelIndex = 0;
    _cameraBrandList.clear();
    _knownCameraList = _gises->vehicle()->staticCameraList();
    _cameraBrandList.append({"Manual (no camera specs)","Custom Camera"});
    for (int i=0; i<_knownCameraList.size(); ++i) {
        CameraMetaData* cameraMetaData = _knownCameraList[i].value<CameraMetaData*>();
        if (!_cameraBrandList.contains(cameraMetaData->brand)) {
            _cameraBrandList.append(cameraMetaData->brand);
        }
    }
    emit brandIndexChanged();
    emit modelIndexChanged();
    emit brandListChanged();
}
void CameraInfo::updateModelList(void)
{
    _cameraModelIndex = 0;
    _cameraModelList.clear();
    for (int i=0; i<_knownCameraList.size(); ++i) {
        CameraMetaData* cameraMetaData = _knownCameraList[i].value<CameraMetaData*>();
        if (cameraMetaData->brand == _cameraBrandList[_cameraBrandIndex]) {
            _cameraModelList.append(cameraMetaData->model);
        }
    }
    emit modelIndexChanged();
    emit modelListChanged();
}
void CameraInfo::updateCameraParam(){
    if(_disableRecalc){
        return;
    }
    if(_cameraBrandIndex > 1){
        CameraMetaData* data = nullptr;
        for (int i=0; i<_knownCameraList.size(); ++i) {
            CameraMetaData* cameraMetaData = _knownCameraList[i].value<CameraMetaData*>();
            if(cameraMetaData->brand == _cameraBrandList[_cameraBrandIndex] &&
                cameraMetaData->model == _cameraModelList[_cameraModelIndex]){
                data = cameraMetaData;
                break;
            }
        }
        if(!data){
            //找不到有效的相机配置
            _cameraBrandIndex = 1;
            emit brandIndexChanged();
        }else{
            _disableRecalc = true;

            sensorWidth()->setRawValue          (data->sensorWidth);
            sensorHeight()->setRawValue         (data->sensorHeight);
            imageWidth()->setRawValue           (data->imageWidth);
            imageHeight()->setRawValue          (data->imageHeight);
            focalLength()->setRawValue          (data->focalLength);
            landscape()->setRawValue            (data->landscape);
            fixedOrientation()->setRawValue     (data->fixedOrientation);
            minTriggerInterval()->setRawValue   (data->minTriggerInterval);

            _disableRecalc = false;
        }
    }
    _recalcTriggerDistance();
    if (0 != _cameraBrandIndex && distanceMode() == QGroundControlQmlGlobal::AltitudeFrameAbsolute) {
        // Manual grids support absolute alts whereas nothing else does. Make sure we are not left in absolute
        setDistanceMode(QGroundControlQmlGlobal::AltitudeFrameRelative);
    }
}
