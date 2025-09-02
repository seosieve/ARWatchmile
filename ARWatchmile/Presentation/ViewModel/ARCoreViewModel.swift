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
import Combine

class ARCoreViewModel {
    let worldOrigin = AnchorEntity(world: matrix_identity_float4x4)
    
    private var garSession: GARSession?
    
    private var resolvedAnchorIds: [String] = []
    private var resolveFutures: [GARResolveCloudAnchorFuture] = []
    private var resolvedModels: [UUID: Entity] = [:]
    private var anchorIdMap: [UUID: String] = [:]
    
    var cameraPos: SIMD2<Float> = .zero
    var resolvedAnchors: [ResolvedAnchor] = []
    
    var affineAnchorPublisher = PassthroughSubject<[ResolvedAnchor], Never>()
    var newAnchorPublisher = PassthroughSubject<ResolvedAnchor, Never>()
    
    private var resolvedGARAnchors: [GARAnchor] = []
    
    init() {
        resolvedAnchorIds = MapDataRepository.shared.getAnchorIds()
        resolveAnchors()
    }
    
    private func resolveAnchors() {
        guard createGARSession(), let garSession else { return }
        
        for anchorId in resolvedAnchorIds {
            if let future = try? garSession.resolveCloudAnchor(anchorId, completionHandler: { [weak self] anchor, cloudState in
                guard let self = self else { return }
                guard let anchor = anchor else { return }
                
                if cloudState == .success {
                    self.resolvedGARAnchors.append(anchor)
                    // AnchorId와 identifier 맵핑 - update에서 AnchorId 사용하기 위함
                    self.anchorIdMap[anchor.identifier] = anchorId
                    // Resolve된 Anchor
                    resolvedAnchors.append(ResolvedAnchor(id: anchorId, location: anchor.transform.translation))
                    newAnchorPublisher.send(ResolvedAnchor(id: anchorId, location: anchor.transform.translation))
                    // Resolve된 Anchor 개수가 3개 이상일때 affineAnchorPublisher 초기화
                    setAffineAnchors(resolvedAnchors: resolvedAnchors)
                    
                    if resolvedGARAnchors.count >= 2 {
                        let oldestAnchor = resolvedGARAnchors.removeFirst()
                        garSession.remove(oldestAnchor)
                    }
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
        // Test
        print("GARSession active anchors count: \(garFrame.anchors.count)")
        
        cameraPos = frame.camera.transform.translation
        
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
    
    func updatePOIs(frame: ARFrame) {
        guard let garSession = garSession, let garFrame = try? garSession.update(frame) else { return }
        
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
    
    private func setAffineAnchors(resolvedAnchors: [ResolvedAnchor]) {
        let cameraPos = self.cameraPos
        if resolvedAnchors.count >= 3 {
            for i in 0..<resolvedAnchors.count {
                self.resolvedAnchors[i].distance = simd_distance(cameraPos, resolvedAnchors[i].location)
            }
            
            let affineAnchors = Array(self.resolvedAnchors.sorted { $0.distance < $1.distance }.prefix(3))
            affineAnchorPublisher.send(affineAnchors)
        }
    }
    
    private func createCloudAnchorModel() -> Entity? {
        return try? Entity.load(named: Constants.cloudAnchorName)
    }
}
