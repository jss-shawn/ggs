
#pragma once

#include <QObject>
#include "mavlink_types.h"

class GCSMavlinkMsgTranslator: public QObject{
    Q_OBJECT
public:
    GCSMavlinkMsgTranslator(QObject* parent = nullptr);
    ~GCSMavlinkMsgTranslator();

    void translate(mavlink_message_t msg);
signals:
private:
    QString tsMagic(uint8_t magic);
    QString tsLen(uint8_t magic);
    QString tsIncompat_flags(uint8_t magic);
    QString tsCompat_flags(uint8_t magic);
    QString tsSeq(uint8_t magic);
    QString tsSysid(uint8_t magic);
    QString tsCompid(uint8_t magic);
    QString tsMsgid(uint32_t magic);
    QString tsChecksum(uint16_t magic);
private:
    QString _tr;
    QString _magic;          ///< protocol magic marker
    QString _len;            ///< Length of payload
    QString _incompat_flags; ///< flags that must be understood
    QString _compat_flags;   ///< flags that can be ignored if not understood
    QString _seq;            ///< Sequence of packet
    QString _sysid;          ///< ID of message sender system/aircraft
    QString _compid;         ///< ID of the message sender component
    QString _msgid;      ///< ID of message in payload
    QString _checksum;      ///< sent at end of packet
    QString _signature;

    QString _payload64;
};
