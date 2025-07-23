//
//  ViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/22/25.
//

import UIKit
import ARKit
import RealityKit

class ViewController: UIViewController, ARSessionDelegate {
    
    var arView: ARView!
    var meshData: [UUID: MeshData] = [:] // 메시 데이터 저장용
    var lastAnalysisTime: Date = Date()
    let analysisCooldown: TimeInterval = 0.5 // 업데이트 주기를 0.5초로 변경
    var setOriginButton: UIButton! // 원점 설정 버튼
    var positionLabel: UILabel! // 위치 표시 레이블
    var statusLabel: UILabel! // 상태 표시 레이블
    var isMapMatched = false // 맵 매칭 상태
    
    // World Map 저장 경로
    var worldMapURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("worldmap.arexperience")
    }

    // 메시 데이터 구조체
    struct MeshData: Codable {
        var vertices: [SIMD3<Float>]
        var timestamp: Date
        
        // UserDefaults 저장을 위한 변환
        func encode() -> Data? {
            return try? JSONEncoder().encode(self)
        }
        
        static func decode(from data: Data) -> MeshData? {
            return try? JSONDecoder().decode(MeshData.self, from: data)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        arView = ARView(frame: view.bounds)
        view.addSubview(arView)
        
        setupButtons()
        setupPositionLabel()
        setupStatusLabel()

        // Scene Reconstruction 사용 가능 여부 확인
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            print("Scene Reconstruction 지원 안됨")
            return
        }

        startARSession()
    }
    
    func setupStatusLabel() {
        statusLabel = UILabel()
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        
        let labelHeight: CGFloat = 32
        statusLabel.frame = CGRect(
            x: 20,
            y: positionLabel.frame.minY - labelHeight - 8,
            width: view.bounds.width - 40,
            height: labelHeight
        )
        
        updateStatusLabel(status: .searching)
        view.addSubview(statusLabel)
    }
    
    enum TrackingStatus {
        case searching
        case matching
        case matched
        case notFound
        
        var description: String {
            switch self {
            case .searching:
                return "주변 환경 스캔 중..."
            case .matching:
                return "저장된 맵과 매칭 중..."
            case .matched:
                return "✅ 위치 파악 완료"
            case .notFound:
                return "❌ 저장된 맵을 찾을 수 없습니다"
            }
        }
        
        var color: UIColor {
            switch self {
            case .searching, .matching:
                return .systemYellow
            case .matched:
                return .systemGreen
            case .notFound:
                return .systemRed
            }
        }
    }
    
    func updateStatusLabel(status: TrackingStatus) {
        DispatchQueue.main.async {
            self.statusLabel.text = status.description
            self.statusLabel.textColor = status.color
        }
    }
    
    func startARSession() {
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        config.environmentTexturing = .automatic
        config.planeDetection = [.horizontal, .vertical]
        
        isMapMatched = false
        
        // 저장된 맵이 있으면 자동으로 로드
        if let worldMap = loadWorldMap() {
            config.initialWorldMap = worldMap
            print("저장된 맵을 자동으로 불러왔습니다.")
            updateStatusLabel(status: .matching)
        } else {
            updateStatusLabel(status: .notFound)
        }

        arView.session.delegate = self
        arView.session.run(config)
        
        // 디버그 옵션 설정 - 메시 시각화
        arView.debugOptions = [.showSceneUnderstanding]
        
        // 저장된 메시 데이터 불러오기
        loadMeshData()
    }
    
    func setupButtons() {
        // 원점 설정 버튼
        setOriginButton = UIButton(type: .system)
        setOriginButton.setTitle("이 위치를 원점(0,0)으로 설정", for: .normal)
        setOriginButton.backgroundColor = .systemBlue
        setOriginButton.setTitleColor(.white, for: .normal)
        setOriginButton.layer.cornerRadius = 8
        setOriginButton.addTarget(self, action: #selector(setOriginButtonTapped), for: .touchUpInside)
        setOriginButton.frame = CGRect(x: 20, y: 50, width: view.bounds.width - 40, height: 50)
        view.addSubview(setOriginButton)
    }
    
    func setupPositionLabel() {
        positionLabel = UILabel()
        positionLabel.numberOfLines = 0
        positionLabel.textAlignment = .center
        positionLabel.font = .systemFont(ofSize: 24, weight: .bold)
        positionLabel.textColor = .white
        positionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        positionLabel.layer.cornerRadius = 12
        positionLabel.layer.masksToBounds = true
        
        let labelHeight: CGFloat = 60
        positionLabel.frame = CGRect(
            x: 20,
            y: view.bounds.height - labelHeight - 20 - view.safeAreaInsets.bottom,
            width: view.bounds.width - 40,
            height: labelHeight
        )
        
        view.addSubview(positionLabel)
    }
    
    @objc func setOriginButtonTapped() {
        guard let currentFrame = arView.session.currentFrame else { return }
        
        // 현재 위치를 원점으로 저장
        let transform = currentFrame.camera.transform
        let position = SIMD3<Float>(transform.columns.3.x,
                                  transform.columns.3.y,
                                  transform.columns.3.z)
        
        // 현재 위치를 원점으로 저장
        UserDefaults.standard.set([position.x, position.z], forKey: "permanent_origin") // y축 제외
        
        // World Map 저장
        arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else { return }
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.worldMapURL, options: [.atomic])
                
                DispatchQueue.main.async {
                    self.setOriginButton.backgroundColor = .systemGreen
                    self.setOriginButton.setTitle("원점 설정 완료! (0,0)", for: .normal)
                    
                    // 3초 후 버튼 상태 복원
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.setOriginButton.backgroundColor = .systemBlue
                        self.setOriginButton.setTitle("이 위치를 원점(0,0)으로 설정", for: .normal)
                    }
                }
            } catch {
                print("월드맵 저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func updatePositionLabel(position: SIMD3<Float>) {
        if let originArray = UserDefaults.standard.array(forKey: "permanent_origin") as? [Float],
           originArray.count == 2 {
            let originX = originArray[0]
            let originZ = originArray[1]
            
            // 원점으로부터의 상대 위치 계산 (X,Z 평면만)
            let relativeX = position.x - originX
            let relativeZ = position.z - originZ
            
            // 매칭되지 않은 상태면 좌표를 표시하지 않음
            let formattedText = isMapMatched ? 
                String(format: "(%.1f, %.1f)", relativeX, relativeZ) :
                "위치 파악 중..."
            
            DispatchQueue.main.async {
                self.positionLabel.text = formattedText
            }
        } else {
            DispatchQueue.main.async {
                self.positionLabel.text = "원점이 설정되지 않음"
            }
        }
    }
    
    @objc func saveWorldMapButtonTapped() {
        arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else {
                print("월드맵 저장 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                return
            }
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.worldMapURL, options: [.atomic])
                print("월드맵 저장 완료")
                
                // 현재 위치를 원점으로 저장
                if let currentFrame = self.arView.session.currentFrame {
                    let transform = currentFrame.camera.transform
                    let position = SIMD3<Float>(transform.columns.3.x,
                                              transform.columns.3.y,
                                              transform.columns.3.z)
                    UserDefaults.standard.set([position.x, position.z], forKey: "permanent_origin") // y축 제외
                }
            } catch {
                print("월드맵 저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadWorldMap() -> ARWorldMap? {
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
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let meshAnchor = anchor as? ARMeshAnchor else { continue }
            print("📦 새 메쉬 추가됨 - id: \(meshAnchor.identifier)")
            analyzeMeshData(for: meshAnchor)
            saveMeshData(for: meshAnchor)
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let meshAnchor = anchor as? ARMeshAnchor else { continue }
//            print("🔄 메쉬 업데이트 - id: \(meshAnchor.identifier)")
            saveMeshData(for: meshAnchor)
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard Date().timeIntervalSince(lastAnalysisTime) >= analysisCooldown else { return }
        lastAnalysisTime = Date()
        
        let cameraTransform = frame.camera.transform
        let currentPosition = SIMD3<Float>(cameraTransform.columns.3.x,
                                         cameraTransform.columns.3.y,
                                         cameraTransform.columns.3.z)
        
        updatePositionLabel(position: currentPosition)
        
        // 카메라가 바라보는 방향 (정면 벡터)
        let cameraForward = normalize(SIMD3<Float>(-cameraTransform.columns.2.x,
                                                  -cameraTransform.columns.2.y,
                                                  -cameraTransform.columns.2.z))
        
        // 주변 환경 분석
        analyzeEnvironment(cameraPosition: currentPosition, cameraForward: cameraForward, frame: frame)
    }
    
    func analyzeEnvironment(cameraPosition: SIMD3<Float>, cameraForward: SIMD3<Float>, frame: ARFrame) {
        var nearestDistance: Float = .infinity
        var nearestMeshID: UUID?
        
        // 모든 메시를 순회하며 가장 가까운 메시 찾기
        for (id, _) in meshData {
            if let meshAnchor = frame.anchors.first(where: { $0.identifier == id }) as? ARMeshAnchor {
                let meshPosition = SIMD3<Float>(meshAnchor.transform.columns.3.x,
                                              meshAnchor.transform.columns.3.y,
                                              meshAnchor.transform.columns.3.z)
                
                let distance = length(meshPosition - cameraPosition)
                if distance < nearestDistance {
                    nearestDistance = distance
                    nearestMeshID = id
                }
            }
        }
        
        // 현재 위치 정보 출력
        print("""
        📱 현재 위치 분석:
        - 카메라 위치: (x: \(String(format: "%.2f", cameraPosition.x))m, 
                      y: \(String(format: "%.2f", cameraPosition.y))m, 
                      z: \(String(format: "%.2f", cameraPosition.z))m)
        - 바라보는 방향: (x: \(String(format: "%.2f", cameraForward.x)), 
                       y: \(String(format: "%.2f", cameraForward.y)), 
                       z: \(String(format: "%.2f", cameraForward.z)))
        - 가장 가까운 메시까지의 거리: \(String(format: "%.2f", nearestDistance))m
        """)
        
        // 바닥 높이 추정
        if let raycastResult = arView.raycast(from: view.center,
                                            allowing: .estimatedPlane,
                                            alignment: .horizontal).first {
            let floorY = raycastResult.worldTransform.columns.3.y
            print("- 현재 바닥과의 높이: \(String(format: "%.2f", cameraPosition.y - floorY))m")
        }
    }
    
    // 메시 데이터 저장
    func saveMeshData(for meshAnchor: ARMeshAnchor) {
        let geometry = meshAnchor.geometry
        let vertices = geometry.vertices
        var positions: [SIMD3<Float>] = []
        
        // vertex 데이터 추출
        let vertexBuffer = Data(bytes: vertices.buffer.contents(), count: vertices.count * vertices.stride)
        vertexBuffer.withUnsafeBytes { buffer in
            let vertices = buffer.bindMemory(to: SIMD3<Float>.self)
            positions = Array(vertices)
        }
        
        // MeshData 생성
        let newMeshData = MeshData(vertices: positions, timestamp: Date())
        newMeshData.encode().map { encodedData in
            // UserDefaults에 저장
            UserDefaults.standard.set(encodedData, forKey: "mesh_\(meshAnchor.identifier.uuidString)")
        }
        
        // 메모리에도 저장
        meshData[meshAnchor.identifier] = newMeshData
        
//        print("💾 메시 데이터 저장됨 - vertices: \(positions.count)")
    }
    
    // 저장된 메시 데이터 불러오기
    func loadMeshData() {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("mesh_") }
        
        for key in keys {
            if let data = defaults.data(forKey: key),
               let meshData = MeshData.decode(from: data) {
                let uuid = UUID(uuidString: String(key.dropFirst(5)))!
                self.meshData[uuid] = meshData
                print("📤 메시 데이터 로드됨 - id: \(uuid), vertices: \(meshData.vertices.count)")
            }
        }
    }

    func analyzeMeshData(for meshAnchor: ARMeshAnchor) {
        let geometry = meshAnchor.geometry
        let vertices = geometry.vertices
        var positions: [SIMD3<Float>] = []
        
        // vertex 데이터 추출
        let vertexBuffer = Data(bytes: vertices.buffer.contents(), count: vertices.count * vertices.stride)
        vertexBuffer.withUnsafeBytes { buffer in
            let vertices = buffer.bindMemory(to: SIMD3<Float>.self)
            positions = Array(vertices)
        }
        
        // 메시 분석
        if let firstVertex = positions.first {
            // 로컬 좌표
            print("📍 첫 번째 vertex 로컬 좌표: x=\(firstVertex.x)m, y=\(firstVertex.y)m, z=\(firstVertex.z)m")
            
            // 월드 좌표로 변환
            let worldPosition = meshAnchor.transform * SIMD4(firstVertex, 1.0)
            print("🌍 첫 번째 vertex 월드 좌표: x=\(worldPosition.x)m, y=\(worldPosition.y)m, z=\(worldPosition.z)m")
        }
        
        // 메시 범위 계산
        let xCoordinates = positions.map { $0.x }
        let yCoordinates = positions.map { $0.y }
        let zCoordinates = positions.map { $0.z }
        
        let minBounds = SIMD3<Float>(
            xCoordinates.min() ?? 0,
            yCoordinates.min() ?? 0,
            zCoordinates.min() ?? 0
        )
        
        let maxBounds = SIMD3<Float>(
            xCoordinates.max() ?? 0,
            yCoordinates.max() ?? 0,
            zCoordinates.max() ?? 0
        )
        
        print("""
        📐 메시 정보:
        - 정점 개수: \(positions.count)개
        - 메시 크기: 
          • 가로: \(abs(maxBounds.x - minBounds.x))m
          • 세로: \(abs(maxBounds.y - minBounds.y))m
          • 깊이: \(abs(maxBounds.z - minBounds.z))m
        - 메시 범위:
          • X: \(minBounds.x)m ~ \(maxBounds.x)m
          • Y: \(minBounds.y)m ~ \(maxBounds.y)m
          • Z: \(minBounds.z)m ~ \(maxBounds.z)m
        """)
    }

    // ARSession 델리게이트 메서드 추가
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            // 트래킹이 정상이고 월드맵이 로드된 상태라면
            if let originArray = UserDefaults.standard.array(forKey: "permanent_origin") as? [Float],
               originArray.count == 2 {
                isMapMatched = true
                updateStatusLabel(status: .matched)
            } else {
                updateStatusLabel(status: .searching)
            }
        case .limited(let reason):
            isMapMatched = false
            switch reason {
            case .initializing:
                updateStatusLabel(status: .searching)
            case .relocalizing:
                updateStatusLabel(status: .matching)
            default:
                updateStatusLabel(status: .searching)
            }
        case .notAvailable:
            isMapMatched = false
            updateStatusLabel(status: .notFound)
        @unknown default:
            break
        }
    }
}

