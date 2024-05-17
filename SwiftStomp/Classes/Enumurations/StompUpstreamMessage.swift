//
//  StompUpstreamMessage.swift
//  Pods
//
//  Created by Ahmad Daneshvar on 5/16/24.
//

import Foundation

public enum StompUpstreamMessage {
    case text(message : String, messageId : String, destination : String, headers : [String : String])
    case data(data: Data,  messageId : String, destination : String, headers : [String : String])
}
