//
//  TiltMonitor.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/28/25.
//

import Foundation
import CoreMotion

class TiltMonitor: NSObject {
    private let motionManager = CMMotionManager()
    var onTiltChange: ((Double) -> Void)?
    var onAccelerationChange: ((Double) -> Void)?
    
    func startMonitoring() {
        motionManager.deviceMotionUpdateInterval = 0.1 // 10Hz
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let motion = motion else { return }
            
            let attitude = motion.attitude
            let pitch = attitude.pitch * 180.0 / .pi
            self?.onTiltChange?(pitch)
            
            // 가속도 콜백
            let acceleration = motion.userAcceleration
            self?.onAccelerationChange?(acceleration.y)
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
}
