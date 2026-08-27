
#include <QLineF>
#include <QPolygonF>
#include "clipper.h"
#include "geoPoint.h"
#include "geoPolygon.h"

GeoPolygon::GeoPolygon(QString name, QObject* parent)
    :GeoShape(name, ShapeType::POLYGON, parent)
{
    init();
}

void GeoPolygon::init(){
    connect(this, &GeoPolygon::dragingChanged, this, &GeoPolygon::onDragingChanged);
}

void GeoPolygon::insert(QGeoCoordinate coord){
    GeoPoint *pt = new GeoPoint(coord, this);
    //默认在尾部添加
    int index = _keypointModel.count();
    if(_keypointModel.count() && _current){
        //当前顶点存在是添加在当前顶点后面
        index = _keypointModel.indexOf(_current) + 1;
    }
    _path.insert(index, QVariant::fromValue(coord));
    _keypointModel.insert(index, pt);
    _current = pt;
    onKeyCoordChanged();
    emit currentChanged();
    connect(pt, &GeoPoint::coordChanged, this, &GeoPolygon::onKeyCoordChanged, Qt::UniqueConnection);
}
void GeoPolygon::remove(GeoPoint* point){
    //默认删除最后一个顶点
    int index = _keypointModel.indexOf(point);
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
    _path.removeAt(index);
    _keypointModel.removeAt(index);
    point->deleteLater();
    onKeyCoordChanged();
    emit currentChanged();
}
void GeoPolygon::setExpand(double expand){
    if(expand >= 0.0 && qAbs(_expand - expand) > 0.01){
        _expand = expand;
        genFramePolygon();
        emit expandChanged();
        emit pathChanged();
    }
}
void GeoPolygon::set(const QList<QGeoCoordinate>& vertexs){
    _path.clear();
    _keypointModel.clearAndDeleteContents();
    GeoPoint *pt = nullptr;
    for(int i=0; i<vertexs.size(); ++i){
        pt = new GeoPoint(vertexs[i], this);
        _keypointModel.append(pt);
        _path.append(QVariant::fromValue(vertexs[i]));
        connect(pt, &GeoPoint::coordChanged, this, &GeoPolygon::onKeyCoordChanged, Qt::UniqueConnection);
    }
    _current = pt;
    onKeyCoordChanged();
    emit currentChanged();
}
void GeoPolygon::set(GeoPolygon* polygon){
    setName(polygon->_name);
    _keypointModel.clearAndDeleteContents();
    _path.clear();
    GeoPoint *pt = nullptr;
    for(int i=0; i<polygon->_keypointModel.count(); ++i){
        pt = new GeoPoint(qobject_cast<GeoPoint*>(polygon->_keypointModel.get(i))->coord(), this);
        connect(pt, &GeoPoint::coordChanged, this, &GeoPolygon::onKeyCoordChanged, Qt::UniqueConnection);
        _keypointModel.append(pt);
        _path.append(QVariant::fromValue(pt->coord()));
    }
    onKeyCoordChanged();
    _current = pt;
    emit currentChanged();
}

void GeoPolygon::genFramePolygon(){
    _frame.clear();
    _frameRalatives.clear();
    if(_valid && _expand > 0.5){
        //精度放大倍数
        int multi = 1000;
        double x = 0, y = 0, z = 0;
        GeoPoint *vertex = nullptr;
        //获取多边形顶点在屏幕的坐标
        QtClipperLib::IntPoint pt;
        QtClipperLib::Path polygonVertex;
        for(int i=0; i<_keypointModel.count(); ++i){
            vertex = qobject_cast<GeoPoint*>(_keypointModel.get(i));
            pt.X = vertex->nedPoint().x() * multi;
            pt.Y = vertex->nedPoint().y() * multi;
            polygonVertex.push_back(pt);
        }
        //根据当前多边形生成外框
        QtClipperLib::ClipperOffset offset;
        QtClipperLib::Paths polygons;
        offset.AddPath(polygonVertex, QtClipperLib::jtSquare, QtClipperLib::etClosedPolygon);
        offset.Execute(polygons, _expand * multi);
        //将外框坐标精度还原后转换为经纬度,
        QGeoCoordinate coord;
        if(polygons.size()){
            for(quint64 i=0; i<polygons[0].size(); ++i){
                x = 1.0 * polygons[0][i].X / multi;
                y = 1.0 * polygons[0][i].Y / multi;
                _tool.nedToGeo(x, y , z, qobject_cast<GeoPoint*>(_keypointModel.get(0))->coord(), coord);
                _frame.append(coord);
            }
        }
    }
    //emit frameChanged();
}

