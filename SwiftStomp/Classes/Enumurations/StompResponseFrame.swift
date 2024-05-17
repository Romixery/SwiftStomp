//
//  StompResponseFrame.swift
//  Pods
//
//  Created by Ahmad Daneshvar on 5/16/24.
//

public enum StompResponseFrame : String{
    case connected = "CONNECTED"
    case message = "MESSAGE"
    case receipt = "RECEIPT"
    case error = "ERROR"
}

