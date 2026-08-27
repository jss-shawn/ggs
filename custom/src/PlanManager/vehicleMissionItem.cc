
#include "vehicleMissionItem.h"

VehicleMissionItem::VehicleMissionItem(MissionItem* item, QObject* parent)
    :QObject(parent)
    ,_item(item)
{

}

bool VehicleMissionItem::isTakeoff(){
    return MAV_CMD_NAV_TAKEOFF == _item->command() || MAV_CMD_NAV_VTOL_TAKEOFF == _item->command();
}

bool VehicleMissionItem::isLand(){
    return MAV_CMD_NAV_LAND == _item->command() || MAV_CMD_NAV_VTOL_LAND == _item->command();
}

void VehicleMissionItem::setCoord(QGeoCoordinate coord){
    if(coord.isValid()){
        _item->setParam5(coord.latitude());
        _item->setParam6(coord.longitude());
        emit coordChanged();
    }
}