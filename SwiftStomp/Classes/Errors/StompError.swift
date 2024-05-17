//
//  StompError.swift
//  Pods
//
//  Created by Ahmad Daneshvar on 5/16/24.
//

public struct StompError: Error {
    public let description: String
    public let receiptId: String?
    public let type: StompErrorType
    
    init(type: StompErrorType, receiptId: String?, description: String) {
        self.description = description
        self.receiptId = receiptId
        self.type = type
    }
    
    init(error: Error, type: StompErrorType) {
        self.description = error.localizedDescription
        self.receiptId = nil
        self.type = type
    }
}
