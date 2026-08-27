
#pragma once

#include <QObject>
#include <QMap>

class GAirVideoSerialParam: public QObject
{
    Q_OBJECT
public:
    Q_PROPERTY(QString name MEMBER _name CONSTANT)
    Q_PROPERTY(int baud MEMBER _baud CONSTANT)
    Q_PROPERTY(int bit MEMBER _bit CONSTANT)
    Q_PROPERTY(int parity MEMBER _parity CONSTANT)
    Q_PROPERTY(int stop MEMBER _stop CONSTANT)
    Q_PROPERTY(int hwFC MEMBER _hwFC CONSTANT)
    Q_PROPERTY(int rx MEMBER _rx CONSTANT)
    Q_PROPERTY(int tx MEMBER _tx CONSTANT)
    Q_PROPERTY(QVariantList data MEMBER _data NOTIFY dataChanged FINAL)

    explicit GAirVideoSerialParam(const QString& name, const QString& shortName, QObject *parent = nullptr);

    Q_INVOKABLE void checkData(int index, const QVariant& data);

    void fromJsonArray(const QJsonArray& array, int type);
    void toJsonArray(QJsonArray& array);
signals:
    void dataChanged();
public:
    QString _name;
    QString _shortName;
    int _baud = 1;
    int _bit = 1;
    int _parity = 1;
    int _stop = 1;
    int _hwFC = 1;	//hardware flow control
    int _rx = 1;
    int _tx = 1;
    QVariantList _data;
};

class GAirVideoNetworkParam : public QObject
{
    Q_OBJECT
public:
    Q_PROPERTY(QString name MEMBER _name CONSTANT)
    Q_PROPERTY(QString host MEMBER _host CONSTANT)
    Q_PROPERTY(quint16 port MEMBER _port CONSTANT)
    Q_PROPERTY(quint16 listen MEMBER _listen CONSTANT)
    Q_PROPERTY(quint16 clientLimit MEMBER _clientLimit CONSTANT)
    Q_PROPERTY(QVariantList data MEMBER _data NOTIFY dataChanged FINAL)

    explicit GAirVideoNetworkParam(const QString& name, const QString& shortName, QObject *parent = nullptr);

    QString shortName() const { return _shortName; }

    Q_INVOKABLE void checkData(int index, const QVariant& data);

    void fromJsonArray(const QJsonArray& array);
    void toJsonArray(QJsonArray& array);
signals:
    void dataChanged();
public:
    QString _name;
    QString _shortName;
    QString _host;
    quint16 _port = 0;
    quint16 _listen = 0;
    quint16 _clientLimit = 0;
    QVariantList _data;
};

class GAirVideoModule : public QObject
{
    Q_OBJECT
public:
    explicit GAirVideoModule(QObject *parent = nullptr);

    void init();
    static void registerQmlTypes();
    Q_INVOKABLE static bool splitAddress(QString address, QList<QString>& parts);

    Q_PROPERTY(QList<QString> dataLog READ dataLog NOTIFY dataLogChanged FINAL)
    Q_PROPERTY(QString host READ host WRITE setHost NOTIFY hostChanged FINAL)
    Q_PROPERTY(QString mask READ mask WRITE setMask NOTIFY maskChanged FINAL)
    Q_PROPERTY(QList<int> pwm READ pwm NOTIFY pwmChanged FINAL)
    Q_PROPERTY(QList<int> fss READ fss NOTIFY fssChanged FINAL)
    Q_PROPERTY(QList<int> fsv READ fsv NOTIFY fsvChanged FINAL)
    Q_PROPERTY(QList<int> pid READ pid NOTIFY pidChanged FINAL)
    Q_PROPERTY(QList<int> brd READ brd NOTIFY brdChanged FINAL)
    Q_PROPERTY(bool fse READ fse WRITE setFse NOTIFY fseChanged FINAL)
    Q_PROPERTY(double flt READ flt WRITE setFlt NOTIFY fltChanged FINAL)
    Q_PROPERTY(int itType READ itType WRITE setItType NOTIFY itTypeChanged FINAL)
    Q_PROPERTY(QList<GAirVideoSerialParam*> serialParams READ serialParams NOTIFY serialParamsChanged FINAL)
    Q_PROPERTY(QList<GAirVideoNetworkParam*> netParams READ netParams NOTIFY netParamsChanged FINAL)

    const QList<QString>& dataLog() { return _dataLog; }
    QString host() { return _host; }
    QString mask() { return _mask; }
    QList<int> pwm() { return _pwm; }
    QList<int> fss() { return _fss; }
    QList<int> fsv() { return _fsv; }
    QList<int> pid() { return _pid; }
    QList<int> brd() { return _brd; }
    bool fse() { return _fse; }
    double flt() { return _flt; }
    int itType() { return _itType; }
    QList<GAirVideoSerialParam*> serialParams() { return _serialParams; }
    QList<GAirVideoNetworkParam*> netParams() { return _netParams; }

    Q_INVOKABLE void clearLog();
    Q_INVOKABLE void setPwm(int index, int value);
    Q_INVOKABLE void setFss(int index, int value);
    Q_INVOKABLE void setFsv(int index, int value);
    Q_INVOKABLE void setPid(int index, int value);
    Q_INVOKABLE void setBrd(int index, int value);
    Q_INVOKABLE void getParam(int cmd);
    Q_INVOKABLE void setParam(int cmd);

    void setHost(QString host);
    void setMask(QString mask);
    void setFse(bool fse);
    void setFlt(int flt);
    void setItType(int itType);
    bool isJsonFile(const QByteArray& bytes, QJsonDocument& jsonDoc, QString& errorString);

    void handleData(const QByteArray& data);
private:
    void _handleHost(const QJsonArray& array);
    void _handlePwm(const QJsonArray& array);
    void _handleFss(const QJsonArray& array);
    void _handleFsv(const QJsonArray& array);
    void _handlePid(const QJsonArray& array);
    void _handleBrd(const QJsonArray& array);
    void _handleSerialParam(const QJsonObject& json);
    void _handleNetParam(const QJsonObject& json);
signals:
    void dataLogChanged();
    void hostChanged();
    void maskChanged();
    void pwmChanged();
    void fssChanged();
    void fsvChanged();
    void pidChanged();
    void brdChanged();
    void fseChanged();
    void fltChanged();
    void itTypeChanged();
    void serialParamsChanged();
    void netParamsChanged();
    void sendData(const QByteArray& data);
private slots:
    void onItTypeChanged();
private:
    QList<QString> _dataLog;

    QList<GAirVideoSerialParam*> _serialParams;
    QList<GAirVideoNetworkParam*> _netParams;
    QString _host;
    QString _mask;
    QList<int> _pwm;
    QList<int> _fss;
    QList<int> _fsv;
    QList<int> _pid;
    QList<int> _brd;
    bool _fse = false;
    double _flt = 0.0;
    int _itType = 1;
    QList<QList<QString>> _portNames = { {"Datalink", "dlnk"}
        ,{"Device", "dev"}
        ,{"RS485", "rs485"}
        ,{"Radio_uart", "radio"}
        ,{"Radio_dbg", "dbg"}
        ,{"S.BUS", "sbs"}
    };
    QMap<int, QString> _cmdList = {
        {7, "host"}
        ,{11, "pwm"}
        ,{12, "fse"}
        ,{15, "fss"}
        ,{16, "fsv"}
        ,{17, "serialParam"}
        ,{18, "netParam"}
        ,{19, "flt"}
        ,{20, "flpid"}
        ,{21, "brd_cfg"}
    };
};
