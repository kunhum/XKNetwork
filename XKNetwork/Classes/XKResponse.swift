//
//  XKBaseResponse.swift
//  XKNetworkSwift
//
//  Created by kenneth on 2021/6/11.
//

import Foundation
import XKJsonResolver
import RxSwift
import Moya

public protocol XKResponsePlainlyProtocol: XKSmartCodable {
    /// 是否通过
    func isPass() -> Bool
}
/// 关于code、message、data 字段不一样时 mapping即可
public protocol XKResponseProtocol: XKResponsePlainlyProtocol {
    
    associatedtype T
    
    var code: Int? { get set }
    var message: String? { get set }
    var data: T? { get set }
}


public extension Response {
    
    //MARK: json to Model
    func xk_mapObject<T: XKSmartCodable>(_ type: T.Type) -> T? {
        
//        guard let jsonObject = type.deserialize(from: try mapJSON() as? [String : Any]) else {
//            
//            throw MoyaError.jsonMapping(self)
//        }
//        return jsonObject
        return type.deserialize(from: try? mapJSON() as? [String : Any])
    }
    
    func xk_mapArray<T: XKSmartCodable>(_ type: T.Type) -> [T]? {
        let data = (try? mapJSON()) as? [[String: Any]]
        return [T].deserialize(from: data)
    }
}

public extension ObservableType where Element == Response {
    
    //MARK: json to Observable<Model>
    func xk_mapObject<T: XKSmartCodable>(_ type: T.Type) -> Observable<T?> {
       
        let result = flatMap { (response) -> Observable<T?> in
            
            return Observable.just(response.xk_mapObject(type))
        }
        return result
    }
    
}
