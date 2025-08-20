//
//  LogVisualizeView.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/20/25.
//

import UIKit
import Then
import SnapKit

class LogVisualizeView: UIView {
    private let logLabel = UILabel().then {
        $0.text = "No Affine Anchor"
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .white
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(logLabel)
        logLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
