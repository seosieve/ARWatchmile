//
//  ARCoreViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/5/25.
//

import UIKit
import ARKit
import ARCore
import RealityKit
import Then
import SnapKit

final class ARCoreViewController: UIViewController {
    private var arCloudAnchorManager: ARCloudAnchorManager
    
    private var resolvedModels: [UUID: Entity] = [:]
    private let worldOrigin = AnchorEntity(world: matrix_identity_float4x4)
    
    private lazy var arView = ARView(frame: view.bounds, cameraMode: .ar, automaticallyConfigureSession: false)
    
    init(arCloudAnchorManager: ARCloudAnchorManager) {
        self.arCloudAnchorManager = arCloudAnchorManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupAR()
        setupUI()
    }
    
    private func setupAR() {
        arView.session.delegate = self
        arCloudAnchorManager.startSession(arView: arView)
        arView.scene.addAnchor(worldOrigin)
    }
    
    private func setupUI() {
        view.addSubview(arView)
    }
}

// MARK: - ARSessionDelegate
extension ARCoreViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let garSession = arCloudAnchorManager.garSession, let garFrame = try? garSession.update(frame) else { return }
        for garAnchor in garFrame.anchors {
            if let model = resolvedModels[garAnchor.identifier] {
                model.transform = Transform(matrix: garAnchor.transform)
                continue
            }
            guard let model = ARObjectManager.createCloudAnchorModel() else { continue }
            resolvedModels[garAnchor.identifier] = model
            model.transform = Transform(matrix: garAnchor.transform)
            worldOrigin.addChild(model)
        }
    }
}
