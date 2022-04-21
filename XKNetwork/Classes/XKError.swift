//
//  XKError.swift
//  XKNetworkSwift
//
//  Created by kenneth on 2021/6/11.
//

import Foundation

enum XKError: Error {
    case nilObject
    case code(String)
}

extension XKError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .nilObject:
            return "网络请求不存在"
        case let .code(reason):
            return reason
        }
    }
}
