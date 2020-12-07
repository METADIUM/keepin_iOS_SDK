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
    
    var registryAddress: RegistryAddress!
    
    var ethereumClient: EthereumClient!
    var delegatorUrl: URL!
    var nodeUrl: URL!
    var didPrefix: String!

    public var keyStore: EthereumKeystoreV3!
    
    var signData: Data!
    
    var timeStamp: Int!
    
    var metaID: String!
    
    var metaWallet: MetaWallet!
    var transactionGroup = DispatchGroup()
    var transactionQueue = DispatchQueue(label: "transactionGroupQueue")
    
    var messenger: MetaDelegatorMessenger!
    
    
    /**
     * @param  delegate Url
     * @param node Url
     * @param didPrefix
     */
    public init(delegatorUrl: String? = "https://testdelegator.metadium.com", nodeUrl: String? = "https://api.metadium.com/dev", didPrefix: String? = "did:meta:testnet:") {
        super.init()
        
        self.delegatorUrl = URL(string: delegatorUrl!)
        self.nodeUrl = URL(string: nodeUrl!)
        self.didPrefix = didPrefix!
        
        self.ethereumClient = EthereumClient.init(url: self.nodeUrl)
        
        self.registryAddress = self.getAllServiceAddress()
    }
    
    
    
    
    /**
     * get registry address
     * @return registryAddress
     */
    private func getAllServiceAddress() -> RegistryAddress {
        
        let group = DispatchGroup()
        group.enter()
        
        
        var registryAddress: RegistryAddress?
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, method: "get_all_service_addresses") { (response, data, error) in
            
            if error != nil {
                return
            }
            
            registryAddress = RegistryAddress.init(dic: data as! Dictionary<String, Any>)
            
            group.leave()
        }
        
        group.wait()
        
        return registryAddress!
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
     */
    public func createIdentityDelegated(signData: Data, r: String, s: String, v: String) -> (MetaTransactionType?, String?) {
        
        var txID: String = ""
        
        if self.registryAddress == nil {
            
            DispatchQueue.global().sync {
                self.registryAddress = self.getAllServiceAddress()
            }
        }
        
        let group = DispatchGroup()
        group.enter()
        
        let resolvers = self.registryAddress.resolvers
        let providers = self.registryAddress.providers
        let addr = self.keyStore?.addresses?.first?.address

        let params = [["recovery_address" : addr!, "associated_address": addr!, "providers":providers!, "resolvers": resolvers!, "v": v, "r": r, "s": s, "timestamp": self.timeStamp!]]
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, method: "create_identity", parmas: params) {(response, result, error) in
            if error != nil {
                return
            }
            
            if let txId = result as? String {
                txID = txId
                
                group.leave()
            }
        }
        
        group.wait()
        
        return (.createDid, txID)
    }
    
    
    
    
    
    /**
     * 퍼블릭키 추가
     * @param signData
     * @r
     * @s
     * @v
     * @return transactionType, txID
     */
    
    public func addPublicKeyDelegated(signData: Data, r: String, s: String, v: String) -> (MetaTransactionType?, String) {
        
        var txID: String = ""
        
        let resolver_publicKey = self.registryAddress.publicKey
        let addr = self.keyStore?.addresses?.first?.address
        let account = try? EthereumAccount.init(keyStore: self.keyStore)
        let publicKey = account!.publicKey

        let params = [["resolver_address" : resolver_publicKey!, "associated_address": addr!, "public_key": publicKey, "v": v, "r": r, "s": s, "timestamp": self.timeStamp!]]
        
        let group = DispatchGroup()
        group.enter()
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, method: "add_public_key_delegated", parmas: params) {(response, result, error) in
            if error != nil {
                group.leave()
                
                return
            }
            
            if let txId = result as? String {
                txID = txId
                
                group.leave()
                
                return
            }
            
            group.leave()
        }
        
        group.wait()
        
        return (.addWalletPublicKey, txID)
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
    
    public func addKeyDelegated(address: String, signData: Data, serviceId: String, r: String, s: String, v: String) -> (MetaTransactionType?, String) {
        
        var txID: String = ""
        
        let resolver = self.registryAddress.serviceKey
        let addr = self.keyStore.addresses?.first?.address
        
        let params = [["resolver_address" : resolver!, "associated_address": addr!, "key": address, "symbol": serviceId, "v": v, "r": r, "s": s, "timestamp": self.timeStamp!]]
        print(params)
        
        let group = DispatchGroup()
        group.enter()
        
        DataProvider.jsonRpcMethod(url: self.delegatorUrl, method: "add_key_delegated", parmas: params) {(response, result, error) in
            if error != nil {
                group.leave()
                
                return
            }
            
            if let txId = result as? String {
                txID = txId
                
                group.leave()
                
                return
            }
            
            group.leave()
        }
        
        group.wait()
        
        return (.addServicePublicKey, txID)
    }
    
    public func removeKeyDelegated() {
        
    }

    
    
}
