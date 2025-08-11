//
//  XKNetwork.swift
//  XKNetworkSwift
//
//  Created by kenneth on 2021/6/11.
//

import Foundation
import Moya
import Alamofire
import RxSwift
import RxCocoa
import XKJsonResolver

let XKNetworkProvider = MoyaProvider<MultiTarget>(requestClosure: XKNetworker.requestClosure)

public let XKNetworker = XKNetwork.share

public class XKNetwork: NSObject {
    
    public static let share = XKNetwork()
    /// 超时时长
    public var timeoutInterval = 10.0
    /// HttpBody处理，适用于要求在参数中放一些通用参数的场景
    public var httpBodyHandler: ((_ httpBody: String) -> String)?
    /// 是否需要再debug模式下输出
    public var debugPrintInfo: Bool = false
    
    let disposeBag = DisposeBag()
    
    var requestClosure = {
        (endpoint: Endpoint, done: MoyaProvider.RequestResultClosure) in
        
        do {
            
            var request = try endpoint.urlRequest()
            
            request.timeoutInterval = XKNetworker.timeoutInterval
            
            guard let tmpBody = request.httpBody, let httpBody = String(data: tmpBody, encoding: .utf8), let bodyHandler = XKNetworker.httpBodyHandler else {
                done(.success(request))
                return
            }
            
            let bodyAfterHandle = bodyHandler(httpBody)
            
            guard let bodyData = bodyAfterHandle.data(using: .utf8) else {
                done(.success(request))
                return
            }
            
            request.httpBody = bodyData
            
            done(.success(request))
        }
        catch {
            done(.failure(MoyaError.underlying(error, nil)))
        }
    }
    
}

public extension XKNetwork {
    
    /// 适合通用请求
    func request<T: XKResponseProtocol>(api: TargetType, responseType: T.Type) -> Observable<(Bool, T?)?> {
        return requestPlainly(api: api, responseType: responseType)
    }
    
    func requestPlainly<T: XKResponsePlainlyProtocol>(api: TargetType, responseType: T.Type) -> Observable<(Bool, T?)?> {
        return createObserver(api: api, type: responseType) { response in
            let responseModel = response.xk_mapObject(responseType)
            return (responseModel?.isPass() == true, responseModel)
        }
        .map { tuple in
            return tuple as? (Bool, T?)
        }
    }
    
    /// 适合请求数据直接是数组的
    func requestArray<T: XKSmartCodable>(api: TargetType, responseType: T.Type) -> Observable<[T]?> {
        return createObserver(api: api, type: responseType) {
            response in
            return response.xk_mapArray(responseType)
        }
        .map { data in
            return data as? [T]
        }
    }
    
    /// 适合请求数据直接是字典的，其实就是少了正常的isPass判断
    func requestDictionary<T: XKSmartCodable>(api: TargetType, responseType: T.Type) -> Observable<T?> {
        return createObserver(api: api, type: responseType) {
            response in
            return response.xk_mapObject(responseType)
        }
        .map { data in
            return data as? T
        }
    }
    
}

fileprivate extension XKNetwork {
    
    func createObserver<T: XKSmartCodable>(api: TargetType, type: T.Type, mapBlock: @escaping ((_ response: Response) -> Any?)) -> Observable<Any?> {
        return Observable.create {
            [weak self]
            observer in
            
            guard let weakSelf = self else {
                observer.onError(MoyaError.requestMapping("网络请求不存在"))
                observer.onCompleted()
                return Disposables.create()
            }
            
            XKNetworkProvider.rx.request(MultiTarget(api)).asObservable().subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background)).subscribe { response in
                
                if XKNetwork.share.debugPrintInfo {
                    debugPrint((try? response.mapString()) ?? "")
                }
                let data = mapBlock(response)
                observer.onNext(data)
                observer.onCompleted()
                
            } onError: { error in
                
                observer.onError(error)
                observer.onCompleted()
                
            }.disposed(by: weakSelf.disposeBag)

            return Disposables.create()
        }
    }
    
}

public extension Reactive where Base: XKNetwork {
    
    ///网络状态
    var reachabilityStatus: ControlEvent<NetworkReachabilityManager.NetworkReachabilityStatus> {
        
        let source: Observable<NetworkReachabilityManager.NetworkReachabilityStatus> = Observable.create { observer in
            
            NetworkReachabilityManager.default?.startListening(onQueue: DispatchQueue.global(qos: .background), onUpdatePerforming: { status in
                observer.onNext(status)
            })
            return Disposables.create()
        }.take(until: deallocated)
        
        return ControlEvent(events: source)
    }
}
