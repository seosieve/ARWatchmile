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
    // MARK: - 다중 메쉬 모델 배치
    func placeMultipleObjects(arView: ARView) {
        let positions: [SIMD3<Float>] = MeshPosition.testBox
        let _ = positions.map { placeObjectAtCoordinates(position: $0, arView: arView) }
        
        print("🎯 \(positions.count)개 물체 배치 완료")
    }
    
    // MARK: - 메쉬 모델 배치
    func placeObjectAtCoordinates(position: SIMD3<Float>, arView: ARView) {
        let originData = UserDefaultsManager.shared.getPermanentOrigin()
        let absolutePosition = originData + position
        
        let objectTransform = matrix_float4x4(translation: absolutePosition)
        let anchor = ARAnchor(transform: objectTransform)
        
        arView.session.add(anchor: anchor)
        self.addModelToAnchor(anchor, view: arView)
    }
    
    // MARK: - 메쉬 모델 생성, Scene 배치
    func addModelToAnchor(_ anchor: ARAnchor, view: ARView) {
        let boxMesh = MeshResource.generateBox(size: 0.3)
        let boxMaterial = SimpleMaterial(color: .red, isMetallic: false)
        let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
        
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(boxEntity)
        
        view.scene.addAnchor(anchorEntity)
    }
    
    // MARK: - 객체 위치들 가져오기
    func getObjectPositions() -> [SIMD3<Float>] {
        let originData = UserDefaultsManager.shared.getPermanentOrigin()
        let positions = MeshPosition.testBox
        
        return positions.map { originData + $0 }
    }
}

extension matrix_float4x4 {
    init(translation: SIMD3<Float>) {
        self = matrix_identity_float4x4
        self.columns.3 = SIMD4<Float>(translation.x, translation.y, translation.z, 1.0)
    }
}
