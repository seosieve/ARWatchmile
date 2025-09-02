//
//  ARDataRepository.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/28/25.
//

import Foundation

final class ARDataRepository {
    static let shared = ARDataRepository()
    private var poiArr: [SIMD2<Float>]?
    
    func getPointOfInterests() -> [SIMD2<Float>] {
        guard let poiArr else { return [] }
        return poiArr
    }

    func setPointOfInterests(position: [SIMD2<Float>]) {
        poiArr = position
    }
}
