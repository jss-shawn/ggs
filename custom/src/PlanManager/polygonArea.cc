
#include <QLineF>
#include <QPolygonF>
#include <QThread>
#include "TerrainQuery.h"
#include "geoLine.h"
#include "geoPoint.h"
#include "polygonArea.h"

PolygonArea::PolygonArea(QObject *parent)
    :SurveyArea(parent)
    ,_tool(this)
    ,_polygon("Polygon", this)
{
    init();
}
PolygonArea::PolygonArea(QString name, QObject *parent)
    :SurveyArea(parent)
    ,_tool(this)
    ,_polygon(name, this)
{
    init();
}
PolygonArea::~PolygonArea(){
}

void PolygonArea::init(){
    connect(&_setup, &SurveySetup::setupChanged, this, &PolygonArea::genVirtualPath);
    connect(&_polygon, &GeoPolygon::pathChanged, this, &PolygonArea::genVirtualPath);
    connect(&_polygon, &GeoPolygon::centerOffset, this, &PolygonArea::dragPath);
    connect(_setup.camera()->distanceToSurface(), &Fact::rawValueChanged, this, &SurveyArea::checkSafety);
    connect(_setup.camera()->altMode(), &Fact::rawValueChanged, this, &SurveyArea::checkSafety);
    connect(this, &PolygonArea::showAllWaypointChanged, this, &PolygonArea::updateWaypoint);
}
void PolygonArea::save(QJsonArray& array, const QString& suffix){
    QJsonObject item;
    if("jplan" == suffix){
        QmlObjectListModel* model = _polygon.keypointModel();
        QJsonArray coords;
        GeoPoint* point = nullptr;
        for(int i=0; i<model->count(); ++i){
            point = qobject_cast<GeoPoint*>(model->get(i));
            QJsonArray coord;
            coord.append(point->coord().latitude());
            coord.append(point->coord().longitude());
            coords.append(coord);
        }
        item["coords"] = coords;
        item["angle"] = _setup.routeAzimuth();
        item["expand"] = _polygon.expand();
        item["frontDistance"] = _setup.camera()->adjustedFootprintFrontal()->rawValue().toDouble();
        item["sideDistance"] = _setup.camera()->adjustedFootprintSide()->rawValue().toDouble();
        item["Altitude"] = _setup.camera()->distanceToSurface()->rawValue().toDouble();
        item["ModeIndex"] = _setup.camera()->altMode()->enumIndex();
        array.append(item);
    }else if("plan" == suffix){
        saveWaypoint(array);
    }
}
void PolygonArea::load(const QJsonObject& node){
    QList<QGeoCoordinate> coords;
    const QJsonArray& array = node["coords"].toArray();
    for(int i=0; i<array.size(); ++i){
        coords.append(QGeoCoordinate(array[i][0].toDouble(), array[i][1].toDouble()));
    }
    _setup.setRouteAzimuth(node["angle"].toDouble());
    _setup.camera()->adjustedFootprintFrontal()->setRawValue(node["frontDistance"].toDouble());
    _setup.camera()->adjustedFootprintSide()->setRawValue(node["sideDistance"].toDouble());
    _setup.camera()->distanceToSurface()->setRawValue(node["Altitude"].toDouble());
    _setup.camera()->altMode()->setEnumIndex(node["ModeIndex"].toInt());
    _polygon.setExpand(node["expand"].toDouble());
    _polygon.set(coords);
}
void PolygonArea::checkSafety(){
    _safety = -1;
    //if(_path.size()){
    if(_checkPath.size()){
        updateAmsls();
        //计算安全性
        double altDiff = 0, dist = 0, slope = 0, beg = 0;
        _safety = 1;
        for(int i=1; i<_srcIndex.size(); ++i){
            int fromIndex = _srcIndex[i-1], toIndex = _srcIndex[i];
            beg = _waypoints[i-1]->amsl();
            altDiff = _waypoints[i]->amsl() - beg;
            dist = _checkPath[fromIndex].distanceTo(_checkPath[toIndex]);
            slope = altDiff / dist;
            for(int j=fromIndex; j<=toIndex-1; ++j){
                double check = _checkPath[j].altitude();
                double alt = (beg + slope * (j - fromIndex)*_checkMeter);
                if(check >= alt){
                    _safety = 0;
                    break;
                }
            }
        }
        if(_checkPath.last().altitude() >= _waypoints.last()->amsl()){
            _safety = 0;
        }
    }
    emit safetyChanged();
}
void PolygonArea::clear(){
    if(_showInfoModel.count()){
        _showInfoModel.clear();
    }
    _notEmpty = false;
    _valid = false;
    _pathSize = 0;
    _frameVertexs.clear();
    _framePolygon.clear();
    _virtualPath.clear();
    _realPath.clear();
    _keyPoints.clear();
    _checkPath.clear();
    _srcIndex.clear();
    _path.clear();
    emit pathChanged();
    emit validChanged();
}
QPolygonF PolygonArea::boundRect(const QPolygonF& polygon, double expand){
    double x = 0, y = 0, minx = 0, miny = 0, maxx = 0, maxy = 0;
    for(int i=0; i<polygon.size(); ++i){
        x = polygon.at(i).x();
        y = polygon.at(i).y();
        if(x < minx) minx = x;
        if(x > maxx) maxx = x;
        if(y < miny) miny = y;
        if(y > maxy) maxy = y;
    }
    return {QPointF(minx - expand, miny - expand),
            QPointF(minx - expand, maxy + expand),
            QPointF(maxx + expand, maxy + expand),
            QPointF(maxx + expand, miny - expand)};
}
void PolygonArea::genRealPath(){
    _realPath.clear();
    _keyPoints.clear();
    QPolygonF polygon;
    QPointF intersect;
    QGeoCoordinate intersectCoor;
    int segmentNumber = 0;
    QList<QLineF> polygonSide;
    QList<QLineF> virtualPath;
    QVector<QList<GeoPoint>> order;
    order.resize(_framePolygon.size());
    QList<GeoPoint> keypoint;
    double x = 0.0, y = 0.0, z =0.0;
    if(_framePolygon.size()){
        QGeoCoordinate origin(qobject_cast<GeoPoint*>(_polygon.keypointModel()->get(0))->coord());
        //获取多边形和所有边
        QPointF p1, p2;
        for(int i=0;i<_framePolygon.size();++i){
            int j = (i+1) % _framePolygon.size();
            _tool.geoToNed(_framePolygon[i], origin, x, y, z);
            p1 = QPointF(x, y);
            _tool.geoToNed(_framePolygon[j], origin, x, y, z);
            p2 = QPointF(x, y);
            polygon.append(p1);
            polygonSide.append({p1, p2});
            GeoPoint pt(_framePolygon[i], this);
            pt.setNedPoint(p1);
            pt.setSideId(i);
            keypoint.append(pt);
        }
        //计算虚拟航线ned坐标
        for(int i=0;i<_virtualPath.size();++i){
            _tool.geoToNed(_virtualPath[i][0], origin, x, y, z);
            p1 = {x, y};
            _tool.geoToNed(_virtualPath[i][1], origin, x, y, z);
            p2 = {x, y};
            virtualPath.append({p1, p2});
        }
        for(int i=0; i<virtualPath.size(); ++i){
            QLineF vpath = virtualPath[i];
            int sideId = 0;
            QList<GeoPoint> intersects;
            for(; sideId<polygonSide.size(); ++sideId){
                if(QLineF::BoundedIntersection == vpath.intersects(polygonSide[sideId], &intersect)){
                    GeoPoint vtx(this);
                    //if(intersect == polygonSide[sideId].p1()){
                    if(intersect == keypoint[sideId].nedPoint()){
                        //顶点
                        vtx = keypoint[sideId];
                    }else{
                        //不是顶点时生成航点并加入交点集合
                        _tool.nedToGeo(intersect.x(), intersect.y(), 0.0, origin, intersectCoor);
                        vtx.setCoord(intersectCoor);
                        vtx.setSideId(sideId);
                        vtx.setNedPoint(intersect);
                    }
                    //按x值升序加入交点集合
                    if(intersects.size()){
                        for(int j=0; j<intersects.size(); ++j){
                            if(intersects[j].nedPoint().x() > intersect.x()){
                                intersects.insert(j, vtx);
                                break;
                            }
                            if(j == intersects.size() - 1){
                                intersects.append(vtx);
                                break;
                            }
                        }
                    }else{
                        intersects.append(vtx);
                    }
                }
            }
            if(intersects.size() == 1){
                continue;
            }
            if(intersects.size() > 1){
                //检查是否有顶点交点并判断是否可以忽略
                for(int m=intersects.size() - 1; m>=0; --m){
                    if(_framePolygon.contains(intersects[m].coord())){
                        if(m != 0 && m != intersects.size() - 1){
                            //中间的顶点交点,忽略
                            intersects.removeAt(m);
                        }
                    }
                }
            }
            if(intersects.size()%2){
                //奇数个交点,说明包含顶点
                continue;
            }
            if(intersects.size() > 1){
                for(int m=1; m<intersects.size(); ++m){
                    QLineF path(intersects[m-1].nedPoint(), intersects[m].nedPoint());
                    //当相邻交点的连线在多边形内部时路径有效,分配路径序号
                    if(polygon.containsPoint(path.center(), Qt::OddEvenFill)){
                        if(intersects[m-1].pathId() == -1){
                            intersects[m-1].setPathId(segmentNumber++);
                        }
                        intersects[m].setPathId(intersects[m-1].pathId());
                        QList<GeoPoint> paths;
                        paths.append(intersects[m-1]);
                        paths.append(intersects[m]);
                        _realPath.append(paths);
                    }
                }
                for(int m=0; m<intersects.size(); ++m){
                    if(keypoint.contains(intersects[m])){
                        continue;
                    }
                    keypoint.append(intersects[m]);
                }
            }
        }
        int size = order.size();
        //按边序号将航点分组
        for(int i=0; i<keypoint.size(); ++i){
            order[keypoint[i].sideId()].append(keypoint[i]);
        }
        for(int i=0; i<order.size(); ++i){
            //排序每条边上的交点
            if(order[i].size() < 3)
                continue;
            //按照边的方向排序(x值升序或降序)
            if((order[(i+1)%size][0].nedPoint().x() < order[i][0].nedPoint().x() && order[i][2].nedPoint().x() > order[i][1].nedPoint().x()) ||
                (order[(i+1)%size][0].nedPoint().x() > order[i][0].nedPoint().x() && order[i][2].nedPoint().x() < order[i][1].nedPoint().x())){
                QList<GeoPoint> list;
                list.append(order[i][0]);
                for(int j=order[i].size()-1;j>0;--j){
                    list.append(order[i][j]);
                }
                order[i].swap(list);
            }
        }
        //从起始点按顺序加入航点集合
        for(int i=0;i<order.size();++i){
            for(int j=0;j<order[i].size();++j){
                _keyPoints.append(order[i][j]);
            }
        }
    }
    genFlightPath();
}

