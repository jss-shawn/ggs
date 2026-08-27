
#pragma once

#include <QObject>
#include "TCPLink.h"
#include "UDPLink.h"

#ifdef QGC_ENABLE_BLUETOOTH
#include "BluetoothLink.h"
#endif

#ifndef NO_SERIAL_LINK
#include "SerialLink.h"
//#include "PositionManager.h"
//#include "UdpIODevice.h"
//#include "GPSRtk.h"
#endif

class GAirVideoModule;

class GModuleControl : public QObject
{
    Q_OBJECT
public:
    GModuleControl(QObject *parent = nullptr);

    void init();
    static void registerQmlTypes();

    Q_PROPERTY(int moduleIndex MEMBER _moduleIndex NOTIFY moduleIndexChanged FINAL)
    Q_PROPERTY(QList<QString> typeNames READ typeNames NOTIFY typeNamesChanged FINAL)
    Q_PROPERTY(LinkConfiguration* config READ config NOTIFY configChanged FINAL)
    Q_PROPERTY(LinkInterface* link READ link NOTIFY linkChanged FINAL)
    Q_PROPERTY(int linkState READ linkState NOTIFY linkStateChanged FINAL)
    Q_PROPERTY(GAirVideoModule* airVideoModule READ airVideoModule NOTIFY airVideoModuleChanged FINAL)

    Q_INVOKABLE void changeLinkType(int index);
    Q_INVOKABLE void reconnect();

    const QList<QString>& typeNames() { return _typeNames; }
    LinkConfiguration* config() { return _config; }
    LinkInterface* link() { return _link; }
    int linkState() { return _linkState; }
    GAirVideoModule* airVideoModule() { return _airVideoModule; }

signals:
    void moduleIndexChanged();
    void typeNamesChanged();
    void configChanged();
    void linkChanged();
    void linkStateChanged();
    void airVideoModuleChanged();
private slots:
    void onSendData(const QByteArray& data);
    void onReceiveData(LinkInterface *link, const QByteArray &data);
    void linkError(const QString &title, const QString &error);
private:
    void setLinkState(int state);

    QStringList _moduleNames;
    int _moduleIndex = 0;
    QList<QString> _typeNames;

    TCPConfiguration* _tcpConfig = nullptr;
    UDPConfiguration* _udpConfig = nullptr;
    SerialConfiguration* _serialConfig = nullptr;
    BluetoothConfiguration* _bluetoothConfig = nullptr;

    LinkConfiguration* _config = nullptr;
    LinkInterface* _link = nullptr;
    int _linkState = 0;

    GAirVideoModule* _airVideoModule = nullptr;

    const QList<QString> _allType = {
        tr("Serial"),
        tr("UDP"),
        tr("TCP"),
        tr("Bluetooth"),
    };
};
