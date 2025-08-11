//
//  ARCloudAnchorManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/6/25.
//

import ARKit
import ARCore
import ARKit
import RealityKit

class ARCloudAnchorManager {
    private(set) weak var arView: ARView?
    
    private var resolvedAnchorIds: [String] = []
    private var resolveFutures: [GARResolveCloudAnchorFuture] = []
    
    var garSession: GARSession?
    
    func startSession(arView: ARView) {
        self.arView = arView
        // Only show planes in hosting mode.
        runSession(trackPlanes: resolvedAnchorIds.isEmpty)
    }
    
    func runSession(trackPlanes: Bool) {
        guard let view = arView else { return }
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        if trackPlanes { configuration.planeDetection = [.horizontal, .vertical] }
        view.session.run(configuration, options: .removeExistingAnchors)
    }
    
    private func createGARSession() -> Bool {
        guard let session = try? GARSession(apiKey: Constants.apiKey, bundleIdentifier: nil) else { return false }
        garSession = session
        
        let configuration = GARSessionConfiguration()
        configuration.cloudAnchorMode = .enabled
        
        var configError: NSError?
        session.setConfiguration(configuration, error: &configError)
        if configError != nil { return false }
        
        return true
    }
    
    func transferAnchor(_ anchorIdSelection: Set<String>) {
        resolvedAnchorIds = Array(anchorIdSelection)
        resolveAnchors()
    }
    
    private func resolveAnchors() {
        guard createGARSession(), let garSession else { return }
        for anchorId in resolvedAnchorIds {
            do {
                resolveFutures.append(
                    try garSession.resolveCloudAnchor(anchorId) { [weak self] anchor, cloudState in
                        guard let self else { return }
                        if cloudState == .success {
                            print("Resolved \(anchorId), continuing to refine pose")
                        } else {
                            print("Failed to resolve \(anchorId): ")
                        }
                        if self.resolveFutures.allSatisfy({ $0.state == .done }) {
                            print("Resolve finished")
                        }
                    })
            } catch {
                print("Failed to start resolving operation: \(error)")
            }
        }
    }
}

// MARK: - Anchor Picker
extension ARCloudAnchorManager {
    // Anchor Picker View UI Method
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
