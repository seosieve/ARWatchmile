//
//  ARModelManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/24/25.
//

import Foundation
import ARKit
import RealityKit

class ARModelManager {
    func addModelToAnchor(_ anchor: ARAnchor, view: ARView) {
        let boxMesh = MeshResource.generateBox(size: 0.3)
        let boxMaterial = SimpleMaterial(color: .red, isMetallic: false)
        let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
        
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(boxEntity)
        
        view.scene.addAnchor(anchorEntity)
    }
}
