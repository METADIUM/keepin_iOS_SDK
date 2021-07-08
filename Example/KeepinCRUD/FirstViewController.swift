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
import JWTsSwift

class FirstViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var didLabel: UILabel!
    @IBOutlet weak var privateKeyLabel: UILabel!
    @IBOutlet weak var signatureLabel: UILabel!
    
    @IBOutlet weak var signTextField: UITextField!
    
    
    var wallet: MetaWallet?
    var delegator: MetaDelegator?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "FirstViewController"
        self.signTextField.text = "Test Data"
        
        
        let btn = UIButton(type: .system)
        btn.addTarget(self, action: #selector(self.createKeyButtonAction), for: .touchUpInside)
        btn.setTitle("키생성", for: .normal)
        
        let barItem = UIBarButtonItem.init(customView: btn)
        self.navigationItem.rightBarButtonItem = barItem
    }


    
    
    @objc func createKeyButtonAction() {
        let vc = ViewController.init(nibName: "ViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    @IBAction func loadKeyButtonAction() {
        
        self.delegator = MetaDelegator.init()
        self.wallet = MetaWallet.init(delegator: self.delegator!, privateKey: "0xb7fddf3e1645b2f2ef8e1f427ec2ae76cc6989fd33999f065bc48cb39d6c2336", did: "did:meta:testnet:0000000000000000000000000000000000000000000000000000000000002f4c")

        DispatchQueue.main.async {
            self.didLabel.text =  self.wallet!.getDid()
        }
        
        
        let key = self.wallet!.getKey()
        
        if key != nil {
            print("privateKey: \(key?.privateKey! ?? "")")
            print("publicKey: \(key?.publicKey! ?? "")")
            print("address: \(key?.address! ?? "")")
        }
    }
    
    
    @IBAction func didDocumentButtonAction() {
//        let did = "did:meta:0000000000000000000000000000000000000000000000000000000000004f82"
        
        let did = self.wallet?.getDid()
        
        self.wallet?.reqDiDDocument(did: did!, complection: { (document, error) in
            if error != nil {
                return
            }
            
            let document = document
            
            print(document)
        })
        
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
                
                MKeepinUtil.showAlert(message: String(data: signature!, encoding: .utf8)?.withHexPrefix, controller: self, onComplection: nil)
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
    
    
    /*
    @IBAction func credentialButtonAction() {
        
        let issuanceDate = Date()
        let expirationDate = Date()
        let nonce = Data.randomBytes(length: 32)?.base64EncodedString()
        
        let vc = try? self.wallet?.issueCredential(types: ["NameCredential"],
                                                   id: "http://aa.metadium.com/credential/name/343",
                                                   nonce: nonce,
                                                   issuanceDate: issuanceDate,
                                                   expirationDate: expirationDate,
                                                   ownerDid: "did:meta:00000...00003159",
                                                   subjects: ["name": "Keepin"]) as! JWSObject
        
        
        let serializedVC = try? vc?.serialize()
        
    }
    
    @IBAction func presentationButtonAction() {
        let issuanceDate = Date()
        let expirationDate = Date()
        let nonce = Data.randomBytes(length: 32)?.base64EncodedString()
        
        let vp = try? self.wallet?.issuePresentation(types: ["TestPresentation"],
                                                     id: "http://aa.metadium.com/presentation/343",
                                                     nonce: nonce,
                                                     issuanceDate: issuanceDate,
                                                     expirationDate: expirationDate,
                                                     vcList: [serializedVC]) as! JWSObject
        
        let serializedVP = try? vp?.serialize()
    }
 */
    
    
    @IBAction func removeKeyButtonAction() {
        if self.wallet != nil {
            
            do {
                let (_, r, s, v) = try self.wallet!.getRemoveKeySign()
                
                self.delegator?.removeKeyDelegated(r: r, s: s, v: v, complection: { (type, txId, error) in
                    if error != nil {
                        return
                    }
                    
                    self.wallet?.transactionReceipt(type: type!, txId: txId!, complection: { (error, receipt) in
                        
                        var title = ""
                        if receipt!.status == .success {
                            title = "RemoveKey:"  + "성공"
                        }
                        else {
                            title = "RemoveKey:"  + "실패"
                        }
                        
                        DispatchQueue.main.async {
                            let alert = UIAlertController.init(title: title, message: receipt!.transactionHash, preferredStyle: .alert)
                            let action = UIAlertAction.init(title: "확인", style: .default, handler: nil)
                            
                            alert.addAction(action)
                            self.present(alert, animated: true, completion: nil)
                        }
                    })
                })
            } catch {
                print(error.localizedDescription)
            }
            
            
        }
    }
    
    @IBAction func removePublicKeyButtonAction() {
        if self.wallet != nil {
            
            do {
                let (_, r, s, v) = try self.wallet!.getRemovePublicKeySign()
                
                self.delegator?.removePublicKeyDelegated(r: r, s: s, v: v, complection: { (type, txId, error) in
                    if error != nil {
                        return
                    }
                    
                    self.wallet?.transactionReceipt(type: type!, txId: txId!, complection: { (error, receipt) in
                        
                        var title = ""
                        if receipt!.status == .success {
                            title = "RemovePublicKey:"  + "성공"
                        }
                        else {
                            title = "RemovePublicKey:"  + "실패"
                        }
                        
                        DispatchQueue.main.async {
                            let alert = UIAlertController.init(title: title, message: receipt!.transactionHash, preferredStyle: .alert)
                            let action = UIAlertAction.init(title: "확인", style: .default, handler: nil)
                            
                            alert.addAction(action)
                            self.present(alert, animated: true, completion: nil)
                        }
                    })
                })
            }
            catch {
                print(error.localizedDescription)
            }
            
            
        }
    }
    
    @IBAction func removeAssociatedAddressButtonAction() {
        if self.wallet != nil {
            
            do {
                let (_, r, s, v) = try self.wallet!.getRemoveAssociatedAddressSign()
                
                self.delegator?.removeAssociatedAddressDelegated(r: r, s: s, v: v, complection: { (type, txId, error) in
                    if error != nil {
                        return
                    }
                    
                    self.wallet?.transactionReceipt(type: type!, txId: txId!, complection: { (error, receipt) in
                        
                        var title = ""
                        if receipt!.status == .success {
                            title = "RemoveAssociatedKey:"  + "성공"
                        }
                        else {
                            title = "RemoveAssociatedKey:"  + "실패"
                        }
                        
                        DispatchQueue.main.async {
                            let alert = UIAlertController.init(title: title, message: receipt!.transactionHash, preferredStyle: .alert)
                            let action = UIAlertAction.init(title: "확인", style: .default, handler: nil)
                            
                            alert.addAction(action)
                            self.present(alert, animated: true, completion: nil)
                        }
                    })
                })
            }
            catch {
                print(error.localizedDescription)
            }
            
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }

}
