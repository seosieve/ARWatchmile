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
    
    var anchor1: SIMD2<Float>?
    var anchor2: SIMD2<Float>?
    var anchor3: SIMD2<Float>?
    
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
                    self.anchorIdMap[anchor.identifier] = anchorId
                    if anchorId == "ua-2176bdc4351f88ba81705a195789551b" { anchor1 = anchor.transform.translation }
                    if anchorId == "ua-38f273c97c0bab7afeffeac4a48294c8" { anchor2 = anchor.transform.translation }
                    if anchorId == "ua-29b3bd27bc453443a010c9ff68ec7386" { anchor3 = anchor.transform.translation }
                    
                    
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
        
        for garAnchor in garFrame.anchors {
            // AnchorId 가져오기
//            if let cloudAnchorId = anchorIdMap[garAnchor.identifier] {
//                print("\(cloudAnchorId) : \(garAnchor.transform.translation)")
//            }
            
            // 이미 배치한 model 위치 이동
            if let model = resolvedModels[garAnchor.identifier] {
                calculateDistance(frame: frame, garAnchor: garAnchor)
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
    
    private func calculateDistance(frame: ARFrame, garAnchor: GARAnchor) {
        let cameraPos = frame.camera.transform.translation
        let anchorPos = garAnchor.transform.translation
        
        let relativePos = SIMD2<Float>(cameraPos.x - anchorPos.x, cameraPos.y - anchorPos.y)
    }
    
    private func createCloudAnchorModel() -> Entity? {
        return try? Entity.load(named: Constants.cloudAnchorName)
    }
}
