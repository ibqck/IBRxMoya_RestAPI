//
//  NetworkType.swift
//  SharedPlatform
//
//  Created by INBEOM on 2023/04/06.
//  Copyright © 2023 60000720. All rights reserved.
//

import Foundation
import Moya
import RxSwift
import UIKit

public protocol TokenManager_Protocol {
    /// 갱신 할 토큰 값
    func refresh_token() -> String
    /// 세션 갱신
    func refreshSession(rest : RestAPI) -> Observable<Bool>
    /// Logout 처리
    func logout(rest : RestAPI)
    /// RefreshToken API Target
    func getRefreshToken_Target(rest : RestAPI)  -> BaseAPI?
}

public enum TokenError : Swift.Error{
    case Token_Expired
    case Token_Invalid
    case Token_Invalid_ETC
}

public protocol NetworkType_ConfigsProtocol{
    var trackInflights : Bool {get}// 중복호출 블록 여부
    var loggingEnabled : Bool {get}
    var timeOut : Int {get}
    var tokenClosure : ((TargetType) -> String)? {get}
}

public struct NetworkType_Configs : NetworkType_ConfigsProtocol{
    public var trackInflights : Bool // 중복호출 블록 여부
    public var loggingEnabled : Bool
    public var timeOut : Int
    public var tokenClosure : ((TargetType) -> String)?

    public init(trackInflights : Bool = true ,loggingEnabled: Bool, timeOut: Int, tokenClosure: ( (TargetType) -> String)? = nil) {
        self.trackInflights = trackInflights
        self.loggingEnabled = loggingEnabled
        self.timeOut = timeOut
        self.tokenClosure = tokenClosure
    }

}
// Conformance NetworkingType
// associatedtype T, typealias T
public struct NetworkProvider : NetworkingType {
    public typealias T = BaseAPI
    public let provider : OnlineProvider<T>

    public init(provider: OnlineProvider<T>) {
        self.provider = provider
    }
}

// extension add request function
extension NetworkProvider {
    typealias Response = Observable<Moya.Response>
    func request(_ token: T, _ refreshToken : T? = nil) -> Response {
        let actualRequest = provider.request(token)
        return actualRequest
    }
}


// TODO: Common Library로 이동
public protocol NetworkingType {
    associatedtype T: TargetType
}

extension NetworkingType {
    static func provider(configs : NetworkType_Configs) -> NetworkProvider {
        
        //TODO: X509 Pass
        //let manager = ServerTrustManager(evaluators: ["*": DisabledTrustEvaluator()])
        //let session = Session(serverTrustManager: manager)
        
        return NetworkProvider(provider: newProvider(plugins(configs),
                                                     timeOut: configs.timeOut,
                                                     trackInflights: configs.trackInflights)
        //,session
        )
    }
}

extension NetworkingType {
    static func endpointsClosure<T>(_ xAccessToken: String? = nil) -> (T) -> Endpoint where T: TargetType {
        return { target in
            let endpoint = MoyaProvider.defaultEndpointMapping(for: target)

            // Sign all non-XApp, non-XAuth token requests
            return endpoint
        }
    }


    static func APIKeysBasedStubBehaviour<T>(_: T) -> Moya.StubBehavior {
        return .never
    }

    // MARK: Plugin
    static func plugins(_ config : NetworkType_Configs? = nil ) -> [PluginType]{
        var plugins: [PluginType] = []


        if config?.loggingEnabled == true {
            let logger = NetworkLoggerPlugin()
            logger.configuration.logOptions = .verbose
            logger.configuration.formatter.responseData = { $0.prettyPrintedJSONString ?? "" }
            plugins.append(logger)

        }


        /// Add Cache
        plugins.append(CachePolicyPlugin())

        /// Add Token Closure
        if let closure  = config?.tokenClosure{
            let authPlugin = AccessTokenPlugin(tokenClosure: closure)
            plugins.append(authPlugin)
        }

        let networkClosure = {(_ change: NetworkActivityChangeType, _ target: TargetType) in
            switch change {
            case .began:
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    //LoadingHUD.show()
                }
            case .ended:
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    //LoadingHUD.hide()
                }
            }
        }

        let networkClosurePlugin = NetworkActivityPlugin(networkActivityClosure: networkClosure)
        plugins.append(networkClosurePlugin)

        return plugins
    }

//    static var plugins: [PluginType] {
//        var plugins: [PluginType] = []
//        if SharedPlatformNetwork.NetworkConfigs.loggingEnabled == true {
//            let logger = NetworkLoggerPlugin()
//            logger.configuration.logOptions = .verbose
//            logger.configuration.formatter.responseData = { $0.prettyPrintedJSONString ?? "" }
//            plugins.append(logger)
//
//        }
//
//
//
//        /// Test Auth Code
//        let token =
//        let authPlugin = AccessTokenPlugin { _ in token }
//        plugins.append(authPlugin)
//
//
//        let networkClosure = {(_ change: NetworkActivityChangeType, _ target: TargetType) in
//            switch change {
//            case .began:
//                DispatchQueue.main.async {
//                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
//                    //LoadingHUD.show()
//                }
//            case .ended:
//                DispatchQueue.main.async {
//                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                    //LoadingHUD.hide()
//                }
//            }
//        }
//
//        let networkClosurePlugin = NetworkActivityPlugin(networkActivityClosure: networkClosure)
//        plugins.append(networkClosurePlugin)
//
//        return plugins
//    }

    // (Endpoint<Target>, NSURLRequest -> Void) -> Void
    static func endpointResolver(timeOut : Int) -> MoyaProvider<T>.RequestClosure {
        return { (endpoint, closure) in
            do {
                var request = try endpoint.urlRequest() // endpoint.urlRequest
                request.timeoutInterval = TimeInterval(timeOut)
                request.httpShouldHandleCookies = true
                closure(.success(request))
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
}


//TODO:  - SessionInit
public func newProvider<T>(_ plugins: [PluginType],
                           timeOut : Int,
                           trackInflights : Bool = false,
                           xAccessToken: String? = nil,
                           session : Session? = nil
) -> OnlineProvider<T> {


    return OnlineProvider(endpointClosure: NetworkProvider.endpointsClosure(xAccessToken),
                          requestClosure: NetworkProvider.endpointResolver(timeOut: timeOut),
                          stubClosure: NetworkProvider.APIKeysBasedStubBehaviour,
                          session: session ?? MoyaProvider<T>.defaultAlamofireSession(),
                          plugins: plugins,trackInflights: trackInflights)
}

// MARK: Cache
public protocol CachePolicyGettable {
    var cachePolicy: URLRequest.CachePolicy { get }
}
final class CachePolicyPlugin: PluginType {
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let cachePolicyGettable = target as? CachePolicyGettable {
            var mutableRequest = request
            mutableRequest.cachePolicy = cachePolicyGettable.cachePolicy
            return mutableRequest
        }

        return request
    }
}


struct INetUtil {
    static func getIFAddresses() -> String? {
        var address: String?
        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return "" }
        guard let firstAddr = ifaddr else { return "" }
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    // Convert interface address to a human readable string:
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)

                }
            }
        }
        freeifaddrs(ifaddr)
        return address

    }
}
