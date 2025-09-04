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
}

// MARK: - Helper Methods
extension UserDefaultsManager {
    func getAnchorName(id: String) -> String {
        return anchorIdDictionary.first(where: { $0.value == id })?.key ?? ""
    }
}