void PolygonArea::genFlightPath(){
    _lines.clearAndDeleteContents();
    _path.clear();
    _pathDistance = 0;
    if(_realPath.size()){
        if(1 == _realPath.size()){
            appendPoint(_realPath.first().first(), GeoPoint::start);
            appendPoint(_realPath.first().last(), GeoPoint::stop);
        }else{
            QList<int> pathSeq;
            QList<int> usedPath;
            usedPath.resize(_realPath.size());
            int cur = _startVertex, keysize = _keyPoints.size();
            //遍历所有关键点,生成飞行路径顺序
            for(int i=0; i<keysize; ++i){
                int pathId = _keyPoints[(cur+i)%keysize].pathId();
                if(-1 != pathId && !usedPath[pathId]){
                    pathSeq.append(pathId);
                    usedPath[pathId] = 1;
                }
            }
            //根据实际路径顺序计算串连方式
            QList<GeoPoint> *curPath = nullptr;
            QList<GeoPoint> *lastPath = nullptr;
            GeoPoint *lastPoint;
            for(int i=0; i<pathSeq.size(); ++i){
                curPath = &_realPath[pathSeq[i]];
                if(0 == _path.size()){
                    if(curPath->first().sideId() < curPath->last().sideId()){
                        appendPoint(curPath->first(), GeoPoint::start);
                        appendPoint(curPath->last(), GeoPoint::stop);
                    }else{
                        appendPoint(curPath->last(), GeoPoint::start);
                        appendPoint(curPath->first(), GeoPoint::stop);
                    }
                }else{
                    lastPoint = _waypoints[_path.size()-1];
                    if(!curPath || !lastPath)
                        return;
                    if(curPath->first().sideId() == lastPath->first().sideId() &&
                        curPath->last().sideId() == lastPath->last().sideId()){
                        //同时共边
                        if(*lastPoint == lastPath->first()){
                            appendPoint(curPath->first(), GeoPoint::start);
                            appendPoint(curPath->last(), GeoPoint::stop);
                        }else{
                            appendPoint(curPath->last(), GeoPoint::start);
                            appendPoint(curPath->first(), GeoPoint::stop);
                        }
                    }else if(curPath->first().sideId() == lastPath->first().sideId()){
                        //起点共边
                        if(*lastPoint == lastPath->last() &&
                            qAbs(lastPoint->sideId() - curPath->last().sideId()) < 2){
                            if(curPath->last().sideId() < lastPath->last().sideId()){
                                appendPoint(_frameVertexs[lastPath->last().sideId()], GeoPoint::none);
                            }else{
                                appendPoint(_frameVertexs[curPath->last().sideId()], GeoPoint::none);
                            }
                            appendPoint(curPath->last(), GeoPoint::start);
                            appendPoint(curPath->first(), GeoPoint::stop);
                        }else{
                            if(*lastPoint == lastPath->last()){
                                appendPoint(lastPath->first(), GeoPoint::none);
                            }
                            appendPoint(curPath->first(), GeoPoint::start);
                            appendPoint(curPath->last(), GeoPoint::stop);
                        }
                    }else if(curPath->last().sideId() == lastPath->last().sideId()){
                        //终点共边
                        if(*lastPoint == lastPath->first() &&
                            qAbs(lastPoint->sideId() - curPath->first().sideId()) < 2){
                            if(curPath->first().sideId() < lastPath->first().sideId()){
                                appendPoint(_frameVertexs[lastPath->first().sideId()], GeoPoint::none);
                            }else{
                                appendPoint(_frameVertexs[curPath->first().sideId()], GeoPoint::none);
                            }
                            appendPoint(curPath->first(), GeoPoint::start);
                            appendPoint(curPath->last(), GeoPoint::stop);
                        }else{
                            if(*lastPoint == lastPath->first()){
                                //最后一个点是起点时先返回终点
                                appendPoint(lastPath->last(), GeoPoint::none);
                            }
                            appendPoint(curPath->last(), GeoPoint::start);
                            appendPoint(curPath->first(), GeoPoint::stop);
                        }
                    }else{
                        //不共边
                        //统计两侧经过的顶点数
                        int lastBeg = lastPath->first().sideId(), lastEnd = lastPath->last().sideId();
                        int curBeg = curPath->first().sideId(), curEnd = curPath->last().sideId();
                        //if(curBeg - lastBeg < lastEnd - curEnd){
                        QList<GeoPoint> beg, end;
                        findWay(lastBeg, curBeg, beg);
                        findWay(lastEnd, curEnd, end);
                        if(*lastPoint == lastPath->first()){
                            //最后一个点是起点
                            if(beg.size() <= end.size() + 1){
                                for(int j=0; j<beg.size(); ++j){
                                    appendPoint(beg[j], GeoPoint::none);
                                }
                                appendPoint(curPath->first(), GeoPoint::start);
                                appendPoint(curPath->last(), GeoPoint::stop);
                            }else{
                                appendPoint(lastPath->last(), GeoPoint::none);
                                for(int j=0; j<end.size(); ++j){
                                    appendPoint(end[j], GeoPoint::none);
                                }
                                appendPoint(curPath->last(), GeoPoint::start);
                                appendPoint(curPath->first(), GeoPoint::stop);
                            }
                        }else{
                            //最后一个点是终点
                            if(end.size() <= beg.size() + 1){
                                for(int j=0; j<end.size(); ++j){
                                    appendPoint(end[j], GeoPoint::none);
                                }
                                appendPoint(curPath->last(), GeoPoint::start);
                                appendPoint(curPath->first(), GeoPoint::stop);
                            }else{
                                appendPoint(lastPath->first(), GeoPoint::none);
                                for(int j=0; j<beg.size(); ++j){
                                    appendPoint(beg[j], GeoPoint::none);
                                }
                                appendPoint(curPath->first(), GeoPoint::start);
                                appendPoint(curPath->last(), GeoPoint::stop);
                            }
                        }
                        // if(beg.size() < end.size()){
                        //     //起点-起点经过的顶点数少
                        //     if(*lastPoint == lastPath->last()){
                        //         appendPoint(lastPath->first(), GeoPoint::none);
                        //     }
                        //     for(int i=0; i<beg.size(); ++i){
                        //         appendPoint(beg[i], GeoPoint::none);
                        //     }
                        //     appendPoint(curPath->first(), GeoPoint::start);
                        //     appendPoint(curPath->last(), GeoPoint::stop);
                        // }else{
                        //     //终点-终点经过的顶点数少
                        //     if(*lastPoint == lastPath->first()){
                        //         appendPoint(lastPath->last(), GeoPoint::none);
                        //     }
                        //     for(int i=0; i<end.size(); ++i){
                        //         appendPoint(end[i], GeoPoint::none);
                        //     }
                        //     appendPoint(curPath->last(), GeoPoint::start);
                        //     appendPoint(curPath->first(), GeoPoint::stop);
                        // }
                    }
                }
                lastPath = curPath;
            }
        }
    }
    _pathSize = _path.size();
    updateWaypoint();
    updateLines();
    emit pathChanged();
    //更新有效性
    bool valid = _pathSize;
    if(_valid != valid){
        _valid = valid;
        emit validChanged();
    }
    _polygon.setCanUpdate(true);
}

