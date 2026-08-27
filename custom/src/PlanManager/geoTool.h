
#pragma once

#include <QObject>
#include <QtCore/QLoggingCategory>
#include <QtPositioning/QGeoCoordinate>

Q_DECLARE_LOGGING_CATEGORY(GeoToolLog)

class GeoTool: public QObject
{
    Q_OBJECT
public:
    GeoTool(QObject* parent = nullptr);

    void geoToNed(const QGeoCoordinate &coord, const QGeoCoordinate &origin, double &x, double &y, double &z);
    void nedToGeo(double x, double y, double z, const QGeoCoordinate &origin, QGeoCoordinate &coord);

    int geoToUTM(const QGeoCoordinate& coord, double &easting, double &northing);
    bool utmToGeo(double easting, double northing, int zone, bool southhemi, QGeoCoordinate &coord);

    QString geoToMGRS(const QGeoCoordinate &coord);
    bool mgrsToGeo(const QString &mgrs, QGeoCoordinate &coord);
private:
    double _epsilon = std::numeric_limits<double>::epsilon();
};
