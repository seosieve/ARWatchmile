//
//  SavedAnchor.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/31/25.
//

import Foundation
import ARKit

struct SavedAnchor: Codable {
    let id: String
    let position: [Float] // SIMD3<Float>를 배열로 변환
    let rotation: [Float] // SIMD4<Float>를 배열로 변환
    let anchorType: String
    let timestamp: Date
    let name: String?
    
    init(from anchor: ARAnchor, name: String? = nil) {
        self.id = anchor.identifier.uuidString
        self.position = [anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z]
        self.rotation = [anchor.transform.columns.0.x, anchor.transform.columns.0.y, anchor.transform.columns.0.z, anchor.transform.columns.0.w]
        self.anchorType = String(describing: type(of: anchor))
        self.timestamp = Date()
        self.name = name
    }
}
