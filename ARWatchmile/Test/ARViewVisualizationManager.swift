//
//  AnchorVisualizationManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/31/25.
//

import Foundation
import ARKit
import RealityKit

class SimpleARViewVisualization {
    private let arView: ARView
    private var anchorEntities: [AnchorEntity] = []
    
    init(arView: ARView) {
        self.arView = arView
        print("🎯 시각화 매니저 초기화됨")
    }
    
    // 간단한 구체로 앵커 시각화
    func visualizeAnchors(_ savedAnchors: [SavedAnchor]) {
        print("🎯 시각화 시작 - 앵커 개수: \(savedAnchors.count)")
        
        // 기존 시각화 제거
        clearAllVisualizations()
        
        for (index, savedAnchor) in savedAnchors.enumerated() {
            let position = SIMD3<Float>(savedAnchor.position[0], savedAnchor.position[1], savedAnchor.position[2])
            
            print("📍 앵커 \(index + 1) 시각화 중:")
            print("  - 위치: \(position)")
            print("  - 이름: \(savedAnchor.name ?? "unnamed")")
            
            // 카메라에서 더 가까운 위치로 조정 (Z축을 앞으로)
            let adjustedPosition = SIMD3<Float>(position.x, position.y, position.z - 2.0)
            
            // 박스 엔티티 생성 (더 잘 보이도록)
            let boxMesh = MeshResource.generateBox(size: 0.3)
            let boxMaterial = SimpleMaterial(color: .red, isMetallic: false)
            let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
            
            // AnchorEntity 생성 (조정된 위치 사용)
            let anchorEntity = AnchorEntity(world: adjustedPosition)
            
            // 자식 엔티티 추가
            anchorEntity.addChild(boxEntity)
            
            // ARView에 추가
            arView.scene.addAnchor(anchorEntity)
            
            // 추적을 위해 배열에 저장
            anchorEntities.append(anchorEntity)
            
            print("  ✅ 앵커 \(index + 1) 시각화 완료 (조정된 위치: \(adjustedPosition))")
        }
        
        print("🎯 \(savedAnchors.count)개 앵커 시각화 완료")
    }
    
    // 모든 시각화 제거
    func clearAllVisualizations() {
        print("🗑️ 기존 시각화 제거 중 - 개수: \(anchorEntities.count)")
        for anchorEntity in anchorEntities {
            anchorEntity.removeFromParent()
        }
        anchorEntities.removeAll()
        print("🗑️ 시각화 제거 완료")
    }
}
