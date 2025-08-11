//
//  ARCloudAnchorManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/6/25.
//

import ARKit
import RealityKit

class ARCloudAnchorManager {
    private static let cloudAnchorName = "cloud_anchor"
    
    static func createCloudAnchorModel() -> Entity? {
        return try? Entity.load(named: cloudAnchorName)
    }
    
    func fetchAndPruneAnchors() -> [AnchorInfo] {
        var timeDictionary = (UserDefaults.standard.dictionary(forKey: Constants.timeDictionaryKey) as? [String: Date]) ?? [:]
        var anchorIdDictionary = (UserDefaults.standard.dictionary(forKey: Constants.anchorIdDictionaryKey) as? [String: String]) ?? [:]
        var infos: [AnchorInfo] = []
        let now = Date()
        
        for (name, time) in timeDictionary.sorted(by: { $0.1.compare($1.1) == .orderedDescending }) {
            let timeInterval = now.timeIntervalSince(time)
            if timeInterval >= Constants.yearSecond {
                timeDictionary.removeValue(forKey: name)
                anchorIdDictionary.removeValue(forKey: name)
                continue
            }
            guard let anchorId = anchorIdDictionary[name] else { continue }
            let age = timeInterval >= 3600 ? "\(Int(timeInterval / 3600))h" : "\(Int(timeInterval / 60))m"
            infos.append(AnchorInfo(id: anchorId, name: name, age: age))
        }
        
        UserDefaults.standard.setValue(timeDictionary, forKey: Constants.timeDictionaryKey)
        UserDefaults.standard.setValue(anchorIdDictionary, forKey: Constants.anchorIdDictionaryKey)
        return infos
    }
}
