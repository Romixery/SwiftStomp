//
//  SwiftStomp.swift
//  SwiftStomp
//
//  Created by Ahmad Daneshvar on 5/16/20.
//  Copyright © 2020 Ahmad Daneshvar. All rights reserved.
//

import Foundation
import Starscream

fileprivate let NULL_CHAR = String(format: "%C", arguments: [0x00])

enum StompRequestFrame : String {
    case connect = "CONNECT"
    case send = "SEND"
    case subscribe = "SUBSCRIBE"
    case unsubscribe = "UNSUBSCRIBE"
    case begin = "BEGIN"
    case commit = "COMMIT"
    case abort = "ABORT"
    case ack = "ACK"
    case nack = "NACK"
    case disconnect = "DISCONNECT"
}

enum StompResponseFrame : String{
    case connected = "CONNECTED"
    case message = "MESSAGE"
    case receipt = "RECEIPT"
    case error = "ERROR"
}


enum StompAckMode : String{
    case clintIndividual = "client-individual"
    case client = "client"
    case auto = "auto"
}

enum StompCommonHeader : String{
    case id = "id"
    case host = "host"
    case receipt = "receipt"
    case session = "session"
    case receiptId = "receipt-id"
    case messageId = "message-id"
    case destination = "destination"
    case contentLength = "content-length"
    case contentType = "content-type"
    case ack = "ack"
    case transaction = "transaction"
    case subscription = "subscription"
    case disconnected = "disconnected"
    case heartBeat = "heart-beat"
    case acceptVersion = "accept-version"
    case message = "message"
}

enum StompErrorType{
    case fromSocket
    case fromStomp
}

enum StompDisconnectType{
    case fromSocket
    case fromStomp
}

enum StompConnectType{
    case toSocketEndpoint
    case toStomp
}


fileprivate enum StompLogType : String{
    case info = "INFO"
    case error = "ERROR"
}

class SwiftStomp{
    
    fileprivate var host : URL
    fileprivate var connectionHeaders : [String : String]?
    fileprivate var socket : WebSocket!
    fileprivate var acceptVersion = "1.1,1.2"
    fileprivate var isConnected = false
    
    var delegate : SwiftStompDelegate?
    var enableLogging = false
    
    init (host : URL, headers : [String : String]? = nil){
        self.host = host
        self.connectionHeaders = headers
    }
    
    func connect(timeout : TimeInterval = 5, acceptVersion : String = "1.1,1.2"){
        var urlRequest = URLRequest(url: self.host)
        
        //** Accept Version
        self.acceptVersion = acceptVersion
        
        //** Time interval
        urlRequest.timeoutInterval = timeout
        
        
        //** Connect
        if self.socket == nil{
            self.socket = WebSocket(request: urlRequest)
        } else {
            self.socket.forceDisconnect()
            
            self.socket.request = urlRequest
        }
        
        self.socket.delegate = self
        self.socket.connect()
    }
    
    func disconnect(force : Bool = false){
        if !force{ //< Send disconnect first over STOMP
            self.stompDisconnect()
        } else { //< Disconnect socket directly! (Not recommended until you have to do it!)
            self.socket.forceDisconnect()
        }
    }
    
    
    func subscribe(to destination : String, mode : StompAckMode = .auto){
        let headers = StompHeaderBuilder
            .add(key: .destination, value: destination)
            .add(key: .id, value: destination)
            .add(key: .ack, value: mode.rawValue)
            .get
        
        self.sendFrame(frame: StompFrame(name: .subscribe, headers: headers))
    }
    
    func unsubscribe(from destination : String, mode : StompAckMode = .auto){
        let headers = StompHeaderBuilder
            .add(key: .id, value: destination)
            .get
        
        self.sendFrame(frame: StompFrame(name: .subscribe, headers: headers))
    }
    
    func send(body : String, to : String, receiptId : String? = nil, headers : [String : String]? = nil){
        let headers = prepareHeadersForSend(to: to, receiptId: receiptId, headers: headers)
        
        self.sendFrame(frame: StompFrame(name: .send, headers: headers, stringBody: body))
    }
    
