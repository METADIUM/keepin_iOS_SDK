//
//  ViewController.swift
//  KeepinCRUD
//
//  Created by jinsikhan on 11/27/2020.
//  Copyright (c) 2020 jinsikhan. All rights reserved.
//

import UIKit
import web3Swift
import KeepinCRUD

class ViewController: UIViewController {
    
    var delegator: MetaDelegator!
    var wallet: MetaWallet!
    
    var store: BIP32Keystore!
    
    var serviceKey: MetadiumKey!
    
    
    @IBOutlet weak var didButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var addPublicKeyButton: UIButton!
    @IBOutlet weak var createServiceKeyButton: UIButton!
    @IBOutlet weak var addServiceKeyButton: UIButton!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var didLabel: UILabel!
    @IBOutlet weak var kidLabel: UILabel!
    
    @IBOutlet weak var signatureLabel: UILabel!
    
    
    var did: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Key Create & Delegate"

        
        UIFont.familyNames.sorted().forEach{ familyName in
                    print("*** \(familyName) ***")
                    UIFont.fontNames(forFamilyName: familyName).forEach { fontName in
                        print("\(fontName)")
                    }
                    print("---------------------")
                }
        
        
        //디폴트는 https://testdelegator.metadium.com, https://api.metadium.com/dev, did:meta:testnet:
        self.delegator = MetaDelegator.init()
        
        
        //delegate url, node url, didPrefix를 직접 설정할 때
        //self.delegator = MetaDelegator.init(delegatorUrl: "https://delegator.metadium.com", nodeUrl: "https://api.metadium.com/prod", didPrefix: "did:meta:testnet:")
                
        self.wallet = MetaWallet.init(delegator: delegator)
        
        self.addPublicKeyButton.isEnabled = false
        self.addServiceKeyButton.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    //지갑 키 생성
    @IBAction func walletKey() {
        //로컬에 키가 없을 경우 생성
        let key = self.wallet.createKey()
        
        print("privateKey: \(key?.privateKey ?? "")\npublicKey: \(key?.publicKey ?? "")\naddress: \(key?.address ?? "")\nnemonic: \(key?.nemonic ?? "")")
        
        //로컬에 프라이빗 키가 이미 저장이 되어 있을 때
        //self.wallet.assignPrivateKey(privateKey: (key?.privateKey)!)
        
        self.addPublicKeyButton.isEnabled = true
        
        DispatchQueue.main.async {
            self.addressLabel.text = self.delegator.keyStore.addresses?.first?.address
        }
    }
    
    
    //DID 생성
    @IBAction func createDidButtonAction() {
        do {
            let (signData, r, s, v) = try self.wallet.getCreateKeySignature()
            
            delegator.createIdentityDelegated(signData: signData!, r: r, s: s, v: v) { (type, txId, error) in
                if error != nil {
                    return
                }
                
                self.wallet.transactionReceipt(type: type!, txId: txId!) { (error, receipt) in
                    
                    if error != nil {
                        return
                    }
                    
                    if receipt == nil {
                        self.wallet.transactionReceipt(type: type!, txId: txId!, complection: nil)
                        
                        return
                    }
                    
                    print("status: \(receipt!.status), hash : \(receipt!.transactionHash)")
                    
                    
                    self.did = self.wallet.getDid()
                    print(self.did)
                    
                    let sign = String(data: signData!, encoding: .utf8)?.withHexPrefix
                    
                    DispatchQueue.main.async {
                        self.didLabel.text = self.did
                        self.signatureLabel.text = sign
                        self.kidLabel.text = self.wallet.getKid()
                    }
                }
            }
        }
        catch {
            print(error)
        }
        
    }
    
    
    //add PublicKey delegate
    @IBAction func addPublicKeyDelegateButtonAction() {
        
        do {
            let (signData, r, s, v) = try self.wallet.getPublicKeySignature()
            print(String(data: signData!, encoding: .utf8))
            
            self.delegator.addPublicKeyDelegated(signData: signData!, r: r, s: s, v: v) { (type, txId, error) in
                
                if error != nil {
                    return
                }
                
                self.wallet.transactionReceipt(type: type!, txId: txId!) { (error, receipt) in
                    if error != nil {
                        return
                    }
                    
                    if receipt == nil {
                        self.wallet.transactionReceipt(type: type!, txId: txId!, complection: nil)
                        
                        return
                    }
                    
                    print("status: \(receipt!.status), hash : \(receipt!.transactionHash)")
                    
                    if receipt!.status == .success {
                        
                        DispatchQueue.main.async {
                            let alert = UIAlertController.init(title: "addPublicKeyDelegate", message: receipt!.transactionHash, preferredStyle: .alert)
                            let action = UIAlertAction.init(title: "확인", style: .default, handler: nil)
                            
                            alert.addAction(action)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        catch {
            print(error)
        }
        
    }
    
    
    
    //서비스 키 생성
    @IBAction func serviceKeyButtonAction() {
        
        var message = "서비스 키가 생성되었습니다."
        
        if self.serviceKey == nil {
            self.serviceKey = self.wallet.createServiceKey()
            self.addServiceKeyButton.isEnabled = true
        }
        else {
            message = "이미 서비스 키가 있습니다."
        }
        
        let alert = UIAlertController.init(title: "", message: message, preferredStyle: .alert)
        let action = UIAlertAction.init(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    //서비스 퍼블릭키 delegate
    @IBAction func addServicePublicKeyDelegateButtonAction() {
        
        if self.serviceKey == nil {
            
            let alert = UIAlertController.init(title: "", message: "서비스 키를 먼저 생성하세요.", preferredStyle: .alert)
            let action = UIAlertAction.init(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            
            return
        }
    
        
        let address = self.serviceKey.address
        
        do {
            let (addr, signData, servieId, r, s, v) = try self.wallet.getSignServiceId(serviceID: "5933e64b-cb34-11ea-9e0f-020c6496fbdc", serviceAddress: address!)
            
            DispatchQueue.main.async {
                self.signatureLabel.text = String(data: signData!, encoding: .utf8)
            }
            
            
            self.delegator.addKeyDelegated(address: addr, signData: signData!, serviceId: servieId, r: r, s: s, v: v) { (type, txId, error) in
                if error != nil {
                    return
                }
                
                self.wallet.transactionReceipt(type: type!, txId: txId!) { (error, receipt) in
                    if error != nil {
                        return
                    }
                    
                    if receipt == nil {
                        self.wallet.transactionReceipt(type: type!, txId: txId!, complection: nil)
                        
                        return
                    }
                    
                    print("status: \(receipt!.status), hash : \(receipt!.transactionHash)")
                    
                    var title = ""
                    if receipt!.status == .success {
                        title = "성공"
                    }
                    else {
                        title = "실패"
                    }
                    
                    DispatchQueue.main.async {
                        let alert = UIAlertController.init(title: title, message: receipt!.transactionHash, preferredStyle: .alert)
                        let action = UIAlertAction.init(title: "확인", style: .default, handler: nil)
                        
                        alert.addAction(action)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
        catch {
            print(error)
        }
    }
    
    
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
            }
            catch {
                print(error)
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
                print(error)
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
                print(error)
            }
        }
    }
}
