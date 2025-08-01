//
//  DirectionIndicator.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/1/25.
//

import UIKit

// 부채꼴 모양의 방향 표시기
class DirectionIndicatorView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear // 배경을 투명하게
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear // 배경을 투명하게
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2 - 2
        
        // 부채꼴 그리기
        context.setFillColor(UIColor.orange.withAlphaComponent(0.6).cgColor)
        context.move(to: center)
        context.addArc(center: center, radius: radius, startAngle: -CGFloat.pi / 4, endAngle: CGFloat.pi / 4, clockwise: false)
        context.closePath()
        context.fillPath()
    }
}
