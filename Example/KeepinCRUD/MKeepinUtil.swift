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
    
    
    //MARK: Get Time Interval From Date
    class func getIntervalSecondInt(from: Date, to: Date) -> Int?{
        let interval = to.timeIntervalSince(from)
        if interval >= Double(Int.min) {
            if interval < Double(Int.max) { // fit for int
                let seconds = Int(interval)
                return seconds
            } else { // too small for int (less than 1 second)
                return 0
            }
        }
        // too big for int (over about 68 years, in 32bit int)
        // return nil if the interval is too big
        NSLog("getIntervalSecondInt(): Prevented Int Overflow ")
        return nil
    }
    
    class func getIntervalMinuteInt(from: Date, to: Date) -> (Int, Int)? {
        if let s = self.getIntervalSecondInt(from: from, to: to) {
            let minute = s / 60
            let second = s % 60
            
            return(minute, second)
        }
        
        return  nil
    }
    
    class func getIntervalHourInt(from: Date, to: Date) -> (Int, Int, Int)?{
        if let minSec = self.getIntervalMinuteInt(from: from, to: to) {
            let hour = minSec.0 / 60
            let minute = minSec.0 % 60
            
            return (hour, minute, minSec.1)
        }
        
        return nil
    }
    
    class func getIntervalDayInt(from: Date, to: Date) -> (Int, Int, Int, Int)?{
        if let hourMinSec = self.getIntervalHourInt(from: from, to: to) {
            let day = hourMinSec.0 / 24
            let hour = hourMinSec.0 % 24
            
            return (day, hour, hourMinSec.1, hourMinSec.2)
        }
        
        return nil
    }
    
    
    
    //MARK: Local User Notification
    
    /**
     @pram : time interval을 입력하여 일정 시간 뒤로 예약하거나, 연월일시분(24h)을 입력하거나, 특정 시간 offset을 입력하여 예약 가능
     */
    class func setPushByTimeInterval (service: MServiceObj?, title: String?, body: String?, seconds: Double, dayOffset: Int) {
        if let timeInterval = TimeInterval.init(exactly: seconds) {
            //create time interval trigger
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            self.schedulePush(service: service, title: title, body: body, trigger: trigger, dayOffset: dayOffset)
        }
        
    }
    
    class func setPushByCalendar (service: MServiceObj?, title: String?, body: String?, minute: Int? = nil, hour: Int? = nil, day: Int? = nil, month: Int? = nil, year: Int? = nil) {
        //specify date conditions
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        
        if let y = year {
            dateComponents.year = y
        }
        if let m = month {
            dateComponents.month = m
        }
        if let d = day {
            dateComponents.day = d
        }
        if let h = hour {
            dateComponents.hour = h
        }
        if let min = minute {
            dateComponents.minute = min
        }
        
        //create calendar trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        self.schedulePush(service: service, title: title, body: body, trigger: trigger)
    }
    
    class func setPushByDayOffset (service: MServiceObj?, title: String, body: String, to: Date , dayOffset: Int) {
        
        let today = Date()
        
        if let dDay = Calendar.current.date(byAdding: .day, value: dayOffset, to: to) {
            let result = dDay.compare(today).rawValue
            if result > 0 {
                let interval = dDay.timeIntervalSince(today)
                print("\n만료Push 예약됨: 현재시간: \(today.description)     목표시간: \(dDay.description)")
                print(Double(interval))
                
                if dayOffset == 0 {
                    self.setPushByTimeInterval(service: service, title: "\(service!.aaObj!.title!) 유효기간 만료", body: "\(service!.aaObj!.title!) 유효기간이 만료되어 삭제되었습니다.", seconds: Double(interval), dayOffset: dayOffset)
                } else {
                    self.setPushByTimeInterval(service: service, title: title, body: "\(body) \(-dayOffset)일 남았습니다.", seconds: Double(interval), dayOffset: dayOffset)
                }
            }
            else {
                print("\n만료Push 무시됨: 현재시간: \(today.description)   예약시간: \(dDay.description)")
            }
        }
    }
    
    private class func schedulePush (service: MServiceObj?, title: String?, body: String?, trigger: UNNotificationTrigger, dayOffset: Int = 1) {
        //create notification content
        let content = UNMutableNotificationContent()
        content.title = title ?? "알림"
        content.body = body ?? "새로운 알림이 있습니다."
        
        var id: String = (service?.id) ?? ""
        if id == "" {
            id = (service?.aaObj?.name) ?? ""
        }
        if dayOffset < 1 {
            id = "\(id)-\(-dayOffset)"
        }
        
        let popupBody: String = body ?? ""
        let popupTitle: String = title ?? ""
        content.userInfo = ["aps": ["alert" : ["title": popupTitle,
                                               "body" : popupBody]    ],
                            "click_action": id]
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        //schedule the request on system
        let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(request) { (error) in
                if let error = error {
                    NSLog("User Notification add Request ERROR Occur !!!")
                    NSLog(error.localizedDescription)
            }
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
