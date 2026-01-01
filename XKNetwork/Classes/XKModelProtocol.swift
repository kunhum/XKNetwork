//
//  XKModelProtocol.swift
//  TcbNetworkManager
//
//  Created by Kenneth Tse on 2025/8/29.
//

import Foundation
import RxSwift
import Moya
import Combine

public enum XKRefreshState: Equatable {
    case idle
    case loading
    case fetchData
    case headerRefresh
    case footerRefresh
    case footerNoMoreData
    case completed
    case noData
    case error(MoyaError)
    
    private var name: String {
        switch self {
        case .idle:
            "idle"
        case .loading:
            "loading"
        case .completed:
            "completed"
        case .fetchData:
            "fetchData"
        case .headerRefresh:
            "headerRefreshing"
        case .footerRefresh:
            "footerRefreshing"
        case .footerNoMoreData:
            "footerNoMoreData"
        case .noData:
            "noData"
        case .error(let error):
            "error" + error.localizedDescription
        }
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }
}

public protocol XKModelProtocol {
    var refreshState: CurrentValueSubject<XKRefreshState, Never> { set get }
    func refresh() -> AnyPublisher<XKRefreshState, Never>
}

public protocol XKRxModelProtocol {
    var refreshSubject: BehaviorSubject<XKRefreshState> { set get }
}

public extension XKModelProtocol {
    func refresh() -> AnyPublisher<XKRefreshState, Never> {
        refreshState
            .filter { $0 == .completed }
            .eraseToAnyPublisher()
    }
}
 
public extension XKRxModelProtocol {
    func refresh() -> Observable<XKRefreshState> {
        refreshSubject
            .filter { $0 == .completed || $0 == .footerNoMoreData || $0 == .noData }
    }
    func fetchData() -> Observable<XKRefreshState> {
        refreshSubject
            .filter { $0 == .fetchData }
    }
    func headerRefresh() -> Observable<XKRefreshState> {
        refreshSubject
            .filter { $0 == .headerRefresh }
    }
    func footerRefresh() -> Observable<XKRefreshState> {
        refreshSubject
            .filter { $0 == .footerRefresh }
    }
    func requestData() -> Observable<XKRefreshState> {
        refreshSubject
            .filter { $0 == .fetchData || $0 == .headerRefresh }
    }
    func requestStateData() -> Observable<XKRefreshState> {
        refreshSubject
            .filter { $0 == .fetchData || $0 == .headerRefresh || $0 == .footerRefresh }
    }
    
    func sendState(pageSize: Int = 10, totalCount: Int, pageCount: Int = 10) {
        if totalCount == 0 {
            refreshSubject.onNext(.noData)
        } else if pageCount < pageSize {
            refreshSubject.onNext(.footerNoMoreData)
        } else {
            refreshSubject.onNext(.completed)
        }
    }
    
    func sendNoMoreOrCompletedState(_ isNilOrEmpty: Bool) {
        isNilOrEmpty ? refreshSubject.onNext(.noData) : refreshSubject.onNext(.completed)
    }
}
