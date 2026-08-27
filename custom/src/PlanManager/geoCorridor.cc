
#include <QLineF>
#include <QPointF>
#include "geoPoint.h"
#include "geoCorridor.h"

Q_LOGGING_CATEGORY(GeoCorridorLog, "GeoCorridorLog")

GeoCorridor::GeoCorridor(QString name, QObject* parent)
    :GeoShape(name, CORRIDOR, parent)
{
    init();
}

void GeoCorridor::init(){
    connect(this, &GeoCorridor::leftWidthChanged, this, &GeoCorridor::genPath);
    connect(this, &GeoCorridor::rightWidthChanged, this, &GeoCorridor::genPath);
    connect(this, &GeoCorridor::dragingChanged, this, &GeoCorridor::onDragingChanged);
}

void GeoCorridor::insert(QGeoCoordinate coord){
    GeoPoint *pt = new GeoPoint(coord, this);
    //默认在尾部添加
    int index = _keypointModel.count();
    //QGeoCoordinate center;
    if(_keypointModel.count() && _current){
        //当前顶点存在是添加在当前顶点后面
        index = _keypointModel.indexOf(_current) + 1;
    }
    _mids.insert(index, coord);
    _keypointModel.insert(index, pt);
    _current = pt;
    updateCenter();
    emit currentChanged();
    setPointNed(pt);
    genPath();
    connect(pt, &GeoPoint::coordChanged, this, &GeoCorridor::onCoordChanged, Qt::UniqueConnection);
}

void GeoCorridor::remove(GeoPoint* point){
    //默认删除最后一个顶点
    int index = _keypointModel.indexOf(point);
    QGeoCoordinate center;
    if(_keypointModel.count() > 1 && -1 != index){
        //删除当前顶点
        if(_current == point){
            //获取新顶点
            if(index+1 != _keypointModel.count()){
                _current = qobject_cast<GeoPoint*>(_keypointModel.get(index+1));
            }else{
                _current = qobject_cast<GeoPoint*>(_keypointModel.get(index-1));
            }
        }
    }
    _mids.removeAt(index);
    _keypointModel.removeAt(index);
    point->deleteLater();
    emit currentChanged();
    updateCenter();
    if(0 == index){
        setPointNed();
    }
    genPath();
}

void GeoCorridor::updateArea(){
    _area = 0;
    if(_valid){
        QGeoCoordinate origin = qobject_cast<GeoPoint*>(_keypointModel.get(0))->coord();
        QGeoCoordinate coord = qvariant_cast<QGeoCoordinate>(_path.last());
        double x = 0, y = 0, z = 0;
        _tool.geoToNed(coord, origin, x, y, z);
        QPointF last(x, y);
        for(int i=0; i<_path.size(); ++i){
            coord = qvariant_cast<QGeoCoordinate>(_path[i]);
            _tool.geoToNed(coord, origin, x, y, z);
            _area += last.x() * y - x * last.y();
            last.setX(x);
            last.setY(y);
        }
        _area = 0.5 * fabs(_area);
    }
}

void GeoCorridor::setLeftWidth(double width){
    if(width > 0 && _leftWidth != width){
        _leftWidth = width;
        emit leftWidthChanged();
    }
}

void GeoCorridor::setRightWidth(double width){
    if(width > 0 && _rightWidth != width){
        _rightWidth = width;
        emit rightWidthChanged();
    }
}