    func send(body : Data, to : String, receiptId : String? = nil, headers : [String : String]? = nil){
        let headers = prepareHeadersForSend(to: to, receiptId: receiptId, headers: headers)
        
        self.sendFrame(frame: StompFrame(name: .send, headers: headers, dataBody: body))
    }
    
    func send <T : Encodable> (body : T, to : String, receiptId : String? = nil, headers : [String : String]? = nil){
        let headers = prepareHeadersForSend(to: to, receiptId: receiptId, headers: headers)
        
        self.sendFrame(frame: StompFrame(name: .send, headers: headers, encodableBody: body))
    }
    
    func ack(messageId : String, transaction : String? = nil){
        let headerBuilder = StompHeaderBuilder
            .add(key: .id, value: messageId)

        if let transaction = transaction{
            _ = headerBuilder.add(key: .transaction, value: transaction)
        }
        
        let headers = headerBuilder.get
        
        self.sendFrame(frame: StompFrame(name: .ack, headers: headers))
    }
    
    func nack(messageId : String, transaction : String? = nil){
        let headerBuilder = StompHeaderBuilder
            .add(key: .id, value: messageId)

        if let transaction = transaction{
            _ = headerBuilder.add(key: .transaction, value: transaction)
        }
        
        let headers = headerBuilder.get
        
        self.sendFrame(frame: StompFrame(name: .nack, headers: headers))
    }
    
    func begin(transactionName : String){
        let headers = StompHeaderBuilder
            .add(key: .transaction, value: transactionName)
            .get
        
        self.sendFrame(frame: StompFrame(name: .begin, headers: headers))
    }
    
    func commit(transactionName : String){
        let headers = StompHeaderBuilder
            .add(key: .transaction, value: transactionName)
            .get
        
        self.sendFrame(frame: StompFrame(name: .commit, headers: headers))
    }
    
    func abort(transactionName : String){
        let headers = StompHeaderBuilder
            .add(key: .transaction, value: transactionName)
            .get
        
        self.sendFrame(frame: StompFrame(name: .abort, headers: headers))
    }
}

