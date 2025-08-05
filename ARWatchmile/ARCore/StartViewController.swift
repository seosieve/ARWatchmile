//
//  StartViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/5/25.
//

import UIKit
import Then
import SnapKit

class StartViewController: UIViewController {
    
    private lazy var hostingButton = UIButton().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
        $0.setTitle("Hosting", for: .normal)
        $0.addTarget(self, action: #selector(hostingButtonTapped), for: .touchUpInside)
    }
    
    private lazy var resolvingButton = UIButton().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
        $0.setTitle("Resolving", for: .normal)
        $0.addTarget(self, action: #selector(resolvingButtonTapped), for: .touchUpInside)
    }
    
    @objc func hostingButtonTapped() {
        let arCoreVC = ARCoreViewController()
        navigationController?.pushViewController(arCoreVC, animated: true)
    }
    
    @objc func resolvingButtonTapped() {
        let arCoreVC = ARCoreViewController()
        navigationController?.pushViewController(arCoreVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(hostingButton)
        hostingButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(60)
        }
        
        view.addSubview(resolvingButton)
        resolvingButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(hostingButton.snp.top).offset(-20)
            make.height.equalTo(60)
        }
    }
}
