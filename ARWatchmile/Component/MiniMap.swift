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
    
    // 방향 조절을 위한 각도 오프셋 (라디안 단위, 85도)
    private var directionOffset: CGFloat = 60 * .pi / 180
    
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
    
    // MARK: - 방향 업데이트 (절대 방향 + 오프셋)
    func updateDirection(angle: CGFloat) {
        // 절대 방향 + 조절 가능한 오프셋
        let adjustedAngle = angle + directionOffset
        directionCone.transform = CGAffineTransform(rotationAngle: adjustedAngle)
        
        // 라디안을 도로 변환해서 로그 출력
        let angleDegrees = angle * 180 / .pi
        let offsetDegrees = directionOffset * 180 / .pi
        let adjustedDegrees = adjustedAngle * 180 / .pi
        
        print("🧭 미니맵 방향 업데이트:")
        print("  - 원본 각도: \(angle) 라디안 (\(angleDegrees)°)")
        print("  - 오프셋: \(directionOffset) 라디안 (\(offsetDegrees)°)")
        print("  - 조정된 각도: \(adjustedAngle) 라디안 (\(adjustedDegrees)°)")
    }
    
    // MARK: - 방향 오프셋 조절 (디버그용)
    func adjustDirectionOffset(offset: CGFloat) {
        directionOffset = offset
        print("🧭 방향 오프셋 조절: \(offset)")
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
            
            // 경계 밖에 있으면 숨기기
            if abs(mapX) > maxOffset || abs(mapY) > maxOffset {
                objectView.isHidden = true
                print("  - 객체 \(index + 1): 경계 밖으로 숨김 (위치: \(mapX), \(mapY))")
            } else {
                objectView.isHidden = false
                objectView.snp.makeConstraints { make in
                    make.centerX.equalToSuperview().offset(mapX)
                    make.centerY.equalToSuperview().offset(mapY)
                    make.width.height.equalTo(6)
                }
                print("  - 객체 \(index + 1): 경계 내 표시 (위치: \(mapX), \(mapY))")
            }
        }
        
        print("🎯 미니맵에 \(objectPositions.count)개 객체 표시됨")
    }
}

