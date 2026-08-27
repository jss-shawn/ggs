
#include <QtQml/qqml.h>

#include <GeographicLib/Constants.hpp>
#include <GeographicLib/Geocentric.hpp>
#include <GeographicLib/LocalCartesian.hpp>
#include <GeographicLib/MGRS.hpp>
#include <GeographicLib/UTMUPS.hpp>
#include "geoTool.h"

Q_LOGGING_CATEGORY(GeoToolLog,"GeoToolLog")

GeoTool::GeoTool(QObject* parent)
    :QObject(parent)
{

}

void GeoTool::geoToNed(const QGeoCoordinate &coord, const QGeoCoordinate &origin, double &x, double &y, double &z)
{
    if (coord == origin) {
        x = y = z = 0.0;
        return;
    }

    // Handle NaN altitude (QGeoCoordinate without altitude set)
    const double originAlt = std::isnan(origin.altitude()) ? 0.0 : origin.altitude();
    const double coordAlt = std::isnan(coord.altitude()) ? 0.0 : coord.altitude();

    double east, north, up;
    GeographicLib::LocalCartesian ltp(origin.latitude(), origin.longitude(), originAlt,
                                      GeographicLib::Geocentric::WGS84());
    ltp.Forward(coord.latitude(), coord.longitude(), coordAlt, east, north, up);

    // Convert ENU to NED
    x = north;
    y = east;
    z = -up;
}
void GeoTool::nedToGeo(double x, double y, double z, const QGeoCoordinate &origin, QGeoCoordinate &coord)
{
    // Convert NED to ENU
    const double east = y;
    const double north = x;
    const double up = -z;

    // Handle NaN altitude
    const double originAlt = std::isnan(origin.altitude()) ? 0.0 : origin.altitude();

    double lat, lon, alt;
    GeographicLib::LocalCartesian ltp(origin.latitude(), origin.longitude(), originAlt,
                                      GeographicLib::Geocentric::WGS84());
    ltp.Reverse(east, north, up, lat, lon, alt);

    coord.setLatitude(lat);
    coord.setLongitude(lon);
    coord.setAltitude(alt);
}

int GeoTool::geoToUTM(const QGeoCoordinate& coord, double &easting, double &northing){
    try {
        int zone = 0;
        bool northp = false;
        GeographicLib::UTMUPS::Forward(coord.latitude(), coord.longitude(), zone, northp, easting, northing);
        return zone;
    } catch(const GeographicLib::GeographicErr& e) {
        qCDebug(GeoToolLog) << Q_FUNC_INFO << e.what();
        return 0;
    }
}
bool GeoTool::utmToGeo(double easting, double northing, int zone, bool southhemi, QGeoCoordinate &coord){
    double lat = 0, lon = 0;
    try {
        GeographicLib::UTMUPS::Reverse(zone, !southhemi, easting, northing, lat, lon);
    } catch(const GeographicLib::GeographicErr& e) {
        qCDebug(GeoToolLog) << Q_FUNC_INFO << e.what();
        return false;
    }
    coord.setLatitude(lat);
    coord.setLongitude(lon);
    return true;
}

QString GeoTool::geoToMGRS(const QGeoCoordinate &coord){
    std::string mgrs;
    try {
        int zone = 0;
        bool northp = false;
        double x = 0, y = 0;
        GeographicLib::UTMUPS::Forward(coord.latitude(), coord.longitude(), zone, northp, x, y);
        GeographicLib::MGRS::Forward(zone, northp, x, y, coord.latitude(), 5, mgrs);
    } catch(const GeographicLib::GeographicErr& e) {
        qCDebug(GeoToolLog) << Q_FUNC_INFO << e.what();
        mgrs = "";
    }

    const QString qstr = QString::fromStdString(mgrs);
    for (int64_t i = qstr.length() - 1; i >= 0; i--) {
        if (!qstr.at(i).isDigit()) {
            const int64_t l = (qstr.length() - i) / 2;
            return qstr.left(i + 1) + " " + qstr.mid(i + 1, l) + " " + qstr.mid(i + 1 + l);
        }
    }
    return qstr;
}
bool GeoTool::mgrsToGeo(const QString &mgrs, QGeoCoordinate &coord){
    double lat = 0, lon = 0;
    try {
        int zone = 0, prec = 0;
        bool northp = false;
        double x = 0, y = 0;
        GeographicLib::MGRS::Reverse(mgrs.simplified().replace(" ", "").toStdString(), zone, northp, x, y, prec);
        GeographicLib::UTMUPS::Reverse(zone, northp, x, y, lat, lon);
    } catch(const GeographicLib::GeographicErr& e) {
        qCDebug(GeoToolLog) << Q_FUNC_INFO << e.what();
        return false;
    }
    coord.setLatitude(lat);
    coord.setLongitude(lon);
    return true;
}
