//
//  AnchorViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/31/25.
//

import UIKit
import ARKit
import RealityKit
import SnapKit
import Then

class AnchorViewController: UIViewController {
    var anchorManager = AnchorManager()
    
    private lazy var addAnchorButton = UIButton().then {
        $0.setTitle("📍 앵커 추가", for: .normal)
        $0.backgroundColor = .systemBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 8
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.addTarget(self, action: #selector(addAnchorButtonTapped), for: .touchUpInside)
    }
    
    private lazy var visualizeButton = UIButton().then {
        $0.setTitle("👁️ 앵커 표시", for: .normal)
        $0.backgroundColor = .systemGreen
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 8
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.addTarget(self, action: #selector(visualizeButtonTapped), for: .touchUpInside)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInitialUI()
        setInitial()
    }
    
    func setInitial() {
        loadSavedAnchors()
    }
    
    func setInitialUI() {
        anchorManager.arView = ARView(frame: view.bounds)
        view.addSubview(anchorManager.arView)
        anchorManager.startARSession()
        
        view.addSubview(addAnchorButton)
        view.addSubview(visualizeButton)
        
        addAnchorButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
        
        visualizeButton.snp.makeConstraints { make in
            make.top.equalTo(addAnchorButton.snp.top)
            make.leading.equalTo(addAnchorButton.snp.trailing).offset(10)
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
    }
    
    @objc private func addAnchorButtonTapped() {
        // 현재 카메라 위치에 앵커 추가
        addAnchorAtCurrentPosition()
    }
    
    @objc private func visualizeButtonTapped() {
        // 저장된 앵커들을 시각화
        anchorManager.visualizeSavedAnchors()
        print("👁️ 앵커 시각화 버튼 탭됨")
    }
    
    private func addAnchorAtCurrentPosition() {
        guard let currentFrame = anchorManager.arView.session.currentFrame else {
            print("❌ 현재 프레임을 가져올 수 없습니다")
            return
        }
        
        let cameraTransform = currentFrame.camera.transform
        let position = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        
        // 앵커 이름 생성 (타임스탬프 기반)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let anchorName = "Anchor_\(formatter.string(from: Date()))"
        
        // 앵커 추가
        anchorManager.addManualAnchor(at: position, name: anchorName)
        
        print(" 앵커 추가 완료: \(anchorName)")
        print("  - 위치: \(position)")
        print("  - 총 앵커 개수: \(anchorManager.getAnchorCount())")
    }
    
    private func loadSavedAnchors() {
        anchorManager.loadSavedAnchors()
        print(" 저장된 앵커 로드 완료")
    }
}