/// Helper functions
private extension SwiftStomp{
    func stompLog(type : StompLogType, message : String){
        if !self.enableLogging { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        print("SwiftStomp:\(type.rawValue)\t\(formatter.string(from: Date())): \(message)")
    }
    
    func prepareHeadersForSend(to : String, receiptId : String? = nil, headers : [String : String]? = nil) -> [String : String]{
        
        let headerBuilder = StompHeaderBuilder
        .add(key: .destination, value: to)
        
        if let receiptId = receiptId{
            _ = headerBuilder.add(key: .receipt, value: receiptId)
        }
        
        var headersToSend = headerBuilder.get
        
        //** Append user headers
        if let headers = headers{
            for (hKey, hVal) in headers{
                headersToSend[hKey] = hVal
            }
        }
        
        return headersToSend
    }
}

/// Back-Operating functions
fileprivate extension SwiftStomp{
    func stompConnect(){
        
        //** Add headers
        var headers = StompHeaderBuilder
            .add(key: .acceptVersion, value: self.acceptVersion)
            .get
        
        //** Append connection headers
        if let connectionHeaders = self.connectionHeaders{
            for (hKey, hVal) in connectionHeaders{
                headers[hKey] = hVal
            }
        }
        
            
        
        self.sendFrame(frame: StompFrame(name: .connect, headers: headers))
    }
    
    func stompDisconnect(){
        //** Add headers
        let headers = StompHeaderBuilder
            .add(key: .receipt, value: "disconnect/safe")
            .get
        
        self.sendFrame(frame: StompFrame(name: .disconnect, headers: headers))
    }
    
    func processReceivedSocketText(text : String){
        var frame : StompFrame<StompResponseFrame>

        //** Deserialize frame
        do{
            frame = try StompFrame(withSerializedString: text)
        }catch let ex{
            stompLog(type: .error, message: "Process frame error: \(ex.localizedDescription)")
            return
        }
        
        //** Dispatch STOMP frame

        switch frame.name {
        case .message:
            stompLog(type: .info, message: "Stomp: Message received: \(String(describing: frame.body))")
            
            let messageId = frame.getCommonHeader(.messageId) ?? ""
            let destination = frame.getCommonHeader(.destination) ?? ""
            
            self.delegate?.onMessageReceived(swiftStomp: self, message: frame.body, messageId: messageId, destination: destination)
            
        case .receipt:
            guard let receiptId = frame.getCommonHeader(.receiptId) else {
                stompLog(type: .error, message: "Stomp > Fatal Error: Receipt message received without receipt-id header: \(text)")
                return
            }
            
            
            stompLog(type: .info, message: "Stomp: Receipt received: \(receiptId)")
            
            self.delegate?.onReceipt(swiftStomp: self, receiptId: receiptId)
            
            if receiptId == "disconnect/safe"{
                self.isConnected = false
                self.delegate?.onDisconnect(swiftStomp: self, disconnectType: .fromStomp)
                self.socket.disconnect()
            }

        case .error:
            guard let briefDescription = frame.getCommonHeader(.message) else {
                stompLog(type: .error, message: "Stomp > Fatal Error: Error message received without message header: \(text)")
                return
            }
            
            let fullDescription = frame.body as? String
            let receiptId = frame.getCommonHeader(.receiptId)
            
            stompLog(type: .error, message: "Stomp: Error received: \(briefDescription)")
            
            self.delegate?.onError(swiftStomp: self, briefDescription: briefDescription, fullDescription: fullDescription, receiptId: receiptId, type: .fromStomp)
            
        case .connected:
            stompLog(type: .info, message: "Stomp: Connected")
            
            self.delegate?.onConnect(swiftStomp: self, connectType: .toStomp)
            self.isConnected = true
            
        default:
            stompLog(type: .info, message: "Stomp: Un-Processable content: \(text)")
        }
    }
    
    func sendFrame(frame : StompFrame<StompRequestFrame>, completion : (() -> ())? = nil){
        let rawFrameToSend = frame.serialize()
        
        stompLog(type: .info, message: "Stomp: Sending...\n\(rawFrameToSend)\n")
        
        self.socket.write(string: rawFrameToSend, completion: completion)
    }
}

/// Web socket delegate
extension SwiftStomp : WebSocketDelegate{
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            stompLog(type: .info, message: "Scoket: connected: \(headers)")
            
            self.delegate?.onConnect(swiftStomp: self, connectType: .toSocketEndpoint)
            self.stompConnect()
        case .disconnected(let reason, let code):
            stompLog(type: .info, message: "Socket: Disconnected: \(reason) with code: \(code)")
            
            self.delegate?.onDisconnect(swiftStomp: self, disconnectType: .fromSocket)
        case .text(let string):
            stompLog(type: .info, message: "Socket: Received text: \(string)")
            print("")
            
            self.processReceivedSocketText(text: string)
        case .binary(let data):
            stompLog(type: .info, message: "Socket: Received data: \(data.count)")
        case .ping(let data):
            stompLog(type: .info, message: "Socket: Ping data with length \(String(describing: data?.count))")
            
        case .pong(let data):
            stompLog(type: .info, message: "Socket: Pong data with length \(String(describing: data?.count))")
            
        case .viabilityChanged(let viability):
            stompLog(type: .info, message: "Socket: Viability changed: \(viability)")
        case .reconnectSuggested(let suggested):
            stompLog(type: .info, message: "Socket: Reconnect suggested: \(suggested)")
        case .cancelled:
            stompLog(type: .info, message: "Socket: Cancelled")
            
            isConnected = false
        case .error(let error):
            stompLog(type: .error, message: "Socket: Error: \(error.debugDescription)")
            
            isConnected = false
            self.delegate?.onError(swiftStomp: self, briefDescription: "Socket Error", fullDescription: error?.localizedDescription, receiptId: nil, type: .fromSocket)
        }
    }
    
}

// MARK: - SwiftStomp delegate
protocol SwiftStompDelegate{
    
    func onConnect(swiftStomp : SwiftStomp, connectType : StompConnectType)
    
    func onDisconnect(swiftStomp : SwiftStomp, disconnectType : StompDisconnectType)
    
    func onMessageReceived(swiftStomp : SwiftStomp, message : Any?, messageId : String, destination : String)
    
