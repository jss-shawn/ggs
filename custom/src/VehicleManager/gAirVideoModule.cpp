
#include <QtCore/QJsonArray>
#include <QtCore/QJsonObject>
#include <QtCore/QJsonParseError>
#include <QtQml/qqml.h>
#include "gAirVideoModule.h"

GAirVideoSerialParam::GAirVideoSerialParam(const QString& name, const QString& shortName, QObject *parent)
    : QObject(parent)
    ,_name(name)
    ,_shortName(shortName)
{
    _data.append(_baud);
    _data.append(_bit);
    _data.append(_parity);
    _data.append(_stop);
    _data.append(_hwFC);
    _data.append(_rx);
    _data.append(_tx);
}
void GAirVideoSerialParam::checkData(int index, const QVariant& data){
    int value = data.toInt();
    switch(index){
    case 0:{
        if(value >=0 && value <= 6){
            _baud = value;
            _data[0] = _baud;
        }
        break;
    }
    case 1:{
        if(value >=0 && value <= 2){
            _bit = value;
            _data[1] = _bit;
        }
        break;
    }
    case 2:{
        if(value >=0 && value <= 2){
            _parity = value;
            _data[2] = _parity;
        }
        break;
    }
    case 3:{
        if(value >=0 && value <= 2){
            _stop = value;
            _data[3] = _stop;
        }
        break;
    }
    case 4:{
        if(value >=0 && value <= 1){
            _hwFC = value;
            _data[4] = _hwFC;
        }
        break;
    }
    case 5:{
        if(value >=0 && value <= 1){
            _rx = value;
            _data[5] = _rx;
        }
        break;
    }
    case 6:{
        if(value >=0 && value <= 1){
            _tx = value;
            _data[6] = _tx;
        }
        break;
    }
    default:{
    }
    }
    emit dataChanged();
}

void GAirVideoSerialParam::fromJsonArray(const QJsonArray& array, int type) {
    _baud = array[0].toInt();
    _bit = array[1].toInt();
    _parity = array[2].toInt();
    _stop = array[3].toInt();
    if(type == 1){
        _hwFC = array[4].toInt();
        _rx = array[5].toInt();
        _tx = array[6].toInt();
    }
}

void GAirVideoSerialParam::toJsonArray(QJsonArray& array) {
    array.append(_baud);
    array.append(_bit);
    array.append(_parity);
    array.append(_stop);
    array.append(_hwFC);
    array.append(_rx);
    array.append(_tx);
}

GAirVideoNetworkParam::GAirVideoNetworkParam(const QString& name, const QString& shortName, QObject *parent)
    : QObject(parent)
    ,_name(name)
    ,_shortName(shortName)
{
    _data.append(_host);
    _data.append(_port);
    _data.append(_listen);
    _data.append(_clientLimit);
}
void GAirVideoNetworkParam::checkData(int index, const QVariant& data){
    int value = 0;
    switch(index){
    case 0:{
        QString host = data.toString();
        if(host == _host)
            break;
        QList<QString> part;
        if(GAirVideoModule::splitAddress(host, part)){
            _host = host;
            _data[0] = _host;
        }
        break;
    }
    case 1:{
        value = data.toInt();
        if(value == _port)
            break;
        if(value > 5000 && value < 65536){
            _port = value;
            _data[1] = _port;
        }
        break;
    }
    case 2:{
        value = data.toInt();
        if(value != _listen)
            break;
        if(value > 0){
            _listen = value;
            _data[2] = _listen;
        }
        break;
    }
    case 3:{
        value = data.toInt();
        if(value != _clientLimit)
            break;
        if(value > 0){
            _clientLimit = value;
            _data[3] = _clientLimit;
        }
        break;
    }
    default:{
    }
    }
    emit dataChanged();
}
void GAirVideoNetworkParam::fromJsonArray(const QJsonArray& array) {
    QString host;
    host.append(QString::number(array[0].toInt()));
    for(int i=1; i<4; ++i){
        host.append(".");
        host.append(QString::number(array[i].toInt()));
    }
    _host = host;
    _port = array[4].toInt();
    _listen = array[5].toInt();
    _clientLimit = array[6].toInt();
}
void GAirVideoNetworkParam::toJsonArray(QJsonArray& array) {
    QList<QString> numbers;
    if(!GAirVideoModule::splitAddress(_host, numbers)){
        //gaApp->setMessage(_shortName + ":地址格式错误", GAApplication::Error);
        return;
    }
    array.append(numbers.last().toInt());
    array.append(_port);
    array.append(_listen);
    array.append(_clientLimit);
}

