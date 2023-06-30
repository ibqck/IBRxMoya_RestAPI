//
//  Dictionary+JSON.swift
//
//
//  Created by INBEOM PYO 
//

import Foundation
import SwiftyJSON

public extension JSON {
    func parseTo<T: Codable>() -> T? {
        guard let data = try? rawData(options: .prettyPrinted) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: data)
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    var jsonString: String? {
        if let dict = (self as AnyObject) as? Dictionary<String, AnyObject> {
            do {
                let data = try JSONSerialization.data(withJSONObject: dict, options:[])
                if let string = String(data: data, encoding: String.Encoding.utf8) {
                    return string
                }
            } catch {
                print(error)
            }
        }
        return nil
    }
}

extension Dictionary where Key: NSObject, Value:AnyObject {
    func toJSONString() -> String{
        guard let string = try? String(data: JSONSerialization.data(withJSONObject: self, options: []), encoding: .utf8) ?? "" else { return "" }
        return string
    }
}

public class IBREST_DictionaryEncoder {
    private let jsonEncoder = JSONEncoder()

    /// Encodes given Encodable value into an array or dictionary
    public func encode<T>(_ value: T) throws -> Any where T: Encodable {
        let jsonData = try jsonEncoder.encode(value)
        return try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
    }

    public func encode<T>(_ value: T, encode : JSONSerialization.ReadingOptions ) throws -> Any where T: Encodable {
        let jsonData = try jsonEncoder.encode(value)
        return try JSONSerialization.jsonObject(with: jsonData, options: encode)
    }

    public init() {

    }


}

class DictionaryDecoder {
    private let jsonDecoder = JSONDecoder()

    /// Decodes given Decodable type from given array or dictionary
    func decode<T>(_ type: T.Type, from json: Any) throws -> T where T: Decodable {
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        return try jsonDecoder.decode(type, from: jsonData)
    }
    
}



//extension KeyedDecodingContainer {
//    func decode<T>(_ key: KeyedDecodingContainer.Key) throws -> T where T: Decodable {
//        return try decode(T.self, forKey: key)
//    }
//    func decodeArray<T>(_ key: KeyedDecodingContainer.Key) throws -> [T] where T: Decodable {
//        return try decode([T].self, forKey: key)
//    }
//
//    func decodeIfPresent<T>(_ key: KeyedDecodingContainer.Key) throws -> T? where T: Decodable {
//        return try decodeIfPresent(T.self, forKey: key)
//    }
//
//    subscript<T>(key: Key) -> T where T: Decodable {
//        return try! decode(T.self, forKey: key)
//    }
//}
