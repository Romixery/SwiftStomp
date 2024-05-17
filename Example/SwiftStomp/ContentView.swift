//
//  ContentView.swift
//  SwiftStomp_Example
//
//  Created by Ahmad Daneshvar on 5/17/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State private var viewModel = ViewModel()
    
    private var messageBinding: Binding<String> {
        Binding { viewModel.viewState.message }
        set: { newValue in
            Task { await viewModel.updateMessage(text: newValue) }
        }
    }
    
    private var destinationBinding: Binding<String> {
        Binding { viewModel.viewState.destination }
        set: { newValue in
            Task { await viewModel.updateDestination(text: newValue) }
        }
    }
    
    var body: some View {
        VStack {
            connectionButton
            
            destinationTextView
            
            messageTextView
            
            sendButton
            
            logView
        }
        .scenePadding()
    }
    
    
    private var connectionButton: some View {
        let isConnected = viewModel.viewState.isConnected
        let title = isConnected ? "Disconnect" : "Connect"
        let color = isConnected ? Color.red : Color.green
        
        
        return Button {
            Task {
                if isConnected{
                    await viewModel.disconnect()
                } else {
                    await viewModel.connect()
                }
            }
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }
    
    private var destinationTextView: some View {
        VStack {
            HStack {
                Text("Destination:")
                Spacer()
            }
            Rectangle()
                .foregroundStyle(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(lineWidth: 0.5)
                        .foregroundStyle(.gray)
                }
                .overlay {
                    TextField("", text: destinationBinding)
                        .padding(12)
                        .foregroundStyle(.gray)
                }
                .frame(height: 50)
        }
        .padding(.top, 20)
    }
    
    private var messageTextView: some View {
        VStack {
            HStack {
                Text("Message:")
                Spacer()
            }
            Rectangle()
                .foregroundStyle(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(lineWidth: 0.5)
                }
                .overlay {
                    TextEditor(text: messageBinding)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.black)
                        .clipShape(.rect(cornerRadius: 7))
                }
                .frame(height: 100)
        }
    }
    
    private var sendButton: some View {
        let isConnected = viewModel.viewState.isConnected
        
        return Button {
            viewModel.sendMessage()
        } label: {
            Text("Send")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .disabled(!isConnected)
    }
    
    private var logView: some View {
        VStack {
            HStack {
                Text("Logs")
                Spacer()
            }
            List(Array(viewModel.viewState.logs.enumerated()), id: \.offset) { item in
                Text(item.element)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
            }
            .clipShape(.rect(cornerRadius: 7.0))
        }
        .padding(.top, 16)
    }
}

#Preview {
    ContentView()
}
