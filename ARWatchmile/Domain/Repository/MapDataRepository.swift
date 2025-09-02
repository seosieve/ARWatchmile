//
//  MapDataRepository.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/25/25.
//

import Foundation

final class MapDataRepository {
    static let shared = MapDataRepository()
    private(set) var mapData: MapData?
    
    private init() {
        self.mapData = Self.load()
    }
    
    private static func load() -> MapData? {
        guard let url = Bundle.main.url(forResource: "VestellaOfficeMap", withExtension: "json"), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(MapData.self, from: data)
    }
    
    func getAnchorPoints() -> [CloudAnchor] {
        guard let mapData else { return [] }
        return mapData.data.floor[0].anchor
    }
    
    func getPointOfInterests() -> [String : POI] {
        guard let mapData else { return [:] }
        return mapData.data.poi
    }
}
