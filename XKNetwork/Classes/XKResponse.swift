//
//  XKBaseResponse.swift
//  XKNetworkSwift
//
//  Created by kenneth on 2021/6/11.
//

import Foundation
import HandyJSON
import RxSwift
import Moya

/// 关于code、message、data 字段不一样时 mapping即可
public protocol XKResponseProtocol: HandyJSON {
    
    associatedtype T
    
    var code: Int { get set }
    var message: String? { get set }
    var data: T? { get set }
    
    func isSuccessfulCode() -> Bool
}

public extension Response {
    
    //MARK: json to Model
    func xk_mapObject<T: XKResponseProtocol>(_ type: T.Type) throws -> T {
        
        guard let jsonObject = type.deserialize(from: try mapJSON() as? [String : Any]) else {
            
            throw MoyaError.jsonMapping(self)
        }
        return jsonObject
    }
}

public extension ObservableType where Element == Response {
    
    //MARK: json to Observable<Model>
    func xk_mapObject<T: XKResponseProtocol>(_ type: T.Type) throws -> Observable<T> {
       
        let result = flatMap { (response) -> Observable<T> in
            
            return Observable.just(try response.xk_mapObject(type))
        }
        return result
    }
    
}
