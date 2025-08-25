//
//  MapDataRepository.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/25/25.
//

import Foundation

final class MapDataRepository {
    static func fetchMapData() -> MapData? {
        guard let url = Bundle.main.url(forResource: "VestellaOfficeMap", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("JSON 파일을 찾을 수 없습니다.")
            return nil
        }
        
        do {
            let mapData = try JSONDecoder().decode(MapData.self, from: data)
            return mapData
        } catch {
            print("JSON 파싱 실패: \(error)")
            return nil
        }
    }
}
