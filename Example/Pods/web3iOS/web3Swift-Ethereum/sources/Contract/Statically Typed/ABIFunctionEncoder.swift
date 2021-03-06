//
//  ABIFunctionEncoder.swift
//  web3swift
//
//  Created by Matt Marshall on 09/04/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

public class ABIFunctionEncoder {
    private let name: String
    private var head = [UInt8]()
    private var tail = [UInt8]()
    private var types: [ABIRawType] = []
    
    public func encode(_ value: String) throws {
        let strValue = value
        guard let type = ABIRawType(type: String.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: Bool) throws {
        let strValue = value ? "true" : "false"
        guard let type = ABIRawType(type: Bool.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: BigInt) throws {
        let strValue = String(value)
        guard let type = ABIRawType(type: BigInt.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: BigUInt) throws {
        let strValue = String(value)
        guard let type = ABIRawType(type: BigUInt.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    public func encode(_ value: Data) throws {
        let strValue = String(bytes: value.bytes)
        guard let type = ABIRawType(type: Data.self) else { throw ABIError.invalidType }
        return try self.encode(type: type, value: strValue)
    }
    
    //20210111 modify - ThePol add
    public func encode(_ value: Data, size: ABIFixedSizeDataType.Type) throws {
        return try self.encode(value, abiType: size)
    }
    
    public func encode(_ value: Data, abiType: ABIType.Type) throws {
        let strValue = String(bytes: value.bytes)
        guard let type = ABIRawType(type: abiType) else {
            throw ABIError.invalidType
        }
        
        return try self.encode(type: type, value: strValue)
    }
    
    private func encode(type: ABIRawType, value: String) throws {
        let result = try ABIEncoder.encode(value, forType: type)
        
        if type.isDynamic {
            let pos = self.types.count*32 + tail.count
            head += try ABIEncoder.encode(String(pos), forType: ABIRawType.FixedInt(256))
            tail += result
        } else {
            head += result
        }
        
        self.types.append(type)
    }
    
    init(_ name: String) {
        self.name = name
    }
    
    func encoded() throws -> Data {
        let sig = try ABIEncoder.signature(name: name, types: types)
        let methodId = Array(sig.prefix(4))
        let allBytes = methodId + head + tail
        return Data(bytes: allBytes)
    }
    
}
