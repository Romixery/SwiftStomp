//
//  StompError.swift
//  Pods
//
//  Created by Ahmad Daneshvar on 5/16/24.
//

public struct StompError: Error {
    public let localizedDescription: String
    public let receiptId: String?
    public let type: StompErrorType
    
    init(type: StompErrorType, receiptId: String?, localizedDescription: String) {
        self.localizedDescription = localizedDescription
        self.receiptId = receiptId
        self.type = type
    }
    
    init(error: Error, type: StompErrorType) {
        self.localizedDescription = error.localizedDescription
        self.receiptId = nil
        self.type = type
    }
}

extension StompError: CustomStringConvertible {
    public var description: String {
        "StompError(\(type)) [receiptId: \(String(describing: receiptId))]: \(localizedDescription)"
    }
}
