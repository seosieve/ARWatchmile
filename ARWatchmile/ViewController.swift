//
//  ViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/22/25.
//

import UIKit
import ARKit
import RealityKit
import simd

class ViewController: UIViewController, ARSessionDelegate {
    
    var arView: ARView!

    override func viewDidLoad() {
        super.viewDidLoad()

        arView = ARView(frame: view.bounds)
        view.addSubview(arView)

        // Scene Reconstruction 사용 가능 여부 확인
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            print("Scene Reconstruction 지원 안됨")
            return
        }

        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        config.environmentTexturing = .automatic
        config.planeDetection = [.horizontal, .vertical]

        arView.session.delegate = self
        arView.session.run(config)
        
        // 디버그 옵션 설정 - 메시 시각화
        arView.debugOptions = [.showSceneUnderstanding]
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let meshAnchor = anchor as? ARMeshAnchor else { continue }
            print("📦 새 메쉬 추가됨 - id: \(meshAnchor.identifier)")
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let meshAnchor = anchor as? ARMeshAnchor else { continue }
            print("🔄 메쉬 업데이트 - id: \(meshAnchor.identifier)")
        }
    }
}

