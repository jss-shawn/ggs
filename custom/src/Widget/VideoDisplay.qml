
import QtQuick
import QtMultimedia

import QGroundControl

Item{
    id: root

    width: height * ar

    property string videoName: ""
    property string thermalName: ""
    property Vehicle vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real ar: showUvc ? 1.7 : QGroundControl.videoManager.aspectRatio
    //camera object
    property QGCCameraManager camManager: vehicle ? vehicle.cameraManager : null
    property int camIndex: camManager ? camManager.currentCamera : 0
    property bool isCam: camManager && camManager.cameras.count
    property MavlinkCameraControlInterface cam: isCam ? camManager.cameras.get(camIndex) : null
    property bool hasZoom: cam && cam.hasZoom
    property int fitMode: QGroundControl.settingsManager.videoSettings.videoFit.rawValue
    property bool decoding: QGroundControl.videoManager.decoding
    property bool showUvc: QGroundControl.videoManager.isUvc
    property bool fit_width: fitMode === 0
    property bool fit_height: fitMode === 1
    property bool fit_fill: fitMode === 2
    property bool no_crop: fitMode === 3

    VideoOutput {
        id: video
        objectName: videoName
        anchors.fill: parent

        // Do NOT set `orientation` here — VideoOutput composes orientation on top of the
        // QVideoFrame's own rotation()/mirrored() metadata that qgcqvideosink forwards from
        // GstVideoOrientationMeta. Setting it would double-rotate any stream with orientation tags.

        // videoFit enum: 0=Fit Width, 1=Fit Height, 2=Fill, 3=No Crop. The container
        // handles fit-width/fit-height sizing; only Fill needs the cropping fillMode.
        // fillMode: QGroundControl.settingsManager.videoSettings.videoFit.rawValue === 2
        //           ? VideoOutput.PreserveAspectCrop
        //           : VideoOutput.PreserveAspectFit
        fillMode: fit_fill ? VideoOutput.PreserveAspectCrop : VideoOutput.PreserveAspectFit

        Connections {
            target: QGroundControl.videoManager
            function onImageFileChanged(filename) {
                grabToImage(function(result) {
                    if (!result.saveToFile(filename)) {
                        console.error('Error capturing video frame');
                    }
                });
            }
        }
    }
    VideoOutput {
        id: thermal
        objectName: thermalName
        opacity: 0.3

        // Do NOT set `orientation` here — VideoOutput composes orientation on top of the
        // QVideoFrame's own rotation()/mirrored() metadata that qgcqvideosink forwards from
        // GstVideoOrientationMeta. Setting it would double-rotate any stream with orientation tags.

        // videoFit enum: 0=Fit Width, 1=Fit Height, 2=Fill, 3=No Crop. The container
        // handles fit-width/fit-height sizing; only Fill needs the cropping fillMode.
        fillMode: fit_fill ? VideoOutput.PreserveAspectCrop : VideoOutput.PreserveAspectFit

        Connections {
            target: QGroundControl.videoManager
            function onImageFileChanged(filename) {
                grabToImage(function(result) {
                    if (!result.saveToFile(filename)) {
                        console.error('Error capturing video frame');
                    }
                });
            }
        }
    }
    onDecodingChanged: {
        if (decoding) {

        }
    }
}