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
    
    private let manager = ARCloudAnchorManager()
    
    private var anchorIdSelection = Set<String>()
    private var anchorInfos = [AnchorInfo]()
    
    private let tableView = UITableView().then {
        $0.backgroundColor = .white
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
        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        tableView.delegate = self
        setupAnchor()
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
    
    private func setupAnchor() {
        anchorInfos = manager.fetchAndPruneAnchors()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension StartViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        anchorInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PickerTableViewCell.identifier, for: indexPath) as? PickerTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(anchorInfo: anchorInfos[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        anchorIdSelection.insert(anchorInfos[indexPath.row].id)   
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        anchorIdSelection.remove(anchorInfos[indexPath.row].id)
    }
}
