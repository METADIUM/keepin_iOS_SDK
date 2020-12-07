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
    
    
    func sendTxID(txID: String, type: MetaTransactionType) {
        
        do {
            let _ = try self.transactionReceipt(type: type, txId: txID)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    
    /**
     * 지갑 키 생성
     */
    
    
    public init(delegator: MetaDelegator) {
        super.init()
        
        self.delegator = delegator
        self.delegator.messenger = self
    }
    
    
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
                
                self.delegator.keyStore = keyStore!
                
                let account = try? EthereumAccount.init(keyStore: self.keyStore!)
                
                let key = MetadiumKey()
                key.address = address?.address
                key.privateKey = account?.privateKey
                key.publicKey = account?.publicKey
                
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
     * 로컬에 저장되어 있는 privateKey로 keystore 생성
     */
    public func assignPrivateKey(privateKey: String) {
        self.keyStore = try! EthereumKeystoreV3.init(privateKey: Data.init(hex: privateKey))
        self.delegator.keyStore = self.keyStore
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
            
            return key
            
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    
    
    
    public func getWalletSignature() -> (Data?, String, String, String) {
        
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
    public func transactionReceipt(type: MetaTransactionType, txId: String) throws -> EthereumTransactionReceipt {
        
        let group = DispatchGroup()
        group.enter()
        
        
        var transactionReceipt: EthereumTransactionReceipt!
        var clientError: EthereumClientError?
        
        self.delegator.ethereumClient.eth_getTransactionReceipt(txHash: txId) { (error, receipt) in
            if error != nil {
                clientError = error
                
                return
            }
            
            if receipt == nil {
                let _ = try? self.transactionReceipt(type: type, txId: txId)
                
                return
            }
            
            if receipt!.status.rawValue == 0 {
                return
            }
        
            
            transactionReceipt = receipt!
        
            if type == .createDid {
                
                DispatchQueue.global().sync {
                    let isEin = self.getEin(receipt: receipt!)
                    
                    if isEin {
                        group.leave()
                    }
                }
                
                return
            }
            
            if type == .addWalletPublicKey {
                
                group.leave()
                
                return
            }
            
            if type == .addServicePublicKey {
                
                group.leave()
                
                return
            }
            
            group.leave()
        }
        
        group.wait()
        
        if clientError != nil {
            throw clientError!
        }
        
        return transactionReceipt
        
    }
    
    
    private func getEin(receipt: EthereumTransactionReceipt) -> Bool {
        
        let result = MHelper.getEvent(receipt: receipt, string: "{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"name\":\"initiator\",\"type\":\"address\"},{\"indexed\":true,\"name\":\"ein\",\"type\":\"uint256\"},{\"indexed\":false,\"name\":\"recoveryAddress\",\"type\":\"address\"},{\"indexed\":false,\"name\":\"associatedAddress\",\"type\":\"address\"},{\"indexed\":false,\"name\":\"providers\",\"type\":\"address[]\"},{\"indexed\":false,\"name\":\"resolvers\",\"type\":\"address[]\"},{\"indexed\":false,\"name\":\"delegated\",\"type\":\"bool\"}],\"name\":\"IdentityCreated\",\"type\":\"event\"}")
        
        if (result.object(forKey: "ein") as! String).count > 0 {
            let ein = BigUInt(hex: (result.object(forKey: "ein") as? String)!)
            self.metaID = self.getInt16Byte(int: ein!).toHexString().withHexPrefix
            
            return true
        }
        
        return false
    }
    
    
    public func getDid() -> String {
        
        var did: String = ""
        
        if self.metaID != nil && !self.metaID.isEmpty {
            
            did = self.delegator.didPrefix + self.metaID
            
            return did
        }
        
        return did
    }
    
    
    public func getKid() -> String {
        
        var kid = ""
        let did = getDid()
        
        if !did.isEmpty {
            kid = did + "#MetaManagementKey#" + self.getAddress()
        }
        
        return kid
    }
    
    
    public func getAddress() -> String {
        
        var address: String = ""
        
        if self.delegator.keyStore != nil {
            address = (self.delegator.keyStore.addresses?.first!.address)!
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
