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
    }
}

// MARK: - ARSessionDelegate
extension AnchorManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("🫡Camera Session Updated")
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            break
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