bool GAirVideoModule::splitAddress(QString address, QList<QString>& parts){
    if(address.count(".") != 3){
        return false;
    }
    QList<QString> numbers;
    QString num;
    while(address.size()){
        num = address.left(address.indexOf('.'));
        if(num.toInt() < 0 || num.toInt() > 255 || num.toInt() == qQNaN()){
            return false;
        }
        numbers.append(num);
        address = address.mid(numbers.last().size()+1, address.size());
    }
    parts.append(numbers);
    return true;
}

GAirVideoModule::GAirVideoModule(QObject *parent)
    : QObject{parent}
    ,_brd({0, 1, 2, 1})
{
    _serialParams.append(new GAirVideoSerialParam("A", "a", this));
    _netParams.append(new GAirVideoNetworkParam("B", "b", this));
    // for(int i=0; i<_portNames.size(); ++i){
    //     _serialParams.append(new AirVideoSerialParam(_portNames[i][0], _portNames[i][1], this));
    //     _netParams.append(new AirVideoNetworkParam(_portNames[i][0], _portNames[i][1], this));
    // }
}

void GAirVideoModule::init(){
    connect(this, &GAirVideoModule::itTypeChanged, this, &GAirVideoModule::onItTypeChanged);
}

void GAirVideoModule::registerQmlTypes(){
    qmlRegisterUncreatableType<GAirVideoModule>("gises", 1, 0, "GAirVideoModule", "Reference only");
    qmlRegisterUncreatableType<GAirVideoNetworkParam>("gises", 1, 0, "GAirVideoNetworkParam", "Uncreatable");
    qmlRegisterUncreatableType<GAirVideoSerialParam>("gises", 1, 0, "GAirVideoSerialParam", "Uncreatable");
}

void GAirVideoModule::clearLog(){
    _dataLog.clear();
    emit dataLogChanged();
}

