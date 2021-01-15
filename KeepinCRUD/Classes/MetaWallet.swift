//
//  MetaWallet.swift
//  KeepinCRUD
//
//  Created by hanjinsik on 2020/12/01.
//

import UIKit
import web3Swift
import BigInt
import CryptoSwift


public typealias TransactionRecipt = (EthereumClientError?, EthereumTransactionReceipt?) -> Void

public enum MetaTransactionType {
    case createDid
    case addWalletPublicKey
    case addServicePublicKey
}

public class MetaWallet: NSObject, MetaDelegatorMessenger {
    
    var account: EthereumAccount!
    
    var delegator: MetaDelegator!
    
    var metaID: String!

    var keyStore: EthereumKeystoreV3?
    
    var did: String! = ""
    var nemonic: String? = ""
    
    
    func sendTxID(txID: String, type: MetaTransactionType) {
        
        let _ = self.transactionReceipt(type: type, txId: txID, complection: nil)
    }
    
    
    public init(delegator: MetaDelegator, nemonic: String? = "", did: String? = "") {
        super.init()
        
        self.delegator = delegator
        self.delegator.messenger = self
        
        self.nemonic = nemonic
        self.did = did
        
        /**
         * 로컬에 저장되어 있는 privateKey로 keystore를 가져온다.
         */
        if !nemonic!.isEmpty {
            let seed = BIP39.seedFromMmemonics(nemonic!)
            
            do {
                let bip32keyStore = try BIP32Keystore(seed: seed!, password: "", prefixPath: KDefine.kBip44PrefixPath, aesMode: KDefine.kAes128CBC)
                let address = bip32keyStore?.addresses?.first
                
                do {
                    let privateKey = try bip32keyStore?.UNSAFE_getPrivateKeyData(password: "", account: address!).toHexString()
                    self.keyStore = try! EthereumKeystoreV3.init(privateKey: Data.init(hex: privateKey!))
                    
                    self.delegator.keyStore = self.keyStore!
                    
                } catch {
                    print(error.localizedDescription)
                }
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    
    /**
     * 지갑 키 생성
     */
    public func createKey() -> MetadiumKey? {
        
        let entropy = Data.randomBytes(length: KDefine.kEntropy_Length)
        let nemonic = BIP39.generateMnemonicsFromEntropy(entropy: entropy!)
        let seed = BIP39.seedFromMmemonics(nemonic!)
        
        do {
            let store = try BIP32Keystore(seed: seed!, password: "", prefixPath: KDefine.kBip44PrefixPath, aesMode: KDefine.kAes128CBC)
            let address = store?.addresses?.first
            
            
            do {
                let privateKey = try store?.UNSAFE_getPrivateKeyData(password: "", account: address!).toHexString()
                self.keyStore = try! EthereumKeystoreV3.init(privateKey: Data.init(hex: privateKey!))
                
                self.delegator.keyStore = self.keyStore!
                
                let account = try? EthereumAccount.init(keyStore: self.keyStore!)
                
                let key = MetadiumKey()
                key.address = address?.address
                key.privateKey = account?.privateKey
                key.publicKey = account?.publicKey
                key.nemonic = nemonic
                
                return key
                
            } catch {
                print(error.localizedDescription)
            }
            
        } catch  {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    
    
    /**
     * 서비스 키 생성
     */
    
    public func createServiceKey() -> MetadiumKey? {
        let entropy = Data.randomBytes(length: KDefine.kEntropy_Length)
        let nemonic = BIP39.generateMnemonicsFromEntropy(entropy: entropy!)
        let seed = BIP39.seedFromMmemonics(nemonic!)
        
        do {
            let store = try BIP32Keystore(seed: seed!, password: "", prefixPath: KDefine.kBip44PrefixPath, aesMode: KDefine.kAes128CBC)
            let address = store?.addresses?.first
            
            let privateKey = try store?.UNSAFE_getPrivateKeyData(password: "", account: address!).toHexString()
            let keyStore = try! EthereumKeystoreV3.init(privateKey: Data.init(hex: privateKey!))
            let account = try? EthereumAccount.init(keyStore: keyStore!)
            
            let key = MetadiumKey()
            key.address = address?.address
            key.privateKey = account?.privateKey
            key.publicKey = account?.publicKey
            key.nemonic = nemonic
            
            return key
            
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    

    
    /**
     * @param  sign data
     */
    
    public func getSignature(data: Data) -> (Data?, String?, String?, String?) {
        
        if self.keyStore != nil {
            let account:EthereumAccount! = try? EthereumAccount.init(keyStore: self.keyStore!)
            
            let signature = try? account.sign(data: data)
            
            let r = signature!.subdata(in: 0..<32).toHexString().withHexPrefix
            let s = signature!.subdata(in: 32..<64).toHexString().withHexPrefix
            let v = UInt8(signature![64]) + 27
            
            let vStr = String(format: "0x%02x", v)
            print(vStr)
            
            let signData = (r.noHexPrefix + s.noHexPrefix + vStr.noHexPrefix).data(using: .utf8)
            
            return (signData!, r, s, vStr)
        }
        
        return (nil, nil, nil, nil)
    }
    
    
    /**
     * create_identity delegate sign
     */
    public func getCreateKeySignature() -> (Data?, String, String, String) {
        
        let resolvers = self.delegator.registryAddress.resolvers
        let providers = self.delegator.registryAddress.providers
        let identityRegistry = self.delegator.registryAddress.identityRegistry?.noHexPrefix
        
        let addr = self.delegator.keyStore!.addresses?.first?.address
        
        let temp = Data([0x19, 0x00])
        let identity = Data.fromHex(identityRegistry!)
        let msg = KDefine.KCreateIdentity.data(using: .utf8)
        let ass = Data.fromHex(addr!)
        
        let resolverData = NSMutableData()
        for resolver in resolvers! {
            let res = resolver
            let data = Data.fromHex("0x000000000000000000000000" + res.noHexPrefix)
            
            resolverData.append(data!)
        }
        
        
        let providerData = NSMutableData()
        for provider in providers! {
            let pro = provider
            let data = Data.fromHex("0x000000000000000000000000" + pro.noHexPrefix)
            
            providerData.append(data!)
        }
        
        let resolData = resolverData as Data
        let proviData = providerData as Data
        
        
        var timeStamp: Int!
        
        
        DispatchQueue.global().sync {
            timeStamp = self.delegator.getTimeStamp()
        }
        
        
        let timeData = self.getInt32Byte(int: BigUInt(Int(timeStamp)))
        
        let data = (temp + identity! + msg! + ass! + ass! + proviData + resolData + timeData).keccak256
        
        self.delegator.signData = data
        
        
        let account = try? EthereumAccount.init(keyStore: self.delegator.keyStore)
        
        let prefixData = (KDefine.kPrefix + String(data.count)).data(using: .ascii)
        let signature = try? account?.sign(data: prefixData! + data)
        
        let r = signature!!.subdata(in: 0..<32).toHexString().withHexPrefix
        let s = signature!!.subdata(in: 32..<64).toHexString().withHexPrefix
        let v = UInt8(signature!![64]) + 27
        
        let vStr = String(format: "0x%02x", v)
        print(vStr)
        
        let signData = (r.noHexPrefix + s.noHexPrefix + vStr.noHexPrefix).data(using: .utf8)
        
        return (signData!, r, s, vStr)
    }
    
    
    
    /**
     * add_public_key_delegated sign
     */

    public func getPublicKeySignature() -> (Data?, String, String, String) {
        let publicKeyResolverAddress = self.delegator.registryAddress.publicKey

        let temp = Data([0x19, 0x00])

        let account = try? EthereumAccount.init(keyStore: self.delegator.keyStore)
        let address = account?.address
        let publicKey = account?.publicKey

        let msg = KDefine.KAdd_PublicKey.data(using: .utf8)
        let addrdata = Data.fromHex(address!)
        let publicKeyData = Data.fromHex(publicKey!)

        let pubKeyData = Data.fromHex(publicKeyResolverAddress!)
        
        var timeStamp: Int!
        
        DispatchQueue.global().sync {
            timeStamp = self.delegator.getTimeStamp()
        }

        let timeData = self.getInt32Byte(int: BigUInt(timeStamp))

        let data = (temp + pubKeyData! + msg! + addrdata! + publicKeyData! + timeData).keccak256

        let prefixData = (KDefine.kPrefix + String(data.count)).data(using: .ascii)
        let signature = try? account!.sign(data: prefixData! + data)

        let r = signature!.subdata(in: 0..<32).toHexString().withHexPrefix
        let s = signature!.subdata(in: 32..<64).toHexString().withHexPrefix
        let v = UInt8(signature![64]) + 27

        let vStr = String(format: "0x%02x", v)
        print(vStr)
        
        let signData = (r.noHexPrefix + s.noHexPrefix + vStr.noHexPrefix).data(using: .utf8)
        
        return (signData!, r, s, vStr)
    }
    
    
    
    /**
     * add_key_delegated sign
     */
    
    public func getSignServiceId(serviceID: String, serviceAddress: String) -> (String, Data?, String, String, String, String) {
        
        let resolver = self.delegator.registryAddress.serviceKey
       
        let temp = Data([0x19, 0x00])
        let resolverData = Data.fromHex(resolver!)
        let msg = KDefine.kAddKey.data(using: .utf8)
        let keyData = Data.fromHex(serviceAddress)
        let symbol = serviceID.data(using: .utf8)
        
        var timeStamp: Int!
        
        DispatchQueue.global().sync {
            timeStamp = self.delegator.getTimeStamp()
        }
        
        let timeData = self.getInt32Byte(int: BigUInt(timeStamp))
       
        let data = (temp + resolverData! + msg! + keyData! + symbol! + timeData).keccak256
        print(data.toHexString())
       
       
        let prefixData = (KDefine.kPrefix + String(data.count)).data(using: .ascii)
       
        let account = try? EthereumAccount.init(keyStore: self.keyStore!)
        let signature = try? account!.sign(data: prefixData! + data)
       
        print(account?.address)
       //ecRecover
        let afterAddr = Web3Utils.personalECRecover(data, signature: signature!)
        print(afterAddr?.address as Any)
       
        let r = signature!.subdata(in: 0..<32).toHexString().withHexPrefix
        let s = signature!.subdata(in: 32..<64).toHexString().withHexPrefix
        let v = UInt8(signature![64]) + 27
        let vStr = String(format: "0x%02x", v)
       
        let signData = (r.noHexPrefix + s.noHexPrefix + vStr.noHexPrefix).data(using: .utf8)
        
        return (serviceAddress, signData!, serviceID, r, s, vStr)
    }
    
    
    
    //transactionReceipt
    public func transactionReceipt(type: MetaTransactionType, txId: String, complection: TransactionRecipt?) -> Void {

        self.delegator.ethereumClient.eth_getTransactionReceipt(txHash: txId) { (error, receipt) in
            if error != nil {
                return complection!(error, nil)
            }
            
            if receipt == nil {
                return complection!(error, nil)
            }
            
            if receipt!.status.rawValue == 0 {
                return complection!(nil, receipt)
            }
        
        
            if type == .createDid {
                
                var isEin: Bool?
                DispatchQueue.global().sync {
                    self.metaID = ""
                    self.did = ""
                    
                    isEin = self.getEin(receipt: receipt!)
                }
                
                
                if isEin != nil {
                    return complection!(nil, receipt)
                }
            }
            
            if type == .addWalletPublicKey {
                
                return complection!(nil, receipt)
            }
            
            if type == .addServicePublicKey {
                
                return complection!(nil, receipt)
            }
        }
    }
    
    
    private func getEin(receipt: EthereumTransactionReceipt) -> Bool {
        
        let result = MHelper.getEvent(receipt: receipt, string: "{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"name\":\"initiator\",\"type\":\"address\"},{\"indexed\":true,\"name\":\"ein\",\"type\":\"uint256\"},{\"indexed\":false,\"name\":\"recoveryAddress\",\"type\":\"address\"},{\"indexed\":false,\"name\":\"associatedAddress\",\"type\":\"address\"},{\"indexed\":false,\"name\":\"providers\",\"type\":\"address[]\"},{\"indexed\":false,\"name\":\"resolvers\",\"type\":\"address[]\"},{\"indexed\":false,\"name\":\"delegated\",\"type\":\"bool\"}],\"name\":\"IdentityCreated\",\"type\":\"event\"}")
        
        if (result.object(forKey: "ein") as! String).count > 0 {
            let ein = BigUInt(hex: (result.object(forKey: "ein") as? String)!)
            self.metaID = self.getInt32Byte(int: ein!).toHexString().withHexPrefix
            
            return true
        }
        
        return false
    }
    
    
    public func getKey() -> MetadiumKey? {
        if self.keyStore != nil {
            let account = try? EthereumAccount.init(keyStore: self.keyStore!)
            
            let key = MetadiumKey()
            key.address = account?.address
            key.privateKey = account?.privateKey
            key.publicKey = account?.publicKey
            key.nemonic = self.nemonic
            
            return key
        }
        
        return nil
    }
    
    
    public func getDid() -> String {
        
        if !self.did.isEmpty {
            return self.did
        }
        
        if self.metaID != nil && !self.metaID.isEmpty {
            
            self.did = self.delegator.didPrefix + self.metaID.noHexPrefix
            
            print(self.metaID)
            
            return self.did
        }
        
        return self.did
    }
    
    
    public func getKid() -> String {
        
        var kid = ""
        let did = getDid()
        
        if !did.isEmpty {
            kid = did + "#MetaManagementKey#" + self.getAddress().lowercased().noHexPrefix
        }
        
        return kid
    }
    
    
    public func getAddress() -> String {
        
        var address: String = ""
        
        
        if self.keyStore != nil  {
            address = (self.keyStore?.addresses?.first!.address)!
        }
        
        return address
    }
    
    
    
    private func getInt32Byte(int: BigUInt) -> Data {
        let bytes = int.bytes // should be <= 32 bytes
        let byte = [UInt8](repeating: 0x00, count: 32 - bytes.count) + bytes
        let data = Data(bytes: byte)
        
        return data
    }
    
    
    func getInt16Byte(int: BigUInt) -> Data {
        let bytes = int.bytes // should be <= 20 bytes
        let byte = [UInt8](repeating: 0x00, count: 16 - bytes.count) + bytes
        let data = Data(bytes: byte)
        
        return data
    }
    
}