void PolygonArea::appendPoint(GeoPoint& pt, GeoPoint::CamAct act){
    //更新航点和内部序号
    int index = 0, size = _path.size();
    GeoPoint* point = nullptr;
    if(_waypoints.size() > size){
        point = _waypoints[size];
        *point = pt;
    }else{
        point = new GeoPoint(pt);
        _waypoints.append(point);
    }
    if(size){
        index = _waypoints[size-1]->index() + 1 + _waypoints[size-1]->action();
        _pathDistance += point->coord().distanceTo(_waypoints[size-1]->coord());
    }
    point->setAction(act);
    point->setIndex(index);
    _path.append(QVariant::fromValue(pt.coord()));
}

void PolygonArea::findWay(int from, int to, QList<GeoPoint> &path){
    if(from == to || _frameVertexs.size() < 3){
        return;
    }
    int size = _frameVertexs.size();
    int half = (size+1)/2;
    int diff = qAbs(from - to);
    if(diff <= half){
        //不需要越过起点
        if(from < to){
            for(int i=from+1; i<=to; ++i){
                path.append(_frameVertexs[i]);
            }
        }else{
            for(int i=from; i>to; --i){
                path.append(_frameVertexs[i]);
            }
        }
    }else{
        //需要越过起点
        if(from < to){
            from += size;
            for(int i=from; i>to; --i){
                path.append(_frameVertexs[i%size]);
            }
        }else{
            to += size;
            for(int i=from+1; i<=to; ++i){
                path.append(_frameVertexs[i%size]);
            }
        }
    }
}

