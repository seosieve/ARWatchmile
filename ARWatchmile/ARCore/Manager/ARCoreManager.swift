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
    
    func runSession(trackPlanes: Bool) {
        guard let view = arView else { return }
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        if trackPlanes { configuration.planeDetection = [.horizontal, .vertical] }
        view.session.run(configuration, options: .removeExistingAnchors)
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
        
        let isOnHorizontalPlane = (result.targetAlignment == .horizontal)
        let anchorTransform: simd_float4x4
        
        if isOnHorizontalPlane {
          // Rotate raycast result around y axis to face user.
          // Compute angle between camera position and raycast result's z axis.
          let anchorFromCamera = simd_mul(simd_inverse(result.worldTransform), frame.camera.transform)
          let x = anchorFromCamera.columns.3[0]
          let z = anchorFromCamera.columns.3[2]
          // Angle from the z axis, measured counterclockwise.
          let angle = atan2f(x, z)
          let rotation = simd_quatf(angle: angle, axis: simd_make_float3(0, 1, 0))
          anchorTransform = simd_mul(result.worldTransform, simd_matrix4x4(rotation))
        } else {
          anchorTransform = result.worldTransform
        }
        
        let anchor = ARAnchor(transform: anchorTransform)
        
        // Refresh Session
        runSession(trackPlanes: false)
        arView.session.add(anchor: anchor)
    }
}