    func onReceipt(swiftStomp : SwiftStomp, receiptId : String)
    
    func onError(swiftStomp : SwiftStomp, briefDescription : String, fullDescription : String?, receiptId : String?, type : StompErrorType)
}

// MARK: - Stomp Frame Class
fileprivate class StompFrame<T : RawRepresentable> where T.RawValue == String{
    var name : T!
    var headers = [String : String]()
    var body : Any?
    
    init (name : T, headers : [String : String] = [:]){
        self.name = name
        self.headers = headers
    }
    
    convenience init <X : Encodable>(name : T, headers : [String : String] = [:], encodableBody : X){
        self.init(name: name, headers: headers)
        
        if let jsonData = try? JSONEncoder().encode(encodableBody){
            self.body = String(data: jsonData, encoding: .utf8)
            self.headers[StompCommonHeader.contentType.rawValue] = "application/json;charset=UTF-8"
        }
    }
    
    convenience init(name : T, headers : [String : String] = [:], stringBody : String){
        self.init(name: name, headers: headers)
        
        self.body = stringBody
        if self.headers[StompCommonHeader.contentType.rawValue] == nil{
            self.headers[StompCommonHeader.contentType.rawValue] = "text/plain"
        }
        
        
        
    }
    
    convenience init(name : T, headers : [String : String] = [:], dataBody : Data){
        self.init(name: name, headers: headers)
        
        self.body = dataBody
    }
    
    init(withSerializedString frame : String) throws{
        try deserialize(frame: frame)
    }
    
    func serialize() -> String{
        var frame = name.rawValue + "\n"
        
        //** Headers
        for (hKey, hVal) in headers{
            frame += "\(hKey):\(hVal)\n"
        }
        
        //** Body
        if body != nil{
            if let stringBody = body as? String{
                frame += "\n\(stringBody)"
            } else if let dataBody = body as? Data{
                let dataAsBase64 = dataBody.base64EncodedString()
                frame += "\n\(dataAsBase64)"
            }
        } else {
            frame += "\n"
        }
        
        //** Add NULL char
        frame += NULL_CHAR
        
        return frame
    }
    
    func deserialize(frame : String) throws{
        var lines = frame.components(separatedBy: "\n")
        
        //** Remove first if was empty string
        if lines.first == ""{
            lines.removeFirst()
        }
        
        //** Parse Command
        if let command = StompRequestFrame(rawValue: lines.first ?? ""){
            self.name = (command as! T)
        } else if let command = StompResponseFrame(rawValue: lines.first ?? ""){
            self.name = (command as! T)
        } else {
            throw InvalidStompCommandError()
        }
        
        lines.removeFirst()
        
        //** Parse Headers
        while let line = lines.first, line != ""{
            let headerParts = line.components(separatedBy: ":")
            
            if headerParts.count != 2{
                break
            }
            
            self.headers[headerParts[0].trimmingCharacters(in: .whitespacesAndNewlines)] = headerParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            lines.removeFirst()
        }
        
        //** Parse body
        var body = lines.joined(separator: "\n")
        
        if body.hasSuffix("\0"){
            body = body.replacingOccurrences(of: "\0", with: "")
        }
        
        if let data = Data(base64Encoded: body){
            self.body = data
        } else {
            self.body = body
        }
    }
    
    func getCommonHeader(_ header : StompCommonHeader) -> String?{
        return self.headers[header.rawValue]
    }
}

// MARK: - Header builder
class StompHeaderBuilder{
    private var headers = [String : String]()
    
    static func add(key : StompCommonHeader, value : Any) -> StompHeaderBuilder{
        return StompHeaderBuilder(key: key.rawValue, value: value)
    }
    
    private init(key : String, value : Any){
        self.headers[key] = "\(value)"
    }
    
    func add(key : StompCommonHeader, value : Any) -> StompHeaderBuilder{
        self.headers[key.rawValue] = "\(value)"
        
        return self
    }
    
    var get : [String : String]{
        return self.headers
    }
}

// MARK: - Errors
class InvalidStompCommandError : Error{
    
    var localizedDescription: String {
        return "Invalid STOMP command"
    }
}
