//
//  ResolvingPickerViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/5/25.
//

import UIKit
import Then
import SnapKit

class ResolvingPickerViewController: UIViewController {
    
    private var viewModel: ResolvingPickerViewModel
    
    private lazy var selectAllButton = UIButton().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
        $0.setTitle("모두 선택", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        $0.addTarget(self, action: #selector(selectAllButtonTapped), for: .touchUpInside)
    }
    
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
    
    @objc func selectAllButtonTapped() {
        if viewModel.anchorIdSelection.count == viewModel.anchorInfos.count {
            // 이미 모두 선택된 경우 → 해제
            viewModel.deselectAllAnchor()
            for row in 0..<viewModel.anchorInfos.count {
                let indexPath = IndexPath(row: row, section: 0)
                tableView.deselectRow(at: indexPath, animated: true)
            }
        } else {
            // 모두 선택
            viewModel.selectAllAnchor()
            for row in 0..<viewModel.anchorInfos.count {
                let indexPath = IndexPath(row: row, section: 0)
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
    }
    
    @objc func resolvingButtonTapped() {
        let viewModel = ARCoreViewModel(selectedAnchor: viewModel.anchorIdSelection)
        let viewController = ARCoreViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    init(viewModel: ResolvingPickerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: true)
        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        tableView.delegate = self
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(selectAllButton)
        selectAllButton.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.width.equalTo(84)
            make.height.equalTo(44)
        }
        
        view.addSubview(resolvingButton)
        resolvingButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(60)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(selectAllButton.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(resolvingButton.snp.top).offset(-20)
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension ResolvingPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.anchorInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: PickerTableViewCell.identifier, for: indexPath)
        guard let cell = reusableCell as? PickerTableViewCell else { return UITableViewCell() }
        
        cell.configure(anchorInfo: viewModel.anchorInfos[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectAnchor(index: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        viewModel.deselectAnchor(index: indexPath.row)
    }
}
