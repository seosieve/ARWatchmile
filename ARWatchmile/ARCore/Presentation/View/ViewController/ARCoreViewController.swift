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
    private var viewModel: ARCoreViewModel
    
    private lazy var arView = ARView().then {
        $0.frame = view.bounds
        $0.cameraMode = .ar
        $0.automaticallyConfigureSession = false
    }
    
    private var miniMapView = MiniMapView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
    }
    
    init(viewModel: ARCoreViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        arView.session.delegate = self
        setupAR()
        setupUI()
    }
    
    private func setupAR() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        arView.session.run(configuration, options: .removeExistingAnchors)
        arView.scene.addAnchor(viewModel.worldOrigin)
    }
    
    private func setupUI() {
        view.addSubview(arView)
        
        view.addSubview(miniMapView)
        miniMapView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(miniMapView.snp.width).multipliedBy(Constants.originMapRatio)
        }
    }
}

// MARK: - ARSessionDelegate
extension ARCoreViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        viewModel.updateResolvedAnchors(frame: frame)
        
        guard let anchor1 = viewModel.anchor1 else { return }
        guard let anchor2 = viewModel.anchor2 else { return }
        guard let anchor3 = viewModel.anchor3 else { return }
        
        let sourcePoints: [SIMD2<Float>] = [anchor1, anchor2, anchor3]
        
        miniMapView.updatePlayerPosition(sourcePoints: sourcePoints, playerPosition: frame.camera.transform.translation)
    }
}
