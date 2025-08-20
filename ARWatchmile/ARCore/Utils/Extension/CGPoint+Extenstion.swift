//
//  CGPoint+Extenstion.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/20/25.
//

import CoreGraphics
import simd

extension CGPoint {
    init(_ simd: SIMD2<Float>) {
        self.init(x: CGFloat(simd.x), y: CGFloat(simd.y))
    }
}

