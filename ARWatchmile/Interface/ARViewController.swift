//
//  ViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/22/25.
//

import UIKit
import ARKit
import RealityKit

class ARViewController: UIViewController {
    var arSessionManager: ARSessionManager!
    var arModelManager: ARModelManager!
    
    // AR 세션 시작 시점의 초기 방향 저장
    private var initialYaw: Float = 0.0
    private var isInitialYawSet = false
    
    private var statusLabel = UILabel().then {
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
    }
    
    private var positionLabel = UILabel().then {
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        $0.layer.cornerRadius = 12
        $0.layer.masksToBounds = true
    }
    
    private var miniMapView = MiniMapView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.arSessionManager = ARSessionManager()
            self.arSessionManager.arView = ARView(frame: self.view.bounds)
            self.arModelManager = ARModelManager()
            
            // ARSessionManager에 ARModelManager 연결
            self.arSessionManager.arModelManager = self.arModelManager
            
            self.view.addSubview(self.arSessionManager.arView)
            initUI()
            updateStatusLabel(status: .searching)
            self.arSessionManager.startARSession()
            
            // 카메라 위치 업데이트 콜백 연결
            self.arSessionManager.onCameraPositionUpdate = { [weak self] position in
                self?.updatePositionLabel(position: position)
                self?.updateMiniMapDirection()
            }
            
            // 초기 방향 설정을 위한 타이머 (첫 번째 프레임에서 초기 방향 저장)
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if !self.isInitialYawSet {
                    self.setInitialDirection()
                }
            }
            
            // 트래킹 상태 업데이트 콜백 연결
            self.arSessionManager.onTrackingStatusUpdate = { [weak self] status in
                self?.updateStatusLabel(status: status)
            }
            
            // 상태 체크 타이머 추가 (1초마다)
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                let originArray = UserDefaults.standard.array(forKey: "permanent_origin") as? [Float]
                self.arSessionManager.checkTrackingStatus(originArray: originArray)
            }
        }
    }
    
    private func initUI() {
        view.addSubview(positionLabel)
        positionLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(60)
        }
        
        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(positionLabel.snp.top).offset(-8)
            make.height.equalTo(32)
        }
        
        view.addSubview(miniMapView)
        miniMapView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.right.equalToSuperview().offset(-20)
        }
    }
    
    func updateStatusLabel(status: TrackingStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statusLabel.text = status.description
            self.statusLabel.textColor = status.color
        }
    }
    
    @objc func setOriginButtonTapped() {
        // 현재 위치를 원점으로 저장 - 현재는 설정되어있으므로 추후 사용
        guard let currentFrame = arSessionManager.arView.session.currentFrame else { return }
        let transform = currentFrame.camera.transform
        let position = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        UserDefaults.standard.set([position.x, position.z], forKey: "permanent_origin")
    }
    
    @objc func mapViewButtonTapped() {
        let mapVC = FeaturePointViewController()
        mapVC.modalPresentationStyle = .fullScreen
        if let originArray = UserDefaults.standard.array(forKey: "permanent_origin") as? [Float], originArray.count == 2 {
            mapVC.originPoint = CGPoint(x: CGFloat(originArray[0]), y: CGFloat(originArray[1]))
        }
        // 월드맵의 특징점 전달
        if let worldMap = arSessionManager.loadWorldMap() {
            let featurePoints = worldMap.rawFeaturePoints.points
            mapVC.featurePoints = featurePoints.map { SIMD3<Float>($0.x, $0.y, $0.z) }
        }
        present(mapVC, animated: true)
    }
    
    func updatePositionLabel(position: SIMD3<Float>?) {
        if !arSessionManager.isMapMatched {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.positionLabel.text = "위치 매칭 중..."
            }
            return
        }
        
        guard let position = position,
              let originArray = UserDefaults.standard.array(forKey: "permanent_origin") as? [Float],
              originArray.count == 2 else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.positionLabel.text = "원점이 설정되지 않음"
            }
            return
        }
        
        let originX = originArray[0]
        let originZ = originArray[1]
        
        // 원점으로부터의 상대 위치 계산 (X,Z 평면만)
        let relativeX = position.x - originX
        let relativeZ = position.z - originZ
        
        // 소수점 한 자리까지 표시
        let formattedText = String(format: "(%.1f, %.1f, %.1f)", relativeX, position.y, relativeZ)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.positionLabel.text = formattedText
        }
    }
    
    // MARK: - 초기 방향 설정
    private func setInitialDirection() {
        guard let currentFrame = arSessionManager.arView.session.currentFrame else { return }
        let cameraTransform = currentFrame.camera.transform
        let yaw = atan2(cameraTransform.columns.0.z, cameraTransform.columns.2.z)
        
        initialYaw = yaw
        isInitialYawSet = true
        print("🧭 초기 방향 설정: \(yaw) 라디안")
    }
    
    // MARK: - 미니맵 업데이트
    private func updateMiniMapDirection() {
        guard let currentFrame = arSessionManager.arView.session.currentFrame else { return }
        
        // 카메라의 회전 정보 가져오기
        let cameraTransform = currentFrame.camera.transform
        let currentYaw = atan2(cameraTransform.columns.0.z, cameraTransform.columns.2.z)
        
        // 초기 방향 대비 상대 각도 계산
        let relativeYaw = currentYaw - initialYaw
        
        print("🧭 방향 정보:")
        print("  - 초기 Yaw: \(initialYaw)")
        print("  - 현재 Yaw: \(currentYaw)")
        print("  - 상대 각도: \(relativeYaw)")
        
        // 미니맵에 방향 업데이트 (상대 각도 사용)
        miniMapView.updateDirection(angle: CGFloat(relativeYaw))
        
        // 미니맵에 객체들 업데이트
        updateMiniMapObjects()
    }
    
    // MARK: - 미니맵 객체 업데이트
    private func updateMiniMapObjects() {
        guard let currentFrame = arSessionManager.arView.session.currentFrame else { return }
        
        // 현재 카메라 위치 (내 위치)
        let cameraTransform = currentFrame.camera.transform
        let playerPosition = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        
        // 객체 위치들 가져오기
        let objectPositions = arModelManager.getObjectPositions()
        
        print("🎯 미니맵 객체 업데이트:")
        print("  - 내 위치: \(playerPosition)")
        print("  - 객체 개수: \(objectPositions.count)")
        
        // 미니맵에 객체들 업데이트
        miniMapView.updateObjects(objectPositions: objectPositions, playerPosition: playerPosition)
    }
}
