//
//  StompFrame.swift
//  Pods
//
//  Created by Ahmad Daneshvar on 5/16/24.
//

import Foundation

internal struct StompFrame<T: RawRepresentable> where T.RawValue == String {
    var name: T!
    var headers = [String: String]()
    var body: Any = ""
    
    init(name: T, headers: [String: String] = [:]) {
        self.name = name
        self.headers = headers
    }
    
    init<X: Encodable>(name: T, headers: [String: String] = [:], encodableBody: X, jsonDateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601) {
        self.init(name: name, headers: headers)
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = jsonDateEncodingStrategy
        
        if let jsonData = try? jsonEncoder.encode(encodableBody),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            self.body = jsonString
            self.headers[StompCommonHeader.contentType.rawValue] = "application/json;charset=UTF-8"
        }
    }
    
    init(name: T, headers: [String: String] = [:], stringBody: String) {
        self.init(name: name, headers: headers)
        
        self.body = stringBody
        if self.headers[StompCommonHeader.contentType.rawValue] == nil {
            self.headers[StompCommonHeader.contentType.rawValue] = "text/plain"
        }
    }
    
    init(name: T, headers: [String: String] = [:], dataBody: Data) {
        self.init(name: name, headers: headers)
        
        self.body = dataBody
    }
    
    init(withSerializedString frame: String) throws {
        try deserialize(frame: frame)
    }
    
    func serialize() -> String {
        var frame = name.rawValue + "\n"
        
        // ** Headers
        for (hKey, hVal) in headers {
            frame += "\(hKey):\(hVal)\n"
        }
        
        // ** Body
        if let stringBody = body as? String, !stringBody.isEmpty {
            frame += "\n\(stringBody)"
        } else if let dataBody = body as? Data, !dataBody.isEmpty {
            let dataAsBase64 = dataBody.base64EncodedString()
            frame += "\n\(dataAsBase64)"
        } else {
            frame += "\n"
        }
        
        // ** Add NULL char
        frame += NULL_CHAR
        
        return frame
    }
    
    mutating func deserialize(frame: String) throws {
        var lines = frame.components(separatedBy: "\n")
        
        // ** Remove first if was empty string
        if let firstLine = lines.first, firstLine.isEmpty {
            lines.removeFirst()
        }
        
        // ** Parse Command
        if let command = StompRequestFrame(rawValue: lines.first ?? "") {
            name = (command as! T)
        } else if let command = StompResponseFrame(rawValue: lines.first ?? "") {
            name = (command as! T)
        } else {
            throw InvalidStompCommandError()
        }
        
        // ** Remove Command
        lines.removeFirst()
        
        // ** Parse Headers
        while let line = lines.first, !line.isEmpty {
            let headerParts = line.components(separatedBy: ":")
            
            if headerParts.count != 2 {
                break
            }
            
            headers[headerParts[0].trimmingCharacters(in: .whitespacesAndNewlines)] = headerParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            lines.removeFirst()
        }
        
        // ** Remove the blank line between the headers and body
        if let firstLine = lines.first, firstLine.isEmpty {
            lines.removeFirst()
        }
        
        // ** Parse body
        var body = lines.joined(separator: "\n")
        
        if body.hasSuffix("\0") {
            body = body.replacingOccurrences(of: "\0", with: "")
        }
        
        if let data = Data(base64Encoded: body) {
            self.body = data
        } else {
            self.body = body
        }
    }
    
    func getCommonHeader(_ header: StompCommonHeader) -> String? {
        return headers[header.rawValue]
    }
}
