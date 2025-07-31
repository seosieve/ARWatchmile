//
//  AnchorManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/31/25.
//

import UIKit
import ARKit
import RealityKit

class AnchorManager: NSObject {
    var arView: ARView!
    private let storageManager = AnchorStorageManager()
    private var visualizationManager: SimpleARViewVisualization?
    
    override init() {
        super.init()
    }
    
    func startARSession() {
        let config = ARWorldTrackingConfiguration()
        config.isLightEstimationEnabled = true
        config.sceneReconstruction = .mesh
        config.environmentTexturing = .automatic
        config.planeDetection = [.horizontal, .vertical]
        config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        arView.session.delegate = self
        arView.session.run(config)
        arView.debugOptions = [.showSceneUnderstanding]
        
        // ARView용 시각화 매니저 초기화
        visualizationManager = SimpleARViewVisualization(arView: arView)
    }
    
    // MARK: - 시각화 메서드들
    func visualizeSavedAnchors() {
        let savedAnchors = storageManager.getAllSavedAnchors()
        print("🎯 시각화 시작 - 앵커 개수: \(savedAnchors.count)")
        visualizationManager?.visualizeAnchors(savedAnchors)
    }
    
    func clearVisualizations() {
        visualizationManager?.clearAllVisualizations()
        print("🗑️ 시각화 제거 완료")
    }
}

// MARK: - AnchorMethods
extension AnchorManager {
    // 수동 앵커 추가
    func addManualAnchor(at position: SIMD3<Float>, name: String? = nil) {
        var transform = matrix_identity_float4x4
        transform.columns.3 = SIMD4<Float>(position.x, position.y, position.z, 1.0)
        
        let anchor = ARAnchor(transform: transform)
        
        // AR 세션에 앵커 추가
        arView.session.add(anchor: anchor)
        
        // 저장 매니저에 저장
        storageManager.saveAnchor(anchor, name: name)
        
        // 즉시 시각화 업데이트
        visualizeSavedAnchors()
        
        print("📍 수동 앵커 추가됨: \(name ?? "unnamed")")
        print("  - 위치: \(position)")
        print("  - 총 앵커 개수: \(getAnchorCount())")
    }
    
    // 저장된 앵커들 가져오기
    func getSavedAnchors() -> [SavedAnchor] {
        return storageManager.getAllSavedAnchors()
    }
    
    // 앵커 개수 가져오기
    func getAnchorCount() -> Int {
        return storageManager.getAnchorCount()
    }
    
    // 모든 앵커 삭제
    func clearAllAnchors() {
        storageManager.clearAllAnchors()
        clearVisualizations()
        print("🗑️ 모든 앵커 삭제 완료")
    }
    
    // 저장된 앵커들 로드
    func loadSavedAnchors() {
        storageManager.loadAnchorsFromFile()
        // 로드 후 시각화
        visualizeSavedAnchors()
        print("📂 저장된 앵커 로드 완료")
    }
}

// MARK: - ARSessionDelegate
extension AnchorManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            print("🥳Camera State normal")
        case .limited:
            print("🥳Camera State limited")
        case .notAvailable:
            print("🥳Camera State notAvailable")
        @unknown default:
            break
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("🥳Camera Session failed")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("🥳Camera Session Interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("🥳Camera Session Interruption Ended")
    }
}
