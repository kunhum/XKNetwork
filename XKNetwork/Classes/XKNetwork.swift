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

let XKNetworkProvider = MoyaProvider<MultiTarget>(requestClosure: XKNetworker.requestClosure)

public let XKNetworker = XKNetwork.share

public class XKNetwork: NSObject {
    
    public static let share = XKNetwork()
    ///超时时长
    public var timeoutInterval = 10.0
    ///HttpBody处理，适用于要求在参数中放一些通用参数的场景
    public var httpBodyHandler: ((_ httpBody: String) -> String)?
    
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
    
    func request<T: XKResponseProtocol>(api: TargetType, responseType: T.Type) -> Observable<T?> {
        
        return Observable.create {
            [weak self]
            observer in
            
            guard let weakSelf = self else {
                observer.onError(XKError.nilObject)
                observer.onCompleted()
                return Disposables.create()
            }
            
            XKNetworkProvider.rx.request(MultiTarget(api)).asObservable().subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background)).subscribe { response in
                
                guard let responseModel = try? response.xk_mapObject(responseType) else {
                    
                    observer.onError(MoyaError.jsonMapping(response))
                    observer.onCompleted()
                    return
                }
                
                guard responseModel.isSuccessfulCode() else {
                    
                    observer.onError(XKError.code(responseModel.message ?? "校验码不正确"))
                    observer.onCompleted()
                    return
                }
                
                observer.onNext(responseModel)
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
