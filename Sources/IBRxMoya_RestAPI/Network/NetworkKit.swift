//
//  NetworkKit.swift
//
//  Created by INBEOM PYO on
//

import RxMoya
import Moya
import RxSwift
import Alamofire
import Foundation

public class OnlineProvider<Target> where Target: Moya.TargetType {
    fileprivate let online: Observable<Bool>
    fileprivate let provider: MoyaProvider<Target>

    public init(endpointClosure: @escaping MoyaProvider<Target>.EndpointClosure = MoyaProvider<Target>.defaultEndpointMapping,
                requestClosure: @escaping MoyaProvider<Target>.RequestClosure = MoyaProvider<Target>.defaultRequestMapping,
                stubClosure: @escaping MoyaProvider<Target>.StubClosure = MoyaProvider<Target>.neverStub,
                session: Session = MoyaProvider<Target>.defaultAlamofireSession(),
                plugins: [PluginType] = [],
                trackInflights: Bool = true,
                online: Observable<Bool> = connectedToInternet()) {
        self.online = online
        self.provider = MoyaProvider(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, session: session, plugins: plugins, trackInflights: trackInflights)
    }

    public func request(_ token: Target) -> Observable<Moya.Response> {
        let actualRequest = provider.rx.request(token)
        
        //FIXME: Cookie Work
        _=actualRequest.map{
            // 쿠기 동기화 (응답 전)
            if let url =  $0.request?.url , let cookies = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "SHPCookie").cookies(for:url){
                HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: url)
            }
        }
        
        return online
            .take(1)
            .flatMap { _ in // Turn the online state into a network request
       
                actualRequest
                    .do(onSuccess: { (response) in
        
                        //FIXME: Cookie Work
                        // 쿠기 동기화 (응답 후)
                        if let url =  response.request?.url , let cookies = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "SHPCookie").cookies(for:url){
                            HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: url)
                        }
                        
                        

                        
                        //debugPrint("+++ response=", response)

                        /// Test Code
//                        if response.statusCode == 200 , token.path == "/bank/account/list/deposit"{
//                            //throw NSError(domain: "Test Error", code: 401)
//                            throw TokenError.TokenExpired
//                        }
                    },
                        //                    onNext: { (onSuccess) in
                        //
                        //
                        //                    },
                        onError: { (error) in

                        if let error = error as? MoyaError {
                            switch error {
                            case .statusCode(let response):
                                if response.statusCode == 401 {
                                    throw TokenError.Token_Expired
                                }

                            default:
                                throw error
                            }
                        }

                    })
                }
            //.debug()
    }
}

// MARK: - Provider support
public func stubbedResponse(_ filename: String) -> Data! {
    guard let path = Bundle.main.path(forResource: filename, ofType: "json") else { return Data() }
    return (try? Data(contentsOf: URL(fileURLWithPath: path)))
}

private extension String {
    var URLEscapedString: String {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
    }
}

public func url(_ route: TargetType) -> String {
    return route.baseURL.appendingPathComponent(route.path).absoluteString
}
