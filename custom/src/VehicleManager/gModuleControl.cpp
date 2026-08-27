
#include <QtQml/qqml.h>
#include "gAirVideoModule.h"
#include "gModuleControl.h"

GModuleControl::GModuleControl(QObject *parent)
    : QObject{parent}
    ,_tcpConfig(new TCPConfiguration("tcp", this))
    ,_udpConfig(new UDPConfiguration("udp"))
    ,_bluetoothConfig(new BluetoothConfiguration("bluetooth"))
    ,_serialConfig(new SerialConfiguration("serial"))
    //,_config(_serialConfig)
    ,_config(_tcpConfig)
    ,_airVideoModule(new GAirVideoModule(this))
{
    SharedLinkConfigurationPtr shp = SharedLinkConfigurationPtr(_serialConfig);
    _link = new SerialLink(shp);

#ifndef NO_SERIAL_LINK
    _typeNames.append(_allType[0]);
#endif
    _typeNames.append(_allType[1]);
    _typeNames.append(_allType[2]);
#ifdef QGC_ENABLE_BLUETOOTH
    _typeNames.append(_allType[3]);
#endif
    connect(_airVideoModule, &GAirVideoModule::sendData, this, &GModuleControl::onSendData);
    _airVideoModule->init();
}
void GModuleControl::init(){
}

void GModuleControl::registerQmlTypes(){
    qmlRegisterUncreatableType<GModuleControl>("gises", 1, 0, "GModuleControl", "Reference only");
    GAirVideoModule::registerQmlTypes();
}

void GModuleControl::changeLinkType(int index){
    int type = _allType.indexOf(_typeNames[index]);
    if(type != _config->type()){
        switch(type){
        case LinkConfiguration::TypeSerial:{
            _config = _serialConfig;
        }
        break;
        case LinkConfiguration::TypeUdp:{
            _config = _udpConfig;
        }
        break;
        case LinkConfiguration::TypeTcp:{
            _config = _tcpConfig;
        }
        break;
        case LinkConfiguration::TypeBluetooth:{
            _config = _bluetoothConfig;
        }
        break;
        default:{
            _config = _tcpConfig;
        }
        break;
        }
        emit configChanged();
    }
}

void GModuleControl::setLinkState(int state){
    _linkState = state;
    emit linkStateChanged();
}
void GModuleControl::reconnect(){
    if(_link){
        disconnect(_link, nullptr, this, nullptr);
        _link->disconnect();
        _link->deleteLater();
        _link = nullptr;
        setLinkState(0);
    }
    SharedLinkConfigurationPtr shp = SharedLinkConfigurationPtr(_config);
    switch(_config->type()){
    case LinkConfiguration::TypeSerial:
        _link = new SerialLink(shp);
        break;
    case LinkConfiguration::TypeUdp:
        _link = new UDPLink(shp);

        break;
    case LinkConfiguration::TypeTcp:
        _link = new TCPLink(shp, this);

        break;
    case LinkConfiguration::TypeBluetooth:
        _link = new BluetoothLink(shp);
        break;
    default:
        _link = nullptr;
        break;
    }
    if(!_link){
        linkError("", tr("Create Link failed"));
        return;
    }
    connect(_link, &LinkInterface::connected, this,  [this](){ setLinkState(1); });
    connect(_link, &LinkInterface::disconnected, this,  [this](){ setLinkState(0); });
    connect(_link, &LinkInterface::bytesReceived, this, &GModuleControl::onReceiveData);
    connect(_link, &LinkInterface::communicationError, this, &GModuleControl::linkError);
    emit linkChanged();
}

void GModuleControl::onSendData(const QByteArray &data){
    if(_link){
        _link->writeBytesThreadSafe(data);
    }
}

void GModuleControl::onReceiveData(LinkInterface *link, const QByteArray &data){
    if(_moduleIndex == 0){
        _airVideoModule->handleData(data);
    }
}
void GModuleControl::linkError(const QString &title, const QString &error){

}
