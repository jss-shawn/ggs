
import QtQuick
import QtQuick.Controls

import QGroundControl

Rectangle{
    width: 100
    height: 100

    enum RegionOperation {
        FAA,
        EU
    }

    property Vehicle vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var manager: vehicle ? vehicle.remoteIDManager : null
    property int regionOperation: QGroundControl.settingsManager.remoteIDSettings.region.value
    property bool stateUnavailable: !vehicle
    property bool stateError: manager && (!manager.commsGood || !manager.armStatusGood || manager.emergencyDeclared)
    property bool stateWarning: manager && ((!manager.gcsGPSGood || !manager.basicIDGood) ||
                                            ((regionOperation === CCRemoteIDInfo.EU ||
                                            QGroundControl.settingsManager.remoteIDSettings.sendOperatorID.value) &&
                                            !manager.operatorIDGood))

}
