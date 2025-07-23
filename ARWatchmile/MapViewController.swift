import UIKit
import ARKit

class MapViewController: UIViewController, UIScrollViewDelegate {
    
    var savedMeshPoints: [SIMD3<Float>] = []
    var currentMeshPoints: [SIMD3<Float>] = []
    var originPoint: CGPoint?
    private var scrollView: UIScrollView!
    private var mapView: UIView!
    private var closeButton: UIButton!
    private let scale: CGFloat = 100 // 1 meter = 100 points
    private let dotSize: CGFloat = 3  // Dot size
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        drawMap()
        scrollView.delegate = self // 줌을 위해 delegate 지정
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // 스크롤 뷰 설정
        scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3.0
        scrollView.frame = view.bounds
        view.addSubview(scrollView)
        
        // 맵 뷰 설정 (스크롤 뷰 안에)
        mapView = UIView()
        mapView.backgroundColor = .black
        // 맵 크기를 충분히 크게 설정 (스크롤 가능한 영역)
        let mapWidth: CGFloat = 2000  // 20미터
        let mapHeight: CGFloat = 2000 // 20미터
        mapView.frame = CGRect(x: 0, y: 0, width: mapWidth, height: mapHeight)
        scrollView.addSubview(mapView)
        
        // 스크롤 뷰의 contentSize 설정
        scrollView.contentSize = mapView.frame.size
        
        // 원점을 스크롤 뷰 중앙으로 스크롤
        let centerX = mapView.frame.width / 2
        let centerY = mapView.frame.height / 2
        scrollView.setContentOffset(CGPoint(x: centerX - scrollView.frame.width/2, y: centerY - scrollView.frame.height/2), animated: false)

        closeButton = UIButton(type: .system)
        closeButton.setTitle("닫기", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = .systemGray
        closeButton.layer.cornerRadius = 8
        // 위치는 viewDidLayoutSubviews에서 조정
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 스크롤 뷰 프레임 업데이트
        scrollView.frame = view.bounds
        
        // 닫기 버튼을 safeArea 아래로 충분히 내림
        let safeTop = view.safeAreaInsets.top
        closeButton.frame = CGRect(x: 20, y: safeTop + 20, width: 60, height: 40)
    }
    