void GeoCorridor::set(const QList<QGeoCoordinate>& list){
    _mids.clear();
    _path.clear();
    _keypointModel.clearAndDeleteContents();
    GeoPoint *pt = nullptr;
    for(int i=0; i<list.size(); ++i){
        pt = new GeoPoint(list[i], this);
        _mids.append(list[i]);
        _path.append(QVariant::fromValue(list[i]));
        _keypointModel.insert(i, pt);
        connect(pt, &GeoPoint::coordChanged, this, &GeoCorridor::onCoordChanged, Qt::UniqueConnection);
    }
    _current = pt;
    updateCenter();
    emit currentChanged();
    setPointNed(pt);
    genPath();
}
bool GeoCorridor::offsetLine(bool inLeft, double width, QList<QGeoCoordinate>& final){
    GeoPoint *p1 = nullptr, *p2 = nullptr;
    double offset = 90, azi1 = 0;
    bool success = true;
    if(inLeft)
        offset = -90;
    if(_keypointModel.count() == 2){
        p1 = qobject_cast<GeoPoint*>(_keypointModel.get(0));
        p2 = qobject_cast<GeoPoint*>(_keypointModel.get(1));
        azi1 = p1->coord().azimuthTo(p2->coord());
        final.append(p1->coord().atDistanceAndAzimuth(width, azi1 + offset));
        final.append(p2->coord().atDistanceAndAzimuth(width, azi1 + offset));
    }else{
        QPointF point;
        QLineF l1, l2;
        QGeoCoordinate c1, c2, origin = qobject_cast<GeoPoint*>(_keypointModel.get(0))->coord();
        QList<QList<QGeoCoordinate>> cLines;
        double azi2 = 0, azi3 = 0, x = 0, y = 0, z = 0;
        //头节点,尾部延长width
        p1 = qobject_cast<GeoPoint*>(_keypointModel.get(0));
        p2 = qobject_cast<GeoPoint*>(_keypointModel.get(1));
        azi1 = p1->coord().azimuthTo(p2->coord());
        c1 = p1->coord().atDistanceAndAzimuth(width, azi1 + offset);
        c2 = p2->coord().atDistanceAndAzimuth(width, azi1 + offset);
        c2 = c2.atDistanceAndAzimuth(width, azi1);
        cLines.append({c1, c2});
        //中间节点,两端延长width
        for(int i=2; i<_keypointModel.count()-1; ++i){
            p1 = qobject_cast<GeoPoint*>(_keypointModel.get(i-1));
            p2 = qobject_cast<GeoPoint*>(_keypointModel.get(i));
            azi1 = p1->coord().azimuthTo(p2->coord());
            c1 = p1->coord().atDistanceAndAzimuth(width, azi1 + offset);
            c1 = c1.atDistanceAndAzimuth(width, azi1 + 180);
            c2 = p2->coord().atDistanceAndAzimuth(width, azi1 + offset);
            c2 = c2.atDistanceAndAzimuth(width, azi1);
            cLines.append({c1, c2});
        }
        //尾节点,头部延长width
        p1 = qobject_cast<GeoPoint*>(_keypointModel.get(_keypointModel.count()-2));
        p2 = qobject_cast<GeoPoint*>(_keypointModel.get(_keypointModel.count()-1));
        azi1 = p1->coord().azimuthTo(p2->coord());
        c1 = p1->coord().atDistanceAndAzimuth(width, azi1 + offset);
        c1 = c1.atDistanceAndAzimuth(width, azi1 + 180);
        c2 = p2->coord().atDistanceAndAzimuth(width, azi1 + offset);
        cLines.append({c1, c2});
        final.append(cLines.first().first());
        //计算交点,合并成一条线
        for(int i=1; i<cLines.size(); ++i){
            azi1 = cLines[i-1][1].azimuthTo(cLines[i-1][0]);
            azi2 = cLines[i][0].azimuthTo(cLines[i][1]);
            azi3 = azi2 - azi1;
            if(azi3 < 0){
                azi3 += 360;
            }
            if(inLeft){
                if(azi3 < 270){
                    //转换第一条线的坐标
                    _tool.geoToNed(cLines[i-1][0], origin, x, y, z);
                    l1.setP1({x, y});
                    _tool.geoToNed(cLines[i-1][1], origin, x, y, z);
                    l1.setP2({x, y});
                    //转换第一条线的坐标
                    _tool.geoToNed(cLines[i][0], origin, x, y, z);
                    l2.setP1({x, y});
                    _tool.geoToNed(cLines[i][1], origin, x, y, z);
                    l2.setP2({x, y});
                    //计算交点,转换成地理坐标,并入航线
                    if(QLineF::BoundedIntersection == l1.intersects(l2, &point)){
                        _tool.nedToGeo(point.x(), point.y(), 0, origin, c1);
                        final.append(c1);
                    }else{
                        success = false;
                        break;
                    }
                }else{
                    final.append(cLines[i-1][1]);
                    final.append(cLines[i][0]);
                }
            }else{
                if(azi3 > 90){
                    //转换第一条线的坐标
                    _tool.geoToNed(cLines[i-1][0], origin, x, y, z);
                    l1.setP1({x, y});
                    _tool.geoToNed(cLines[i-1][1], origin, x, y, z);
                    l1.setP2({x, y});
                    //转换第一条线的坐标
                    _tool.geoToNed(cLines[i][0], origin, x, y, z);
                    l2.setP1({x, y});
                    _tool.geoToNed(cLines[i][1], origin, x, y, z);
                    l2.setP2({x, y});
                    //计算交点,转换成地理坐标,并入航线
                    if(QLineF::BoundedIntersection == l1.intersects(l2, &point)){
                        _tool.nedToGeo(point.x(), point.y(), 0, origin, c1);
                        final.append(c1);
                    }else{
                        success = false;
                        break;
                    }
                }else{
                    final.append(cLines[i-1][1]);
                    final.append(cLines[i][0]);
                }
            }
        }
        final.append(cLines.last().last());
    }
    if(!success){
        final.clear();
        //inLeft ? qDebug()<<"左侧夹角过小" : qDebug()<<"右侧夹角过小";
    }
    return success;
}

