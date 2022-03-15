/*
 * Copyright (C) 2019-2022 HERE Europe B.V.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 * License-Filename: LICENSE
 */

import heresdk

class MapObjectsExample {

    private let berlinGeoCoordinates = GeoCoordinates(latitude: 52.51760485151816, longitude: 13.380312380535472)
    
    private let mapScene: MapSceneLite
    private let mapCamera: CameraLite
    private var mapPolyline: MapPolylineLite?
    private var mapPolygon: MapPolygonLite?
    private var mapCircle: MapCircleLite?

    init(mapView: MapViewLite) {
        // Configure the map.
        mapCamera = mapView.camera
        mapCamera.setTarget(GeoCoordinates(latitude: 52.51760485151816, longitude: 13.380312380535472))
        mapCamera.setZoomLevel(13)

        mapScene = mapView.mapScene
    }

    func onMapPolylineClicked() {
        clearMap()
        // Move map to expected location.
        mapCamera.setTarget(berlinGeoCoordinates)
        mapCamera.setZoomLevel(13.0)
        
        mapPolyline = createMapPolyline()
        mapScene.addMapPolyline(mapPolyline!)
    }

    func onMapPolygonClicked() {
        clearMap()
        // Move map to expected location.
        mapCamera.setTarget(berlinGeoCoordinates)
        mapCamera.setZoomLevel(13.0)
        
        mapPolygon = createMapPolygon()
        mapScene.addMapPolygon(mapPolygon!)
    }

    func onMapCircleClicked() {
        clearMap()
        // Move map to expected location.
        mapCamera.setTarget(berlinGeoCoordinates)
        mapCamera.setZoomLevel(13.0)
        
        mapCircle = createMapCircle()
        mapScene.addMapCircle(mapCircle!)
    }

    func onClearButtonClicked() {
        clearMap()
    }

    private func createMapPolyline() -> MapPolylineLite {
        let coordinates = [GeoCoordinates(latitude: 52.53032, longitude: 13.37409),
                           GeoCoordinates(latitude: 52.5309, longitude: 13.3946),
                           GeoCoordinates(latitude: 52.53894, longitude: 13.39194),
                           GeoCoordinates(latitude: 52.54014, longitude: 13.37958)]

        // We are sure that the number of vertices is greater than two, so it will not crash.
        let geoPolyline = try! GeoPolyline(vertices: coordinates)
        let mapPolylineStyle = MapPolylineStyleLite()
        mapPolylineStyle.setWidthInPixels(inPixels: 20.0)
        mapPolylineStyle.setColor(0x00908AA0, encoding: .rgba8888)
        let mapPolyline = MapPolylineLite(geometry: geoPolyline, style: mapPolylineStyle)

        return mapPolyline
    }

    private func createMapPolygon() -> MapPolygonLite {
        let coordinates = [GeoCoordinates(latitude: 52.53032, longitude: 13.37409),
                           GeoCoordinates(latitude: 52.5309, longitude: 13.3946),
                           GeoCoordinates(latitude: 52.53894, longitude: 13.39194),
                           GeoCoordinates(latitude: 52.54014, longitude: 13.37958)]

        // We are sure that the number of vertices is greater than three, so it will not crash.
        let geoPolygon = try! GeoPolygon(vertices: coordinates)
        let mapPolygonStyle = MapPolygonStyleLite()
        mapPolygonStyle.setFillColor(0x00908AA0, encoding: .rgba8888)
        let mapPolygon = MapPolygonLite(geometry: geoPolygon, style: mapPolygonStyle)

        return mapPolygon
    }

    private func createMapCircle() -> MapCircleLite {
        let geoCircle = GeoCircle(center: GeoCoordinates(latitude: 52.51760485151816, longitude: 13.380312380535472),
                                  radiusInMeters: 300.0)
        let mapCircleStyle = MapCircleStyleLite()
        mapCircleStyle.setFillColor(0x00908AA0, encoding: .rgba8888)
        let mapCircle = MapCircleLite(geometry: geoCircle, style: mapCircleStyle)

        return mapCircle
    }

    private func clearMap() {
        if let line = mapPolyline {
            mapScene.removeMapPolyline(line)
        }

        if let area = mapPolygon {
            mapScene.removeMapPolygon(area)
        }

        if let circle = mapCircle {
            mapScene.removeMapCircle(circle)
        }
    }
}
