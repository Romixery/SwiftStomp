//
//  ViewController.swift
//  SwiftStomp
//
//  Created by Romixery on 05/17/2020.
//  Copyright (c) 2020 Romixery. All rights reserved.
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
    }
    
    private func initStomp(){
        let url = URL(string: "ws://192.168.88.252:8081/socket")!
        
        self.swiftStomp = SwiftStomp(host: url, headers: ["Authorization" : "bearer 4b0ff3fb-b3ac-4832-9f10-9b6c76005aac"])
        self.swiftStomp.enableLogging = true
        self.swiftStomp.delegate = self
    }

    @IBAction func triggerConnect(_ sender: Any) {
        self.swiftStomp.connect(timeout: 10)
    }
    
    @IBAction func triggerSend(_ sender: Any) {
        messageIndex += 1
        Int.random(in: 0..<1000)
        swiftStomp.send(body: self.messageTextView.text, to: destinationTextField.text!, receiptId: "msg-\(messageIndex)", headers: [:])
    }
    
}

extension ViewController : SwiftStompDelegate{
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        if connectType == .toSocketEndpoint{
            print("Connected to socket")
        } else if connectType == .toStomp{
            print("Connected to stomp")
            
            //** Subscribe to topics or queues just after connect to the stomp!
            swiftStomp.subscribe(to: "/topic/greeting", mode: .clientIndividual)
        }
    }
    
    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        if disconnectType == .fromSocket{
            print("Socket disconnected. Disconnect completed")
        } else if disconnectType == .fromStomp{
            print("Client disconnected from stomp but socket is still connected!")
        }
    }
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String) {
        
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
            print("Socket error occured! [\(briefDescription)]")
        } else if type == .fromStomp{
            print("Stomp error occured! [\(briefDescription)]")
        } else {
            print("Unknown error occured!")
        }
    }
    
    
}

