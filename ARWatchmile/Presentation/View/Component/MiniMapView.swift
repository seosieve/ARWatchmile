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
    
    private var convensiaImageView = UIImageView().then {
        $0.image = UIImage(named: Constants.convensiaImage)
        $0.contentMode = .scaleAspectFit
    }
    
    private var routePointViews: [UIView] = []
    
    private var routePathViews: [UIView] = []
    
    private var pointOfInterestViews: [UIView] = []
    
    private var cloudAnchorViews: [UIView] = []
    
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
        ratio = Float(bounds.size.width / Constants.originConvensiaMapSize.width)
        layoutPointOfInterests()
        layoutAnchorPoints()
    }
    
    private func setupUI() {
        addSubview(convensiaImageView)
        convensiaImageView.snp.makeConstraints { make in
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
        if let targetView = cloudAnchorViews.first(where: { $0.accessibilityIdentifier == id }) {
            targetView.backgroundColor = color
        }
    }
}

// MARK: - Anchor Point 배치 관련 함수들
extension MiniMapView {
    private func layoutPointOfInterests() {
        let poiDic = MapDataRepository.shared.getPointOfInterests()
        
        for (id, poi) in poiDic {
            let anchorView = makeDotView(id: id, location: SIMD2(x: poi.x, y: poi.y), color: .green)
            addSubview(anchorView)
            pointOfInterestViews.append(anchorView)
        }
    }
    
    private func layoutAnchorPoints() {
        let cloudAnchors = MapDataRepository.shared.getAnchorPoints()
        
        for anchor in cloudAnchors {
            let anchorView = makeDotView(id: anchor.id, location: SIMD2(anchor: anchor), color: .lightGray)
            addSubview(anchorView)
            cloudAnchorViews.append(anchorView)
        }
    }
    
    func layoutAffineAnchorPoints(affineAnchors: [ResolvedAnchor]) {
        var cloudAnchors = MapDataRepository.shared.getAnchorPoints()
        
        affineAnchorViews.forEach { $0.removeFromSuperview() }
        affineAnchorViews.removeAll()
        
        let affineAnchorIds = affineAnchors.map { $0.id }
        cloudAnchors = cloudAnchors.filter { affineAnchorIds.contains($0.id) }
        
        for anchor in cloudAnchors {
            let anchorView = makeDotView(id: anchor.id, location: SIMD2(anchor: anchor), color: .blue)
            addSubview(anchorView)
            affineAnchorViews.append(anchorView)
        }
    }
    
    private func makeDotView(id: String, location: SIMD2<Float>, color: UIColor) -> UIView {
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

// MARK: - POI AR위치 역연산
extension MiniMapView {
    func calculatePOIARPosition() {
        guard affineTransform != nil else { return }
        let poiDic = MapDataRepository.shared.getPointOfInterests()
        let position = poiDic.compactMap { mapToAR(SIMD2<Float>(x: $0.value.x, y: $0.value.x)) }
        ARDataRepository.shared.setPointOfInterests(position: position)
    }
    
    func mapToAR(_ mapPos: SIMD2<Float>) -> SIMD2<Float>? {
        guard let affine = affineTransform else { return nil }
        
        // Map 좌표를 ratio로 나누어서 원래 AR 좌표 스케일에 맞춤
        let point = CGPoint(x: CGFloat(mapPos.x) * CGFloat(ratio), y: CGFloat(mapPos.y) * CGFloat(ratio))
        
        let arPoint = point.applying(affine.inverted())
        return SIMD2<Float>(Float(arPoint.x), Float(arPoint.y))
    }
}