void GAirVideoModule::setHost(QString host){
    if(_host != host){
        _host = host;
        emit hostChanged();
    }
}
void GAirVideoModule::setMask(QString mask){
    if(_mask != mask){
        _mask = mask;
        emit maskChanged();
    }
}
void GAirVideoModule::setPwm(int index, int value){
    _pwm[index] = value;
    emit pwmChanged();
}
void GAirVideoModule::setFse(bool fse){
    if(fse != _fse){
        _fse = fse;
        emit fseChanged();
    }
}
void GAirVideoModule::setFlt(int flt){
    double val = (double)flt / 10.0;
    if(qAbs(_flt - val) >= 0.1){
        _flt = val;
        emit fltChanged();
    }
}
void GAirVideoModule::setFss(int index, int value){
    _fss[index] = value;
    emit fssChanged();
}
void GAirVideoModule::setFsv(int index, int value){
    _fsv[index] = value;
    emit fsvChanged();
}
void GAirVideoModule::setPid(int index, int value){
    _pid[index] = value;
    emit pidChanged();
}
void GAirVideoModule::setBrd(int index, int value){
    _brd[index] = value;
    emit brdChanged();
}
void GAirVideoModule::getParam(int cmd){
    if(!_cmdList.contains(cmd)){
        ////gaApp->setMessage("不支持该命令:" + QString::number(cmd), GAApplication::Error);
        return;
    }
    QByteArray data;
    QJsonObject req;
    req["operation"] = "get";
    req["cmd"] = cmd;
    QJsonDocument doc(req);
    data = doc.toJson();
    data.replace("\n","");
    data.replace(" ","");
    emit sendData(data);
    _dataLog.append("sendData: " + data);
    emit dataLogChanged();
}
void GAirVideoModule::setParam(int cmd){
    QByteArray data;
    QJsonObject req;
    req["operation"] = "set";
    req["cmd"] = cmd;
    switch(cmd){
    case 7:{
        QJsonArray array;
        QList<QString> param;
        if(!splitAddress(_host, param) || !splitAddress(_mask, param)){
            //gaApp->setMessage("localHost:地址格式错误", GAApplication::Error);
        }
        if(param.size() != 8){
            return;
        }
        for(int i=0; i<param.size(); ++i){
            array.append(param[i].toInt());
        }
        req["host"] = array;
        break;
    }
    case 17:{
        QJsonObject serial;
        //for(int i=0; i<_portNames.size(); ++i){
        for(int i=0; i<_serialParams.size(); ++i){
            QJsonArray array;
            _serialParams[i]->toJsonArray(array);
            serial[_serialParams[i]->_shortName] = array;
        }
        req["air_uart_para"] = serial;
        break;
    }
    case 18:{
        QJsonObject net;
        //for(int i=0; i<_portNames.size(); ++i){
        for(int i=0; i<_netParams.size(); ++i){
            QJsonArray array;
            _netParams[i]->toJsonArray(array);
            net[_netParams[i]->shortName()] = array;
        }
        req["air_net_para"] = net;
        break;
    }
    }
    QJsonDocument doc(req);
    data = doc.toJson();
    emit sendData(data);
    data.replace("\n","");
    data.replace(" ","");
    _dataLog.append("sendData: " + data);
    emit dataLogChanged();
}
void GAirVideoModule::setItType(int type){
    if(type != _itType){
        _itType = type;
        emit itTypeChanged();
    }
}
bool GAirVideoModule::GAirVideoModule::isJsonFile(const QByteArray& bytes, QJsonDocument& jsonDoc, QString& errorString){

    QJsonParseError parseError;

    jsonDoc = QJsonDocument::fromJson(bytes, &parseError);

    if (parseError.error == QJsonParseError::NoError) {
        return true;
    } else {
        int startPos = qMax(0, parseError.offset - 100);
        int length = qMin(bytes.length() - startPos, 200);
        QString error(QStringLiteral("Json read error '%1'").arg(bytes.mid(startPos, length).constData()));
        //gaApp->setMessage(error, GAApplication::Error);
        errorString = parseError.errorString();
        return false;
    }
}

