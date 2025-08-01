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
    
    // OfficeMap 이미지 뷰
    private var officeMapImageView = UIImageView().then {
        $0.image = UIImage(named: "OfficeMap")
        $0.contentMode = .scaleAspectFit
        $0.alpha = 0.7 // 약간 투명하게
    }
    
    // 방향 조절을 위한 각도 오프셋 (라디안 단위, 85도)
    private var directionOffset: CGFloat = 60 * .pi / 180
    
    // 처음 시작점 조정 변수들
    private var initialMapOffsetX: CGFloat = 0.0 // 지도 초기 X 오프셋
    private var initialMapOffsetY: CGFloat = 0.0 // 지도 초기 Y 오프셋
    private var initialRotationAngle: CGFloat = 0.0 // 지도 초기 회전 각도 (라디안)
    
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
        layer.masksToBounds = true // overflow hidden
        
        // OfficeMap 이미지 추가 (맨 뒤에)
        addSubview(officeMapImageView)
        officeMapImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(365)
            make.height.equalTo(100)
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
    
    // MARK: - 빨간 네모들과 내 위치 업데이트 (OfficeMap 좌표에 매핑)
    func updateObjects(objectPositions: [SIMD3<Float>], playerPosition: SIMD3<Float>, relativePosition: CGPoint) {
        // 기존 객체 뷰들 제거
        objectViews.forEach { $0.removeFromSuperview() }
        objectViews.removeAll()
        
        print("🎯 미니맵 업데이트:")
        print("  - 내 위치: \(playerPosition)")
        print("  - 상대 위치: \(relativePosition)")
        print("  - 객체 개수: \(objectPositions.count)")
        
        // 실제 위치 → OfficeMap 좌표 변환식 찾기
        // 빨간점들의 실제 위치와 OfficeMap 좌표 매핑
        let actualPositions = [
            (x: 0.0, z: 0.0),      // 실제 위치
            (x: 6.7, z: 6.0),      // 실제 위치
            (x: 5.1, z: -5.1),     // 실제 위치
            (x: 11.7, z: 0.8)      // 실제 위치
        ]
        
        let officeMapCoordinates = [
            CGPoint(x: 0, y: 0),    // OfficeMap 좌표
            CGPoint(x: 0, y: 100),  // OfficeMap 좌표
            CGPoint(x: 80, y: 0),   // OfficeMap 좌표
            CGPoint(x: 80, y: 100)  // OfficeMap 좌표
        ]
        
        // 아핀변환을 사용한 정확한 매핑
        let playerActualX = relativePosition.x
        let playerActualZ = relativePosition.y
        
        // 아핀변환 행렬 계산 (4개 점 매핑)
        let sourcePoints = [
            CGPoint(x: actualPositions[0].x, y: actualPositions[0].z),  // (0, 0)
            CGPoint(x: actualPositions[1].x, y: actualPositions[1].z),  // (6.7, 6.0)
            CGPoint(x: actualPositions[2].x, y: actualPositions[2].z),  // (5.1, -5.1)
            CGPoint(x: actualPositions[3].x, y: actualPositions[3].z)   // (11.7, 0.8)
        ]
        
        let targetPoints = [
            CGPoint(x: officeMapCoordinates[0].x, y: officeMapCoordinates[0].y),  // (0, 0)
            CGPoint(x: officeMapCoordinates[1].x, y: officeMapCoordinates[1].y),  // (0, 100)
            CGPoint(x: officeMapCoordinates[2].x, y: officeMapCoordinates[2].y),  // (80, 0)
            CGPoint(x: officeMapCoordinates[3].x, y: officeMapCoordinates[3].y)   // (80, 100)
        ]
        
        // 아핀변환 행렬 계산
        let transform = calculateAffineTransform(from: sourcePoints, to: targetPoints)
        
        // 플레이어 위치를 OfficeMap 좌표로 변환
        let playerPoint = CGPoint(x: playerActualX, y: playerActualZ)
        let transformedPoint = playerPoint.applying(transform)
        
        let playerOfficeMapX = transformedPoint.x
        let playerOfficeMapY = transformedPoint.y
        
        print("  - 아핀변환 적용: (\(playerActualX), \(playerActualZ)) → (\(playerOfficeMapX), \(playerOfficeMapY))")
        
        print("  - 내 위치: 상대(\(relativePosition.x), \(relativePosition.y)) → OfficeMap(\(playerOfficeMapX), \(playerOfficeMapY))")
        print("  - 노란점 최종 위치: (\(playerOfficeMapX - 182.5), \(playerOfficeMapY - 50))")
        
        // 내 위치 점 업데이트 (OfficeMap 기준으로 통일)
        playerDot.snp.remakeConstraints { make in
            make.centerX.equalTo(officeMapImageView).offset(playerOfficeMapX - 182.5) // OfficeMap 중앙 기준
            make.centerY.equalTo(officeMapImageView).offset(playerOfficeMapY - 50) // OfficeMap 중앙 기준
            make.width.height.equalTo(8)
        }
        
        // 새로운 객체 뷰들 생성 (고정 위치)
        for (index, position) in objectPositions.enumerated() {
            let objectView = UIView().then {
                $0.backgroundColor = .red
                $0.layer.cornerRadius = 2
                $0.layer.masksToBounds = true
            }
            
            addSubview(objectView)
            objectViews.append(objectView)
            
            // OfficeMap 좌표로 고정 위치 설정
            let officeMapPoint = officeMapCoordinates[index]
            
            print("  - 객체 \(index + 1): 실제위치(\(position.x), \(position.z)) → OfficeMap위치(\(officeMapPoint.x), \(officeMapPoint.y))")
            
            // OfficeMap 이미지뷰 기준 좌표로 설정
            objectView.snp.makeConstraints { make in
                make.centerX.equalTo(officeMapImageView).offset(officeMapPoint.x - 182.5) // OfficeMap 중앙 기준
                make.centerY.equalTo(officeMapImageView).offset(officeMapPoint.y - 50) // OfficeMap 중앙 기준
                make.width.height.equalTo(6)
            }
            print("  - 객체 \(index + 1): OfficeMap 기준 위치(\(officeMapPoint.x), \(officeMapPoint.y))")
        }
    }
    
    // MARK: - 아핀변환 계산 함수
    private func calculateAffineTransform(from sourcePoints: [CGPoint], to targetPoints: [CGPoint]) -> CGAffineTransform {
        // 3개 점을 사용한 아핀변환 계산 (4개 점 중 3개 사용)
        let p1 = sourcePoints[0]
        let p2 = sourcePoints[1]
        let p3 = sourcePoints[2]
        
        let q1 = targetPoints[0]
        let q2 = targetPoints[1]
        let q3 = targetPoints[2]
        
        // 아핀변환 행렬 계산
        let det = p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y)
        
        let a = (q1.x * (p2.y - p3.y) + q2.x * (p3.y - p1.y) + q3.x * (p1.y - p2.y)) / det
        let b = (q1.x * (p3.x - p2.x) + q2.x * (p1.x - p3.x) + q3.x * (p2.x - p1.x)) / det
        let c = (q1.y * (p2.y - p3.y) + q2.y * (p3.y - p1.y) + q3.y * (p1.y - p2.y)) / det
        let d = (q1.y * (p3.x - p2.x) + q2.y * (p1.x - p3.x) + q3.y * (p2.x - p1.x)) / det
        let tx = (q1.x * (p2.x * p3.y - p3.x * p2.y) + q2.x * (p3.x * p1.y - p1.x * p3.y) + q3.x * (p1.x * p2.y - p2.x * p1.y)) / det
        let ty = (q1.y * (p2.x * p3.y - p3.x * p2.y) + q2.y * (p3.x * p1.y - p1.x * p3.y) + q3.y * (p1.x * p2.y - p2.x * p1.y)) / det
        
        return CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
    }
}

