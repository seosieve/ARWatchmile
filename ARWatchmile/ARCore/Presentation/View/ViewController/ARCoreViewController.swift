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
    
    private var logVisualizeView = LogVisualizeView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
    }
    
    private var dotStatusView = DotStatusView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func setupAR() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        arView.session.run(configuration, options: .removeExistingAnchors)
        arView.scene.addAnchor(viewModel.worldOrigin)
    }
    
    private func setupUI() {
        view.addSubview(arView)
        
        view.addSubview(logVisualizeView)
        logVisualizeView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(60)
        }
        
        view.addSubview(miniMapView)
        miniMapView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(miniMapView.snp.width).multipliedBy(Constants.originMapRatio)
        }
        
        view.addSubview(dotStatusView)
        dotStatusView.snp.makeConstraints { make in
            make.bottom.equalTo(miniMapView.snp.top).offset(-8)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(32)
        }
    }
}

// MARK: - ARSessionDelegate
extension ARCoreViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        var textArr: [String] = []
        
        for anchor in viewModel.affineAnchor {
            let dic = UserDefaultsManager.shared.anchorIdDictionary.filter{ $0.value == anchor.id }.first!
            textArr.append(dic.key)
        }
        
        logVisualizeView.updateLog(textArr.joined(separator: ", "))
        viewModel.updateResolvedAnchors(frame: frame)
        // 1점 이상 Resolved일 때 AnchorColor 변경
        guard let anchorId = viewModel.resolvedAnchor.last?.id else { return }
        miniMapView.changeResolvedColor(of: anchorId, color: .darkGray)
        // 3점 이상 Resolved일 때 내 위치 표시
        guard viewModel.affineAnchor.count >= 3 else { return }
        let resolvedAnchors = viewModel.affineAnchor
        let playerPosition = frame.camera.transform.translation
        
        miniMapView.updatePlayerPosition(resolvedAnchors: resolvedAnchors, playerPosition: playerPosition)
    }
}
