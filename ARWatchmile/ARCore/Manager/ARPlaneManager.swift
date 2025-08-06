//
//  ARPlaneManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/6/25.
//

import ARKit
import RealityKit

class ARPlaneManager {
    static let planeMaterial = UnlitMaterial(color: UIColor(red: 0, green: 0, blue: 1, alpha: 0.7))
    static var planeModels: [UUID: ModelEntity] = [:]
    
    static func createPlaneMesh(for planeAnchor: ARPlaneAnchor) -> MeshResource? {
        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffers.Positions(planeAnchor.geometry.vertices)
        descriptor.primitives = .triangles(planeAnchor.geometry.triangleIndices.map { UInt32($0) })
        return try? MeshResource.generate(from: [descriptor])
    }
    
    static func createPlaneModel(for planeAnchor: ARPlaneAnchor) -> ModelEntity? {
        guard let mesh = createPlaneMesh(for: planeAnchor) else { return nil }
        return ModelEntity(mesh: mesh, materials: [planeMaterial])
    }
    
    static func updatePlaneModel(_ model: ModelEntity, planeAnchor: ARPlaneAnchor) {
        guard let planeMesh = createPlaneMesh(for: planeAnchor) else { return }
        model.model?.mesh = planeMesh
    }
}
