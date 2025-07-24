import Foundation
import ARKit
import RealityKit
import UIKit

class ARSessionManager: NSObject, ARSessionDelegate {
    var arView: ARView!
    var isMapMatched = false
    var lastAnalysisTime: Date = Date()
    let analysisCooldown: TimeInterval = 0.5
    var onCameraPositionUpdate: ((SIMD3<Float>) -> Void)?
    var onTrackingStatusUpdate: ((TrackingStatus) -> Void)?
    var worldMapURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("worldmap.arexperience")
    }
    
    override init() {
        super.init()
    }
    
    func startARSession() {
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        config.environmentTexturing = .automatic
        config.planeDetection = [.horizontal, .vertical]
        isMapMatched = false
        if let worldMap = loadWorldMap() {
            config.initialWorldMap = worldMap
            print("저장된 맵을 자동으로 불러왔습니다.")
            onTrackingStatusUpdate?(.matching(0.0))
        } else {
            onTrackingStatusUpdate?(.searching)
        }
        arView.session.delegate = self
        arView.session.run(config)
        arView.debugOptions = [.showSceneUnderstanding]
    }
    
    func checkTrackingStatus(originArray: [Float]?) {
        guard let originArray = originArray, originArray.count == 2 else { return }
        arView.session.getCurrentWorldMap { [weak self] worldMap, error in
            guard let self = self, let worldMap = worldMap else { return }
            let pointCount = worldMap.rawFeaturePoints.points.count
            let quality = min(Float(pointCount) / 100.0, 1.0)
            let matched = (quality >= 0.5 && self.arView.session.currentFrame?.camera.trackingState == .normal)
            let trackingState = self.arView.session.currentFrame?.camera.trackingState
            print("quality: \(quality), trackingState: \(String(describing: trackingState))")
            if matched {
                self.isMapMatched = true
                self.onTrackingStatusUpdate?(.matched)
            } else {
                self.onTrackingStatusUpdate?(.matching(quality))
            }
        }
    }
    
    func saveWorldMap() {
        arView.session.getCurrentWorldMap { [weak self] worldMap, error in
            guard let self = self, let map = worldMap else {
                print("월드맵 저장 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                return
            }
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.worldMapURL, options: [.atomic])
                print("월드맵 저장 완료")
            } catch {
                print("월드맵 저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func loadWorldMap() -> ARWorldMap? {
        guard let data = try? Data(contentsOf: worldMapURL) else {
            return nil
        }
        do {
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) else {
                print("월드맵 로드 실패")
                return nil
            }
            return worldMap
        } catch {
            print("월드맵 로드 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    // ARSessionDelegate 필수 메서드
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard Date().timeIntervalSince(lastAnalysisTime) >= analysisCooldown else { return }
        lastAnalysisTime = Date()
        let cameraTransform = frame.camera.transform
        let currentPosition = SIMD3<Float>(cameraTransform.columns.3.x,
                                           cameraTransform.columns.3.y,
                                           cameraTransform.columns.3.z)
        onCameraPositionUpdate?(currentPosition)
    }
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            break // 필요시 상태 업데이트
        case .limited:
            isMapMatched = false
            onTrackingStatusUpdate?(.searching)
        case .notAvailable:
            isMapMatched = false
            onTrackingStatusUpdate?(.notFound)
        @unknown default:
            break
        }
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        isMapMatched = false
        onTrackingStatusUpdate?(.notFound)
    }
    func sessionWasInterrupted(_ session: ARSession) {
        isMapMatched = false
        onTrackingStatusUpdate?(.searching)
    }
    func sessionInterruptionEnded(_ session: ARSession) {
        onTrackingStatusUpdate?(.matching(0.0))
        startARSession()
    }
}
