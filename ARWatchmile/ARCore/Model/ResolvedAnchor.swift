//
//  ResolvedAnchor.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/19/25.
//

import Foundation

struct ResolvedAnchor: Identifiable {
    let id: String
    let location: SIMD2<Float>
    var distance: Float = .infinity
}
