//
//  AffineTransform.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/1/25.
//

import Foundation
import simd

class AffineTransform {
    static func calculate(from sourcePoints: [SIMD2<Float>], to targetPoints: [SIMD2<Float>]) -> CGAffineTransform {
        guard sourcePoints.count >= 2, targetPoints.count >= 2 else {
            return .identity
        }
        
        let p1 = SIMD2<Float>(sourcePoints[0].x, sourcePoints[0].y)
        let p2 = SIMD2<Float>(sourcePoints[1].x, sourcePoints[1].y)
        let q1 = SIMD2<Float>(targetPoints[0].x, targetPoints[0].y)
        let q2 = SIMD2<Float>(targetPoints[1].x, targetPoints[1].y)
        
        // 벡터 추출
        let v1 = p2 - p1
        let v2 = q2 - q1
        
        // 회전 각도
        let angle = atan2(v2.y, v2.x) - atan2(v1.y, v1.x)
        
        // 스케일
        let scale = simd_length(v2) / simd_length(v1)
        
        // Transform 조합
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: CGFloat(q1.x), y: CGFloat(q1.y))
        transform = transform.rotated(by: CGFloat(angle))
        transform = transform.scaledBy(x: CGFloat(scale), y: CGFloat(scale))
        transform = transform.translatedBy(x: CGFloat(-p1.x), y: CGFloat(-p1.y))
        
        return transform
    }
}


