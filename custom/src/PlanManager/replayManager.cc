
#include <QtEndian>
#include <QDateTime>
#include <QElapsedTimer>
#include "replayManger.h"

ReplayManager::ReplayManager(QObject* parent)
    :QObject(parent)
{

}
ReplayManager::~ReplayManager(){
}

quint64 ReplayManager::_parseTimestamp(const QByteArray& bytes){
    quint64 timestamp = qFromBigEndian(*((quint64*)(bytes.constData())));
    quint64 currentTimestamp = ((quint64)QDateTime::currentMSecsSinceEpoch()) * 1000;
    // Now if the parsed timestamp is in the future, it must be an old file where the timestamp was stored as
    // little endian, so switch it.
    if (timestamp > currentTimestamp) {
        timestamp = qbswap(timestamp);
    }
    return timestamp;
}
void ReplayManager::loadFile(QString fileName){
    if(_logFile.fileName() != fileName){
        if(_logFile.isOpen()){
            _logFile.close();
        }
        _logFile.setFileName(fileName);
    }
    if(!_logFile.isOpen()){
        if (!_logFile.open(QFile::ReadOnly)) {
            return;
        }
    }
    getAllTimeStampMSec();
}

bool ReplayManager::getAllTimeStampMSec(){
    _logFile.reset();
    _timeStampPos.clear();
    _timeStampMSecs.clear();
    //开始读取时间戳
    bool first = true;
    char byte;
    uint32_t len = 0;
    quint64 timeStamp = 0;
    QElapsedTimer time;
    time.start();
    while(_logFile.bytesAvailable()){
        timeStamp = _parseTimestamp(_logFile.read(timestampByteLength)) / 1000 - _startTimeStamp;
        if(first) {
            _startTimeStamp = timeStamp;
            timeStamp = 0;
        }
        if(first || (!first && _timeStampMSecs.last() != timeStamp)){
            _timeStampPos.append(_logFile.pos() - timestampByteLength);
            _timeStampMSecs.append(timeStamp);
        }
        _logFile.getChar(&byte);
        if(first){
            _magic = byte;
            first = false;
        }else{
            if((uint8_t)byte != _magic){
                qDebug()<<_logFile.bytesAvailable();
                qDebug()<<"文件格式错误, 无法读取到消息头";
                return false;
            }
        }
        _logFile.getChar(&byte);
        len = (uint8_t)byte;
        len += 10;
        _logFile.seek(_logFile.pos() + len);
    }
    qDebug()<<(double)_timeStampMSecs.last() / 1000;
    qDebug()<<(double)time.elapsed() / 1000;
    return true;
}
