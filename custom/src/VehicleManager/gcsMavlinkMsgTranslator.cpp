
#include "gcsMavlinkMsgTranslator.h"

GCSMavlinkMsgTranslator::GCSMavlinkMsgTranslator(QObject* parent)
    :QObject(parent)
{

}
GCSMavlinkMsgTranslator::~GCSMavlinkMsgTranslator(){
}

void GCSMavlinkMsgTranslator::translate(mavlink_message_t msg){
    tsMagic(msg.magic);
}

QString GCSMavlinkMsgTranslator::tsMagic(uint8_t magic){
    QString str("Mavlink ");
    ///0xFD == 254
    253 == magic ? str.append("v2.0\n") : str.append("v1.0\n");
    return str;
}
QString GCSMavlinkMsgTranslator::tsLen(uint8_t len){
    QString str(tr("length: "));
    str.append(QString::number(len));
    return str;
}
QString GCSMavlinkMsgTranslator::tsIncompat_flags(uint8_t iflag){
    QString str(tr("incompat: "));
    str.append(QString::number(iflag));
    return str;
}
QString GCSMavlinkMsgTranslator::tsCompat_flags(uint8_t cflag){
    QString str(tr("length: "));
    str.append(QString::number(cflag));
    return str;
}
QString GCSMavlinkMsgTranslator::tsSeq(uint8_t seq){
    QString str(tr("length: "));
    str.append(QString::number(seq));
    return str;
}
QString GCSMavlinkMsgTranslator::tsSysid(uint8_t sysid){
    QString str(tr("length: "));
    str.append(QString::number(sysid));
    return str;
}
QString GCSMavlinkMsgTranslator::tsCompid(uint8_t compip){
    QString str(tr("length: "));
    str.append(QString::number(compip));
    return str;
}
QString GCSMavlinkMsgTranslator::tsMsgid(uint32_t msgid){
    QString str(tr("length: "));
    str.append(QString::number(msgid));
    return str;
}
QString GCSMavlinkMsgTranslator::tsChecksum(uint16_t checksum){
    QString str(tr("length: "));
    str.append(QString::number(checksum));
    return str;
}
