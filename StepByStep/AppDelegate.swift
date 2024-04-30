//
//  AppDelegate.swift
//  StepByStep
//
//  Created by Yune gim on 2023/05/02.
//

import UIKit
import KakaoSDKCommon
import KakaoSDKAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        KakaoSDK.initSDK(appKey: "bd5e626fd8ad0592f6cf5bcd449f53f3")
        //let viewController = iPhoneController()
        //viewController.LoginCheck()
        if AuthApi.hasToken() {
            // 토큰이 있을 경우에 수행할 작업
            // 예: 자동 로그인 처리 등
            let storyboard = UIStoryboard(name: "IphoneMain", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainStoryboard")
            tabBarController.modalPresentationStyle = .fullScreen
            
            // 윈도우 객체를 가져와서 루트 뷰 컨트롤러로 설정
            if let window = self.window {
                window.rootViewController = tabBarController
                window.makeKeyAndVisible()
            }
        } else {
            // 토큰이 없을 경우에 수행할 작업
            // 예: 로그인 화면으로 이동 등
            // ...
        }
        sleep(1)
        return true
    }
}

extension UIViewController {
    func hideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
            action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
