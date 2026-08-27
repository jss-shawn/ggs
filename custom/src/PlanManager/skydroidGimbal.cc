
#include "skydroidGimbal.h"
#include "UDPLink.h"

SkydroidGimbal::SkydroidGimbal(QObject* parent)
    :QObject(parent)
    ,_udp(new UDPConfiguration("skydroid_gimbal"))
{
    _udp->addHost("192.168.144.108", 5000);
    _udp->setLocalPort(9876);
    SharedLinkConfigurationPtr shp = SharedLinkConfigurationPtr(_udp);
    _link = std::make_shared<UDPLink>(shp);
    connect(_link.get(), &LinkInterface::bytesReceived, this, &SkydroidGimbal::receiveBytes);
    connect(_link.get(), &LinkInterface::bytesSent, this, &SkydroidGimbal::logSentBytes);
    connect(_link.get(), &LinkInterface::connected, this, &SkydroidGimbal::linkConnected);
    connect(_link.get(), &LinkInterface::disconnected, this, &SkydroidGimbal::linkDisconnected);
}

SkydroidGimbal::~SkydroidGimbal(){
}

void SkydroidGimbal::conn(){
    // if(!_link->_connect()){
    //     qDebug()<<"skydroid udp connect error";
    // }
}

void SkydroidGimbal::disc(){
    if(_link->isConnected()){
        _link->disconnect();
    }
}

void SkydroidGimbal::doAction(uint8_t act){
    if(!_link->isConnected()){
        _cmd = "skydroid gimbal do not connected";
        emit cmdChanged();
        return;
    }
    QString cmd;
    switch (act) {
    case Reset:{
        cmd = "#TPUGCwGAM000064000064";
        QByteArray data = cmd.toUtf8();
        char crc = calcCrc(data.data(), data.size());
        QString crcStr = QString::number(crc, 16);
        cmd.append(crcStr.toUpper().toUtf8());
        break;
    }
    case SetM:{
        cmd = "#TPUG2wPTZ0B";
        QByteArray data = cmd.toUtf8();
        char crc = calcCrc(data.data(), data.size());
        QString crcStr = QString::number(crc, 16);
        cmd.append(crcStr.toUpper().toUtf8());
        break;
    }
    case SetW:{
        cmd = "#TPUG2wPTZ0A";
        QByteArray data = cmd.toUtf8();
        char crc = calcCrc(data.data(), data.size());
        QString crcStr = QString::number(crc, 16);
        cmd.append(crcStr.toUpper().toUtf8());
        break;
    }
    case TurnUp:
        cmd = "#TPUG2wGSP6460";
        break;
    case TurnLeft:
        cmd = "#TPUG2wGSY6469";
        break;
    case TurnRight:
        cmd = "#TPUG2wGSY9C7B";
        break;
    case TurnDown:
        cmd = "#TPUG2wGSP9C72";
        break;
    default:
        return;
    }
    _link->writeBytesThreadSafe(cmd.toUtf8().data(), cmd.length());
}

void SkydroidGimbal::custom(const QString& cmd){
    if(_link->isConnected()){
        QByteArray data = cmd.toUtf8();
        char crc = calcCrc(data.data(), data.size());
        QString crcStr = QString::number(crc, 16);
        data.append(crcStr.toUpper().toUtf8());
        _link->writeBytesThreadSafe(data.data(), data.size());
    }
}

char SkydroidGimbal::calcCrc(const char* data, int length){
    char crc = 0;
    for (int i = 0; i < length; i++) {
        crc += data[i];
    }
    return crc;
}

//SLOTS
void SkydroidGimbal::receiveBytes(LinkInterface *link, const QByteArray &data){
    Q_UNUSED(link)
    _cmd = "recv:";
    _cmd += data;
    emit cmdChanged();
}

void SkydroidGimbal::logSentBytes(LinkInterface *link, const QByteArray &data){
    Q_UNUSED(link)
    Q_UNUSED(data)
}

void SkydroidGimbal::linkConnected(){
    _linkState = true;
    emit connectedChanged();
}

void SkydroidGimbal::linkDisconnected(){
    _linkState = false;
    emit connectedChanged();
}