void GeoPolygon::calcCenter(){
    GeoPoint *vertex = nullptr;
    double dist = 0, azi = 0, x = 0, y = 0, z = 0;
    QGeoCoordinate center, from, to;
    if(_keypointModel.count() > 2){
        QGeoCoordinate origin = qobject_cast<GeoPoint*>(_keypointModel.get(0))->coord();
        //计算重心
        QPointF rcenter(0,0), gcenter(0,0);
        QPolygonF polygon;
        for(int i=0; i<_keypointModel.count(); ++i){
            vertex = qobject_cast<GeoPoint*>(_keypointModel.get(i));
            polygon.append(vertex->nedPoint());
            gcenter += vertex->nedPoint();
        }
        x = gcenter.x() / _keypointModel.count();
        y = gcenter.y() / _keypointModel.count();
        gcenter = QPointF(x, y);
        _tool.nedToGeo(x, y, z, origin, to);
        if(polygon.containsPoint(gcenter, Qt::OddEvenFill)){
            //重心在多边形内部
            center = to;
        }else{
            //计算外接矩形中心
            QRectF rect = polygon.boundingRect();
            rcenter = rect.center();
            _tool.nedToGeo(rcenter.x(), rcenter.y(), z, origin, from);
            if(polygon.containsPoint(rcenter, Qt::OddEvenFill)){
                center = from;
            }else{
                //重心在多边形内部
                //计算矩形中心到对角的长度
                _tool.nedToGeo(rect.x(), rect.y(), z, origin, center);
                dist = from.distanceTo(center);
                azi = from.azimuthTo(to);
                //计算中心点偏移线
                to = from.atDistanceAndAzimuth(dist, azi);
                _tool.geoToNed(to, origin, x, y, z);
                QLineF line(rcenter, QPointF(x, y));
                QPointF crossPoint;
                QList<QPointF> cross;
                //计算与多边形的交点并取中点
                for(int i=0; i<polygon.size(); ++i){
                    QLineF side(polygon[i], polygon[(i+1)%polygon.size()]);
                    if(QLineF::BoundedIntersection == line.intersects(side, &crossPoint)){
                        cross.append(crossPoint);
                    }
                }
                if(cross.size() < 2){
                    cross.clear();
                    to = from.atDistanceAndAzimuth(dist, azi + 180);
                    _tool.geoToNed(to, origin, x, y, z);
                    line.setP2(QPointF(x, y));
                    for(int i=0; i<polygon.size(); ++i){
                        QLineF side(polygon[i], polygon[(i+1)%polygon.size()]);
                        if(QLineF::BoundedIntersection == line.intersects(side, &crossPoint)){
                            cross.append(crossPoint);
                        }
                    }
                }
                crossPoint = QLineF(cross[0], cross[1]).center();
                _tool.nedToGeo(crossPoint.x(), crossPoint.y(), z, origin, center);
            }
        }
        // _pathRalatives.clear();
        // for(int i=0; i<_keypointModel.count(); ++i){
        //     vertex = qobject_cast<GeoPoint*>(_keypointModel.get(i));
        //     dist = center.distanceTo(vertex->coord());
        //     azi = center.azimuthTo(vertex->coord());
        //     _pathRalatives.append({dist, azi});
        // }
    }
    disconnect(this , &GeoPolygon::centerOffset, this, &GeoPolygon::onCenterOffset);
    _center = center;
    emit centerChanged();
    connect(this , &GeoPolygon::centerOffset, this, &GeoPolygon::onCenterOffset);
}



