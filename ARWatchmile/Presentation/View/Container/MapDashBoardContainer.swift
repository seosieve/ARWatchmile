//
//  MapDashBoardContainer.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 9/2/25.
//

import UIKit
import Then
import SnapKit

class MapDashBoardContainer: UIView {
    private lazy var resetButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: "scope", withConfiguration: config)
        $0.setImage(image, for: .normal)
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        $0.tintColor = .white
        $0.layer.cornerRadius = 16
        $0.addTarget(self, action: #selector(resetMapPosition), for: .touchUpInside)
        $0.setTitle(nil, for: .normal)
    }
    
    private var dotStatusView = DotStatusView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
    }
    
    internal var miniMapView = MiniMapView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
    }
    
    @objc private func resetMapPosition() {
        miniMapView.zoomScale = 1.0
        miniMapView.panOffset = .zero
        miniMapView.isPanning = false
        miniMapView.lastPanTranslation = .zero
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) { [weak self] in
            guard let self else { return }
            self.miniMapView.updateMapTransform()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let resetPoint = resetButton.convert(point, from: self)
        if let hitView = resetButton.hitTest(resetPoint, with: event) { return hitView }
        
        let miniMapPoint = miniMapView.convert(point, from: self)
        if let hitView = miniMapView.hitTest(miniMapPoint, with: event) { return hitView }
        return nil
    }
    
    private func setupUI() {
        self.addSubview(miniMapView)
        miniMapView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(miniMapView.snp.width).multipliedBy(Constants.originConvensiaMapRatio)
        }
        
        self.addSubview(resetButton)
        resetButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.bottom.equalTo(miniMapView.snp.top).offset(-8)
            make.width.height.equalTo(32)
        }
        
        self.addSubview(dotStatusView)
        dotStatusView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.bottom.equalTo(miniMapView.snp.top).offset(-8)
            make.height.equalTo(32)
        }
    }
}
