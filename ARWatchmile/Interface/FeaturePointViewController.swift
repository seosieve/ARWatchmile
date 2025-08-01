import UIKit
import ARKit

class FeaturePointViewController: UIViewController, UIScrollViewDelegate {
    var featurePoints: [SIMD3<Float>] = []
    var originPoint: SIMD3<Float>?
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
        scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.minimumZoomScale = 0.4
        scrollView.maximumZoomScale = 3.0
        scrollView.frame = view.bounds
        view.addSubview(scrollView)
        mapView = UIView()
        mapView.backgroundColor = .black
        let mapWidth: CGFloat = 2000
        let mapHeight: CGFloat = 2000
        mapView.frame = CGRect(x: 0, y: 0, width: mapWidth, height: mapHeight)
        scrollView.addSubview(mapView)
        scrollView.contentSize = mapView.frame.size
        let centerX = mapView.frame.width / 2
        let centerY = mapView.frame.height / 2
        scrollView.setContentOffset(CGPoint(x: centerX - scrollView.frame.width/2, y: centerY - scrollView.frame.height/2), animated: false)
        closeButton = UIButton(type: .system)
        closeButton.setTitle("닫기", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = .systemGray
        closeButton.layer.cornerRadius = 8
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let safeTop = view.safeAreaInsets.top
        let buttonY = safeTop + 20
        let buttonHeight: CGFloat = 40
        closeButton.frame = CGRect(x: 20, y: buttonY, width: 60, height: buttonHeight)
        if let infoLabel = view.subviews.first(where: { $0 is UILabel && ($0 as! UILabel).text?.contains("특징점") == true }) as? UILabel {
            infoLabel.sizeToFit()
            infoLabel.frame = CGRect(
                x: view.bounds.width - infoLabel.frame.width - 20,
                y: buttonY + (buttonHeight - infoLabel.frame.height) / 2,
                width: infoLabel.frame.width,
                height: infoLabel.frame.height
            )
        }
    }

    private func drawMap() {
        guard !featurePoints.isEmpty else {
            let label = UILabel()
            label.text = "특징점 데이터가 없습니다"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = mapView.bounds
            mapView.addSubview(label)
            return
        }
        var minX: Float = .infinity
        var maxX: Float = -.infinity
        var minZ: Float = .infinity
        var maxZ: Float = -.infinity
        for point in featurePoints {
            guard point.x.isFinite && point.z.isFinite else { continue }
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minZ = min(minZ, point.z)
            maxZ = max(maxZ, point.z)
        }
        guard minX.isFinite && maxX.isFinite && minZ.isFinite && maxZ.isFinite,
              minX < maxX && minZ < maxZ else {
            let label = UILabel()
            label.text = "유효하지 않은 특징점 데이터"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = mapView.bounds
            mapView.addSubview(label)
            return
        }
        let mapWidth = CGFloat(maxX - minX) * scale
        let mapHeight = CGFloat(maxZ - minZ) * scale
        guard mapWidth > 0, mapWidth.isFinite,
              mapHeight > 0, mapHeight.isFinite
        else {
            let label = UILabel()
            label.text = "맵 크기가 유효하지 않습니다\(mapWidth), \(mapHeight)"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = mapView.bounds
            mapView.addSubview(label)
            return
        }
        let mapFrame = CGRect(
            x: (mapView.bounds.width - mapWidth) / 2,
            y: (mapView.bounds.height - mapHeight) / 2,
            width: mapWidth,
            height: mapHeight
        )
        drawGrid(in: mapFrame, minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ)
        let infoLabel = UILabel()
        infoLabel.text = "특징점: \(featurePoints.count)개"
        infoLabel.numberOfLines = 1
        infoLabel.textColor = .white
        infoLabel.textAlignment = .right
        infoLabel.font = .systemFont(ofSize: 12)
        infoLabel.sizeToFit()
        let safeTop = view.safeAreaInsets.top
        let buttonY = safeTop + 20
        let buttonHeight: CGFloat = 40
        infoLabel.frame = CGRect(
            x: view.bounds.width - infoLabel.frame.width - 20,
            y: buttonY + (buttonHeight - infoLabel.frame.height) / 2,
            width: infoLabel.frame.width,
            height: infoLabel.frame.height
        )
        view.addSubview(infoLabel)
        // 특징점(노란색)만 그리기
        drawPoints(points: featurePoints, color: .systemYellow, minX: minX, minZ: minZ, mapFrame: mapFrame)
    }

    private func drawPoints(points: [SIMD3<Float>], color: UIColor, minX: Float, minZ: Float, mapFrame: CGRect) {
        for i in stride(from: 0, to: points.count, by: 10) {
            let point = points[i]
            guard point.x.isFinite && point.z.isFinite else { continue }
            let x = CGFloat(point.x) * scale + mapView.bounds.midX
            let y = CGFloat(point.z) * scale + mapView.bounds.midY
            guard x.isFinite && y.isFinite,
                  x >= mapFrame.minX - 100 && x <= mapFrame.maxX + 100,
                  y >= mapFrame.minY - 100 && y <= mapFrame.maxY + 100
            else { continue }
            let dotView = UIView(frame: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
            dotView.backgroundColor = color.withAlphaComponent(0.5)
            dotView.layer.cornerRadius = dotSize / 2
            dotView.center = CGPoint(x: x, y: y)
            mapView.addSubview(dotView)
        }
    }

    private func drawGrid(in frame: CGRect, minX: Float, maxX: Float, minZ: Float, maxZ: Float) {
        let gridSpacing: CGFloat = scale
        let originScreenX = mapView.frame.width / 2
        let originScreenY = mapView.frame.height / 2
        var x = originScreenX
        while x >= originScreenX - (6 * gridSpacing) {
            let line = UIView()
            line.backgroundColor = x == originScreenX ? UIColor.white.withAlphaComponent(0.5) : UIColor.gray.withAlphaComponent(0.3)
            line.frame = CGRect(x: x, y: 0, width: 1, height: mapView.frame.height)
            mapView.addSubview(line)
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
        x = originScreenX + gridSpacing
        while x <= mapView.frame.width {
            let line = UIView()
            line.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
            line.frame = CGRect(x: x, y: 0, width: 1, height: mapView.frame.height)
            mapView.addSubview(line)
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
        var y = originScreenY
        while y >= 0 {
            let line = UIView()
            line.backgroundColor = y == originScreenY ? UIColor.white.withAlphaComponent(0.5) : UIColor.gray.withAlphaComponent(0.3)
            line.frame = CGRect(x: 0, y: y, width: mapView.frame.width, height: 1)
            mapView.addSubview(line)
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
        y = originScreenY + gridSpacing
        while y <= mapView.frame.height {
            let line = UIView()
            line.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
            line.frame = CGRect(x: 0, y: y, width: mapView.frame.width, height: 1)
            mapView.addSubview(line)
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
        let scaleLabel = UILabel()
        scaleLabel.text = "1칸 = 1미터"
        scaleLabel.textColor = .white
        scaleLabel.font = .systemFont(ofSize: 12)
        scaleLabel.sizeToFit()
        scaleLabel.frame = CGRect(x: frame.maxX - 80, y: frame.maxY + 45, width: 80, height: 20)
        mapView.addSubview(scaleLabel)
        let borderView = UIView(frame: frame)
        borderView.backgroundColor = .clear
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        mapView.addSubview(borderView)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mapView
    }
} 
