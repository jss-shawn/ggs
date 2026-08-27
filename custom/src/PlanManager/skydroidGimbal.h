
#pragma once

#include <QObject>
#include "LinkInterface.h"

class UDPConfiguration;

class SkydroidGimbal : public QObject{
    Q_OBJECT
public:
    enum Action{
        Reset = 0,
        SetM,
        SetW,
        TurnUp,
        TurnLeft,
        TurnRight,
        TurnDown,
        ReadPTZ,
    };
    Q_ENUM(Action)

    SkydroidGimbal(QObject* parent = nullptr);
    ~SkydroidGimbal();

    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged FINAL)
    Q_PROPERTY(QString cmd READ cmd NOTIFY cmdChanged FINAL)

    Q_INVOKABLE void conn();
    Q_INVOKABLE void disc();
    Q_INVOKABLE void doAction(uint8_t act);
    Q_INVOKABLE void custom(const QString& cmd);

    bool connected() { return _linkState; }
    QString cmd() { return _cmd; }

    char calcCrc(const char* data, int length);
signals:
    void connectedChanged();
    void cmdChanged();
private slots:
    void receiveBytes(LinkInterface *link, const QByteArray &data);
    void logSentBytes(LinkInterface *link, const QByteArray &data);
    void linkConnected();
    void linkDisconnected();
private:
    QString _cmd;
    UDPConfiguration* _udp = nullptr;
    SharedLinkInterfacePtr _link;
    bool _linkState = false;
};