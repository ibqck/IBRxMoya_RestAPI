//
//  RestAPI.swift
//  SharedPlatform
//
//  Created by INBEOM on 2023/04/05.
//  Copyright © 2023 60000720. All rights reserved.
//

import Foundation
import Moya
import RxMoya
import RxSwift
import SwiftyJSON


//protocol RestAPI{
//    associatedtype Ttype: TargetType,AccessTokenAuthorizable
//}

@objcMembers
public class RestAPI: NSObject {
    let provider: NetworkProvider
    let provider_stub = MoyaProvider<BaseAPI>.init(stubClosure: MoyaProvider<BaseAPI>.immediatelyStub)

    private let disposeBag = DisposeBag()
    public init(config: NetworkType_Configs) {
        self.provider = NetworkProvider.provider(configs : config)
    }

    // 공통에러 처리
    typealias CommonError = ((Swift.Error) throws -> Void)?
    lazy var errorHandler:CommonError = { [weak self] (error) in

//        debugPrint("###################### REST Error Handler :  \(error)")
        throw error
//        guard let errorResponse = (error as? MoyaError)?.response else {
//            self?.showAlert(with: "Network Error : \(error.localizedDescription)", code: 500)
//            return
//        }





    }


//    private func handleInternetConnection<T: Any>(error: Error) throws -> Single<T> {
//      guard
//        let urlError = Self.converToURLError(error),
//        Self.isNotConnection(error: error)
//      else { throw error }
//      throw MyAPIError.internetConnection(urlError)
//    }
//
//      private func handleTimeOut<T: Any>(error: Error) throws -> Single<T> {
//        guard
//          let urlError = Self.converToURLError(error),
//          urlError.code == .timedOut
//        else { throw error }
//        throw MyAPIError.requestTimeout(urlError)
//      }




    // 공통응답 처리(200)
    typealias CommonNext = ((Moya.Response) -> Void)?
    lazy var nextHandler:CommonNext = { [weak self] (response) in

        /// ?? 예외처리
        if response.statusCode != 200{
            //try onError?(response)
//            throw DecodingError.dataCorruptedError(in: response,
//                                                   debugDescription: "Response error (\(response.statusCode))")
//            return
            //return Single
            //onerror

            //errorHandler()
        }

    }

    final let decoder: JSONDecoder = {

        let decoder = JSONDecoder()

        //decoder.keyDecodingStrategy = .convertFromSnakeCase

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            debugPrint("Cannot decode date string")

            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Cannot decode date string \(dateString)")
        }

        return decoder
    }()
}

extension RestAPI {
    @discardableResult

    /// Test API
    /// - Returns: ~/Samples JSON File
    public func request_Stub<T: Codable>(_ target: BaseAPI, type: T.Type) -> Single<T>
    {


//        let provider_stub = MoyaProvider<target.rawValue.t>.init(stubClosure: MoyaProvider<target.rawValue>.immediatelyStub)


        provider_stub.rx.request(target, callbackQueue: DispatchQueue.main).observe(on: SerialDispatchQueueScheduler.init(qos: .background))
            .do(onSuccess: nextHandler, onError: errorHandler)
            .map {
                return $0
            }
            .map(T.self, using: decoder)
            .do(onError: errorHandler)
            //.observe(on: MainScheduler.instance)
    }

    @discardableResult
    public func request(to target: BaseAPI) -> Single<Any> {
        return provider.request(target)
            .mapJSON()
            //.observe(on: MainScheduler.instance)
            .asSingle()
    }

    public func requestImage(_ target: BaseAPI) -> Single<Image> {
        return provider.request(target)
            .do(onNext: nextHandler, onError: errorHandler)
            .mapImage()
            .do(onError: errorHandler)
            .asSingle()
    }

    @discardableResult
    public func requestWithoutMapping(_ target: BaseAPI) -> Single<Moya.Response> {
        return provider.request(target)
            //.observe(on: MainScheduler.instance)
            .asSingle()
    }

    @discardableResult
    public func requestObject<T: Codable>(_ target: BaseAPI, type: T.Type) -> Single<T> {
        provider.request(target)
            .observe(on: SerialDispatchQueueScheduler.init(qos: .background))
            .do(onNext: nextHandler, onError: errorHandler)
            .map {
                return $0
            }
            .map(T.self, using: decoder)
            .do(onError: errorHandler)
            //.observe(on: MainScheduler.instance)
            .asSingle()
    }

    public func requestObject(_ target: BaseAPI) -> Single<JSON> {
        provider.request(target)
            .observe(on: SerialDispatchQueueScheduler.init(qos: .background))
            .do(onNext: nextHandler, onError: errorHandler)
            .map {
                return $0
            }
            .map(JSON.self, using: decoder)
            .do(onError: errorHandler)
            //.observe(on: MainScheduler.instance)
            .asSingle()
    }

    /// OAuth 연동
    @discardableResult
    public func requestObject<T: Codable>(_ target: BaseAPI, type: T.Type,tokenManager : TokenManager_Protocol) -> Single<T> {
        let logout = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                // here is logout
                tokenManager.logout(rest: self)
            })
        }

        let doRefreshToken = { ()  -> Observable<Bool> in
            return tokenManager.refreshSession(rest: self)
        }



        return provider.request(target , tokenManager.getRefreshToken_Target(rest: self))
            .observe(on: SerialDispatchQueueScheduler.init(qos: .background))
            //.debug()
            .retry(when: { (error : Observable<TokenError>) -> Observable<(Bool)> in
                guard tokenManager.refresh_token().count > 0 else {
                    return Observable.error(TokenError.Token_Expired)
                }
                return error.flatMap { error  -> Observable<(Bool)> in
                    switch error {
                    case .Token_Expired :
                        return doRefreshToken().flatMap { result -> Observable<Bool> in
                            return Observable.just(result)
                        }
                    default :
                        return Observable.error(error)
                    }
                }
            })
            .do(onNext: nextHandler, onError: errorHandler)
            .map(T.self, using: decoder)
            .do(onError: errorHandler)
            .asSingle()
    }
}


