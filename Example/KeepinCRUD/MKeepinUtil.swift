//
//  MKeepinUtil.swift
//  MetaID_real
//
//  Created by hanjinsik on 2020/02/27.
//  Copyright © 2020 metadium. All rights reserved.
//

import UIKit

typealias AlertAction = (UIAlertController?, Int?) -> Void

class MKeepinUtil: NSObject {
    
    
    class func showAlert(message: String? = "오류가 발생했습니다.\n잠시 후 다시 시도해주세요.", controller: UIViewController, onComplection: AlertAction?) -> Void {
        
        let alert = UIAlertController.init(title: "", message: message, preferredStyle: .alert)
        
        let action = UIAlertAction.init(title: "확인", style: .default) { (action) in
            if onComplection != nil {
                onComplection!(alert, 0)
            }
            
        }
        alert.addAction(action)
        
        DispatchQueue.main.async {
            controller.present(alert, animated: true, completion: nil)
        }
    }
    
    
    class func showAlert(title: String? = "", message: String? = "오류가 발생했습니다.\n잠시 후 다시 시도해주세요.", buttons: [String], controller: UIViewController, onComplection: @escaping AlertAction) -> Void {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        
        if buttons.count > 1 {
            let action = UIAlertAction.init(title: buttons[0], style: .default) { (action) in
                onComplection(alert, 0)
            }
            
            let action1 = UIAlertAction.init(title: buttons[1], style: .default) { (action) in
                onComplection(alert, 1)
            }
            
            alert.addAction(action)
            alert.addAction(action1)
        }
        else {
            let action = UIAlertAction.init(title: buttons[0], style: .default) { (action) in
                onComplection(alert, 0)
            }
            
            alert.addAction(action)
        }
        
        DispatchQueue.main.async {
            controller.present(alert, animated: true, completion: nil)
        }
    }
}




//MARK: Extensions
//navigation bar setting extension
extension UIViewController {
    internal func setNavigationBarWithBackButton(title: String = "") {
        self.navigationController?.isNavigationBarHidden = false
        self.title = title
        
        let btn = UIButton.init(type: .custom)
        btn.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        btn.setImage(UIImage(named: "icArrowLeftN"), for: .normal)
        btn.addTarget(self, action: #selector(vcPopButtonAction), for: .touchUpInside)
        
        let barBtn = UIBarButtonItem.init(customView: btn)
        self.navigationItem.leftBarButtonItem = barBtn
    }
    
    @objc internal func vcPopButtonAction() {
        
        if self.navigationController?.viewControllers.count == 1 {
            self.navigationController?.dismiss(animated: true, completion: nil)
            return
        }
        self.navigationController?.popViewController(animated: true)
    }
}

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