void GAirVideoModule::handleData(const QByteArray& data){
    _dataLog.append("recvData: " + data);
    emit dataLogChanged();
    QJsonDocument jsonDoc;
    QString error;
    if(!isJsonFile(data, jsonDoc, error)){
        //qCCritical(TCPLinkLog) << "data can not be parsed as JSON:" << error;
        return;
    }
    QJsonObject root = jsonDoc.object();
    int cmd = -1;
    int state;
    if(root.contains("cmd")){
        cmd = root["cmd"].toInt();
    }
    switch(cmd){
    case 0:{
        //_handleHost(root["host"].toArray());
        _handlePwm(root["pwm"].toArray());
        setFse(root["fse"].toInt());
        _handleFss(root["fss"].toArray());
        _handleFsv(root["fsv"].toArray());
        setFlt(root["flt"].toInt());
        _handlePid(root["pid"].toArray());
        _handleBrd(root["brd_cfg"].toArray());
        break;
    }
    case 7:{
        _handleHost(root["host"].toArray());
        break;
    }
    case 11:{
        _handlePwm(root["pwm"].toArray());
        break;
    }
    case 12:{
        setFse(root["fse"].toInt());
        break;
    }
    case 15:{
        _handleFss(root["fss"].toArray());
        break;
    }
    case 16:{
        _handleFsv(root["fsv"].toArray());
        break;
    }
    case 17:{
        _handleSerialParam(root["air_uart_para"].toObject());
        break;
    }
    case 18:{
        _handleNetParam(root["air_net_para"].toObject());
        break;
    }
    case 19:{
        setFlt(root["flt"].toInt());
        break;
    }
    case 20:{
        _handlePid(root["pid"].toArray());
        break;
    }
    case 21:{
        _handleBrd(root["brd_cfg"].toArray());
        break;
    }
    default:{
        //gaApp->setMessage("未处理的命令:" + QString::number(cmd), GAApplication::Warning);
        break;
    }
    }
}
void GAirVideoModule::_handleHost(const QJsonArray& array){
    if(array.isEmpty())
        return;
    //[10,10,10,83,255,255,255,0]
    _host.clear();
    _host.append(QString::number(array[0].toInt()));
    for(int i=1; i<4; ++i){
        _host.append("."+QString::number(array[i].toInt()));
    }
    if(array.size()>4){
        _mask.clear();
        _mask.append(QString::number(array[4].toInt()));
        for(int i=5; i<8; ++i){
            _mask.append("."+QString::number(array[i].toInt()));
        }
    }
    emit hostChanged();
    emit maskChanged();
}
void GAirVideoModule::_handlePwm(const QJsonArray& array){
    if(array.isEmpty())
        return;
    //[1,2,3]
    _pwm.clear();
    _pwm.append(array[0].toInt());
    _pwm.append(array[1].toInt());
    _pwm.append(array[2].toInt());
    emit pwmChanged();
}
void GAirVideoModule::_handleFss(const QJsonArray& array){
    //[1,2,3]
    if(array.isEmpty())
        return;
    _fss.clear();
    for(int i=0; i<array.size(); ++i){
        _fss.append(array[i].toInt());
    }
    emit fssChanged();
}
void GAirVideoModule::_handleFsv(const QJsonArray& array){
    if(array.isEmpty())
        return;
    //[1,2,3]
    _fsv.clear();
    for(int i=0; i<array.size(); ++i){
        _fsv.append(array[i].toInt());
    }
    emit fsvChanged();
}
void GAirVideoModule::_handlePid(const QJsonArray& array){
    if(array.isEmpty())
        return;
    _pid.clear();
    for(int i=0; i<array.size(); ++i){
        _pid.append(array[i].toInt());
    }
    emit pidChanged();
}
void GAirVideoModule::_handleBrd(const QJsonArray& array){
    if(array.isEmpty())
        return;
    _brd.clear();
    for(int i=0; i<array.size(); ++i){
        _brd.append(array[i].toInt());
    }
    emit brdChanged();
}
void GAirVideoModule::_handleSerialParam(const QJsonObject& json){
    if(json.isEmpty())
        return;
    int i=0;
    QJsonObject::const_iterator itor = json.begin();
    while(itor != json.end()){
        if(i<_serialParams.size()){
            _serialParams[i]->fromJsonArray(itor.value().toArray(), _itType);
        }else{
            GAirVideoSerialParam* pm = new GAirVideoSerialParam(itor.key(), itor.key(), this);
            pm->fromJsonArray(itor.value().toArray(), _itType);
            _serialParams.append(pm);
        }
        ++i;
        ++itor;
    }
    if(i < _serialParams.size()){
        _serialParams.resize(i);
    }
    emit serialParamsChanged();
}
void GAirVideoModule::_handleNetParam(const QJsonObject& json){
    if(json.isEmpty())
        return;
    int i=0;
    QJsonObject::const_iterator itor = json.begin();
    while(itor != json.end()){
        if(i<_netParams.size()){
            _netParams[i]->fromJsonArray(itor.value().toArray());
        }else{
            GAirVideoNetworkParam* pm = new GAirVideoNetworkParam(itor.key(), itor.key(), this);
            pm->fromJsonArray(itor.value().toArray());
            _netParams.append(pm);
        }
        ++itor;
        ++i;
    }
    if(i < _netParams.size()){
        _netParams.resize(i);
    }
    emit netParamsChanged();
}

//SLOTS
void GAirVideoModule::onItTypeChanged(){
}
