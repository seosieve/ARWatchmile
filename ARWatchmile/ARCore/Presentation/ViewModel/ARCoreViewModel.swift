//
//  ARCoreViewModel.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/6/25.
//

import ARKit
import ARCore
import ARKit
import RealityKit

class ARCoreViewModel {
    let worldOrigin = AnchorEntity(world: matrix_identity_float4x4)
    
    private var garSession: GARSession?
    
    private var resolvedAnchorIds: [String] = []
    private var resolveFutures: [GARResolveCloudAnchorFuture] = []
    private var resolvedModels: [UUID: Entity] = [:]
    private var anchorIdMap: [UUID: String] = [:]
    
    var resolvedAnchors: [ResolvedAnchor] = []
    var affineAnchors: [ResolvedAnchor] = []
    
    init(selectedAnchor: Set<String>) {
        resolvedAnchorIds = Array(selectedAnchor)
        resolveAnchors()
    }
    
    private func resolveAnchors() {
        guard createGARSession(), let garSession else { return }
        for anchorId in resolvedAnchorIds {
            if let future = try? garSession.resolveCloudAnchor(anchorId, completionHandler: { [weak self] anchor, cloudState in
                guard let self = self else { return }
                guard let anchor = anchor else { return }
                
                if cloudState == .success {
                    print("Resolved \(anchorId), continuing to refine pose")
                    // AnchorId와 identifier 맵핑 - update에서 AnchorId 사용하기 위함
                    self.anchorIdMap[anchor.identifier] = anchorId
                    // Resolve된 Anchor
                    resolvedAnchors.append(ResolvedAnchor(id: anchorId, location: anchor.transform.translation))
                    affineAnchors.append(ResolvedAnchor(id: anchorId, location: anchor.transform.translation))
                } else {
                    print("Failed to resolve \(anchorId): ")
                }
                
                if self.resolveFutures.allSatisfy({ $0.state == .done }) {
                    print("Resolve finished")
                }
            }) { resolveFutures.append(future) } else {
                print("Failed to start resolving operation for anchorId: \(anchorId)")
            }
        }
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
    
    func updateResolvedAnchors(frame: ARFrame) {
        guard let garSession = garSession, let garFrame = try? garSession.update(frame) else { return }
        
        print(affineAnchors.count)
        if affineAnchors.count == 4 {
            removeLongest(frame: frame, garFrame: garFrame)
        }
        
        for garAnchor in garFrame.anchors {
            // 이미 배치한 model 위치 이동
            if let model = resolvedModels[garAnchor.identifier] {
                model.transform = Transform(matrix: garAnchor.transform)
                continue
            }
            
            // Model 초기 배치
            guard let model = createCloudAnchorModel() else { continue }
            resolvedModels[garAnchor.identifier] = model
            model.transform = Transform(matrix: garAnchor.transform)
            
            worldOrigin.addChild(model)
        }
    }
    
    private func removeLongest(frame: ARFrame, garFrame: GARFrame) {
        var longest: Float = 0
        var longestId: String = ""
        
        for garAnchor in garFrame.anchors {
            guard let cloudAnchorId = anchorIdMap[garAnchor.identifier] else { continue }
            let distance = calculateDistance(frame: frame, garAnchor: garAnchor)
            if longest < distance {
                longest = distance
                longestId = cloudAnchorId
            }
        }
        
        guard let index = affineAnchors.firstIndex(where: { $0.id==longestId }) else { return }
        affineAnchors.remove(at: index)
        print(affineAnchors.map{ $0.id })
    }
    
    private func calculateDistance(frame: ARFrame, garAnchor: GARAnchor) -> Float {
        let cameraPos = frame.camera.transform.translation
        let anchorPos = garAnchor.transform.translation
        
        return simd_distance(cameraPos, anchorPos)
    }
    
    private func createCloudAnchorModel() -> Entity? {
        return try? Entity.load(named: Constants.cloudAnchorName)
    }
}
