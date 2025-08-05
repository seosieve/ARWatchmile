import UIKit
import ARKit
import RealityKit

class ARSessionManager: NSObject, ARSessionDelegate {
    var arView: ARView!
    var arModelManager: ARModelManager?
    var isMapMatched = false
    var objectsPlacedInSession = false // 세션 내에서만 사용하는 플래그
    var lastAnalysisTime: Date = Date()
    let analysisCooldown: TimeInterval = 0.5
    var onCameraPositionUpdate: ((SIMD3<Float>) -> Void)?
    var onTrackingStatusUpdate: ((TrackingStatus) -> Void)?
    lazy var worldMapURL = getWorldMapURL()
    
    override init() {
        super.init()
    }
    
    func getWorldMapURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("worldmap.arexperience")
    }
    
    func startARSession() {
        guard let arView = arView else {
            print("❌ ARView가 nil입니다")
            return
        }
        
        let config = ARWorldTrackingConfiguration()
        config.isLightEstimationEnabled = true
        config.sceneReconstruction = .mesh
        config.environmentTexturing = .none
        config.planeDetection = [.horizontal, .vertical]
        isMapMatched = false
        objectsPlacedInSession = false // 세션 시작 시 플래그 초기화
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let worldMap = self.loadWorldMap() {
                config.initialWorldMap = worldMap
                print("저장된 맵을 자동으로 불러왔습니다.")
                self.onTrackingStatusUpdate?(.matching(0.0))
            } else {
                self.onTrackingStatusUpdate?(.searching)
            }
            
            arView.session.delegate = self
            arView.session.run(config)
        }
    }
    
    func checkTrackingStatus(originData: SIMD3<Float>) {
        arView.session.getCurrentWorldMap { [weak self] worldMap, error in
            guard let self = self, let worldMap = worldMap else { return }
            let pointCount = worldMap.rawFeaturePoints.points.count
            let quality = min(Float(pointCount) / 100.0, 1.0)
            let matched = (quality >= 0.5 && self.arView.session.currentFrame?.camera.trackingState == .normal)
            
            if matched {
                self.isMapMatched = true
                self.onTrackingStatusUpdate?(.matched)
                
                // 위치 매칭 완료 시 물체 자동 배치
                self.placeObjectsWhenMatched()
            } else {
                self.onTrackingStatusUpdate?(.matching(quality))
            }
        }
    }
    
    // MARK: - 위치 매칭 완료 시 물체 배치
    private func placeObjectsWhenMatched() {
        // 세션 내에서 한 번만 배치
        if !objectsPlacedInSession {
            arModelManager?.placeMultipleObjects(arView: arView)
            objectsPlacedInSession = true
            print("🎯 위치 매칭 완료! 물체 자동 배치됨")
        }
    }
    
    func saveWorldMap() {
        // arView가 nil이거나 세션이 없을 때 안전하게 처리
        guard let arView = arView else {
            print("❌ ARView가 nil입니다")
            return
        }
        
        arView.session.getCurrentWorldMap { [weak self] worldMap, error in
            guard let self = self, let map = worldMap else {
                print("월드맵 저장 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                return
            }
            
            DispatchQueue.main.async {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    try data.write(to: self.worldMapURL, options: [.atomic])
                    print("월드맵 저장 완료")
                } catch {
                    print("월드맵 저장 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadWorldMap() -> ARWorldMap? {
        guard let data = try? Data(contentsOf: worldMapURL) else {
            print("📂 저장된 WorldMap 파일이 없습니다")
            return nil
        }
        do {
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) else {
                print("❌ WorldMap 언아카이브 실패")
                return nil
            }
            
            // WorldMap 유효성 검사
            let featurePointCount = worldMap.rawFeaturePoints.points.count
            print("📂 WorldMap 로드 완료 - 특징점 개수: \(featurePointCount)")
            
            // 특징점이 너무 적으면 로드하지 않음
            if featurePointCount < 100 {
                print("⚠️ 특징점이 너무 적습니다 (\(featurePointCount)개). WorldMap을 로드하지 않습니다.")
                return nil
            }
            
            return worldMap
        } catch {
            print("❌ WorldMap 로드 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    // ARSessionDelegate 필수 메서드
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard Date().timeIntervalSince(lastAnalysisTime) >= analysisCooldown else { return }
        lastAnalysisTime = Date()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let cameraTransform = frame.camera.transform
            let (x,y,z) = (cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
            let currentPosition = SIMD3<Float>(x,y,z)
            self.onCameraPositionUpdate?(currentPosition)
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch camera.trackingState {
            case .normal:
                break // 필요시 상태 업데이트
            case .limited:
                self.isMapMatched = false
                self.onTrackingStatusUpdate?(.searching)
            case .notAvailable:
                self.isMapMatched = false
                self.onTrackingStatusUpdate?(.notFound)
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isMapMatched = false
            self.onTrackingStatusUpdate?(.notFound)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isMapMatched = false
            self.onTrackingStatusUpdate?(.searching)
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onTrackingStatusUpdate?(.matching(0.0))
            
            // 세션 재시작 전에 잠시 대기
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startARSession()
            }
        }
    }
}
