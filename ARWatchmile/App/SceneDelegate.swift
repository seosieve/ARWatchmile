//
//  SceneDelegate.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 7/22/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        //상수 사용을 위해 이름을 넣습니다.
        let viewController = UIWindow(windowScene: windowScene)
        //최초 진입 뷰 컨트롤러를 지정합니다.
        viewController.rootViewController = ARCoreViewController()
        //창을 활성화하고 표시합니다.
        viewController.makeKeyAndVisible()
        //self.window에 생성한 윈도우를 지정합니다.
        self.window = viewController
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // 앱이 백그라운드로 갈 때 WorldMap 저장
        saveWorldMapOnBackground()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // 앱이 완전히 종료될 때 WorldMap 저장
        saveWorldMapOnBackground()
    }
    
    private func saveWorldMapOnBackground() {
        // 메인 스레드에서 안전하게 실행
        DispatchQueue.main.async {
            // 현재 활성화된 ARViewController 찾기
            if let window = self.window,
               let rootViewController = window.rootViewController as? ARViewController {
                rootViewController.arSessionManager.saveWorldMap()
                print("🔄 앱 종료 시 WorldMap 저장 완료")
            }
        }
    }
}