void PolygonArea::updateLines()
{
    if (_lines.count()) {
        _lines.clearAndDeleteContents();
    }
    GeoPoint* from = nullptr;
    GeoPoint* to = nullptr;
    for (int i=1; i<_waypoints.size(); ++i) {
        from = _waypoints[i-1];
        to = _waypoints[i];
        GeoLine* line = new GeoLine(from, to, this);
        _lines.append(line);
    }
}

//SLOTS
void PolygonArea::genVirtualPath()
{
    _frameVertexs.clear();
    _framePolygon.clear();
    _virtualPath.clear();
    if(_polygon.valid()){
        if(_polygon.draging()){
            return;
        }
        _notEmpty = true;
        _polygon.setCanUpdate(false);
        //if(_setup.expandDistance() > 1.0){
        if(_polygon.expand() > 1.0){
            //_polygon.genFramePolygon(_setup.expandDistance(), _framePolygon);
            _framePolygon = _polygon.frame();
        }else{
            for(int i=0; i<_polygon.keypointModel()->count(); ++i){
                _framePolygon.append(qobject_cast<GeoPoint*>(_polygon.keypointModel()->get(i))->coord());
            }
        }
        QGeoCoordinate origin(qobject_cast<GeoPoint*>(_polygon.keypointModel()->get(0))->coord());
        double x = 0, y = 0, z = 0, nx = 0, ny = 0;
        //原始多边形
        QPolygonF src;
        for(int i=0; i<_framePolygon.size(); ++i){
            _tool.geoToNed(_framePolygon[i], origin, x, y, z);
            src.append(QPointF(x, y));
            GeoPoint vertex(_framePolygon[i], this);
            vertex.setSideId(i);
            vertex.setNedPoint(QPointF(x, y));
            _frameVertexs.append(vertex);
            src.append(vertex.nedPoint());
        }
        //旋转多边形
        QPolygonF rot;
        //外接矩形
        QPolygonF des;
        double sideRange = _setup.camera()->adjustedFootprintSide()->rawValue().toDouble();
        QList<QGeoCoordinate> desRect;
        QGeoCoordinate coord;
        //旋转多边形
        double azimuth = _setup.routeAzimuth();
        double anti = 360 - azimuth;
        for(int i=0; i<src.size(); ++i){
            x = src.at(i).x();
            y = src.at(i).y();
            nx = x  *cos(azimuth  *3.1415926 / 180.0) - y  *sin(azimuth  *3.1415926 / 180.0);
            ny = x  *sin(azimuth  *3.1415926 / 180.0) + y  *cos(azimuth  *3.1415926 / 180.0);
            rot.append(QPointF(nx, ny));
        }
        //生成外接矩形
        des = boundRect(rot, 10);
        //回正外接矩形
        for(int i=0; i<des.size(); ++i){
            x = des.at(i).x();
            y = des.at(i).y();
            nx = x  *cos(anti  *3.1415926 / 180.0) - y  *sin(anti  *3.1415926 / 180.0);
            ny = x  *sin(anti  *3.1415926 / 180.0) + y  *cos(anti  *3.1415926 / 180.0);
            des[i] = QPointF(nx, ny);
            _tool.nedToGeo(nx, ny, z, origin, coord);
            desRect.append(coord);
        }
        //计算外接矩形的四个顶点的经纬度和中心线起止点
        QGeoCoordinate tLeft, tRight, bRight, bLeft;
        QGeoCoordinate midStart, midEnd, start, end;
        bLeft  = desRect.at(0);//左下
        tLeft  = desRect.at(1);//左上
        tRight = desRect.at(2);//右上
        bRight = desRect.at(3);//右下
        //航向角度和航线长度
        double azi = bLeft.azimuthTo(tLeft);
        double distance = bLeft.distanceTo(tLeft);
        //侧向角度和宽度
        double sideAzi = bLeft.azimuthTo(bRight);
        double sideDist = bLeft.distanceTo(bRight);
        midStart = bLeft.atDistanceAndAzimuth(sideDist / 2, sideAzi);
        midEnd = midStart.atDistanceAndAzimuth(distance, azi);
        _virtualPath.append({midStart, midEnd});
        int lineCount = sideDist / 2 / sideRange;
        for(int i=1; i<=lineCount; ++i){
            //left
            start = midStart.atDistanceAndAzimuth(sideRange  *i, sideAzi + 180);
            end = midEnd.atDistanceAndAzimuth(sideRange  *i, sideAzi + 180);
            QList<QGeoCoordinate> left({start, end});
            //azimuth < 90.0 ? _virtualPath.prepend(left) : _virtualPath.append(left);
            _virtualPath.prepend(left);
            start = midStart.atDistanceAndAzimuth(sideRange  *i, sideAzi);
            end = midEnd.atDistanceAndAzimuth(sideRange  *i, sideAzi);
            QList<QGeoCoordinate> right({start, end});
            //azimuth < 90.0 ? _virtualPath.append(right) : _virtualPath.prepend(right);
            _virtualPath.append(right);
        }
        genRealPath();
    }else{
        if(_notEmpty){
            clear();
        }
    }
}
void PolygonArea::dragPath(double dist, double azim)
{
    _path.clear();
    _pathDistance = 0;
    for(int i=0; i<_pathSize; ++i){
        QGeoCoordinate coord = _waypoints[i]->coord().atDistanceAndAzimuth(dist, azim);
        _waypoints[i]->setCoord(coord);
        _path.append(QVariant::fromValue(coord));
        if(i){
            _pathDistance += coord.distanceTo(_waypoints[i-1]->coord());
        }
    }
    updateLines();
    emit pathChanged();
    emit simpleInfoChanged();
}
void PolygonArea::updateWaypoint()
{
    if(_pathSize){
        GeoPoint* ptr = nullptr;
        if(_showAllWaypoint){
            for(int i=0; i<_pathSize; ++i){
                ptr = qobject_cast<GeoPoint*>(_showInfoModel.get(i));
                if(i<_showInfoModel.count()){
                    if(ptr != _waypoints[i]){
                        _showInfoModel.removeAt(i);
                        _showInfoModel.insert(i, _waypoints[i]);
                    }
                }else{
                    _showInfoModel.append(_waypoints[i]);
                }
            }
            if(_showInfoModel.count() > _pathSize){
                while(_showInfoModel.count() > _pathSize){
                    _showInfoModel.removeAt(_pathSize);
                }
            }
        }else{
            int size = _showInfoModel.count();
            if(size){
                if(size > 2){
                    _showInfoModel.clear();
                }else{
                    _showInfoModel.removeAt(0);
                    _showInfoModel.removeAt(0);
                }
            }
            _showInfoModel.append(_waypoints.first());
            _showInfoModel.append(_waypoints.at(_pathSize-1));
        }
    }else if(_showInfoModel.count()){
        _showInfoModel.clear();
    }
}
void PolygonArea::onRecvCheck(bool success, QList<double> heights)
{
    //qDebug()<<"ack:"<<QThread::currentThread();
    if(success && heights.size() == _checkPath.size()){
        int index = 0;
        for(int i=0; i<_checkPath.size(); ++i){
            _checkPath[i].setAltitude(heights[i]);
            //更新航点高度
            if(i == _srcIndex[index]){
                _waypoints[index]->setTerrain(heights[i]);
                ++index;
            }
        }
        checkSafety();
    }
    _polygon.setCanUpdate(true);
}
