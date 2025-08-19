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
    private var ratio: Float = 0
    private var affineTransform: CGAffineTransform?
    
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
        ratio = Float(mapSize.width / Constants.originMapSize.width)
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
        let scale: Float = Float(mapSize.width / Constants.originMapSize.width)
        let rawData = RawData.AnchorPointArr
        
        for location in rawData.values {
            let objectView = UIView().then {
                $0.backgroundColor = .blue
                $0.layer.cornerRadius = 2
            }
            
            addSubview(objectView)
            testBoxViews.append(objectView)
            
            objectView.snp.makeConstraints { make in
                make.centerX.equalTo(officeImageView.snp.left).offset(location.x * scale)
                make.centerY.equalTo(officeImageView.snp.top).offset(location.y * scale)
                make.width.height.equalTo(4)
            }
        }
    }
    
    private func calculateAffine(resolvedAnchors: [ResolvedAnchor]) -> CGAffineTransform {
        var sourcePoints: [SIMD2<Float>] = []
        var targetPoints: [SIMD2<Float>] = []
        
        for anchor in resolvedAnchors {
            sourcePoints.append(anchor.location)
            targetPoints.append(RawData.AnchorPointArr[anchor.id]! * ratio)
        }
        
        let transform = AffineTransform.calculate(from: sourcePoints, to: targetPoints)
        
        return transform
    }
    
    // MARK: - 내 위치 업데이트
    func updatePlayerPosition(resolvedAnchors: [ResolvedAnchor], playerPosition: SIMD2<Float>) {
        let affineTransform = affineTransform ?? calculateAffine(resolvedAnchors: resolvedAnchors)

        let playerPoint = CGPoint(x: CGFloat(playerPosition.x), y: CGFloat(playerPosition.y))
        let transformedPoint = playerPoint.applying(affineTransform)
        print(transformedPoint)
        playerDot.backgroundColor = .green
        
        playerDot.snp.remakeConstraints { make in
            make.centerX.equalTo(officeImageView.snp.left).offset(transformedPoint.x)
            make.centerY.equalTo(officeImageView.snp.top).offset(transformedPoint.y)
            make.width.height.equalTo(8)
        }
    }
}

