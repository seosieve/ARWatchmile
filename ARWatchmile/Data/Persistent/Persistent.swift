//
//  Persistent.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/19/25.
//

import Foundation

class Persistent {
    /// Parameter 형식
    // "기업부설연구소 비상구", "ua-2176bdc4351f88ba81705a195789551b", "2025-08-11 03:00:42 +0000"
    static func insertAnchor(anchorName: String, anchorId: String, anchorTime: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        var timeDictionary = UserDefaultsManager.shared.timeDictionary
        var anchorIdDictionary = UserDefaultsManager.shared.anchorIdDictionary
        
        // 문자열을 Date로 변환
        if let date = dateFormatter.date(from: anchorTime) {
            timeDictionary[anchorName] = date
        }
        
        anchorIdDictionary[anchorName] = anchorId
        
        UserDefaultsManager.shared.timeDictionary = timeDictionary
        UserDefaultsManager.shared.anchorIdDictionary = anchorIdDictionary
        
        print(UserDefaultsManager.shared.timeDictionary)
        print(UserDefaultsManager.shared.anchorIdDictionary)
    }
}
