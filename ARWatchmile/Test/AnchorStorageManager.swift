//
//  AnchorStorageManager.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/31/25.
//

import Foundation
import ARKit

class AnchorStorageManager {
    private var savedAnchors: [SavedAnchor] = []
    private var manualAnchors: [ARAnchor] = []
    
    // 앵커 저장
    func saveAnchor(_ anchor: ARAnchor, name: String? = nil) {
        let savedAnchor = SavedAnchor(from: anchor, name: name)
        savedAnchors.append(savedAnchor)
        manualAnchors.append(anchor)
        
        print("📍 앵커 저장됨:")
        print("  - ID: \(savedAnchor.id)")
        print("  - 위치: (\(savedAnchor.position[0]), \(savedAnchor.position[1]), \(savedAnchor.position[2]))")
        print("  - 타입: \(savedAnchor.anchorType)")
        print("  - 이름: \(savedAnchor.name ?? "unnamed")")
        
        // 파일에 저장
        saveAnchorsToFile()
    }
    
    // 모든 앵커 가져오기
    func getAllSavedAnchors() -> [SavedAnchor] {
        return savedAnchors
    }
    
    // 앵커 개수
    func getAnchorCount() -> Int {
        return savedAnchors.count
    }
    
    // 앵커 삭제
    func clearAllAnchors() {
        savedAnchors.removeAll()
        manualAnchors.removeAll()
        saveAnchorsToFile()
        print("🗑️ 모든 앵커 삭제됨")
    }
}

// MARK: - FileIOSystem
extension AnchorStorageManager {
    // 파일 URL 가져오기
    private func getAnchorsFileURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("saved_anchors.json")
    }
    
    // 앵커들을 파일에 저장
    private func saveAnchorsToFile() {
        let url = getAnchorsFileURL()
        
        do {
            let data = try JSONEncoder().encode(savedAnchors)
            try data.write(to: url)
            print("💾 앵커 파일 저장 완료: \(savedAnchors.count)개")
        } catch {
            print("❌ 앵커 저장 실패: \(error)")
        }
    }
    
    // 파일에서 앵커들 로드
    func loadAnchorsFromFile() {
        let url = getAnchorsFileURL()
        
        guard let data = try? Data(contentsOf: url) else {
            print("�� 저장된 앵커 파일이 없습니다")
            return
        }
        
        do {
            savedAnchors = try JSONDecoder().decode([SavedAnchor].self, from: data)
            print("📂 앵커 로드 완료: \(savedAnchors.count)개")
            
            // 로드된 앵커들 정보 출력
            for (index, anchor) in savedAnchors.enumerated() {
                print("  \(index + 1). \(anchor.name ?? "unnamed") - (\(anchor.position[0]), \(anchor.position[1]), \(anchor.position[2]))")
            }
        } catch {
            print("❌ 앵커 로드 실패: \(error)")
        }
    }
}
