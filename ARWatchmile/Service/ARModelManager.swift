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
        DispatchQueue.main.async {
            let boxMesh = MeshResource.generateBox(size: 0.3)
            let boxMaterial = SimpleMaterial(color: .red, isMetallic: false)
            let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
            
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.addChild(boxEntity)
            
            view.scene.addAnchor(anchorEntity)
        }
    }
    
    func placeMultipleObjects(arView: ARView) {
        let positions = [
            (x: Float(0), z: Float(0)),
            (x: Float(-3.2), z: Float(-2.2)),
            (x: Float(-6.5), z: Float(-6.0)),
            (x: Float(-5.5), z: Float(0.2)),
            (x: Float(-2.2), z: Float(3.3)),
            (x: Float(-7), z: Float(-2.1)),
            (x: Float(-0.6), z: Float(-4.7))
        ]
        
        for position in positions {
            placeObjectAtCoordinates(x: position.x, z: position.z, arView: arView)
        }
        
        print("🎯 \(positions.count)개 물체 배치 완료")
    }
    
    func placeObjectAtCoordinates(x: Float, z: Float, arView: ARView) {
        guard let originData = UserDefaults.standard.array(forKey: "permanent_origin") as? [Float],
              originData.count == 2 else {
            print("❌ 원점을 먼저 설정해주세요")
            return
        }
        
        let originPoint = SIMD3<Float>(originData[0], 0, originData[1])
        let absolutePosition = originPoint + SIMD3<Float>(x, 0, z)
        
        let objectTransform = matrix_float4x4(translation: absolutePosition)
        let anchor = ARAnchor(transform: objectTransform)
        
        DispatchQueue.main.async {
            arView.session.add(anchor: anchor)
            self.addModelToAnchor(anchor, view: arView)
            print("물체 배치 완료: 원점에서 (\(x), 0, \(z))")
        }
    }
}

extension matrix_float4x4 {
    init(translation: SIMD3<Float>) {
        self = matrix_identity_float4x4
        self.columns.3 = SIMD4<Float>(translation.x, translation.y, translation.z, 1.0)
    }
}
