//
//  XKRequest.swift
//  XKNetwork
//
//  Created by Kenneth Tse on 2025/8/11.
//

import Foundation

public protocol XKRequest {
    func toJson() -> [String: Any]
}

public extension XKRequest {
    func toJson() -> [String: Any] {
        let mirror = Mirror(reflecting: self)
        var dict: [String: Any] = [:]
        
        for child in mirror.children {
            guard let key = child.label else { continue }
            let value = unwrap(child.value)
            guard !(value is NSNull) else { continue }
            dict[key] = value
        }
        
        return dict
    }
    
    // 递归解包 Optional / 嵌套结构体
    private func unwrap(_ any: Any) -> Any {
        let mirror = Mirror(reflecting: any)
        
        // 处理 Optional
        if mirror.displayStyle == .optional {
            if let first = mirror.children.first {
                return unwrap(first.value)
            }
            return NSNull() // nil 转成 NSNull，方便 JSON 化
        }
        
        // 如果是数组
        if let arr = any as? [Any] {
            return arr.map { unwrap($0) }
        }
        
        // 如果是字典
        if let dict = any as? [String: Any] {
            return dict.mapValues { unwrap($0) }
        }
        
        // 如果是 RawRepresentable (比如枚举)，取 rawValue
        if let rawRepresentable = any as? any RawRepresentable {
            return unwrap(rawRepresentable.rawValue)
        }
        
        // 如果是 XKRequest 协议类型，递归调用 toJson
        if let model = any as? XKRequest {
            return model.toJson()
        }
        
        return any
    }
}

