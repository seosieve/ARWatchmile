//
//  AnchorViewController.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/31/25.
//

import UIKit
import ARKit
import RealityKit

class AnchorViewController: UIViewController {
    var anchorManager: AnchorManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInitial()
    }
    
    func setInitial() {
        anchorManager = AnchorManager()
        anchorManager.arView = ARView(frame: view.bounds)
        view.addSubview(anchorManager.arView)
    }
}
