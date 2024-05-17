//
//  StompHeaderBuilder.swift
//  Pods
//
//  Created by Ahmad Daneshvar on 5/16/24.
//

import Foundation

public class StompHeaderBuilder{
    private var headers = [String : String]()
    
    static func add(key : StompCommonHeader, value : Any) -> StompHeaderBuilder{
        return StompHeaderBuilder(key: key.rawValue, value: value)
    }
    
    private init(key : String, value : Any){
        self.headers[key] = "\(value)"
    }
    
    func add(key : StompCommonHeader, value : Any) -> StompHeaderBuilder{
        self.headers[key.rawValue] = "\(value)"
        
        return self
    }
    
    var get : [String : String]{
        return self.headers
    }
}
