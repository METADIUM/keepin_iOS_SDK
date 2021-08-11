//
//  MetaDelegator.swift
//  KeepinCRUD
//
//  Created by hanjinsik on 2020/12/01.
//

import UIKit
import web3Swift
import BigInt

public enum MetaError: Error {
    case blockNumberError
    case blockTimeStampError
}


protocol MetaDelegatorMessenger {
    func sendTxID(txID: String, type: MetaTransactionType)
}


public class MetaDelegator: NSObject {
    
    public var registryAddress: RegistryAddress?
    public var keyStore: EthereumKeystoreV3!
    public var delegatorUrl: URL!
    
    var ethereumClient: EthereumClient!
    
    var nodeUrl: URL!
    var resolverUrl: String!
    
    var didPrefix: String!
    var api_key: String!

    var signData: Data!
    
    var timeStamp: Int!
    
    var messenger: MetaDelegatorMessenger!
    
    
    /**
     * @param  delegate Url
     * @param node Url
     * @param didPrefix
     * @param api_key
     */
    public init(delegatorUrl: String? = "https://testdelegator.metadium.com", nodeUrl: String? = "https://api.metadium.com/dev", resolverUrl: String? = "https://testnetresolver.metadium.com/1.0/identifiers/", didPrefix: String? = "did:meta:testnet:", api_key: String? = "") {
        
        super.init()
        
        self.delegatorUrl = URL(string: delegatorUrl!)
        self.nodeUrl = URL(string: nodeUrl!)
        self.resolverUrl = resolverUrl
        
        self.didPrefix = didPrefix!
        self.api_key = api_key
        
        self.ethereumClient = EthereumClient.init(url: self.nodeUrl)
        
        self.getAllServiceAddress()
    }
    
    
    
    
    public func getAllServiceAddress() {
        if self.registryAddress == nil {
            
            let semaPhore = DispatchSemaphore(value: 0)
            
            self.getAllServiceAddress { (registryAddress, error) in
                if error != nil {
                    semaPhore.signal()
                    
                    return
                }
                
                self.registryAddress = registryAddress
                
                semaPhore.signal()
            }
            
            semaPhore.wait()
        }
    }
    
    
    
    
    
    
    /**
     * get registry address
     * @return registryAddress
     */
    public func getAllServiceAddress(complection: @escaping(RegistryAddress?, Error?) -> Void) {
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, api_key: self.api_key, method: "get_all_service_addresses") { (response, data, error) in
            if error != nil {
                return complection(nil, error)
            }
            
            
            if data != nil {
                let registryAddress = RegistryAddress.init(dic: data as! Dictionary<String, Any>)
                
                return complection(registryAddress, nil)
            }
        }
    }
    
    
    
    
    
    /**
     * get time stamp
     */
    
    public func getTimeStamp() -> Int {
        
        var timeStamp: Int = 0
        
        let group = DispatchGroup()
        group.enter()
        
        self.ethereumClient.eth_blockNumber { (error, index) in
            
            if error != nil {
                return
            }
            
            self.ethereumClient.eth_getBlockByNumber(EthereumBlock(rawValue: index!)) { (error, blockInfo) in
                
                if error != nil {
                    return
                }
            
                guard let block = blockInfo else {
                    return
                }
                
                timeStamp = Int(block.timestamp.timeIntervalSince1970)
                
                self.timeStamp = timeStamp
                
                group.leave()
            }
        }
        
        group.wait()
        
        return timeStamp
    }
    
    
    
    
    /**
     * DID 생성
     * @param signData
     * @r
     * @s
     * @v
     * @return transactionType, txID
     */
    
    public func createIdentityDelegated(signData: Data, r: String, s: String, v: String, complection: @escaping(MetaTransactionType?, String?, Error?) -> Void) {
        
        self.getAllServiceAddress()
        
        let resolvers = self.registryAddress!.resolvers
        let providers = self.registryAddress!.providers
        let addr = self.keyStore?.addresses?.first?.address

        let params = [["recovery_address" : addr!, "associated_address": addr!, "providers":providers!, "resolvers": resolvers!, "v": v, "r": r, "s": s, "timestamp": self.timeStamp!]]
        
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, api_key: self.api_key, method: "create_identity", parmas: params) {(response, result, error) in
            if error != nil {
                return complection(.createDid, nil, error)
            }
            
            if let txId = result as? String {
                return complection(.createDid, txId, nil)
            }
        }
    }
    
    
    
    
    
    /**
     * 퍼블릭키 추가
     * @param signData
     * @r
     * @s
     * @v
     * @return transactionType, txID
     */
    
    public func addPublicKeyDelegated(signData: Data, r: String, s: String, v: String, complection: @escaping(MetaTransactionType?, String?, Error?) -> ()) {
        
        self.getAllServiceAddress()
        
        let resolver_publicKey = self.registryAddress!.publicKey
        let addr = self.keyStore?.addresses?.first?.address
        let account = try? EthereumAccount.init(keyStore: self.keyStore)
        let publicKey = account!.publicKey

        let params = [["resolver_address" : resolver_publicKey!, "associated_address": addr!, "public_key": publicKey, "v": v, "r": r, "s": s, "timestamp": self.timeStamp!]]
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, api_key: self.api_key, method: "add_public_key_delegated", parmas: params) {(response, result, error) in
            if error != nil {
                return complection(.addWalletPublicKey, nil, error)
            }
            
            if let txId = result as? String {
                return complection(.addWalletPublicKey, txId, nil)
            }
        }
    }
    
    

    
    /**
     * 서비스 키 추가
     * @param address
     * @param signData
     * @r
     * @s
     * @v
     * @return transactionType, txID
     */
    
    public func addKeyDelegated(address: String, signData: Data, serviceId: String, r: String, s: String, v: String, complection: @escaping(MetaTransactionType?, String?, Error?) -> Void) {
        
        self.getAllServiceAddress()
        
        let resolver = self.registryAddress!.serviceKey
        let addr = self.keyStore.addresses?.first?.address
        
        let params = [["resolver_address" : resolver!, "associated_address": addr!, "key": address, "symbol": serviceId, "v": v, "r": r, "s": s, "timestamp": self.timeStamp!]]
        print(params)
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, api_key: self.api_key, method: "add_key_delegated", parmas: params) {(response, result, error) in
            if error != nil {
                return complection(.addServicePublicKey, nil, error)
            }
            
            if let txId = result as? String {
                
                return complection(.addServicePublicKey, txId, error)
            }
        }
    }
    
    
    
    /**
     * 모든 서비스 키 삭제
     * @param address
     * @param signData
     * @r
     * @s
     * @v
     * @return transactionType, txID
     */
    
    public func removeKeyDelegated(r: String, s: String, v: String, complection: @escaping(MetaTransactionType?, String?, Error?) -> Void) {
        self.getAllServiceAddress()
        
        let resolver = self.registryAddress!.serviceKey
        let addr = self.keyStore.addresses?.first?.address
        
        let params = [["resolver_address" : resolver!, "associated_address": addr!, "v": v, "r": r, "s": s, "timestamp": self.timeStamp!]]
        print(params)
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, api_key: self.api_key, method: "remove_keys_delegated", parmas: params) {(response, result, error) in
            if error != nil {
                return complection(.removeKeys, nil, error)
            }
            
            if let txId = result as? String {
                
                return complection(.removeKeys, txId, error)
            }
        }
    }
    
    
    
    /**
     * 퍼블릭 키 삭제
     * @param address
     * @param signData
     * @r
     * @s
     * @v
     * @return transactionType, txID
     */
    
    public func removePublicKeyDelegated(r: String, s: String, v: String, complection: @escaping(MetaTransactionType?, String?, Error?) -> Void) {
        self.getAllServiceAddress()
        
        let resolver = self.registryAddress!.publicKey
        let addr = self.keyStore.addresses?.first?.address
        
        let params = [["resolver_address" : resolver!, "associated_address": addr!, "v": v, "r": r, "s": s, "timestamp": self.timeStamp!]]
        print(params)
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, api_key: self.api_key, method: "remove_public_key_delegated", parmas: params) {(response, result, error) in
            if error != nil {
                return complection(.removePublicKey, nil, error)
            }
            
            if let txId = result as? String {
                
                return complection(.removePublicKey, txId, error)
            }
        }
    }
    
    
    
    /**
     * associated_address  삭제
     * @param address
     * @param signData
     * @r
     * @s
     * @v
     * @return transactionType, txID
     */
    
    public func removeAssociatedAddressDelegated(r: String, s: String, v: String, complection: @escaping(MetaTransactionType?, String?, Error?) -> Void) {
        self.getAllServiceAddress()
        
        let addr = self.keyStore.addresses?.first?.address
        
        let params = [["address_to_remove": addr!, "v": v, "r": r, "s": s, "timestamp": self.timeStamp!]]
        print(params)
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, api_key: self.api_key, method: "remove_associated_address_delegated", parmas: params) {(response, result, error) in
            if error != nil {
                return complection(.removeAssociatedAddress, nil, error)
            }
            
            if let txId = result as? String {
                
                return complection(.removeAssociatedAddress, txId, error)
            }
        }
    }

}
