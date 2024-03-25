//
//  SwiftStomp.swift
//  SwiftStomp
//
//  Created by Ahmad Daneshvar on 5/16/20.
//  Copyright © 2020 Ahmad Daneshvar. All rights reserved.
//

import Foundation
import Starscream
import Reachability

fileprivate let NULL_CHAR = String(format: "%C", arguments: [0x00])

// MARK: - Enums
public enum StompRequestFrame : String {
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

public enum StompResponseFrame : String{
    case connected = "CONNECTED"
    case message = "MESSAGE"
    case receipt = "RECEIPT"
    case error = "ERROR"
}


public enum StompAckMode : String{
    case clientIndividual = "client-individual"
    case client = "client"
    case auto = "auto"
}

public enum StompCommonHeader : String{
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

public enum StompErrorType{
    case fromSocket
    case fromStomp
}

public enum StompDisconnectType{
    case fromSocket
    case fromStomp
}

public enum StompConnectType{
    case toSocketEndpoint
    case toStomp
}

public enum StompConnectionStatus{
    case connecting
    case socketDisconnected
    case socketConnected
    case fullyConnected
}

fileprivate enum StompLogType : String{
    case info = "INFO"
    case socketError = "SOCKET ERROR"
    case stompError = "STOMP ERROR"
}

// MARK: - SwiftStomp
public class SwiftStomp{
    
    fileprivate var host : URL
    fileprivate var httpConnectionHeaders : [String : String]?
    fileprivate var stompConnectionHeaders : [String : String]?
    fileprivate var socket : WebSocket!
    fileprivate var acceptVersion = "1.1,1.2"
    fileprivate var status : StompConnectionStatus = .socketDisconnected
    fileprivate var reconnectScheduler : Timer?
    fileprivate var reconnectTryCount = 0
    fileprivate var reachability : Reachability!
    fileprivate var hostIsReachabile = true
    
    /// Auto ping peroperties
    fileprivate var pingTimer : Timer?
    fileprivate var pingInterval: TimeInterval = 10 //< 10 Seconds
    fileprivate var autoPingEnabled = false
    
    /// It's not a weak delegate - please make sure you avoid retain cycles!
    public var delegate : SwiftStompDelegate? // WARNING - It's not a weak delegate!
    public var enableLogging = false
    public var isConnected : Bool {
        return self.status == .fullyConnected
    }
    public var connectionStatus : StompConnectionStatus{
        return self.status
    }
    public var callbacksThread : DispatchQueue?
    public var autoReconnect = false
    
    public init (host : URL, headers : [String : String]? = nil, httpConnectionHeaders : [String : String]? = nil){
        self.host = host
        
        
        self.stompConnectionHeaders = headers
        self.httpConnectionHeaders = httpConnectionHeaders
        /// Configure reachability
        self.initReachability()
    }
    
