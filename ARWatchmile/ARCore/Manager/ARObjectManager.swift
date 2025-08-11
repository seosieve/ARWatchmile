//
//  ARObjectManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/11/25.
//

import ARKit
import RealityKit

class ARObjectManager {
    static func createCloudAnchorModel() -> Entity? {
        return try? Entity.load(named: Constants.cloudAnchorName)
    }
}
