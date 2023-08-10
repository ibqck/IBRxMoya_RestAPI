//
//  BaseAPI.swift
//  Test2
//
//  Created by INBEOM on 2023/04/10.
//

import Foundation
import RxSwift
import Moya


/// Custom TargetType
public protocol TargetProtocol : TargetType , AccessTokenAuthorizable, CachePolicyGettable{
    var parameters: [String: Any]? { get }          /// Target Parameter
    //var authorization_Token: String { get}          /// OAuthToken
    var parameterEncoding: ParameterEncoding {get}  /// Custom Target Encoding | ex) post = JSONEncoding, get = URLEncoding
    func stubbedResponse(_ filename: String) -> Data? /// Test JSON Bundle 링크
}

public protocol BaseAPIProtocol {
    typealias Target = TargetProtocol
}

public class BaseAPI : BaseAPIProtocol
{
    var target: TargetProtocol
    var accessToken : String?
    
    public init(_ target: Target , token : String? = nil) {
        self.target = target
        self.accessToken = token
    }



    //public rawType()

}

extension BaseAPI : TargetType, AccessTokenAuthorizable,CachePolicyGettable{
    var authorization_Token: String {
        return self.accessToken ?? ""
    }

    public var authorizationType: Moya.AuthorizationType?{
        return self.target.authorizationType
    }

    public var headers: [String: String]? {
        return self.target.headers
    }

    public var baseURL: URL {
        return self.target.baseURL
    }

    public var path: String {
        return self.target.path
    }

    public var method: Moya.Method {
        return self.target.method
    }

    var parameters: [String: Any]? {
        self.target.parameters
    }

    public var parameterEncoding: ParameterEncoding {
        return self.target.parameterEncoding
    }

    //multi
    public var task: Task {
        self.target.task
    }

    public var sampleData: Data {
        return self.target.sampleData
    }

    public var cachePolicy: URLRequest.CachePolicy {
        return self.target.cachePolicy
    }
}

//extension BaseAPI  {
//    enum MoviewDBAPI : base{
//        case GetMovies(param: [String:Any])
//    }
//}


//MARK :: -Test json
extension RestAPI {
    static func stubbedResponse(_ filename: String) -> Data? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "json") else{
            return nil
        }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return data
        }
        return nil
    }
}