    private func initReachability(){
        
        reachability = try! Reachability(queueQoS: .utility, targetQueue: DispatchQueue(label: "swiftStomp.reachability"), notificationQueue: .global())
        reachability.whenReachable = { [weak self] _ in
            self?.stompLog(type: .info, message: "Network IS reachable")
            self?.hostIsReachabile = true
        }
        reachability.whenUnreachable = { [weak self] _ in
            self?.stompLog(type: .info, message: "Network IS NOT reachable")
            self?.hostIsReachabile = false
        }
    }
}

/// Public Operating functions
public extension SwiftStomp{
    func connect(timeout : TimeInterval = 5, acceptVersion : String = "1.1,1.2", autoReconnect : Bool = false){
        
        self.autoReconnect = autoReconnect

        //** If socket is connected now, just needs to connect to the Stomp
        if self.status == .socketConnected{
            self.stompConnect()
            return
        }
        
        var urlRequest = URLRequest(url: self.host)
        
        //** Accept Version
        self.acceptVersion = acceptVersion
        
        //** Time interval
        urlRequest.timeoutInterval = timeout

        if let httpConnectionHeaders {
            for header in httpConnectionHeaders {
                urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }

        //** Connect
        self.socket = WebSocket(request: urlRequest)
        
        if let callbackQueue = self.callbacksThread{
            self.socket.callbackQueue = callbackQueue
        }
        
        self.status = .connecting
        
        self.socket.delegate = self
        self.socket.connect()
    }
    
    func disconnect(force : Bool = false){
        
        self.disableAutoPing()
        self.invalidateConnector()
        
        if !force{ //< Send disconnect first over STOMP
            self.stompDisconnect()
        } else { //< Disconnect socket directly! (Not recommended until you have to do it!)
            self.socket.forceDisconnect()
        }
    }
    
    func subscribe(to destination : String, mode : StompAckMode = .auto, headers : [String : String]? = nil){
        var headersToSend = StompHeaderBuilder
            .add(key: .destination, value: destination)
            .add(key: .id, value: destination)
            .add(key: .ack, value: mode.rawValue)
            .get
        
        //** Append extra headers
        headers?.forEach({ hEntry in
            headersToSend[hEntry.key] = hEntry.value
        })
        
        self.sendFrame(frame: StompFrame(name: .subscribe, headers: headersToSend))
    }
    
    func unsubscribe(from destination : String, mode : StompAckMode = .auto, headers : [String : String]? = nil){
        var headersToSend = StompHeaderBuilder
            .add(key: .id, value: destination)
            .get
        
        //** Append extra headers
        headers?.forEach({ hEntry in
            headersToSend[hEntry.key] = hEntry.value
        })
        
        self.sendFrame(frame: StompFrame(name: .unsubscribe, headers: headersToSend))
    }
    
    func send(body : String, to : String, receiptId : String? = nil, headers : [String : String]? = nil){
        let headers = prepareHeadersForSend(to: to, receiptId: receiptId, headers: headers)
        
        self.sendFrame(frame: StompFrame(name: .send, headers: headers, stringBody: body))
    }
    
    func send(body : Data, to : String, receiptId : String? = nil, headers : [String : String]? = nil){
        let headers = prepareHeadersForSend(to: to, receiptId: receiptId, headers: headers)
        
        self.sendFrame(frame: StompFrame(name: .send, headers: headers, dataBody: body))
    }
    
    func send <T : Encodable> (body : T, to : String, receiptId : String? = nil, headers : [String : String]? = nil, jsonDateEncodingStrategy : JSONEncoder.DateEncodingStrategy = .iso8601){
        let headers = prepareHeadersForSend(to: to, receiptId: receiptId, headers: headers)
        
        self.sendFrame(frame: StompFrame(name: .send, headers: headers, encodableBody: body, jsonDateEncodingStrategy: jsonDateEncodingStrategy))
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
    
    
    /// Send ping command to keep connection alive
    /// - Parameters:
    ///   - data: Date to send over Web socket
    ///   - completion: Completion block
    func ping(data: Data = Data(), completion: (() -> Void)? = nil) {
        
        //** Check socket status
        if self.status != .fullyConnected && self.status != .socketConnected{
            self.stompLog(type: .info, message: "Stomp: Unable to send `ping`. Socket is not connected!")
            return
        }
        
        self.socket.write(ping: data, completion: completion)
        
        self.stompLog(type: .info, message: "Stomp: Ping sent!")
        
        //** Reset ping timer
        self.resetPingTimer()
    }
    
    
    /// Enable auto ping command to ensure connection will keep alive and prevent connection to stay idle
    /// - Notice: Please be care if you used `disconnect`, you have to re-enable the timer again.
    /// - Parameter pingInterval: Ping command send interval
    func enableAutoPing(pingInterval: TimeInterval = 10){
        self.pingInterval = pingInterval
        self.autoPingEnabled = true
        
        //** Reset ping timer
        self.resetPingTimer()
    }
    
    
    /// Disable auto ping function
    func disableAutoPing(){
        self.autoPingEnabled = false
        self.pingTimer?.invalidate()
    }
    
}

/// Helper functions
fileprivate extension SwiftStomp{
    func stompLog(type : StompLogType, message : String){
        if !self.enableLogging { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        print("\(formatter.string(from: Date())) SwiftStomp [\(type.rawValue)]:\t \(message)")
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
    
    func scheduleConnector(){
        if let scheduler = self.reconnectScheduler, scheduler.isValid{
            scheduler.invalidate()
        }

        try? self.reachability.startNotifier()

        self.reconnectScheduler = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] (timer) in
            guard let self = self else {
                return
            }
            if !self.hostIsReachabile{
                self.stompLog(type: .info, message: "Network is not reachable. Ignore connecting!")
                return
            }

            self.connect(autoReconnect: self.autoReconnect)
        })
    }
    
    func invalidateConnector(){
        if let connector = self.reconnectScheduler, connector.isValid{
            connector.invalidate()
        }

        self.reachability.stopNotifier()
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
        if let stompConnectionHeaders = self.stompConnectionHeaders{
            for (hKey, hVal) in stompConnectionHeaders{
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
            stompLog(type: .stompError, message: "Process frame error: \(ex.localizedDescription)")
            return
        }
        
        //** Dispatch STOMP frame

        switch frame.name {
        case .message:
            stompLog(type: .info, message: "Stomp: Message received: \(String(describing: frame.body))")
            
            let messageId = frame.getCommonHeader(.messageId) ?? ""
            let destination = frame.getCommonHeader(.destination) ?? ""
            
            self.delegate?.onMessageReceived(swiftStomp: self, message: frame.body, messageId: messageId, destination: destination, headers: frame.headers)
            
        case .receipt:
            guard let receiptId = frame.getCommonHeader(.receiptId) else {
                stompLog(type: .stompError, message: "Receipt message received without `receipt-id` header: \(text)")
                return
            }
            
            
            stompLog(type: .info, message: "Receipt received: \(receiptId)")
            
            self.delegate?.onReceipt(swiftStomp: self, receiptId: receiptId)
            
            if receiptId == "disconnect/safe"{
                self.status = .socketConnected
                
                self.delegate?.onDisconnect(swiftStomp: self, disconnectType: .fromStomp)
                self.socket.disconnect()
            }

        case .error:
            self.status = .socketConnected
            
            guard let briefDescription = frame.getCommonHeader(.message) else {
                stompLog(type: .stompError, message: "Stomp error frame received without `message` header: \(text)")
                return
            }
            
            let fullDescription = frame.body as? String
            let receiptId = frame.getCommonHeader(.receiptId)
            
            stompLog(type: .stompError, message: briefDescription)
            
            self.delegate?.onError(swiftStomp: self, briefDescription: briefDescription, fullDescription: fullDescription, receiptId: receiptId, type: .fromStomp)
        case .connected:
            self.status = .fullyConnected
            
            stompLog(type: .info, message: "Stomp: Connected")
            
            self.delegate?.onConnect(swiftStomp: self, connectType: .toStomp)
        default:
            stompLog(type: .info, message: "Stomp: Un-Processable content: \(text)")
        }
    }
    
    func sendFrame(frame : StompFrame<StompRequestFrame>, completion : (() -> ())? = nil){
        switch self.status {
        case .socketConnected:
            if frame.name != .connect{
                stompLog(type: .info, message: "Unable to send frame \(frame.name.rawValue): Stomp is not connected!")
                return
            }
        case .socketDisconnected, .connecting:
            stompLog(type: .info, message: "Unable to send frame \(frame.name.rawValue): Invalid state: \(self.status)")
            return
        default:
            break
        }
            
        let rawFrameToSend = frame.serialize()
        
        stompLog(type: .info, message: "Stomp: Sending...\n\(rawFrameToSend)\n")
        
        self.socket.write(string: rawFrameToSend, completion: completion)
        
        //** Reset ping timer
        self.resetPingTimer()
    }
    
    func resetPingTimer(){
        if !autoPingEnabled{
            return
        }
        
        //** Invalidate if timer is valid
        if let t = self.pingTimer, t.isValid{
            t.invalidate()
        }
        
        //** Schedule the ping timer
        self.pingTimer = Timer.scheduledTimer(withTimeInterval: self.pingInterval, repeats: true, block: { [weak self] _ in
            self?.ping()
        })
    }
}

/// Web socket delegate
extension SwiftStomp : WebSocketDelegate{
    public func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            self.status = .socketConnected
            
            self.invalidateConnector()
            
            stompLog(type: .info, message: "Scoket: connected: \(headers)")
            
            self.delegate?.onConnect(swiftStomp: self, connectType: .toSocketEndpoint)
            
            self.stompConnect()
        case .disconnected(let reason, let code):
            
            stompLog(type: .info, message: "Socket: Disconnected: \(reason) with code: \(code)")
            
            self.delegate?.onDisconnect(swiftStomp: self, disconnectType: .fromSocket)
            
            //** Disable auto ping
            self.disableAutoPing()
            
        case .text(let string):
            stompLog(type: .info, message: "Socket: Received text")
            
            self.processReceivedSocketText(text: string)
        case .binary(let data):
            stompLog(type: .info, message: "Socket: Received data: \(data.count)")
        case .ping(let data):
            stompLog(type: .info, message: "Socket: Ping data with length \(String(describing: data?.count))")
            
        case .pong(let data):
            stompLog(type: .info, message: "Socket: Pong data with length \(String(describing: data?.count))")
            
        case .viabilityChanged(let viability):
            stompLog(type: .info, message: "Socket: Viability changed: \(viability)")
            self.delegate?.onSocketEvent(eventName: "viabilityChangedTo\(viability)", description: "Socket viability changed")
            
        case .reconnectSuggested(let suggested):
            stompLog(type: .info, message: "Socket: Reconnect suggested: \(suggested)")
            
            self.delegate?.onSocketEvent(eventName: "reconnectSuggested", description: "Socket Reconnect suggested")

            if suggested{
                self.connect()
            }
        case .cancelled:
            self.status = .socketDisconnected

            stompLog(type: .info, message: "Socket: Cancelled")
            
            self.delegate?.onSocketEvent(eventName: "cancelled", description: "Socket cancelled")

            if self.autoReconnect{
                self.scheduleConnector()
            }
        case .error(let error):
            self.status = .socketDisconnected
            
            stompLog(type: .socketError, message: "Socket: Error: \(error.debugDescription)")
            self.delegate?.onError(swiftStomp: self, briefDescription: "Socket Error", fullDescription: error?.localizedDescription, receiptId: nil, type: .fromSocket)
            
            if self.autoReconnect{
                self.scheduleConnector()
            }
        case .peerClosed:
            stompLog(type: .info, message: "Socket: Peer closed")
        @unknown default:
            stompLog(type: .info, message: "Socket: Unexpected event kind: \(String(describing: event))")
        }
    }
    
}

// MARK: - SwiftStomp delegate
public protocol SwiftStompDelegate{
    
    func onConnect(swiftStomp : SwiftStomp, connectType : StompConnectType)
    
    func onDisconnect(swiftStomp : SwiftStomp, disconnectType : StompDisconnectType)
    
    func onMessageReceived(swiftStomp : SwiftStomp, message : Any?, messageId : String, destination : String, headers : [String : String])
    
    func onReceipt(swiftStomp : SwiftStomp, receiptId : String)
    
    func onError(swiftStomp : SwiftStomp, briefDescription : String, fullDescription : String?, receiptId : String?, type : StompErrorType)
    
    func onSocketEvent(eventName : String, description : String)
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
    
    convenience init <X : Encodable>(name : T, headers : [String : String] = [:], encodableBody : X, jsonDateEncodingStrategy : JSONEncoder.DateEncodingStrategy = .iso8601){
        self.init(name: name, headers: headers)
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = jsonDateEncodingStrategy
        
        if let jsonData = try? jsonEncoder.encode(encodableBody){
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
public class StompHeaderBuilder{
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
public class InvalidStompCommandError : Error{
    
    var localizedDescription: String {
        return "Invalid STOMP command"
    }
}

