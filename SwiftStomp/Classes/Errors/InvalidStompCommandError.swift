//
//  InvalidStompCommandError.swift
//  Pods
//
//  Created by Ahmad Daneshvar on 5/16/24.
//

public class InvalidStompCommandError : Error{
    
    var localizedDescription: String {
        return "Invalid STOMP command"
    }
}

