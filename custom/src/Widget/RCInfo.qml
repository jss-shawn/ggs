
import QtQuick
import QtQuick.Controls

import QGroundControl

Rectangle{
    width: 100
    height: 100
    property Vehicle vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool rcRSSIAvailable: vehicle ? (vehicle.rcRSSI > 0 && vehicle.rcRSSI <= 100) : false
}