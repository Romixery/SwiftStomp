//
//  ContentViewViewModel.swift
//  SwiftStomp_Example
//
//  Created by Ahmad Daneshvar on 5/17/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SwiftUI
import Observation
import SwiftStomp
import Combine

extension ContentView {
    @Observable class ViewModel {
        static let connectionURL = "ws://localhost:8080/gs-guide-websocket"
        static let subscriptionTopic = "/topic/greetings"
        
        private(set) var viewState: ViewState = .default
        
        private var swiftStomp = SwiftStomp(host: URL(string: connectionURL)!)
        private var subscriptions = [AnyCancellable]()
        private var messageIndex = 0
        
        init() {
            configureSwiftStomp()
            subscribeToUpstreams()
        }
        
        @MainActor
        func connect() {
            if !swiftStomp.isConnected{
                swiftStomp.connect()
            }
        }
        
        @MainActor
        func disconnect() {
            if swiftStomp.isConnected{
                swiftStomp.disconnect()
            }
        }
        
        @MainActor
        func updateMessage(text: String) {
            viewState.message = text
        }
        
        @MainActor
        func updateDestination(text: String) {
            viewState.destination = text
        }
        
        func sendMessage() {
            messageIndex += 1
            swiftStomp.send(body: viewState.message, to: viewState.destination, receiptId: "msg-\(messageIndex)", headers: [:])
        }
        
        private func configureSwiftStomp() {
            self.swiftStomp.enableLogging = true
            self.swiftStomp.autoReconnect = true
            
            self.swiftStomp.enableAutoPing()
        }
        
        private func subscribeToUpstreams() {
            swiftStomp.eventsUpstream
                .receive(on: RunLoop.main)
                .sink { [weak self] event in
                    guard let self else { return }
                    
                    switch event {
                    case let .connected(type):
                        if type == .toStomp {
                            swiftStomp.subscribe(to: ViewModel.subscriptionTopic)
                        }
                        viewState.isConnected = true
                    case .disconnected(_):
                        viewState.isConnected = false
                    case let .error(error):
                        print("Error: \(error)")
                    }
                }
                .store(in: &subscriptions)
            
            swiftStomp.messagesUpstream
                .receive(on: RunLoop.main)
                .sink { [weak self] message in
                    guard let self else { return }
                    
                    switch message {
                    case let .text(message, messageId, destination, _):
                        viewState.logs += ["\(Date().formatted()) [id: \(messageId), at: \(destination)]: \(message)\n"]
                    case let .data(data, messageId, destination, _):
                        viewState.logs += ["Data message with id `\(messageId)` and binary length `\(data.count)` received at destination `\(destination)`"]
                    }
                }
                .store(in: &subscriptions)
            
            swiftStomp.receiptUpstream
                .sink { receiptId in
                    print("SwiftStop: Receipt received: \(receiptId)")
                }
                .store(in: &subscriptions)
        }
    }
    
    struct ViewState: Equatable {
        var isConnected: Bool
        var destination: String
        var message: String
        var logs: [String]
        
        static let `default` = ViewState(
            isConnected: false,
            destination: "",
            message: "",
            logs: []
        )
    }
}
