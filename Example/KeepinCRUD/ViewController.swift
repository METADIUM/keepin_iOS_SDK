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
    var serviceKey: MetadiumKey!
    
    
    @IBOutlet weak var didButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var addPublicKeyButton: UIButton!
    @IBOutlet weak var createServiceKeyButton: UIButton!
    @IBOutlet weak var addServiceKeyButton: UIButton!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var didLabel: UILabel!
    
    
    var did: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Key Create & Delegate"
        
        
        /**
         * 개발서버 delegateUrl: https://testdelegator.metadium.com, nodeUrl:  https://api.metadium.com/dev, resolverUrl: https://testnetresolver.metadium.com/1.0/identifiers/,  didPrefix: did:meta:testnet:
         * 운영서버 delegateUrl: https://delegator.metadium.com, nodeUrl:  https://api.metadium.com/prod, resolverUrl: https://resolver.metadium.com/1.0/identifiers/, didPrefix: did:meta:
         */

        
        self.delegator = MetaDelegator.init(delegatorUrl: "https://testdelegator.metadium.com",
                                            nodeUrl: "https://api.metadium.com/dev",
                                            resolverUrl: "https://testnetresolver.metadium.com/1.0/identifiers/",
                                            didPrefix: "did:meta:testnet:",
                                            api_key: "abcd1234efgzPiefqeq3l1ba344gg")
                
        self.wallet = MetaWallet.init(delegator: self.delegator)
        
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
        
        print("privateKey: \(key?.privateKey ?? "")\npublicKey: \(key?.publicKey ?? "")\naddress: \(key?.address ?? "")")
        
        //로컬에 프라이빗 키가 이미 저장이 되어 있을 때
        //self.wallet.assignPrivateKey(privateKey: (key?.privateKey)!)
        
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
                
                //delay를 주지 않으면 트랜잭션 리셉 받아올 때 error가 떨어지기 때문에 어느정도의 delay가 필요합니다.
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    
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
                        print(self.did!)
                        
                        let jsonStr = self.wallet.toJson()
                        print(jsonStr!)
                        
                        let sign = String(data: signData!, encoding: .utf8)?.withHexPrefix
                        
                        DispatchQueue.main.async {
                            self.didLabel.text = self.did
                            MKeepinUtil.showAlert(message: sign, controller: self, onComplection: nil)
                            
                            print(self.wallet.getKid())
                        }
                        
                        self.addPublicKeyDelegate()
                    }
                }
            }
        }
        catch {
            print(error)
        }
        
    }
    
    
    //add PublicKey delegate
    func addPublicKeyDelegate() {
        
        do {
            let (signData, r, s, v) = try self.wallet.getPublicKeySignature()
            print(String(data: signData!, encoding: .utf8))
            
            self.delegator.addPublicKeyDelegated(signData: signData!, r: r, s: s, v: v) { (type, txId, error) in
                
                if error != nil {
                    return
                }
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    
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
                print(String(data: signData!, encoding: .utf8))
            }
            
            
            self.delegator.addKeyDelegated(address: addr, signData: signData!, serviceId: servieId, r: r, s: s, v: v) { (type, txId, error) in
                if error != nil {
                    return
                }
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
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
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                        self.wallet?.transactionReceipt(type: type!, txId: txId!, complection: { (error, receipt) in
                            
                            if error != nil {
                                return
                            }
                            
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
                    }
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
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
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
                    }
                    
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
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                        
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
                    }
                    
                })
            }
            catch {
                print(error)
            }
        }
    }
}

