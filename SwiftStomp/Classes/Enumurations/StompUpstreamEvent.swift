//
//  StompUpstreamEvent.swift
//  Pods
//
//  Created by Ahmad Daneshvar on 5/16/24.
//

public enum StompUpstreamEvent {
    case connected(type: StompConnectType)
    case disconnected(type: StompDisconnectType)
    case error(error: StompError)
}
