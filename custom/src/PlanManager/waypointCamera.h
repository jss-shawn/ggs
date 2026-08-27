#pragma once

#include <QObject>
#include <QtQmlIntegration/QtQmlIntegration>

class FactMetaData;
class MissionItem;

class WaypointCamera: public QObject{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    enum CameraAction{
        CameraActionNone,
        TakePhotosIntervalTime,
        TakePhotosIntervalDistance,
        TakePhoto,
        StopTakingPhotos,
        TakeVideo,
        StopTakingVideo,
    };
    WaypointCamera(QObject* parent = nullptr);
    WaypointCamera(const WaypointCamera& other, QObject* parent);
    WaypointCamera& operator=(const WaypointCamera& right);

    Q_PROPERTY(int actionIndex READ actionIndex WRITE setActionIndex NOTIFY actionIndexChanged FINAL)
    Q_PROPERTY(int actionTime READ actionTime WRITE setActionTime NOTIFY actionTimeChanged FINAL)
    Q_PROPERTY(double actionDistance READ actionDistance WRITE setActionDistance NOTIFY actionDistanceChanged FINAL)
    Q_PROPERTY(bool specifyCameraMode READ specifyCameraMode WRITE setSpecifyCameraMode NOTIFY specifyCameraModeChanged FINAL)
    Q_PROPERTY(int cameraMode READ cameraMode WRITE setCameraMode NOTIFY cameraModeChanged FINAL)
    Q_PROPERTY(double gimbalYaw READ gimbalYaw WRITE setGimbalYaw NOTIFY gimbalYawChanged FINAL)
    Q_PROPERTY(double gimbalPitch READ gimbalPitch WRITE setGimbalPitch NOTIFY gimbalPitchChanged FINAL)
    Q_PROPERTY(bool gimbalAdjust READ gimbalAdjust WRITE setGimbalAdjust NOTIFY gimbalAdjustChanged FINAL)
    Q_PROPERTY(QString cameraActionIcon READ cameraActionIcon NOTIFY actionIndexChanged FINAL)

    Q_PROPERTY(QStringList actionName READ actionName CONSTANT)
    Q_PROPERTY(QStringList modeName READ modeName CONSTANT)
    Q_PROPERTY(bool cameraModeSupported READ cameraModeSupported CONSTANT)

    int actionIndex() { return _actionIndex; }
    int actionTime() { return _actionTime; }
    double actionDistance() { return _actionDistance; }
    bool specifyCameraMode() { return _specifyCameraMode; }
    int cameraMode() { return _cameraMode; }
    double gimbalYaw() { return _gimbalYaw; }
    double gimbalPitch() { return _gimbalPitch; }
    bool gimbalAdjust() { return _gimbalAdjust; }

    QStringList actionName() const { return _actionName; }
    QStringList modeName();
    bool cameraModeSupported() const;
    CameraAction action() { return _actionValue[_actionIndex]; }
    QString cameraActionIcon() { return _actionIcon[_actionIndex]; }
    void reset();
    int allActions();

    void setAction(CameraAction action);
    void setActionIndex(int index);
    void setActionTime(int times);
    void setActionDistance(double distance);
    void setSpecifyCameraMode(bool spe);
    void setCameraMode(int mode);
    void setGimbalYaw(double yaw);
    void setGimbalPitch(double pitch);
    void setGimbalAdjust(bool adjust);

    QList<MissionItem*> genMissionItem(int waypointIndex, QObject* parent = nullptr);
signals:
    void actionIndexChanged();
    void actionTimeChanged();
    void actionDistanceChanged();
    void specifyCameraModeChanged();
    void cameraModeChanged();
    void gimbalYawChanged();
    void gimbalPitchChanged();
    void gimbalAdjustChanged();
    void takePhotoChanged();
    void allActionChanged();
private:
    int _actionIndex = 0;
    int _actionTime = 1;
    double _actionDistance = 1.0;
    bool _specifyCameraMode = false;
    int _cameraMode = 0;
    bool _gimbalAdjust = false;
    double _gimbalYaw = 0.0;
    double _gimbalPitch = 0.0;
    bool _reset = false;
    static QMap<QString, FactMetaData*> _metaDataMap;
    const QList<CameraAction> _actionValue = {
        CameraActionNone,
        TakePhotosIntervalTime,
        TakePhotosIntervalDistance,
        TakePhoto,
        StopTakingPhotos,
        TakeVideo,
        StopTakingVideo
    };
    const QStringList _actionName = {"No Change",
                                     "Take Photos(time)",
                                     "Take Photos(Distance)",
                                     "Take Photo",
                                     "Stop Taking Photos",
                                     "Start Recording Video",
                                     "Stop Recording Video"};
    const QStringList _actionIcon = { "",
                                      "/classic/CCCameraOn.svg",
                                      "/classic/CCCameraOn.svg",
                                      "/classic/CCCameraOn.svg",
                                      "/classic/CCCameraOff.svg",
                                      "/classic/CCVideoOn.svg",
                                      "/classic/CCVideoOff.svg"
                                     };
};
