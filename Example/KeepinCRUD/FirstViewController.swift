//
//  FirstViewController.swift
//  KeepinCRUD_Example
//
//  Created by hanjinsik on 2021/01/12.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import web3Swift
import KeepinCRUD

class FirstViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var didLabel: UILabel!
    @IBOutlet weak var privateKeyLabel: UILabel!
    @IBOutlet weak var signatureLabel: UILabel!
    
    @IBOutlet weak var signTextField: UITextField!
    
    
    var wallet: MetaWallet?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "FirstViewController"
        self.signTextField.text = "Test Data"
    }


    @IBAction func createKeyButtonAction() {
        let vc = ViewController.init(nibName: "ViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBAction func loadKeyButtonAction() {
        
        let delegator = MetaDelegator.init()
        
        self.wallet = MetaWallet.init(delegator: delegator, nemonic: "found dilemma able enemy wagon review bronze wall attend cannon patient script", did: "did:meta:testnet:0x00000000000000000000000000002991")
        
        DispatchQueue.main.async {
            self.didLabel.text =  self.wallet!.getDid()
        }
        
        
        let key = self.wallet!.getKey()
        
        if key != nil {
            print("privateKey: \(key?.privateKey! ?? "")")
            print("publicKey: \(key?.publicKey! ?? "")")
            print("address: \(key?.address! ?? "")")
            print("nemonic: \(key?.nemonic! ?? "")")
        }
    }
    
    
    @IBAction func signButtonAction() {
        
        if self.wallet != nil {
            var str = ""
            
            if !self.signTextField.text!.isEmpty {
                str = self.signTextField.text!
            }
            
            if str.isEmpty {
                return
            }
            
            let data = str.data(using: .utf8)
            
            let (signature, r, s, v) = self.wallet!.getSignature(data: data!)
            
            print("r: \(r ?? ""), s: \(s ?? ""), v: \(v ?? "")")
            
            DispatchQueue.main.async {
                self.signatureLabel.text = String(data: signature!, encoding: .utf8)?.withHexPrefix
            }
            
            return
        }
        
        
        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: "", message: "키가 없습니다. 키를 생성하세요.", preferredStyle: .alert)
            let action = UIAlertAction.init(title: "확인", style: .default, handler: nil)
            
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }

}
