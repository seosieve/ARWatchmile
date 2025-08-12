//
//  ResolvingPickerViewModel.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/12/25.
//

import Foundation

class ResolvingPickerViewModel {
    lazy var anchorInfos = fetchAndPruneAnchors()
    var anchorIdSelection = Set<String>()
    
    func selectAnchor(index: Int) {
        anchorIdSelection.insert(anchorInfos[index].id)
    }
    
    func deselectAnchor(index: Int) {
        anchorIdSelection.remove(anchorInfos[index].id)
    }
}

// MARK: - Resolve Anchor Method
extension ResolvingPickerViewModel {
    func fetchAndPruneAnchors() -> [AnchorInfo] {
        var timeDictionary = UserDefaultsManager.shared.timeDictionary
        var anchorIdDictionary = UserDefaultsManager.shared.anchorIdDictionary
        var infos: [AnchorInfo] = []
        let date = Date()
        
        for (name, time) in timeDictionary.sorted(by: { $0.1.compare($1.1) == .orderedDescending }) {
            let timeInterval = date.timeIntervalSince(time)
            if timeInterval >= Seconds.year {
                timeDictionary.removeValue(forKey: name)
                anchorIdDictionary.removeValue(forKey: name)
                continue
            }
            guard let anchorId = anchorIdDictionary[name] else { continue }
            let age = formatAge(from: timeInterval)
            infos.append(AnchorInfo(id: anchorId, name: name, age: age))
        }
        
        UserDefaultsManager.shared.timeDictionary = timeDictionary
        UserDefaultsManager.shared.anchorIdDictionary = anchorIdDictionary
        
        return infos
    }
    
    private func formatAge(from timeInterval: TimeInterval) -> String {
        if timeInterval >= Seconds.month {
            return "\(Int(timeInterval / Seconds.month))개월 전"
        } else if timeInterval >= Seconds.day {
            return "\(Int(timeInterval / Seconds.day))일 전"
        } else if timeInterval >= Seconds.hour {
            return "\(Int(timeInterval / Seconds.hour))시간 전"
        } else {
            return "\(Int(timeInterval / Seconds.minute))분 전"
        }
    }
}
