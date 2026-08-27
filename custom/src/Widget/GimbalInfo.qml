
import QtQuick
import QtQuick.Controls

import QGroundControl

Rectangle{
    width: 100
    height: 100

    property Vehicle vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var gimbal: vehicle ? vehicle.gimbalController : null
    property var activeGimbal: gimbal ? gimbal.activeGimbal : undefined
    property bool multiGimbal: gimbal ? gimbal.gimbals.count>1 : false
}
