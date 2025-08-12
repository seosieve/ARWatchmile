//
//  UserDefaultsManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/1/25.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private init() { }
    
    @UserDefault(key: Constants.timeDictionaryKey, defaultValue: [:])
    var timeDictionary: [String: Date]
    
    @UserDefault(key: Constants.anchorIdDictionaryKey, defaultValue: [:])
    var anchorIdDictionary: [String: String]
    
    @UserDefault(key: "permanent_origin", defaultValue: [Float]())
    var permanentOrigin: [Float]
    
    // 편의 메서드 추가
    func setPermanentOrigin(position: SIMD3<Float>) {
        permanentOrigin = [position.x, position.y, position.z]
        print("✔️ 원점 설정됨: \(position.x), \(position.y), \(position.z)")
    }
    
    func getPermanentOrigin() -> SIMD3<Float> {
        let simdPosition = SIMD3<Float>(permanentOrigin[0], permanentOrigin[1], permanentOrigin[2])
        return simdPosition
    }
}
