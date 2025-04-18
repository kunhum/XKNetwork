//
//  ViewController.swift
//  XKNetwork
//
//  Created by kenneth on 04/21/2022.
//  Copyright (c) 2022 kenneth. All rights reserved.
//

import UIKit
import Moya
import RxSwift
import RxCocoa
import XKNetwork
import XKJsonResolver

// MARK: - WelcomeElement
struct WelcomeElement: Codable {
    let teamID: Int
    let rating: Double
    let wins, losses, lastMatchTime: Int
    let name, tag: String
    let logoURL: String?

    enum CodingKeys: String, CodingKey {
        case teamID = "team_id"
        case rating, wins, losses
        case lastMatchTime = "last_match_time"
        case name, tag
        case logoURL = "logo_url"
    }
}

typealias Welcome = [WelcomeElement]

class ViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        XKNetworker.rx.reachabilityStatus.bind { status in
            print(status)
            switch status {
            case .unknown:
                print("未知网络")
            case .notReachable:
                print("网络不正常")
            case .reachable(.cellular):
                print("蜂窝网络")
            case .reachable(.ethernetOrWiFi):
                print("wifi网络")
            }
        }.disposed(by: disposeBag)
        
        XKNetworker.requestArray(api: TestTargetType.team, responseType: TestModel.self)
            .subscribe { data in
                debugPrint("")
            } onError: { err in
                debugPrint("")
            }
            .disposed(by: disposeBag)
        
            
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
//        debugPrint(TestModel.deserialize(from: ["a": "123"])?.name)
    }
}

struct TestModel: XKResponsePlainlyProtocol {
    
    func isPass() -> Bool {
        return true
    }
    
    var name: String?
    
    var logo_url: String?
    
//    static func mappingForKey() -> [SmartKeyTransformer]? {
//        return [
//            CodingKeys.name <--- ["user_id", "userId", "id"],
//            CodingKeys.logo_url <--- "joined_at"
//        ]
//    }
    
}

enum TestTargetType: TargetType {
    
    case team
    
    var headers: [String : String]? {
        return [:]
    }
    
    var path: String {
        return "/api/teams"
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var task: Moya.Task {
        return .requestParameters(parameters: [:], encoding: URLEncoding.default)
    }
    
    var baseURL: URL {
        return URL(string: "https://api.opendota.com")!
    }
    
}
