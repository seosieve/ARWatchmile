//
//  ARCoreViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/5/25.
//

import UIKit
import Then
import SnapKit
import ARCore
import ARKit
import RealityKit

final class ARCoreViewController: UIViewController {
    private var arCoreManager: ARCoreManager!
    
    private lazy var arView = ARView(frame: view.bounds, cameraMode: .ar, automaticallyConfigureSession: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupAR()
        setupUI()
    }
    
    private func setupAR() {
        arView.session.delegate = self
        runSession(trackPlanes: true)
        arCoreManager = ARCoreManager(arView: arView)
        arCoreManager.setupTapGesture()
    }
    
    private func setupUI() {
        view.addSubview(arView)
    }
    
    private func runSession(trackPlanes: Bool) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        if trackPlanes { configuration.planeDetection = [.horizontal, .vertical] }
        arView.session.run(configuration, options: .removeExistingAnchors)
    }
}

// MARK: - arViewTap
extension ARCoreViewController {
    
}

// MARK: - ARSessionDelegate
extension ARCoreViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if anchor is AREnvironmentProbeAnchor { continue }
            if let planeAnchor = (anchor as? ARPlaneAnchor) {
                guard let model = ARPlaneManager.createPlaneModel(for: planeAnchor) else { continue }
                ARPlaneManager.planeModels[planeAnchor.identifier] = model
                let anchorEntity = AnchorEntity(.anchor(identifier: anchor.identifier))
                anchorEntity.addChild(model)
                arView.scene.addAnchor(anchorEntity)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = (anchor as? ARPlaneAnchor) else { continue }
            guard let model = ARPlaneManager.planeModels[planeAnchor.identifier] else { continue }
            ARPlaneManager.updatePlaneModel(model, planeAnchor: planeAnchor)
        }
    }
}
