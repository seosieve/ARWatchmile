//
//  ViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/22/25.
//

import UIKit
import ARKit
import RealityKit

class ViewController: UIViewController {
    var arSessionManager: ARSessionManager!
    var setOriginButton: UIButton!
    var positionLabel: UILabel!
    var statusLabel: UILabel!
    var mapViewButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arSessionManager = ARSessionManager()
        arSessionManager.arView = ARView(frame: view.bounds)
        view.addSubview(arSessionManager.arView)
        setupButtons()
        setupPositionLabel()
        setupStatusLabel()
        setupMapViewButton()
        arSessionManager.startARSession()
        // 카메라 위치 업데이트 콜백 연결
        arSessionManager.onCameraPositionUpdate = { [weak self] position in
            self?.updatePositionLabel(position: position)
        }
        // 트래킹 상태 업데이트 콜백 연결
        arSessionManager.onTrackingStatusUpdate = { [weak self] status in
            self?.updateStatusLabel(status: status)
        }
        // 상태 체크 타이머 추가 (1초마다)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            let originArray = UserDefaults.standard.array(forKey: "permanent_origin") as? [Float]
            self?.arSessionManager.checkTrackingStatus(originArray: originArray)
        }
    }
    
    func setupStatusLabel() {
        statusLabel = UILabel()
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        
        let labelHeight: CGFloat = 32
        statusLabel.frame = CGRect(
            x: 20,
            y: positionLabel.frame.minY - labelHeight - 8,
            width: view.bounds.width - 40,
            height: labelHeight
        )
        
        updateStatusLabel(status: .searching)
        view.addSubview(statusLabel)
    }
    
    func updateStatusLabel(status: TrackingStatus) {
        DispatchQueue.main.async {
            self.statusLabel.text = status.description
            self.statusLabel.textColor = status.color
        }
    }
    
    func setupButtons() {
        // 원점 설정 버튼
        setOriginButton = UIButton(type: .system)
        setOriginButton.setTitle("이 위치를 원점으로 설정", for: .normal)
        setOriginButton.backgroundColor = .systemBlue
        setOriginButton.setTitleColor(.white, for: .normal)
        setOriginButton.layer.cornerRadius = 8
        setOriginButton.addTarget(self, action: #selector(setOriginButtonTapped), for: .touchUpInside)
        setOriginButton.frame = CGRect(x: 20, y: 50, width: 100, height: 50)
        view.addSubview(setOriginButton)
        
        let saveWorldMapButton = UIButton(type: .system)
        saveWorldMapButton.setTitle("월드맵 저장", for: .normal)
        saveWorldMapButton.backgroundColor = .systemGreen
        saveWorldMapButton.setTitleColor(.white, for: .normal)
        saveWorldMapButton.layer.cornerRadius = 8
        saveWorldMapButton.addTarget(self, action: #selector(saveWorldMapButtonTapped), for: .touchUpInside)
        saveWorldMapButton.frame = CGRect(x: 20, y: 120, width: 120, height: 50)
        view.addSubview(saveWorldMapButton)
    }
    
    func setupPositionLabel() {
        positionLabel = UILabel()
        positionLabel.numberOfLines = 0
        positionLabel.textAlignment = .center
        positionLabel.font = .systemFont(ofSize: 24, weight: .bold)
        positionLabel.textColor = .white
        positionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        positionLabel.layer.cornerRadius = 12
        positionLabel.layer.masksToBounds = true
        
        let labelHeight: CGFloat = 60
        positionLabel.frame = CGRect(
            x: 20,
            y: view.bounds.height - labelHeight - 20 - view.safeAreaInsets.bottom,
            width: view.bounds.width - 40,
            height: labelHeight
        )
        
        view.addSubview(positionLabel)
    }
    
    func setupMapViewButton() {
        mapViewButton = UIButton(type: .system)
        mapViewButton.setTitle("2D 맵 보기", for: .normal)
        mapViewButton.backgroundColor = .systemIndigo
        mapViewButton.setTitleColor(.white, for: .normal)
        mapViewButton.layer.cornerRadius = 8
        mapViewButton.addTarget(self, action: #selector(mapViewButtonTapped), for: .touchUpInside)
        
        // 상단 오른쪽에 배치
        let buttonSize: CGFloat = 100
        let padding: CGFloat = 16
        mapViewButton.frame = CGRect(
            x: view.bounds.width - buttonSize - padding,
            y: setOriginButton.frame.minY,
            width: buttonSize,
            height: 50
        )
        
        view.addSubview(mapViewButton)
    }
    
    @objc func setOriginButtonTapped() {
        // 현재 위치를 원점으로 저장 (월드맵 저장 X)
        guard let currentFrame = arSessionManager.arView.session.currentFrame else { return }
        let transform = currentFrame.camera.transform
        let position = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        UserDefaults.standard.set([position.x, position.z], forKey: "permanent_origin")
        // UI 피드백 등만 처리
    }
    
    @objc func mapViewButtonTapped() {
        let mapVC = MapViewController()
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
    
    @objc func saveWorldMapButtonTapped() {
        arSessionManager.saveWorldMap()
        // UI 피드백(예: 저장 완료 토스트 등) 추가 가능
        print("🟩 월드맵 수동 저장")
    }
    
    func updatePositionLabel(position: SIMD3<Float>?) {
        if !arSessionManager.isMapMatched {
            DispatchQueue.main.async {
                self.positionLabel.text = "위치 매칭 중..."
            }
            return
        }
        
        guard let position = position,
              let originArray = UserDefaults.standard.array(forKey: "permanent_origin") as? [Float],
              originArray.count == 2 else {
            DispatchQueue.main.async {
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
        let formattedText = String(format: "(%.1f, %.1f)", relativeX, relativeZ)
        
        DispatchQueue.main.async {
            self.positionLabel.text = formattedText
        }
    }
}

