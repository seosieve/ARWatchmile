import UIKit

enum TrackingStatus {
    case searching
    case matching(Float)
    case matched
    case notFound

    var description: String {
        switch self {
        case .searching:
            return "주변 환경 스캔 중..."
        case .matching(let quality):
            let percentage = Int(quality * 100)
            return "맵 매칭 중... (\(percentage)%)"
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