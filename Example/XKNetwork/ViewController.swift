//
//  ViewController.swift
//  XKNetwork
//
//  Created by kenneth on 04/21/2022.
//  Copyright (c) 2022 kenneth. All rights reserved.
//

import UIKit
import RxSwift
import XKNetwork

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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

