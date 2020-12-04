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
    
    
    @IBOutlet weak var didButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var addPublicKeyButton: UIButton!
    @IBOutlet weak var createServiceKeyButton: UIButton!
    @IBOutlet weak var addServiceKeyButton: UIButton!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var didLabel: UILabel!
    @IBOutlet weak var signatureLabel: UILabel!
    
    
    var did: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.delegator = MetaDelegator.init()
        self.wallet = MetaWallet.init(delegator: delegator)
        
        
        self.addPublicKeyButton.isEnabled = false
        self.addServiceKeyButton.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    
    @IBAction func walletKey() {
        self.wallet.createKey(type: .walletKey)
        
        self.addPublicKeyButton.isEnabled = true
        
        DispatchQueue.main.async {
            self.addressLabel.text = self.delegator.keyStore.addresses?.first?.address
        }
    }
    
    @IBAction func createDidButtonAction() {
        let (signData, r, s, v) = wallet.getWalletSignature()
        
        DispatchQueue.global().sync {
            let (type, txID) = delegator.createIdentityDelegated(signData: signData!, r: r, s: s, v: v)
            let receipt = self.wallet.transactionReceipt(type: type!, txId: txID!)
            
            print("status: \(receipt.status), hash : \(receipt.transactionHash)")
        }
        
        
        self.did = self.wallet.getDid()
        let sign = String(data: signData!, encoding: .utf8)?.withHexPrefix
        
        DispatchQueue.main.async {
            self.didLabel.text = self.did
            self.signatureLabel.text = sign
        }
    }
    
    
    @IBAction func addPublicKeyDelegateButtonAction() {
        let (signData, r, s, v) = self.wallet.getPublicKeySignature()
        print(String(data: signData!, encoding: .utf8))
        
        
        let (type, txID) = self.delegator.addPublicKeyDelegated(signData: signData!, r: r, s: s, v: v)
        let receipt = self.wallet.transactionReceipt(type: type!, txId: txID)
        
        print("status: \(receipt.status), hash : \(receipt.transactionHash)")
    }
    
    
    @IBAction func serviceKeyButtonAction() {
        self.store = self.wallet.createServiceKey()
        self.addServiceKeyButton.isEnabled = true
        
        
        if self.store != nil {
            let alert = UIAlertController.init(title: "", message: "서비스키 생성 완료", preferredStyle: .alert)
            let action = UIAlertAction.init(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    
    @IBAction func addServicePublicKeyDelegateButtonAction() {
        
        let address = self.store?.addresses?.first
        
        let privateKey = try! self.store?.UNSAFE_getPrivateKeyData(password: "", account: address!)
        print(privateKey)
        
        let serviceAddr = address?.address
        
        let (addr, signData, servieId, r, s, v) = self.wallet.getSignServiceId(serviceID: "5933e64b-cb34-11ea-9e0f-020c6496fbdc", serviceAddress: serviceAddr!)
        
        DispatchQueue.main.async {
            self.signatureLabel.text = String(data: signData!, encoding: .utf8)
        }
        
        
        DispatchQueue.global().sync {
            let (type, txID) = self.delegator.addKeyDelegated(address: addr, signData: signData!, serviceId: servieId, r: r, s: s, v: v)
            let receipt = self.wallet.transactionReceipt(type: type!, txId: txID)
            
            print("status: \(receipt.status), hash : \(receipt.transactionHash)")
            
            
            var title = ""
            if receipt.status == .success {
                title = "성공"
            }
            else {
                title = "실패"
            }
            
            let alert = UIAlertController.init(title: title, message: receipt.transactionHash, preferredStyle: .alert)
            let action = UIAlertAction.init(title: "확인", style: .default, handler: nil)
            
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
}

