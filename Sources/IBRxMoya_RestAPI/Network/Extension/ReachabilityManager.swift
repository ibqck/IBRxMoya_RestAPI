//
//  ReachabilityManager.swift
//  SharedPlatform
//
//  Created by INBEOM on 2023/04/06.
//  Copyright © 2023 60000720. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire

// An observable that completes when the app gets online (possibly completes immediately).
public func connectedToInternet() -> Observable<Bool> {
    return ReachabilityManager.shared.reach
}

public class ReachabilityManager: NSObject {

    static let shared = ReachabilityManager()

    let manager : NetworkReachabilityManager? = NetworkReachabilityManager.init()

    let reachSubject = ReplaySubject<Bool>.create(bufferSize: 1)
    public var reach: Observable<Bool> {
        return reachSubject.asObservable()
    }

    override init() {
        super.init()
        NetworkReachabilityManager.default?.startListening(onUpdatePerforming: { (status) in
            switch status {
            case .notReachable:
                self.reachSubject.onNext(false)
            case .reachable:
                self.reachSubject.onNext(true)
            case .unknown:
                self.reachSubject.onNext(false)
            }
        })
    }
}




