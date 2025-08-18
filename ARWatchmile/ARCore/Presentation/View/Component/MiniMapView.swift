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
    private var mapSize = CGSize(width: 0, height: 0)
    
    private var officeImageView = UIImageView().then {
        $0.image = UIImage(named: Constants.officeImage)
        $0.contentMode = .scaleAspectFit
    }
    
    private var testBoxViews: [UIView] = []
    
    private var playerDot = UIView().then {
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
    }
    
    // 방향을 나타내는 부채꼴
    private var directionCone = DirectionIndicatorView()
    
    // 방향 조절을 위한 각도 오프셋 (라디안 단위, 85도)
    private var directionOffset: CGFloat = 60 * .pi / 180
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        mapSize = bounds.size
        updateTestBoxes()
    }
    
    private func setupUI() {
        addSubview(officeImageView)
        officeImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(playerDot)
        playerDot.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(8)
        }
    }
    
    // MARK: - 빨간 테스트 박스 위치 생성
    func updateTestBoxes() {
        let scale = mapSize.width / Constants.originMapSize.width
        let coordinates: [(CGFloat,CGFloat)] = [(3039, 601), (3039, 1006)]
        
        for (x, y) in coordinates {
            let objectView = UIView().then {
                $0.backgroundColor = .blue
                $0.layer.cornerRadius = 2
            }
            
            addSubview(objectView)
            testBoxViews.append(objectView)
            
            objectView.snp.makeConstraints { make in
                make.centerX.equalTo(officeImageView.snp.left).offset(x*scale)
                make.centerY.equalTo(officeImageView.snp.top).offset(y*scale)
                make.width.height.equalTo(4)
            }
        }
        
        affineTest()
    }
    
    func createRandomPoints() {
        let objectView = UIView().then {
            $0.backgroundColor = .blue
            $0.layer.cornerRadius = 2
        }
        
        addSubview(objectView)
        testBoxViews.append(objectView)
        
        objectView.snp.makeConstraints { make in
            make.centerX.equalTo(officeImageView.snp.left).offset(Int.random(in: 0...300))
            make.centerY.equalTo(officeImageView.snp.top).offset(Int.random(in: 0...300))
            make.width.height.equalTo(4)
        }
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
        let playerPosition2 = CGPoint(x: CGFloat(playerPosition.x), y: CGFloat(playerPosition.z))
        let transformedPoint = playerPosition2.applying(transform)
        playerDot.backgroundColor = .yellow
        
        playerDot.snp.remakeConstraints { make in
            make.centerX.equalTo(officeImageView.snp.left).offset(transformedPoint.x) // OfficeMap 중앙 기준
            make.centerY.equalTo(officeImageView.snp.top).offset(transformedPoint.y) // OfficeMap 중앙 기준
            make.width.height.equalTo(8)
        }
    }
}

