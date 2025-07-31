//
//  ViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/22/25.
//

import UIKit
import ARKit
import RealityKit
import CoreLocation

class ARViewController: UIViewController, CLLocationManagerDelegate {
    var arSessionManager: ARSessionManager!
    var arModelManager: ARModelManager!
    
    // 나침반을 위한 Location Manager
    private var locationManager = CLLocationManager()
    
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
        
        // 나침반 설정
        setupCompass()
        
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
            
            // 트래킹 상태 업데이트 콜백
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
        miniMapView.setInitialMapPosition(offsetX: -250, offsetY: -120, rotationAngle: 80)
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
    
    // MARK: - 나침반 설정
    private func setupCompass() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 나침반 권한 요청
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
            print("🧭 나침반 시작됨")
        } else {
            print("❌ 나침반을 사용할 수 없습니다")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // 나침반 방향 업데이트
        let trueHeading = newHeading.trueHeading // 실제 북쪽 기준
        let headingRadians = CGFloat(trueHeading * .pi / 180)
        
        print("🧭 나침반 방향: \(trueHeading)°")
        
        // 미니맵에 나침반 방향 업데이트
        miniMapView.updateDirection(angle: headingRadians)
    }
    
    // MARK: - 미니맵 업데이트 (나침반 방향)
    private func updateMiniMapDirection() {
        // 나침반 방향은 locationManager에서 자동으로 업데이트됨
        // 여기서는 객체들만 업데이트
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