    private func drawMap() {
        // 데이터가 없으면 return
        guard !savedMeshPoints.isEmpty || !currentMeshPoints.isEmpty else {
            let label = UILabel()
            label.text = "스캔 데이터가 없습니다"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = mapView.bounds
            mapView.addSubview(label)
            return
        }
        
        // 모든 포인트의 범위 계산 (저장 + 실시간)
        var minX: Float = .infinity
        var maxX: Float = -.infinity
        var minZ: Float = .infinity
        var maxZ: Float = -.infinity
        
        let allPoints = savedMeshPoints + currentMeshPoints
        for point in allPoints {
            guard point.x.isFinite && point.z.isFinite else { continue }
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minZ = min(minZ, point.z)
            maxZ = max(maxZ, point.z)
        }
        
        // 유효한 범위 체크
        guard minX.isFinite && maxX.isFinite && minZ.isFinite && maxZ.isFinite,
              minX < maxX && minZ < maxZ else {
            let label = UILabel()
            label.text = "유효하지 않은 스캔 데이터"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = mapView.bounds
            mapView.addSubview(label)
            return
        }
        
        // 맵 크기 계산
        let mapWidth = CGFloat(maxX - minX) * scale
        let mapHeight = CGFloat(maxZ - minZ) * scale
        
        // 맵 크기가 너무 작거나 크지 않은지 확인
        guard mapWidth > 0, mapWidth.isFinite,
              mapHeight > 0, mapHeight.isFinite,
              mapWidth < 10000, mapHeight < 10000 else {
            let label = UILabel()
            label.text = "맵 크기가 유효하지 않습니다"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = mapView.bounds
            mapView.addSubview(label)
            return
        }
        
        // 맵 프레임 설정 - 0,0을 화면 중앙에 고정
        let mapFrame = CGRect(
            x: (mapView.bounds.width - mapWidth) / 2,
            y: (mapView.bounds.height - mapHeight) / 2,
            width: mapWidth,
            height: mapHeight
        )
        
        // 격자 그리기
        drawGrid(in: mapFrame, minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ)
        
        // 정보 표시
        let infoLabel = UILabel()
        infoLabel.text = "저장된 포인트: \(savedMeshPoints.count)개\n실시간 포인트: \(currentMeshPoints.count)개"
        infoLabel.numberOfLines = 2
        infoLabel.textColor = .white
        infoLabel.textAlignment = .right
        infoLabel.font = .systemFont(ofSize: 12)
        infoLabel.frame = CGRect(x: mapView.bounds.width - 200, y: 10, width: 190, height: 40)
        mapView.addSubview(infoLabel)
        
        // 범례 표시
        let legendView = UIView(frame: CGRect(x: 10, y: 10, width: 200, height: 50))
        
        let savedDot = UIView(frame: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
        savedDot.backgroundColor = .systemRed.withAlphaComponent(0.5)
        savedDot.layer.cornerRadius = dotSize / 2
        legendView.addSubview(savedDot)
        
        let savedLabel = UILabel(frame: CGRect(x: 10, y: -4, width: 100, height: 20))
        savedLabel.text = "저장된 데이터"
        savedLabel.textColor = .white
        savedLabel.font = .systemFont(ofSize: 12)
        legendView.addSubview(savedLabel)
        
        let currentDot = UIView(frame: CGRect(x: 0, y: 20, width: dotSize, height: dotSize))
        currentDot.backgroundColor = .systemBlue.withAlphaComponent(0.5)
        currentDot.layer.cornerRadius = dotSize / 2
        legendView.addSubview(currentDot)
        
        let currentLabel = UILabel(frame: CGRect(x: 10, y: 16, width: 100, height: 20))
        currentLabel.text = "실시간 데이터"
        currentLabel.textColor = .white
        currentLabel.font = .systemFont(ofSize: 12)
        legendView.addSubview(currentLabel)
        
        mapView.addSubview(legendView)
        
        // 저장된 점들 그리기 (빨간색)
        drawPoints(points: savedMeshPoints, color: .systemRed, minX: minX, minZ: minZ, mapFrame: mapFrame)
        
        // 실시간 점들 그리기 (파란색)
        drawPoints(points: currentMeshPoints, color: .systemBlue, minX: minX, minZ: minZ, mapFrame: mapFrame)
        

    }
    
    private func drawPoints(points: [SIMD3<Float>], color: UIColor, minX: Float, minZ: Float, mapFrame: CGRect) {
        // 10개의 포인트마다 1개만 사용
        for i in stride(from: 0, to: points.count, by: 10) {
            let point = points[i]
            guard point.x.isFinite && point.z.isFinite else { continue }
            
            // 원점(0,0)을 화면 중앙에 고정하고 상대 좌표 계산
            let x = CGFloat(point.x) * scale + mapView.bounds.midX
            let y = CGFloat(point.z) * scale + mapView.bounds.midY
            
            // 좌표 유효성 검사 - 화면 범위만 체크
            guard x.isFinite && y.isFinite,
                  x >= mapFrame.minX - 100 && x <= mapFrame.maxX + 100,  // 여유 공간 추가
                  y >= mapFrame.minY - 100 && y <= mapFrame.maxY + 100   // 여유 공간 추가
            else { continue }
            
            let dotView = UIView(frame: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
            dotView.backgroundColor = color.withAlphaComponent(0.5)
            dotView.layer.cornerRadius = dotSize / 2
            dotView.center = CGPoint(x: x, y: y)
            mapView.addSubview(dotView)
        }
    }
    
    private func drawGrid(in frame: CGRect, minX: Float, maxX: Float, minZ: Float, maxZ: Float) {
        let gridSpacing: CGFloat = scale  // 1미터 간격
        
        // 원점을 맵 중앙에 고정
        let originScreenX = mapView.frame.width / 2
        let originScreenY = mapView.frame.height / 2
        
        // 세로선 (X축 표시)
        // 원점에서 왼쪽으로 (-6까지 강제 표시)
        var x = originScreenX
        while x >= originScreenX - (6 * gridSpacing) {
            let line = UIView()
            line.backgroundColor = x == originScreenX ? UIColor.white.withAlphaComponent(0.5) : UIColor.gray.withAlphaComponent(0.3)
            line.frame = CGRect(x: x, y: 0, width: 1, height: mapView.frame.height)
            mapView.addSubview(line)
            
            // X축 좌표값 표시
            let realX = (x - originScreenX) / scale
            let label = UILabel()
            label.text = String(format: "%.1f", realX)
            label.textColor = x == originScreenX ? .white : .gray
            label.font = .systemFont(ofSize: 10)
            label.sizeToFit()
            label.center = CGPoint(x: x, y: mapView.frame.height - 20)
            mapView.addSubview(label)
            
            x -= gridSpacing
        }
        
        // 원점에서 오른쪽으로
        x = originScreenX + gridSpacing
        while x <= mapView.frame.width {
            let line = UIView()
            line.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
            line.frame = CGRect(x: x, y: 0, width: 1, height: mapView.frame.height)
            mapView.addSubview(line)
            
            // X축 좌표값 표시
            let realX = (x - originScreenX) / scale
            let label = UILabel()
            label.text = String(format: "%.1f", realX)
            label.textColor = .gray
            label.font = .systemFont(ofSize: 10)
            label.sizeToFit()
            label.center = CGPoint(x: x, y: mapView.bounds.height - 20)
            mapView.addSubview(label)
            
            x += gridSpacing
        }
        
        // 가로선 (Z축 표시)
        // 원점에서 위로
        var y = originScreenY
        while y >= 0 {
            let line = UIView()
            line.backgroundColor = y == originScreenY ? UIColor.white.withAlphaComponent(0.5) : UIColor.gray.withAlphaComponent(0.3)
            line.frame = CGRect(x: 0, y: y, width: mapView.frame.width, height: 1)
            mapView.addSubview(line)
            
            // Z축 좌표값 표시
            let realZ = (y - originScreenY) / scale
            let label = UILabel()
            label.text = String(format: "%.1f", realZ)
            label.textColor = y == originScreenY ? .white : .gray
            label.font = .systemFont(ofSize: 10)
            label.sizeToFit()
            label.center = CGPoint(x: 30, y: y)
            mapView.addSubview(label)
            
            y -= gridSpacing
        }
        
        // 원점에서 아래로
        y = originScreenY + gridSpacing
        while y <= mapView.frame.height {
            let line = UIView()
            line.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
            line.frame = CGRect(x: 0, y: y, width: mapView.frame.width, height: 1)
            mapView.addSubview(line)
            
            // Z축 좌표값 표시
            let realZ = (y - originScreenY) / scale
            let label = UILabel()
            label.text = String(format: "%.1f", realZ)
            label.textColor = .gray
            label.font = .systemFont(ofSize: 10)
            label.sizeToFit()
            label.center = CGPoint(x: frame.minX - 30, y: y)
            mapView.addSubview(label)
            
            y += gridSpacing
        }
        
        // 원점 표시를 더 강조
        let originPoint = UIView(frame: CGRect(x: originScreenX - 5, y: originScreenY - 5, width: 10, height: 10))
        originPoint.backgroundColor = .white
        originPoint.layer.cornerRadius = 5
        mapView.addSubview(originPoint)
        
        let originLabel = UILabel()
        originLabel.text = "(0,0)"
        originLabel.textColor = .white
        originLabel.font = .systemFont(ofSize: 12, weight: .bold)
        originLabel.sizeToFit()
        originLabel.center = CGPoint(x: originScreenX, y: originScreenY - 20)
        mapView.addSubview(originLabel)
        
        // 축 레이블
        let xAxisLabel = UILabel()
        xAxisLabel.text = "X축 (미터)"
        xAxisLabel.textColor = .white
        xAxisLabel.font = .systemFont(ofSize: 12)
        xAxisLabel.sizeToFit()
        xAxisLabel.center = CGPoint(x: frame.midX, y: frame.maxY + 45)
        mapView.addSubview(xAxisLabel)
        
        let zAxisLabel = UILabel()
        zAxisLabel.text = "Z축 (미터)"
        zAxisLabel.textColor = .white
        zAxisLabel.font = .systemFont(ofSize: 12)
        zAxisLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        zAxisLabel.sizeToFit()
        zAxisLabel.center = CGPoint(x: frame.minX - 55, y: frame.midY)
        mapView.addSubview(zAxisLabel)
        
        // 현재 축적 표시
        let scaleLabel = UILabel()
        scaleLabel.text = "1칸 = 1미터"
        scaleLabel.textColor = .white
        scaleLabel.font = .systemFont(ofSize: 12)
        scaleLabel.sizeToFit()
        scaleLabel.frame = CGRect(x: frame.maxX - 80, y: frame.maxY + 45, width: 80, height: 20)
        mapView.addSubview(scaleLabel)
        
        // 격자 테두리
        let borderView = UIView(frame: frame)
        borderView.backgroundColor = .clear
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        mapView.addSubview(borderView)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // UIScrollViewDelegate - 줌 지원
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mapView
    }
} 