//
//  MiniMap.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/31/25.
//

import UIKit
import SnapKit
import Then

// 부채꼴 모양의 방향 표시기
class DirectionIndicatorView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear // 배경을 투명하게
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear // 배경을 투명하게
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2 - 2
        
        // 부채꼴 그리기
        context.setFillColor(UIColor.orange.withAlphaComponent(0.6).cgColor)
        context.move(to: center)
        context.addArc(center: center, radius: radius, startAngle: -CGFloat.pi / 4, endAngle: CGFloat.pi / 4, clockwise: false)
        context.closePath()
        context.fillPath()
    }
}

class MiniMapView: UIView {
    
    // 내 위치를 나타내는 노란 점
    private var playerDot = UIView().then {
        $0.backgroundColor = .yellow
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
    }
    
    // 방향을 나타내는 부채꼴
    private var directionCone = DirectionIndicatorView()
    
    // 빨간 네모들을 나타내는 뷰들
    private var objectViews: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
        // 크기 제약 설정
        snp.makeConstraints { make in
            make.width.equalTo(160)
            make.height.equalTo(160)
        }
        
        // 방향 부채꼴 추가
        addSubview(directionCone)
        directionCone.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(32)
            make.height.equalTo(32)
        }
        
        // 내 위치 점 추가
        addSubview(playerDot)
        playerDot.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(8)
        }
    }
    
    // MARK: - 방향 업데이트
    func updateDirection(angle: CGFloat) {
        // 부채꼴 회전
        directionCone.transform = CGAffineTransform(rotationAngle: angle)
    }
    
    // MARK: - 빨간 네모들 업데이트
    func updateObjects(objectPositions: [SIMD3<Float>], playerPosition: SIMD3<Float>) {
        // 기존 객체 뷰들 제거
        objectViews.forEach { $0.removeFromSuperview() }
        objectViews.removeAll()
        
        print("🎯 미니맵 업데이트:")
        print("  - 내 위치: \(playerPosition)")
        print("  - 객체 개수: \(objectPositions.count)")
        
        // 새로운 객체 뷰들 생성
        for (index, position) in objectPositions.enumerated() {
            let objectView = UIView().then {
                $0.backgroundColor = .red
                $0.layer.cornerRadius = 2
                $0.layer.masksToBounds = true
            }
            
            addSubview(objectView)
            objectViews.append(objectView)
            
            // 내 위치 기준으로 상대 위치 계산
            let relativeX = position.x - playerPosition.x
            let relativeZ = position.z - playerPosition.z
            
            // 미니맵 스케일 (실제 거리를 미니맵 크기에 맞게 조정)
            let scale: Float = 10 // 더 큰 스케일로 조정
            let mapX = CGFloat(relativeX * scale)
            let mapY = CGFloat(relativeZ * scale)
            
            print("  - 객체 \(index + 1): 상대위치(\(relativeX), \(relativeZ)) -> 미니맵위치(\(mapX), \(mapY))")
            
            // 미니맵 경계 내에 있는지 확인
            let maxOffset: CGFloat = 70 // 미니맵 반지름보다 작게
            let clampedX = max(-maxOffset, min(maxOffset, mapX))
            let clampedY = max(-maxOffset, min(maxOffset, mapY))
            
            objectView.snp.makeConstraints { make in
                make.centerX.equalToSuperview().offset(clampedX)
                make.centerY.equalToSuperview().offset(clampedY)
                make.width.height.equalTo(6) // 크기도 증가
            }
        }
        
        print("🎯 미니맵에 \(objectPositions.count)개 객체 표시됨")
    }
}

