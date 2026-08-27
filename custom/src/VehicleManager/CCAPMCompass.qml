
import QtQuick
import QtQuick.Controls

import gises.base
import gises.widget

Item{
    id: root
    width: parent.width
    height: col.height

    property var busTypes: {
        0: '-',
        1: 'I2C',
        2: 'SPI',
        3: 'UAVCAN',
        4: 'SITL',
        5: 'MSP',
        6: 'EAHRS'
    }

    property var compassTypes: {
        0x01: 'HMC5883_OLD',
        0x07: 'HMC5883',
        0x02: 'LSM303D',
        0x04: 'AK8963',
        0x05: 'BMM150',
        0x06: 'LSM9DS1',
        0x08: 'LIS3MDL',
        0x09: 'AK09916',
        0x0A: 'IST8310',
        0x0B: 'ICM20948',
        0x0C: 'MMC3416',
        0x0D: 'QMC5883L',
        0x0E: 'MAG3110',
        0x0F: 'SITL',
        0x10: 'IST8308',
        0x11: 'RM3100',
        0x12: 'RM3100_2',
        0x13: 'MMC5983',
        0x14: 'AK09918',
        0x15: 'AK09915',
        0x16: 'QMC5883P',
        0x17: 'BMM350'
    }

    property var imuTypes: {
        0x09: 'BMI160',
        0x10: 'L3G4200D',
        0x11: 'ACC_LSM303D',
        0x12: 'ACC_BMA180',
        0x13: 'ACC_MPU6000',
        0x16: 'ACC_MPU9250',
        0x17: 'ACC_IIS328DQ',
        0x18: 'ACC_LSM9DS1',
        0x21: 'GYR_MPU6000',
        0x22: 'GYR_L3GD20',
        0x24: 'GYR_MPU9250',
        0x25: 'GYR_I3G4250D',
        0x26: 'GYR_LSM9DS1',
        0x27: 'INS_ICM20789',
        0x28: 'INS_ICM20689',
        0x29: 'INS_BMI055',
        0x2A: 'SITL',
        0x2B: 'INS_BMI088',
        0x2C: 'INS_ICM20948',
        0x2D: 'INS_ICM20648',
        0x2E: 'INS_ICM20649',
        0x2F: 'INS_ICM20602',
        0x30: 'INS_ICM20601',
        0x31: 'INS_ADIS1647X',
        0x32: 'SERIAL',
        0x33: 'INS_ICM40609',
        0x34: 'INS_ICM42688',
        0x35: 'INS_ICM42605',
        0x36: 'INS_ICM40605',
        0x37: 'INS_IIM42652',
        0x38: 'BMI270',
        0x39: 'INS_BMI085',
        0x3A: 'INS_ICM42670',
        0x3B: 'INS_ICM45686',
        0x3C: 'INS_SCHA63T',
        0x3D: 'INS_IIM42653'
    }

    property var baroTypes: {
        0x01: 'SITL',
        0x02: 'BMP085',
        0x03: 'BMP280',
        0x04: 'BMP388',
        0x05: 'DPS280',
        0x06: 'DPS310',
        0x07: 'FBM320',
        0x08: 'ICM20789',
        0x09: 'KELLERLD',
        0x0A: 'LPS2XH',
        0x0B: 'MS5611',
        0x0C: 'SPL06',
        0x0D: 'UAVCAN',
        0x0E: 'MSP',
        0x0F: 'ICP101XX',
        0x10: 'ICP201XX',
        0x11: 'MS5607',
        0x12: 'MS5837',
        0x13: 'MS5637',
        0x14: 'BMP390',
        0x15: 'BMP581'
    }

    property var airspeedTypes: {
        0x01: 'SITL',
        0x02: 'MS4525',
        0x03: 'MS5525',
        0x04: 'DLVR',
        0x05: 'MSP',
        0x06: 'SDP3X',
        0x07: 'UAVCAN',
        0x08: 'ANALOG',
        0x09: 'NMEA',
        0x0A: 'ASP5033'
    }

    function decode (device) {
        var devid = parseInt(device.valueString)
        var deviceName = device.name
        var busType = busTypes[devid & 0x07]
        var bus = (devid >> 3) & 0x1F
        var address = (devid >> 8) & 0xFF
        var devtype = (devid >> 16)
        var decodedDevname;

        if (devid === 0) {
            return ""
        }
        if (deviceName.startsWith('COMPASS')) {
            if (busType === 3 && devtype === 1) {
                decodedDevname = 'UAVCAN'
            } else if (busType === 6 && devtype === 1) {
                decodedDevname = 'EAHRS'
            } else {
                decodedDevname = compassTypes[devtype] || '?'
            }
        }
        if (deviceName.startsWith('INS')) {
            decodedDevname = imuTypes[devtype] || '?'
        }
        if (deviceName.startsWith('GND_BARO')) {
            decodedDevname = baroTypes[devtype] || '?'
        }
        if (deviceName.startsWith('BARO')) {
            decodedDevname = baroTypes[devtype] || '?'
        }
        if (deviceName.startsWith('ARSP')) {
            decodedDevname = airspeedTypes[devtype] || '?'
        }
        return `${decodedDevname} (${busType}${bus})`
    }
    property bool showFitness: false
    property bool hasPrimary: params.compassPrimaryFactAvailable
    property bool compassAutoRotAvailable: ctrl.parameterExists(-1, "COMPASS_AUTO_ROT")
    property var compassAutoRotFact: ctrl.getParameterFact(-1, "COMPASS_AUTO_ROT", false /* reportMissing */)
    property bool compassAutoRot: compassAutoRotAvailable ? compassAutoRotFact.rawValue === 2 : false
    Column{
        width: parent.width
        id: col
        Repeater{
            model: 3
            Column{
                id: compass
                width: parent.width
                visible: params.rgCompassAvailable[index]
                Component.onCompleted: {
                    checkCombox()
                }
                property bool isPrimary: params.rgCompassPrimary[index]
                property string pString: hasPrimary ? isPrimary ? qsTr(" primary -") : qsTr(" secondary -") : ""
                property string eString: params.rgCompassExternal[index] ? qsTr(" external") : qsTr(" internal")
                property var cid: params.rgCompassId[index].rawValue
                property real greenMaxThreshold: 8 * (params.rgCompassExternal[index] ? 1 : 2)
                property real yellowMaxThreshold: 15 * (params.rgCompassExternal[index] ? 1 : 2)
                property real fitnessRange: 25 * (params.rgCompassExternal[index] ? 1 : 2)

                function checkCombox(){
                    var i = 0
                    for(i=0; i<3; ++i){
                        if(cid === params.rgCompassPrio[i].rawValue){
                            comb.currentIndex = i
                            break;
                        }
                    }
                }
                Rectangle{
                    id: redArea
                    width: parent.width
                    height: ui.fontHeight
                    color: "red"
                    visible: showFitness
                    Rectangle{
                        id: yellowArea
                        width: parent.width * (compass.yellowMaxThreshold / compass.fitnessRange)
                        height: parent.height
                        color: "yellow"
                    }
                    Rectangle{
                        id: greenArea
                        width: parent.width * (compass.greenMaxThreshold / compass.fitnessRange)
                        height: parent.height
                        color: "green"
                    }
                    Rectangle {
                        width: parent.height * 0.8
                        height: width
                        x: (parent.width * (Math.min(Math.max(ctrl.rgCompassCalFitness[index], 0.0), compass.fitnessRange) / compass.fitnessRange)) - (width / 2)
                        radius: height / 2
                        color: "white"
                        border.color: "black"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                CCText{
                    height: contentHeight + ui.x2margin
                    text: qsTr("Compass ") + (index + 1) + parent.pString + parent.eString
                }
                CCText{
                    width: parent.width
                    height: contentHeight + ui.x2margin
                    text: decode(params.rgCompassId[index])
                    CCSwitchButton{
                        id: useCompass
                        stateOn: params.rgCompassUseFact[index].rawValue
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: params.rgCompassUseParamAvailable[index] && !params.rgCompassPrimary[index]
                        onClicked: {
                            params.rgCompassUseFact[index].rawValue = !params.rgCompassUseFact[index].rawValue
                        }
                    }
                }
                CCComboBoxEditor{
                    id: comb
                    title: qsTr("Use Compass")
                    model: [ qsTr("Priority 1"), qsTr("Priority 2"), qsTr("Priority 3"), qsTr("Not Set") ]
                    visible: params.compassPrimaryFactAvailable && useCompass.visible && useCompass.stateOn
                    onUpdateResult:
                        (idx)=>{
                            if(idx === 3){
                                parent.checkCombox()
                            }else{
                                params.rgCompassPrio[idx].rawValue = params.rgCompassId[index].rawValue
                            }
                        }
                }
                CCComboBoxEditor{
                    title: qsTr("Orientation")
                    fact: params.rgCompassRotFact[index]
                    visible: !compassAutoRot && params.rgCompassExternal[index] && params.rgCompassRotParamAvailable[index]
                }
            }
        }
    }
}
