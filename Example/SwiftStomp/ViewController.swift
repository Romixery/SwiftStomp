//
//  ViewController.swift
//  SwiftStomp
//
//  Created by Romixery (Ahmad Daneshvar) on 05/17/2020.
//  Copyright (c) 2021 Romixery. All rights reserved.
//

import UIKit
import SwiftStomp

class ViewController: UIViewController {
    
    /// Outlets
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!
    
    
    /// Client
    private var swiftStomp : SwiftStomp!
    private var messageIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initStomp()
        registerObservers()
    }
    
    private func initStomp(){
        let url = URL(string: "ws://192.168.1.6:8081/socket")!
        
        self.swiftStomp = SwiftStomp(host: url, headers: ["Authorization" : "Bearer 5c09614a-22dc-4ccd-89c1-5c78338f45e9"])
        self.swiftStomp.enableLogging = true
        self.swiftStomp.delegate = self
        self.swiftStomp.autoReconnect = true
        
        self.swiftStomp.enableAutoPing()
    }
    
    private func registerObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
    }
    /**
     * Observer functions
     */
    @objc func appDidBecomeActive(notification : Notification){
        if !self.swiftStomp.isConnected{
            self.swiftStomp.connect()
        }
    }
    
    @objc func appWillResignActive(notication : Notification){
        if self.swiftStomp.isConnected{
            self.swiftStomp.disconnect(force: true)
        }
    }
    
    /**
     * IBActions
     */

    @IBAction func triggerConnect(_ sender: Any) {
        if !self.swiftStomp.isConnected{
            self.swiftStomp.connect()
        }
        
    }
    
    @IBAction func triggerDisconnect(_ sender: Any) {
        if self.swiftStomp.isConnected{
            self.swiftStomp.disconnect()
        }
    }
    
    
    @IBAction func triggerSend(_ sender: Any) {
        messageIndex += 1
        swiftStomp.send(body: self.messageTextView.text, to: destinationTextField.text!, receiptId: "msg-\(messageIndex)", headers: [:])
        
        self.view.endEditing(true)
    }
    
}

extension ViewController : SwiftStompDelegate{
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        if connectType == .toSocketEndpoint{
            print("Connected to socket")
        } else if connectType == .toStomp{
            print("Connected to stomp")
            
            //** Subscribe to topics or queues just after connect to the stomp!
            swiftStomp.subscribe(to: "/topic/greeting")
            swiftStomp.subscribe(to: "/topic/greeting2")
            
        }
    }
    
    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        if disconnectType == .fromSocket{
            print("Socket disconnected. Disconnect completed")
        } else if disconnectType == .fromStomp{
            print("Client disconnected from stomp but socket is still connected!")
        }
    }
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers : [String : String]) {
        
        if let message = message as? String{
            print("Message with id `\(messageId)` received at destination `\(destination)`:\n\(message)")
        } else if let message = message as? Data{
            print("Data message with id `\(messageId)` and binary length `\(message.count)` received at destination `\(destination)`")
        }
        
        print()
    }
    
    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        print("Receipt with id `\(receiptId)` received")
    }
    
    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        if type == .fromSocket{
            print("Socket error occurred! [\(briefDescription)]")
        } else if type == .fromStomp{
            print("Stomp error occurred! [\(briefDescription)] : \(String(describing: fullDescription))")
        } else {
            print("Unknown error occured!")
        }
    }
    
    func onSocketEvent(eventName: String, description: String) {
        print("Socket event occured: \(eventName) => \(description)")
    }
}

