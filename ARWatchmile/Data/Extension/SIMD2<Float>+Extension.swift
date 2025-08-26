//
//  simd+Extension.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/26/25.
//

import Foundation

extension SIMD2<Float> {
    init(anchor: CloudAnchor) {
        self.init(Float(anchor.x) , Float(anchor.y))
    }
}