void GeoPolygon::updatePointNed(GeoPoint *pt){
    if(_keypointModel.count()){
        GeoPoint *ori = qobject_cast<GeoPoint*>(_keypointModel.get(0));
        GeoPoint *ver = nullptr;
        double x = 0, y = 0, z = 0;
        if(pt && pt != ori){
            _tool.geoToNed(pt->coord(), ori->coord(), x, y, z);
            pt->setNedPoint(QPointF(x, y));
        }else{
            for(int i=0; i<_keypointModel.count(); ++i){
                ver = qobject_cast<GeoPoint*>(_keypointModel.get(i));
                _tool.geoToNed(ver->coord(), ori->coord(), x, y, z);
                ver->setNedPoint(QPointF(x, y));
            }
        }
    }
}

void GeoPolygon::checkValid(){
    bool valid = false;
    if(_keypointModel.count() > 2){
        valid = true;
        if(_keypointModel.count() > 3){
            int size = _keypointModel.count();
            GeoPoint *p1 = nullptr;
            GeoPoint *p2 = nullptr;
            QList<QLineF> side;
            for(int i=0; i<size; ++i){
                p1 = qobject_cast<GeoPoint*>(_keypointModel.get(i));
                p2 = qobject_cast<GeoPoint*>(_keypointModel.get((i+1)%size));
                side.append(QLineF(p1->nedPoint(), p2->nedPoint()));
            }
            for(int i=0; i<side.size()-1; ++i){
                int times = size - 3, j = i + 2;
                while(times--){
                    if(QLineF::BoundedIntersection == side[i].intersects(side[(j++)%size])){
                        valid = false;
                        break;
                    }
                }
            }
        }
    }
    setValid(valid);
}

//SLOTS
void GeoPolygon::onKeyCoordChanged(){
    if(!_draging){
        GeoPoint* point = qobject_cast<GeoPoint*>(sender());
        updatePointNed(point);
        checkValid();
        if(point){
            int idx = _keypointModel.indexOf(point);
            _path[idx] = QVariant::fromValue(point->coord());
        }
        calcCenter();
        genFramePolygon();
        updateArea();
        _needUpdate = true;
    }
    if(_canUpdate){
        _needUpdate = false;
        emit pathChanged();
    }
}
void GeoPolygon::onCenterOffset(double dist, double azim){
    GeoPoint *vertex = nullptr;
    for(int i=0; i<_keypointModel.count(); ++i){
        vertex = qobject_cast<GeoPoint*>(_keypointModel.get(i));
        vertex->setCoord(vertex->coord().atDistanceAndAzimuth(dist, azim));
        //vertex->setCoord(_center.atDistanceAndAzimuth(_pathRalatives[i][0], _pathRalatives[i][1]));
        _path[i] = QVariant::fromValue(vertex->coord());
    }
    if(_frame.size()){
        for(int i=0; i<_frame.size(); ++i){
            _frame[i] = _frame[i].atDistanceAndAzimuth(dist, azim);
            //_frame[i] = _center.atDistanceAndAzimuth(_frameRalatives[i][0], _frameRalatives[i][1]);
        }
    }
    _needUpdate = true;
    if(_canUpdate){
        _needUpdate = false;
        emit pathChanged();
    }
}

void GeoPolygon::onDragingChanged(){
    GeoPoint *vertex = nullptr;
    for(int i=0; i<_keypointModel.count(); ++i){
        vertex = qobject_cast<GeoPoint*>(_keypointModel.get(i));
        if(_draging)
            disconnect(vertex, &GeoPoint::coordChanged, this, &GeoPolygon::onKeyCoordChanged);
        else{
            connect(vertex, &GeoPoint::coordChanged, this, &GeoPolygon::onKeyCoordChanged, Qt::UniqueConnection);
        }
    }
}
