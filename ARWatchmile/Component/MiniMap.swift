//
//  MiniMap.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/31/25.
//

import UIKit
import Then
import SnapKit

class MiniMapView: UIView {
    private var officeMapImageView = UIImageView().then {
        $0.image = UIImage(named: "OfficeMap")
        $0.contentMode = .scaleAspectFit
        $0.alpha = 0.7 // 약간 투명하게
    }
    
    private var testBoxViews: [UIView] = []
    
    private var playerDot = UIView().then {
        $0.backgroundColor = .yellow
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
    }
    
    // 방향을 나타내는 부채꼴
    private var directionCone = DirectionIndicatorView()
    
    // 방향 조절을 위한 각도 오프셋 (라디안 단위, 85도)
    private var directionOffset: CGFloat = 60 * .pi / 180
    
    // 처음 시작점 조정 변수들
    private var initialMapOffsetX: CGFloat = 0.0 // 지도 초기 X 오프셋
    private var initialMapOffsetY: CGFloat = 0.0 // 지도 초기 Y 오프셋
    private var initialRotationAngle: CGFloat = 0.0 // 지도 초기 회전 각도 (라디안)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateTestBoxes()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
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
//    func updateDirection(angle: CGFloat) {
//        // 절대 방향 + 조절 가능한 오프셋
//        let adjustedAngle = angle + directionOffset
//        directionCone.transform = CGAffineTransform(rotationAngle: adjustedAngle)
//        
//        // 라디안을 도로 변환해서 로그 출력
//        let angleDegrees = angle * 180 / .pi
//        let offsetDegrees = directionOffset * 180 / .pi
//        let adjustedDegrees = adjustedAngle * 180 / .pi
//        
//        print("🧭 미니맵 방향 업데이트:")
//        print("  - 원본 각도: \(angle) 라디안 (\(angleDegrees)°)")
//        print("  - 오프셋: \(directionOffset) 라디안 (\(offsetDegrees)°)")
//        print("  - 조정된 각도: \(adjustedAngle) 라디안 (\(adjustedDegrees)°)")
//    }
    
    // MARK: - 빨간 테스트 박스 위치 생성
    func updateTestBoxes() {
        let coordinates = [(0, 0), (0, 100), (80, 0), (80, 100)]
        
        for (x, y) in coordinates {
            let objectView = UIView().then {
                $0.backgroundColor = .red
                $0.layer.cornerRadius = 2
            }
            
            addSubview(objectView)
            testBoxViews.append(objectView)
            
            objectView.snp.makeConstraints { make in
                make.centerX.equalTo(officeMapImageView.snp.left).offset(x)
                make.centerY.equalTo(officeMapImageView.snp.top).offset(y)
                make.width.height.equalTo(6)
            }
        }
        
        affineTest()
    }
    
    func affineTest() {
        let sourcePoints: [SIMD3<Float>] = [
            SIMD3<Float>(0.0, 0.0, 0.0),
            SIMD3<Float>(6.7, 0.0, 6.0),
            SIMD3<Float>(5.1, 0.0, -5.1),
            SIMD3<Float>(11.7, 0.0, 0.8)
        ]

        let targetPoints: [SIMD3<Float>] = [
            SIMD3<Float>(0.0, 0.0, 0.0),
            SIMD3<Float>(0.0, 0.0, 100.0),
            SIMD3<Float>(80.0, 0.0, 0.0),
            SIMD3<Float>(80.0, 0.0, 100.0)
        ]
        
        let transform = AffineTransform.calculate(from: sourcePoints, to: targetPoints)
        
        // 각 점을 테스트
        for i in 0..<4 {
            let sourcePoint = CGPoint(x: CGFloat(sourcePoints[i].x), y: CGFloat(sourcePoints[i].z))
            let transformedPoint = sourcePoint.applying(transform)
            let expectedPoint = CGPoint(x: CGFloat(targetPoints[i].x), y: CGFloat(targetPoints[i].z))
            
            print("점 \(i): \(sourcePoint) → \(transformedPoint) (예상: \(expectedPoint))")
        }
    }
    
    // MARK: - 내 위치 업데이트
    func updatePlayerPosition(playerPosition: SIMD3<Float>) {
        // 내 위치 점 업데이트 (OfficeMap 기준으로 통일)
//        playerDot.snp.remakeConstraints { make in
//            make.centerX.equalTo(officeMapImageView).offset(playerOfficeMapX - 182.5) // OfficeMap 중앙 기준
//            make.centerY.equalTo(officeMapImageView).offset(playerOfficeMapY - 50) // OfficeMap 중앙 기준
//            make.width.height.equalTo(8)
//        }
    }
}

