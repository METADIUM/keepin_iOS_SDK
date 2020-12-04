//
//  DataProvider.swift
//  KeepinCRUD
//
//  Created by hanjinsik on 2020/12/01.
//

import UIKit


typealias ServiceResponse = (URLResponse?, Any?, Error?) -> Void

class DataProvider: NSObject {

    
    class func jsonRpcMethod(url: URL, method: String, parmas: [[String: Any]]? = [[:]], complection: @escaping ServiceResponse) {
        let session = URLSession.shared
        let request = NSMutableURLRequest.init(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json-rpc", forHTTPHeaderField: "Content-Type")
        
        
        let jsonRpc = ["jsonrpc" : "2.0", "id" : 1, "method" : method, "params" : parmas!] as [String : Any]
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: jsonRpc, options: .prettyPrinted)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if error != nil {
                return complection(response, nil, error)
            }
            
            
            let result = try? JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as! NSDictionary
            
            if let dic = result!["result"] as? Any {
                return complection(response, dic, nil)
            }
            
            return complection(response, data, nil)
            
        }
        
        task.resume()
    }
}
