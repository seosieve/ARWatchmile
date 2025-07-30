//
//  TiltViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/28/25.
//

import UIKit

final class TiltViewController: UIViewController {
    private let tiltMonitor = TiltMonitor()
    private var value: Double = 0
    
    private let coverView = UIView()
    private let pitchLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        setupUI()
        setupTiltMonitoring()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tiltMonitor.stopMonitoring()
    }
}

// MARK: - UI Components
extension TiltViewController {
    private func setupUI() {
        // 하단 반 화면 view
        coverView.backgroundColor = .systemBlue
        coverView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(coverView)
        
        // pitch 라벨
        pitchLabel.text = "Pitch: 0.0°"
        pitchLabel.textAlignment = .center
        pitchLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        pitchLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pitchLabel)
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            pitchLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pitchLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
    }
}

// MARK: - Tilt Interaction
extension TiltViewController {
    private func setupTiltMonitoring() {
        tiltMonitor.onTiltChange = { [weak self] (pitch) in
            self?.handleTiltChange(pitch: pitch)
        }
        
        tiltMonitor.startMonitoring()
    }
    
    private func handleTiltChange(pitch: Double) {
        let pitchText = String(format: "Pitch: %.1f°", pitch)
        pitchLabel.text = pitchText
        print(pitchText)
        
        // pitch가 20도 아래로 가면 화면 완전 덮기
        updateCoverView(pitch: pitch)
    }
    
    private func updateCoverView(pitch: Double) {
        let threshold: Double = 20.0 // 임계값
        
        if pitch < threshold {
            // 화면 완전 덮기
            UIView.animate(
                    withDuration: 0.8,
                    delay: 0,
                    usingSpringWithDamping: 0.7,  // 스프링 강도 (0~1, 낮을수록 튀는 효과)
                    initialSpringVelocity: 0.5,   // 초기 속도
                    options: [.curveEaseInOut],
                    animations: {
                        self.coverView.frame = self.view.bounds
                    },
                    completion: nil
                )
        } else {
            // 원래 크기로 복원
            UIView.animate(
                withDuration: 0.8,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.3,
                options: [.curveEaseInOut],
                animations: {
                    self.coverView.frame = CGRect(
                        x: 0,
                        y: self.view.bounds.height * 0.5,
                        width: self.view.bounds.width,
                        height: self.view.bounds.height * 0.5
                    )
                    self.coverView.backgroundColor = .systemBlue
                },
                completion: nil
            )
        }
    }
}
