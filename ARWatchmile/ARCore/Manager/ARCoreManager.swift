//
//  ARCoreManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/6/25.
//

import UIKit
import ARKit
import RealityKit

class ARCoreManager: NSObject, ARSessionDelegate {
    private(set) weak var arView: ARView?
    
    init(arView: ARView) {
        self.arView = arView
    }
    
    func setupTapGesture() {
        guard let view = arView else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(arViewTap(_:)))
        view.addGestureRecognizer(tap)
    }
    
    @objc func arViewTap(_ sender: UITapGestureRecognizer) {
        guard let arView, let frame = arView.session.currentFrame else { return }
        guard frame.camera.trackingState == .normal else { return }
        
        let point = sender.location(in: arView)
        let results =
          arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .horizontal)
          + arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .vertical)
          + arView.raycast(from: point, allowing: .estimatedPlane, alignment: .horizontal)
          + arView.raycast(from: point, allowing: .estimatedPlane, alignment: .vertical)
        guard let result = results.first else { return }
        print(result)
    }
}
