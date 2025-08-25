//
//  simd_float4x4+Extension.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/18/25.
//

import Foundation
import simd

extension simd_float4x4 {
    var translation: SIMD2<Float> {
        let col = columns.3
        return SIMD2<Float>(col.x, col.z)
    }
}
