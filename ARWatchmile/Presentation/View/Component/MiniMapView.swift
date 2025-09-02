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
    
    // 핀치 확대/축소 관련 프로퍼티
    var zoomScale: CGFloat = 1.0
    private let minZoomScale: CGFloat = 0.7
    private let maxZoomScale: CGFloat = 2.3
    
    // 드래그 관련 프로퍼티
    var panOffset: CGPoint = .zero
    
    // 제스처 상태 추적
    var isPanning: Bool = false
    var lastPanTranslation: CGPoint = .zero
    
    // 모든 맵 요소들을 담는 컨테이너 뷰
    private var mapContainerView = UIView()
    
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
        // 컨테이너 뷰 추가
        addSubview(mapContainerView)
        mapContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        mapContainerView.addSubview(convensiaImageView)
        convensiaImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        mapContainerView.addSubview(playerDot)
        playerDot.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(8)
        }
        
        // 핀치 제스처 추가
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
        
        // 팬 제스처 추가 (드래그)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        // 핀치와 팬 제스처가 동시에 인식되도록 설정
        pinchGesture.delegate = self
        panGesture.delegate = self
    }
}

// MARK: - 핀치 확대/축소 기능
extension MiniMapView {
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.numberOfTouches == 2 else { return }
        
        if gesture.state == .changed {
            let scale = gesture.scale
            let newScale = zoomScale * scale
            let clampedScale = max(minZoomScale, min(maxZoomScale, newScale))
            
            guard clampedScale != zoomScale else { return }
            
            // 핀치 중심점 (현재 뷰 좌표계 기준)
            let pinchCenter = gesture.location(in: self)
            
            // 현재 맵 컨테이너의 중심점 (panOffset 적용된 상태)
            let currentMapCenter = CGPoint(x: bounds.midX + panOffset.x, y: bounds.midY + panOffset.y)
            
            // 핀치 중심점에서 맵 중심점까지의 벡터
            let vectorX = currentMapCenter.x - pinchCenter.x
            let vectorY = currentMapCenter.y - pinchCenter.y
            
            // 스케일 변화 비율
            let scaleRatio = clampedScale / zoomScale
            
            // 핀치 중심점을 기준으로 확대/축소하기 위한 새로운 맵 중심점 계산
            let newMapCenterX = pinchCenter.x + vectorX * scaleRatio
            let newMapCenterY = pinchCenter.y + vectorY * scaleRatio
            
            // 새로운 panOffset 계산
            panOffset.x = newMapCenterX - bounds.midX
            panOffset.y = newMapCenterY - bounds.midY
            
            zoomScale = clampedScale
            updateMapTransform()
            
            gesture.scale = 1.0
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if gesture.state == .began {
            isPanning = true
            lastPanTranslation = translation
        } else if gesture.state == .changed {
            let deltaX = translation.x - lastPanTranslation.x
            let deltaY = translation.y - lastPanTranslation.y
            
            panOffset.x += deltaX
            panOffset.y += deltaY
            updateMapTransform()
            
            lastPanTranslation = translation
        } else if gesture.state == .ended || gesture.state == .cancelled {
            isPanning = false
            lastPanTranslation = .zero
        }
    }
    
    func updateMapTransform() {
        // 확대/축소와 드래그를 결합한 transform 적용
        mapContainerView.transform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
        mapContainerView.center = CGPoint(x: bounds.midX + panOffset.x, y: bounds.midY + panOffset.y)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MiniMapView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 핀치와 팬 제스처가 동시에 인식되지 않도록 함
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        if gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer {
            return false
        }
        return true
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            // 두 손가락이 있으면 팬 제스처 비활성화
            return panGesture.numberOfTouches == 1
        }
        if let pinchGesture = gestureRecognizer as? UIPinchGestureRecognizer {
            // 두 손가락이 있어야 핀치 제스처 활성화
            return pinchGesture.numberOfTouches == 2
        }
        return true
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
            mapContainerView.addSubview(anchorView)
            pointOfInterestViews.append(anchorView)
        }
    }
    
    private func layoutAnchorPoints() {
        let cloudAnchors = MapDataRepository.shared.getAnchorPoints()
        
        for anchor in cloudAnchors {
            let anchorView = makeDotView(id: anchor.id, location: SIMD2(anchor: anchor), color: .lightGray)
            mapContainerView.addSubview(anchorView)
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
            mapContainerView.addSubview(anchorView)
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