void GeoCorridor::updateCenter(){
    QGeoCoordinate center;
    double dist = 0, azi = 0, total = 0;
    for(int i=1; i<_keypointModel.count(); ++i){
        total += qobject_cast<GeoPoint*>(_keypointModel.get(i-1))->coord().distanceTo(
                qobject_cast<GeoPoint*>(_keypointModel.get(i))->coord());
    }
    total /= 2;
    for(int i=1; i<_keypointModel.count(); ++i){
        dist = qobject_cast<GeoPoint*>(_keypointModel.get(i-1))->coord().distanceTo(
                qobject_cast<GeoPoint*>(_keypointModel.get(i))->coord());
        if(total > dist){
            total -= dist;
        }else{
            azi = qobject_cast<GeoPoint*>(_keypointModel.get(i-1))->coord().azimuthTo(
                        qobject_cast<GeoPoint*>(_keypointModel.get(i))->coord());
            center = qobject_cast<GeoPoint*>(_keypointModel.get(i-1))->coord().atDistanceAndAzimuth(total, azi);
            break;
        }
    }
    _center = center;
    //updateRalatives();
    disconnect(this , &GeoCorridor::centerOffset, this, &GeoCorridor::onCenterOffset);
    emit centerChanged();
    connect(this , &GeoCorridor::centerOffset, this, &GeoCorridor::onCenterOffset);
}
void GeoCorridor::updateRalatives(){
    _pathRalatives.clear();
    if(_center.isValid()){
        double dist = 0, azi = 0;
        for(int i=0; i<_keypointModel.count(); ++i){
            dist = _center.distanceTo(qobject_cast<GeoPoint*>(_keypointModel.get(i))->coord());
            azi = _center.azimuthTo(qobject_cast<GeoPoint*>(_keypointModel.get(i))->coord());
            _pathRalatives.append({dist, azi});
        }
    }
}
void GeoCorridor::setPointNed(GeoPoint *pt){
    if(_keypointModel.count()){
        GeoPoint *ori = qobject_cast<GeoPoint*>(_keypointModel.get(0));
        GeoPoint *ver = nullptr;
        double x = 0, y = 0, z = 0;
        if(pt && pt != ori){
            _tool.geoToNed(pt->coord(), ori->coord(), x, y, z);
            pt->setNedPoint(QPointF(x, y));
            _mids[_keypointModel.indexOf(pt)] = pt->coord();
        }else{
            for(int i=0; i<_keypointModel.count(); ++i){
                ver = qobject_cast<GeoPoint*>(_keypointModel.get(i));
                _mids[i] = ver->coord();
                _tool.geoToNed(ver->coord(), ori->coord(), x, y, z);
                ver->setNedPoint(QPointF(x, y));
            }
        }
    }
}

//SLOTS
void GeoCorridor::genPath(){
    _path.clear();
    bool valid = false;
    GeoPoint* point = qobject_cast<GeoPoint*>(sender());
    if(point){
        setPointNed(point);
    }
    if(_keypointModel.count() > 1 && (_leftWidth > 0.5 || _rightWidth > 0.5)){
        QList<QGeoCoordinate> left, right;
        bool leftSuccess = true, rightSuccess = true;
        if(_leftWidth > 0){
            leftSuccess = offsetLine(true, _leftWidth, left);
        }
        if(_rightWidth > 0){
            rightSuccess = offsetLine(false, _rightWidth, right);
        }
        if((left.size() || right.size()) && leftSuccess && rightSuccess){
            if(left.isEmpty()){
                left = _mids;
            }
            if(right.isEmpty()){
                right = _mids;
            }
            for(int i=0; i<left.size(); ++i){
                _path.append(QVariant::fromValue(left[i]));
            }
            for(int i=right.size()-1; i>=0; --i){
                _path.append(QVariant::fromValue(right[i]));
            }
            valid = true;
        }
    }
    setValid(valid);
    updateArea();
    emit pathChanged();
}
void GeoCorridor::onCoordChanged(){
    GeoPoint* point = qobject_cast<GeoPoint*>(sender());
    if(point){
        updateCenter();
        setPointNed(point);
        genPath();
    }
}
void GeoCorridor::onCenterOffset(double dist, double azim){
    GeoPoint *vertex = nullptr;
    for(int i=0; i<_keypointModel.count(); ++i){
        vertex = qobject_cast<GeoPoint*>(_keypointModel.get(i));
        vertex->setCoord(vertex->coord().atDistanceAndAzimuth(dist, azim));
        //vertex->setCoord(_center.atDistanceAndAzimuth(_pathRalatives[i][0], _pathRalatives[i][1]));
        _mids[i] = vertex->coord();
        _path[i] = QVariant::fromValue(vertex->coord());
    }
    genPath();
    emit pathChanged();
}
void GeoCorridor::onDragingChanged(){
    GeoPoint *vertex = nullptr;
    for(int i=0; i<_keypointModel.count(); ++i){
        vertex = qobject_cast<GeoPoint*>(_keypointModel.get(i));
        if(_draging)
            disconnect(vertex, &GeoPoint::coordChanged, this, &GeoCorridor::onCoordChanged);
        else
            connect(vertex, &GeoPoint::coordChanged, this, &GeoCorridor::onCoordChanged, Qt::UniqueConnection);
    }
}
