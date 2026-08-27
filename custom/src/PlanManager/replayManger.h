
#pragma once

#include <QObject>
#include <QFile>
#include <QTimer>
#include "mavlink_types.h"

class ReplayManager: public QObject{
    Q_OBJECT
public:
    ReplayManager(QObject* parent = nullptr);
    ~ReplayManager();

    Q_INVOKABLE void loadFile(QString fileName);

signals:

private:
    quint64 _parseTimestamp(const QByteArray& bytes);
    bool getAllTimeStampMSec();
private:
    QFile _logFile;
    QTimer _timer;
    uint64_t _startTimeStamp = 0;
    QList<quint32> _timeStampMSecs;	//时间戳列表
    QList<quint32> _timeStampPos;	//时间戳对应的文件位置
    uint8_t _magic = 0xfd;
    static const int timestampByteLength = sizeof(quint64);
};
