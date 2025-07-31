//
//  MiniMap.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/31/25.
//

import UIKit
import SnapKit
import Then

// 부채꼴 모양의 방향 표시기
class DirectionIndicatorView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear // 배경을 투명하게
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear // 배경을 투명하게
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2 - 2
        
        // 부채꼴 그리기
        context.setFillColor(UIColor.orange.withAlphaComponent(0.6).cgColor)
        context.move(to: center)
        context.addArc(center: center, radius: radius, startAngle: -CGFloat.pi / 4, endAngle: CGFloat.pi / 4, clockwise: false)
        context.closePath()
        context.fillPath()
    }
}

class MiniMapView: UIView {
    
    // 내 위치를 나타내는 노란 점
    private var playerDot = UIView().then {
        $0.backgroundColor = .yellow
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
    }
    
    // 방향을 나타내는 부채꼴
    private var directionCone = DirectionIndicatorView()
    
    // 빨간 네모들을 나타내는 뷰들
    private var objectViews: [UIView] = []
    
    // OfficeMap 이미지 뷰
    private var officeMapImageView = UIImageView().then {
        $0.image = UIImage(named: "OfficeMap")
        $0.contentMode = .scaleAspectFit
        $0.alpha = 0.7 // 약간 투명하게
    }
    
    // 방향 조절을 위한 각도 오프셋 (라디안 단위, 85도)
    private var directionOffset: CGFloat = 60 * .pi / 180
    
    // 처음 시작점 조정 변수들
    private var initialMapOffsetX: CGFloat = 0.0 // 지도 초기 X 오프셋
    private var initialMapOffsetY: CGFloat = 0.0 // 지도 초기 Y 오프셋
    private var initialRotationAngle: CGFloat = 0.0 // 지도 초기 회전 각도 (라디안)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        layer.cornerRadius = 8
        layer.masksToBounds = true // overflow hidden
        
        // 크기 제약 설정
        snp.makeConstraints { make in
            make.width.equalTo(160)
            make.height.equalTo(160)
        }
        
