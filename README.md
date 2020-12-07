# KeepinCRUD

[![CI Status](https://img.shields.io/travis/jinsikhan/KeepinCRUD.svg?style=flat)](https://travis-ci.org/jinsikhan/KeepinCRUD)
[![Version](https://img.shields.io/cocoapods/v/KeepinCRUD.svg?style=flat)](https://cocoapods.org/pods/KeepinCRUD)
[![License](https://img.shields.io/cocoapods/l/KeepinCRUD.svg?style=flat)](https://cocoapods.org/pods/KeepinCRUD)
[![Platform](https://img.shields.io/cocoapods/p/KeepinCRUD.svg?style=flat)](https://cocoapods.org/pods/KeepinCRUD)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.



## Requirements

## Installation

KeepinCRUD is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'KeepinCRUD'
```



## Use It

### 지갑 키 생성

    self.delegator = MetaDelegator.init() 

    //delegate url, node url, didPrefix를 직접 설정할 때 초기화 부분에 셋팅
    //self.delegator = MetaDelegator.init(delegatorUrl: "https://delegator.metadium.com", nodeUrl: "https://api.metadium.com/prod", didPrefix: "did:meta:testnet:")

    let wallet = MetaWallet.init(delegator: self.delegator)

    //key.privateKey, key.publicKey, key.address
    let key = wallet.createKey()



### 로컬 privatekey assign 및 sign값 

    let wallet = wallet.assignPrivateKey(privateKey: privateKey)
    let (signatureData, r, s, v)  = wallt.getWalletSignature()


### DID 생성

    let (type, txID) = self.delegator.createIdentityDelegated(signData: signData!, r: r, s: s, v: v)
    let receipt = try? wallet.transactionReceipt(type: type!, txId: txID!)


### 서비스 키 생성
    let serviceKey = wallet.createServiceKey()
    
    
### Delegate

#### add_public_key_delegated : 지갑 publicKey를 publickey resolver에 delegate를 통해 등록

    let (type, txID) = self.delegator.addPublicKeyDelegated(signData: signData!, r: r, s: s, v: v)
    let receipt = try? self.wallet.transactionReceipt(type: type!, txId: txID)
    print("status: \(receipt!.status), hash : \(receipt!.transactionHash)")


#### add_key_delegated :  서비스키를 service_key resolver에 delegate를 통해 등록

    let (addr, signData, serviceId, r, s, v)  = wallet.getSignServiceId(serviceID: "5933e64b-cb34-11ea-9e0f-020c6496fbdc", serviceAddress: address!)
    let (type, txID) = self.delegator.addKeyDelegated(address: addr, signData: signData!, serviceId: servieId, r: r, s: s, v: v)
    let receipt = try? self.wallet.transactionReceipt(type: type!, txId: txID)

    //성공시
    if receipt!.status == .success {
        
    }
    
    
## Author

jinsikhan, jshan@coinplug.com

## License

KeepinCRUD is available under the MIT license. See the LICENSE file for more info.
