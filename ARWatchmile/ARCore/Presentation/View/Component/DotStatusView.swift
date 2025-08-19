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
    
    private let redDot = UIView().then {
        $0.backgroundColor = .red
        $0.layer.cornerRadius = 4
    }
    
    private let redLabel = UILabel().then {
        $0.text = "빨간점"
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .white
    }
    
    private let blueDot = UIView().then {
        $0.backgroundColor = .blue
        $0.layer.cornerRadius = 4
    }
    
    private let blueLabel = UILabel().then {
        $0.text = "파란점"
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .white
    }
    
    private let yellowDot = UIView().then {
        $0.backgroundColor = .yellow
        $0.layer.cornerRadius = 4
    }
    
    private let yellowLabel = UILabel().then {
        $0.text = "노란점"
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
        addSubview(redDot)
        redDot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(8)
        }
        
        addSubview(redLabel)
        redLabel.snp.makeConstraints { make in
            make.leading.equalTo(redDot.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        
        addSubview(blueDot)
        blueDot.snp.makeConstraints { make in
            make.leading.equalTo(redLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(8)
        }
        
        addSubview(blueLabel)
        blueLabel.snp.makeConstraints { make in
            make.leading.equalTo(blueDot.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        
        addSubview(yellowDot)
        yellowDot.snp.makeConstraints { make in
            make.leading.equalTo(blueLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(8)
        }
        
        addSubview(yellowLabel)
        yellowLabel.snp.makeConstraints { make in
            make.leading.equalTo(yellowDot.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
        }
    }
}
