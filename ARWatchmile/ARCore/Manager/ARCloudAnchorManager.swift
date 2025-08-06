//
//  ARCloudAnchorManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/6/25.
//

import ARKit
import RealityKit

class ARCloudAnchorManager {
    private static let cloudAnchorName = "cloud_anchor"
    
    static func createCloudAnchorModel() -> Entity? {
        return try? Entity.load(named: cloudAnchorName)
    }
}
