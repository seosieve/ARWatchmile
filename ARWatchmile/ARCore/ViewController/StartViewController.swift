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
    
    private let data = ["첫 번째 타이틀", "두 번째 타이틀", "세 번째 타이틀", "네 번째 타이틀"]
    
    private let tableView = UITableView().then {
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = false
        $0.register(PickerTableViewCell.self, forCellReuseIdentifier: PickerTableViewCell.identifier)
    }
    
    private lazy var resolvingButton = UIButton().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
        $0.setTitle("Resolving", for: .normal)
        $0.addTarget(self, action: #selector(resolvingButtonTapped), for: .touchUpInside)
    }
    
    @objc func resolvingButtonTapped() {
        let arCoreVC = ARCoreViewController()
        navigationController?.pushViewController(arCoreVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(resolvingButton)
        resolvingButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(60)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(resolvingButton.snp.top).offset(-20)
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension StartViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PickerTableViewCell.identifier, for: indexPath) as? PickerTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(title: data[indexPath.row])
        return cell
    }
    
    // 높이 고정 또는 동적 설정 가능
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
}
