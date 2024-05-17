//
//  StompCommandHeader.swift
//  Pods
//
//  Created by Ahmad Daneshvar on 5/16/24.
//

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
