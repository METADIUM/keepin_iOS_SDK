# Metadium DID SDK for iOS

[![CI Status](https://img.shields.io/travis/jinsikhan/KeepinCRUD.svg?style=flat)](https://travis-ci.org/jinsikhan/KeepinCRUD)
[![Version](https://img.shields.io/cocoapods/v/KeepinCRUD.svg?style=flat)](https://cocoapods.org/pods/KeepinCRUD)
[![License](https://img.shields.io/cocoapods/l/KeepinCRUD.svg?style=flat)](https://cocoapods.org/pods/KeepinCRUD)
[![Platform](https://img.shields.io/cocoapods/p/KeepinCRUD.svg?style=flat)](https://cocoapods.org/pods/KeepinCRUD)

#### DID 생성 및 키 관리 기능과 Verifiable Credential의 서명과 검증에 대한 기능을 제공한다.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.



## Requirements

## Installation

KeepinCRUD is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/METADIUM/Web3Swift-iOS'

target 'project' do
    pod 'KeepinCRUD'
end
```



## Use It

### 지갑 키 생성
#### 추가로 Metadium mainnet, testnet 을 사용시에는 apiKey 는 Metadium 운영부서에서 발급을 받아야 합니다.

    //delegate url, node url, resolver url, didPrefix를 직접 설정할 때 초기화 부분에 셋팅합니다.
    /**
     * 개발서버 delegateUrl: https://testdelegator.metadium.com, nodeUrl:  https://api.metadium.com/dev, resolverUrl: https://testnetresolver.metadium.com/1.0/identifiers/,  didPrefix: did:meta:testnet:
     * 운영서버 delegateUrl: https://delegator.metadium.com, nodeUrl:  https://api.metadium.com/prod, resolverUrl: https://resolver.metadium.com/1.0/identifiers/, didPrefix: did:meta:
     */
    
    let delegator = MetaDelegator.init(delegatorUrl: "https://testdelegator.metadium.com",
                                        nodeUrl: "https://api.metadium.com/dev",
                                        resolverUrl: "https://testnetresolver.metadium.com/1.0/identifiers/",
                                        didPrefix: "did:meta:testnet:",
                                        api_key: "testKey")

    let key = wallet.createKey()
    
    //key.privateKey, key.publicKey, key.address


### load KeyStore

    let delegator = MetaDelegator.init(delegatorUrl: "https://testdelegator.metadium.com",
                                        nodeUrl: "https://api.metadium.com/dev",
                                        resolverUrl: "https://testnetresolver.metadium.com/1.0/identifiers/",
                                        didPrefix: "did:meta:testnet:",
                                        api_key: "testKey")
    
    let wallet = MetaWallet.init(delegator: delegator, privateKey: "0xb7fddf3e1645b2f2ef8e1f427ec2ae76cc6989fd33999f065bc48cb39d6c2336", did: "did:meta:testnet:0000000000000000000000000000000000000000000000000000000000002f4c")


### key sign

    let data = "test data".data(using: .utf8)
    let (signature, r, s, v) = wallet.getSignature(data: data!)


### 로컬 privatekey assign 및 sign값 

    let wallet = wallet.assignPrivateKey(privateKey: privateKey)
    let (signatureData, r, s, v)  = wallt.getWalletSignature()


### DID 생성

    let (signData, r, s, v) = wallet.getCreateKeySignature()

    delegator.createIdentityDelegated(signData: signData!, r: r, s: s, v: v) { (type, txId, error) in
        if error != nil {
            return
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            self.wallet.transactionReceipt(type: type!, txId: txId!) { (error, receipt) in
            
                if error != nil {
                    return
                }
            
                if receipt == nil {
                    self.wallet.transactionReceipt(type: type!, txId: txId!, complection: nil)
                
                    return
                }
            
                if receipt!.status == .success {
                    //Todo...
                }
            }
        }
    }
}


### 서비스 키 생성
    let serviceKey = wallet.createServiceKey()
    
    
### Delegate

#### add_public_key_delegated : 지갑 publicKey를 publickey resolver에 delegate를 통해 등록

    let (signData, r, s, v) = self.wallet.getPublicKeySignature()
    
    self.delegator.addPublicKeyDelegated(signData: signData!, r: r, s: s, v: v) { (type, txId, error) in
    
        if error != nil {
            return
            }
    
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
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
                    //Todo...
                }
            }
        }
    }
}


#### add_key_delegated :  서비스키를 service_key resolver에 delegate를 통해 등록

    let (addr, signData, servieId, r, s, v) = self.wallet.getSignServiceId(serviceID: "5933e64b-cb34-11ea-9e0f-020c6496fbdc", serviceAddress: address!)

    self.delegator.addKeyDelegated(address: addr, signData: signData!, serviceId: servieId, r: r, s: s, v: v) { (type, txId, error) in 
        if error != nil {
            return
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
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
                    //Todo...
                }
                else {
                    //Todo...
                }
            }
        }
    }
}


### remove_keys_delegated

    let (_, r, s, v) = self.wallet!.getRemoveKeySign()

    self.delegator?.removeKeyDelegated(r: r, s: s, v: v, complection: { (type, txId, error) in
        if error != nil {
            return
        }
    
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            self.wallet?.transactionReceipt(type: type!, txId: txId!, complection: { (error, receipt) in
            
                if receipt!.status == .success {
                    //Todo..
                }
            })
        }
    })
    
    
### remove_public_key_delegated

    let (_, r, s, v) = self.wallet!.getRemovePublicKeySign()

    self.delegator?.removePublicKeyDelegated(r: r, s: s, v: v, complection: { (type, txId, error) in
        if error != nil {
            return
        }
    
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            self.wallet?.transactionReceipt(type: type!, txId: txId!, complection: { (error, receipt) in
            
                if receipt!.status == .success {
                    //Todo...
                }
            })
        }
    })
    
### remove_associated_address_delegated

    let (_, r, s, v) = self.wallet!.getRemoveAssociatedAddressSign()

    self.delegator?.removeAssociatedAddressDelegated(r: r, s: s, v: v, complection: { (type, txId, error) in
        if error != nil {
            return
        }
    
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            self.wallet?.transactionReceipt(type: type!, txId: txId!, complection: { (error, receipt) in
            
                if receipt!.status == .success {
                    //Todo...
                }
            })
        }
    })

    
    
    
### Get DID Document
#### DID Document 정보를 얻는다.

    let did = self.wallet?.getDid()

    self.wallet?.reqDiDDocument(did: did!, complection: { (document, error) in
        if error != nil {
            return
        }
        
        let didDocument = document
    })
    
    
    
### Verifiable Credential
#### Verifiable credential, Verifiable presentation 발급 및 검증
#### Issue Credential

#### verifiable credential을 발급한다.
#### 발급자(Issuer)는 DID가 생성되어 있어야 하며 credential의 이름(types), 사용자(holder)의 DID, 발급할 내용(claims)가 필수로 필요하다.

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
    
    
    
    
#### Issue Presentation
#### verifiable presentation을 발급한다.
#### 사용자(holder)는 DID가 생성되어 있어야 하며 검증자(verifier)에게 전달할 발급받은 credential을 포함해야 한다.

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
    
    
    
    
### Verify Credential or Presentation
#### 네트워크가 메인넷이 안닌 경우 검증 전에 resolver URL 이 설정되어 있어야 정상적이 검증이 가능하다.  
#### 사용자 또는 검증자가 credential 또는 presentation 을 검증을 한다.


    let jws = try? JWSObject.init(string: serializedVC)
    let jwt = try? JWT.init(jsonData: jws!.payload)

    let expireDate = jwt!.expirationTime

    let isVerify =  try? self.wallet?.verify(jwt: jws!)

    if isVerify == false {
        //검증실패
    }
    else if (expireDate != nil && expireDate! > Date()) {
        // 유효기간 초과
    }
        
    
    
## Author

jinsikhan, jshan@coinplug.com

## License

KeepinCRUD is available under the MIT license. See the LICENSE file for more info.
