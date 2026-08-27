
#pragma once

#include <QtQmlIntegration/QtQmlIntegration>
#include "CameraSpec.h"
#include "SettingsFact.h"
#include "QGroundControlQmlGlobal.h"

class GisesManager;
class Vehicle;

class CameraInfo: public CameraSpec
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")

public:
    CameraInfo(const QString& settingsGroup, QObject* parent = nullptr);

    Q_PROPERTY(QStringList brandList READ brandList NOTIFY brandListChanged FINAL)
    Q_PROPERTY(QStringList modelList READ modelList NOTIFY modelListChanged FINAL)
    Q_PROPERTY(int brandIndex READ brandIndex WRITE setBrandIndex NOTIFY brandIndexChanged FINAL)
    Q_PROPERTY(int modelIndex READ modelIndex WRITE setModelIndex NOTIFY modelIndexChanged FINAL)

    Q_PROPERTY(Fact* valueSetIsDistance       READ valueSetIsDistance       CONSTANT)                                   ///< true: distance specified, resolution calculated
    Q_PROPERTY(Fact* distanceToSurface        READ distanceToSurface        CONSTANT)                                   ///< Distance to surface for image foot print calculation
    Q_PROPERTY(Fact* imageDensity             READ imageDensity             CONSTANT)                                   ///< Image density on surface (cm/px)
    Q_PROPERTY(Fact* frontalOverlap           READ frontalOverlap           CONSTANT)
    Q_PROPERTY(Fact* sideOverlap              READ sideOverlap              CONSTANT)
    Q_PROPERTY(Fact* adjustedFootprintSide    READ adjustedFootprintSide    CONSTANT)                                   ///< Side footprint adjusted down for overlap
    Q_PROPERTY(Fact* adjustedFootprintFrontal READ adjustedFootprintFrontal CONSTANT)                                   ///< Frontal footprint adjusted down for overlap
    Q_PROPERTY(Fact* altMode 				  READ altMode 					CONSTANT)

    // The following values are calculated from the camera properties
    Q_PROPERTY(double imageFootprintSide    READ imageFootprintSide     NOTIFY imageFootprintSideChanged)       ///< Size of image size side in meters
    Q_PROPERTY(double imageFootprintFrontal READ imageFootprintFrontal  NOTIFY imageFootprintFrontalChanged)    ///< Size of image size frontal in meters

    QStringList brandList() { return _cameraBrandList; }
    QStringList modelList() { return _cameraModelList; }
    int brandIndex() { return _cameraBrandIndex; }
    int modelIndex() { return _cameraModelIndex; }

    void setBrandIndex(int index);
    void setModelIndex(int index);
    Fact* valueSetIsDistance        (void) { return &_valueSetIsDistanceFact; }
    Fact* distanceToSurface         (void) { return &_distanceToSurfaceFact; }
    Fact* imageDensity              (void) { return &_imageDensityFact; }
    Fact* frontalOverlap            (void) { return &_frontalOverlapFact; }
    Fact* sideOverlap               (void) { return &_sideOverlapFact; }
    Fact* adjustedFootprintSide     (void) { return &_footprintSideFact; }
    Fact* adjustedFootprintFrontal  (void) { return &_footprintFrontalFact; }
    Fact* altMode					(void) { return &_altModeFact; }

    const Fact* valueSetIsDistance          (void) const { return &_valueSetIsDistanceFact; }
    const Fact* distanceToSurface           (void) const { return &_distanceToSurfaceFact; }
    const Fact* imageDensity                (void) const { return &_imageDensityFact; }
    const Fact* frontalOverlap              (void) const { return &_frontalOverlapFact; }
    const Fact* sideOverlap                 (void) const { return &_sideOverlapFact; }
    const Fact* adjustedFootprintSide       (void) const { return &_footprintSideFact; }
    const Fact* adjustedFootprintFrontal    (void) const { return &_footprintFrontalFact; }

    double  imageFootprintSide          (void) const { return _imageFootprintSide; }
    double  imageFootprintFrontal       (void) const { return _imageFootprintFrontal; }

    QGroundControlQmlGlobal::AltitudeFrame distanceMode(void) const { return _distanceMode; }

    void setDistanceMode                (QGroundControlQmlGlobal::AltitudeFrame altMode);

    void save(QJsonObject& json) const;
    bool load(const QJsonObject& json);

    static constexpr const char* brandName = "brand";
    static constexpr const char* modelName = "model";
    static constexpr const char* valueSetIsDistanceName = "ValueSetIsDistance";
    static constexpr const char* distanceToSurfaceName = "DistanceToSurface";
    static constexpr const char* distanceModeName = "DistanceMode";
    static constexpr const char* imageDensityName = "ImageDensity";
    static constexpr const char* frontalOverlapName = "FrontalOverlap";
    static constexpr const char* sideOverlapName = "SideOverlap";
    static constexpr const char* adjustedFootprintFrontalName = "AdjustedFootprintFrontal";
    static constexpr const char* adjustedFootprintSideName = "AdjustedFootprintSide";

    void set(CameraInfo* camera);
signals:
    void brandListChanged();
    void modelListChanged();
    void brandIndexChanged();
    void modelIndexChanged();
    void imageFootprintSideChanged(double imageFootprintSide);
    void imageFootprintFrontalChanged(double imageFootprintFrontal);
    void distanceModeChanged(int altMode);

private slots:
    void _recalcTriggerDistance(void);
    void updateBrandList();
    void updateModelList();
    void updateCameraParam();

private:
    GisesManager* _gises = nullptr;

    bool _disableRecalc = false;

    QVariantList _knownCameraList;
    QStringList _cameraBrandList;
    QStringList _cameraModelList;
    int	_cameraBrandIndex = 0;
    int	_cameraModelIndex = 0;

    QGroundControlQmlGlobal::AltitudeFrame _distanceMode = QGroundControlQmlGlobal::AltitudeFrameRelative;
    double _imageFootprintSide = 0;
    double _imageFootprintFrontal = 0;

    QMap<QString, FactMetaData*> _metaDataMap;

    SettingsFact _valueSetIsDistanceFact;
    SettingsFact _distanceToSurfaceFact;
    SettingsFact _imageDensityFact;
    SettingsFact _frontalOverlapFact;
    SettingsFact _sideOverlapFact;
    SettingsFact _footprintSideFact;
    SettingsFact _footprintFrontalFact;
    Fact _altModeFact;

    // The following are deprecated and only included in order to convert V0 formats
    enum CameraSpecType {
        CameraSpecNone,
        CameraSpecCustom,
        CameraSpecKnown
    };

    static constexpr const char* _jsonCameraSpecTypeKeyDeprecated            = "CameraSpecType";
    // The following are deprecated and only included in order to convert V1 formats
    static constexpr const char* _jsonDistanceToSurfaceRelativeKeyDeprecated = "DistanceToSurfaceRelative";
};
