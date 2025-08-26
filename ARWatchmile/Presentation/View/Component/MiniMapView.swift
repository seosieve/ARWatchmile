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
    private var firstLayout = true
    private var ratio: Float = 0
    private var resolvedCount: Int = 0
    private var affineTransform: CGAffineTransform?
    
    private var officeImageView = UIImageView().then {
        $0.image = UIImage(named: Constants.officeImage)
        $0.contentMode = .scaleAspectFit
    }
    
    private var anchorViews: [UIView] = []
    
    private var affineAnchorViews: [UIView] = []
    
    private var playerDot = UIView().then {
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard firstLayout else { return }
        firstLayout = false
        ratio = Float(bounds.size.width / Constants.originMapSize.width)
        layoutAnchorPoints()
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
}

// MARK: - Anchor 색상 변경 관련 함수들
extension MiniMapView {
    func changeResolvedColor(of id: String, color: UIColor) {
        if let targetView = anchorViews.first(where: { $0.accessibilityIdentifier == id }) {
            targetView.backgroundColor = color
        }
    }
}

// MARK: - Anchor Point 배치 관련 함수들
extension MiniMapView {
    private func layoutAnchorPoints() {
        let cloudAnchors = MapDataRepository.shared.getAnchorPoints()
        
        for anchor in cloudAnchors {
            let anchorView = makeAnchorView(id: anchor.id, location: SIMD2(anchor: anchor), color: .lightGray)
            addSubview(anchorView)
            anchorViews.append(anchorView)
        }
    }
    
    func layoutAffineAnchorPoints(affineAnchors: [ResolvedAnchor]) {
        var cloudAnchors = MapDataRepository.shared.getAnchorPoints()
        
        affineAnchorViews.forEach { $0.removeFromSuperview() }
        affineAnchorViews.removeAll()
        
        let affineAnchorIds = affineAnchors.map { $0.id }
        cloudAnchors = cloudAnchors.filter { affineAnchorIds.contains($0.id) }
        
        for anchor in cloudAnchors {
            let anchorView = makeAnchorView(id: anchor.id, location: SIMD2(anchor: anchor), color: .blue)
            addSubview(anchorView)
            affineAnchorViews.append(anchorView)
        }
    }
    
    private func makeAnchorView(id: String, location: SIMD2<Float>, color: UIColor) -> UIView {
        let view = UIView().then {
            $0.frame.size = CGSize(width: 4, height: 4)
            $0.backgroundColor = color
            $0.layer.cornerRadius = 2
            $0.accessibilityIdentifier = id
            $0.center = CGPoint(location * ratio)
        }
        return view
    }
}

// MARK: - 내 위치 관련 함수들
extension MiniMapView {
    func updatePlayerPosition(playerPosition: SIMD2<Float>) {
        guard let affineTransform else { return }

        let playerPoint = CGPoint(playerPosition)
        let transformedPoint = playerPoint.applying(affineTransform)
        
        playerDot.backgroundColor = .green
        playerDot.center = CGPoint(x: transformedPoint.x, y: transformedPoint.y)
    }
    
    func calculateAffine(affineAnchors: [ResolvedAnchor]) {
        var sourcePoints: [SIMD2<Float>] = []
        var targetPoints: [SIMD2<Float>] = []
        let cloudAnchors = MapDataRepository.shared.getAnchorPoints()
        
        for anchor in affineAnchors {
            sourcePoints.append(anchor.location)
            let cloudAnchor = cloudAnchors.first(where: { $0.id == anchor.id })!
            targetPoints.append(SIMD2(anchor: cloudAnchor) * ratio)
        }
        
        affineTransform = AffineTransform.calculate(from: sourcePoints, to: targetPoints)
    }
}