        // OfficeMap 이미지 추가 (맨 뒤에)
        addSubview(officeMapImageView)
        officeMapImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(200) // 미니맵보다 크게
        }
        
        // 방향 부채꼴 추가
        addSubview(directionCone)
        directionCone.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(32)
            make.height.equalTo(32)
        }
        
        // 내 위치 점 추가
        addSubview(playerDot)
        playerDot.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(8)
        }
    }
    
    // MARK: - 방향 업데이트 (절대 방향 + 오프셋)
    func updateDirection(angle: CGFloat) {
        // 절대 방향 + 조절 가능한 오프셋
        let adjustedAngle = angle + directionOffset
        directionCone.transform = CGAffineTransform(rotationAngle: adjustedAngle)
        
        // 라디안을 도로 변환해서 로그 출력
        let angleDegrees = angle * 180 / .pi
        let offsetDegrees = directionOffset * 180 / .pi
        let adjustedDegrees = adjustedAngle * 180 / .pi
        
        print("🧭 미니맵 방향 업데이트:")
        print("  - 원본 각도: \(angle) 라디안 (\(angleDegrees)°)")
        print("  - 오프셋: \(directionOffset) 라디안 (\(offsetDegrees)°)")
        print("  - 조정된 각도: \(adjustedAngle) 라디안 (\(adjustedDegrees)°)")
    }
    
    // MARK: - 방향 오프셋 조절 (디버그용)
    func adjustDirectionOffset(offset: CGFloat) {
        directionOffset = offset
        print("🧭 방향 오프셋 조절: \(offset)")
    }
    
    // MARK: - 지도 초기 위치 설정
    func setInitialMapPosition(offsetX: CGFloat, offsetY: CGFloat, rotationAngle: CGFloat) {
        initialMapOffsetX = offsetX
        initialMapOffsetY = offsetY
        initialRotationAngle = rotationAngle
        print("🗺️ 지도 초기 위치 설정:")
        print("  - X 오프셋: \(offsetX)")
        print("  - Y 오프셋: \(offsetY)")
        print("  - 회전 각도: \(rotationAngle * 180 / .pi)°")
    }
    
    // MARK: - 빨간 네모들 업데이트
    func updateObjects(objectPositions: [SIMD3<Float>], playerPosition: SIMD3<Float>) {
        // 기존 객체 뷰들 제거
        objectViews.forEach { $0.removeFromSuperview() }
        objectViews.removeAll()
        
        print("🎯 미니맵 업데이트:")
        print("  - 내 위치: \(playerPosition)")
        print("  - 객체 개수: \(objectPositions.count)")
        
        // OfficeMap 위치 업데이트 (플레이어 위치에 따라)
        print("🗺️ OfficeMap 업데이트 시작")
        updateOfficeMapPosition(playerPosition: playerPosition)
        
        // 새로운 객체 뷰들 생성
        for (index, position) in objectPositions.enumerated() {
            let objectView = UIView().then {
                $0.backgroundColor = .red
                $0.layer.cornerRadius = 2
                $0.layer.masksToBounds = true
            }
            
            addSubview(objectView)
            objectViews.append(objectView)
            
            // 내 위치 기준으로 상대 위치 계산
            let relativeX = position.x - playerPosition.x
            let relativeZ = position.z - playerPosition.z
            
            // 미니맵 스케일 (실제 거리를 미니맵 크기에 맞게 조정)
            let scale: Float = 10 // 더 큰 스케일로 조정
            let mapX = CGFloat(relativeX * scale)
            let mapY = CGFloat(relativeZ * scale)
            
            print("  - 객체 \(index + 1): 상대위치(\(relativeX), \(relativeZ)) -> 미니맵위치(\(mapX), \(mapY))")
            
            // 미니맵 경계 내에 있는지 확인
            let maxOffset: CGFloat = 70 // 미니맵 반지름보다 작게
            
            // 경계 밖에 있으면 숨기기
            if abs(mapX) > maxOffset || abs(mapY) > maxOffset {
                objectView.isHidden = true
                print("  - 객체 \(index + 1): 경계 밖으로 숨김 (위치: \(mapX), \(mapY))")
            } else {
                objectView.isHidden = false
                objectView.snp.makeConstraints { make in
                    make.centerX.equalToSuperview().offset(mapX)
                    make.centerY.equalToSuperview().offset(mapY)
                    make.width.height.equalTo(6)
                }
                print("  - 객체 \(index + 1): 경계 내 표시 (위치: \(mapX), \(mapY))")
            }
        }
        
        print("🎯 미니맵에 \(objectPositions.count)개 객체 표시됨")
    }
    
    // MARK: - OfficeMap 위치 업데이트
    private func updateOfficeMapPosition(playerPosition: SIMD3<Float>) {
        // updateObjects와 같은 방식으로 계산
        // 플레이어 위치를 기준으로 맵이 반대 방향으로 움직이도록
        let mapOffsetX = CGFloat(-playerPosition.x * 10.0) + initialMapOffsetX // 초기 오프셋 추가
        let mapOffsetY = CGFloat(-playerPosition.z * 10.0) + initialMapOffsetY
        
        // 이동과 회전을 결합한 transform
        let translationTransform = CGAffineTransform(translationX: mapOffsetX, y: mapOffsetY)
        let rotationTransform = CGAffineTransform(rotationAngle: initialRotationAngle)
        let combinedTransform = translationTransform.concatenating(rotationTransform)
        
        officeMapImageView.transform = combinedTransform
        
        print("🗺️ OfficeMap 위치 업데이트:")
        print("  - 플레이어 위치: \(playerPosition)")
        print("  - 맵 오프셋: (\(mapOffsetX), \(mapOffsetY))")
        print("  - 초기 오프셋: (\(initialMapOffsetX), \(initialMapOffsetY))")
        print("  - 초기 회전: \(initialRotationAngle * 180 / .pi)°")
        print("  - transform 적용됨")
        
        // 테스트용: 강제로 움직임 확인
        if abs(mapOffsetX) > 0 || abs(mapOffsetY) > 0 {
            print("🎯 지도가 움직여야 함! 오프셋이 0이 아님")
        } else {
            print("⚠️ 오프셋이 0이라서 움직이지 않음")
        }
    }
}

