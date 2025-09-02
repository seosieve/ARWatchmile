//
//  DotStatusView.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/19/25.
//

import UIKit
import Then
import SnapKit

class DotStatusView: UIView {
    private let lightGrayDot = UIView().then {
        $0.backgroundColor = .lightGray
        $0.layer.cornerRadius = 4
    }
    
    private let unresolvedLabel = UILabel().then {
        $0.text = "Unresolved"
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .white
    }
    
    private let darkGrayDot = UIView().then {
        $0.backgroundColor = .darkGray
        $0.layer.cornerRadius = 4
    }
    
    private let resolvedLabel = UILabel().then {
        $0.text = "Resolved"
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .white
    }
    
    private let calculatingDot = UIView().then {
        $0.backgroundColor = .blue
        $0.layer.cornerRadius = 4
    }
    
    private let calculatingLabel = UILabel().then {
        $0.text = "Calculating"
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
        addSubview(lightGrayDot)
        lightGrayDot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(8)
        }
        
        addSubview(unresolvedLabel)
        unresolvedLabel.snp.makeConstraints { make in
            make.leading.equalTo(lightGrayDot.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        
        addSubview(darkGrayDot)
        darkGrayDot.snp.makeConstraints { make in
            make.leading.equalTo(unresolvedLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(8)
        }
        
        addSubview(resolvedLabel)
        resolvedLabel.snp.makeConstraints { make in
            make.leading.equalTo(darkGrayDot.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        
        addSubview(calculatingDot)
        calculatingDot.snp.makeConstraints { make in
            make.leading.equalTo(resolvedLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(8)
        }
        
        addSubview(calculatingLabel)
        calculatingLabel.snp.makeConstraints { make in
            make.leading.equalTo(calculatingDot.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
        }
    }
}
