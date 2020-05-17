# SwiftStomp

## An elegent Stomp client for swift, Base on Starscream websocket library.

[![CI Status](https://img.shields.io/travis/Romixery/SwiftStomp.svg?style=flat)](https://travis-ci.org/Romixery/SwiftStomp)
[![Version](https://img.shields.io/cocoapods/v/SwiftStomp.svg?style=flat)](https://cocoapods.org/pods/SwiftStomp)
[![License](https://img.shields.io/cocoapods/l/SwiftStomp.svg?style=flat)](https://cocoapods.org/pods/SwiftStomp)
[![Platform](https://img.shields.io/cocoapods/p/SwiftStomp.svg?style=flat)](https://cocoapods.org/pods/SwiftStomp)

## Fetures
- Easy to setup, Very light-weight
- Support all STOMP V1.2 frames. CONNECT, SUBSCRIBE, RECEIPT and ....
- Auto object serialize using native JSON `Encoder`.
- Send and receive `Data` and `Text`
- Logging

## Usage

### Setup
Quick initialize with minimum requirements:
```Swift
let url = URL(string: "ws://192.168.88.252:8081/socket")!
        
self.swiftStomp = SwiftStomp(host: url) ///< Create instance
self.swiftStomp.delegate = self ///< Set delegate

self.swiftStomp.connect() ///< Connect
```

### Delegate
Implement all delegate methods to handle all STOMP events!
```swift
func onConnect(swiftStomp : SwiftStomp, connectType : StompConnectType)
    
func onDisconnect(swiftStomp : SwiftStomp, disconnectType : StompDisconnectType)

func onMessageReceived(swiftStomp : SwiftStomp, message : Any?, messageId : String, destination : String)

func onReceipt(swiftStomp : SwiftStomp, receiptId : String)

func onError(swiftStomp : SwiftStomp, briefDescription : String, fullDescription : String?, receiptId : String?, type : StompErrorType)
```

### Connect
Full `Connect` signature:
```Swift
self.swiftStomp.connect(timeout: 5.0, acceptVersion: "1.1,1.2")
```

### Subscription
Full `Subsribe` signature. Please notice to subscribe only when you ensure connected to the STOMP. I suggest do it in the `onConnect` delegate with `connectType == .toStomp`

```swift
swiftStomp.subscribe(to: "/topic/greeting", mode: .clientIndividual)
```

### Send Message
You have full controll for sending messages. Full signature is as follows:
```swift
swiftStomp.send(body: "This is message's text body", to: "/app/greeting", receiptId: "msg-\(Int.random(in: 0..<1000))", headers: [:])
```

### Example
Please refer to the Example for more functionalities

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- iOS 10 or above

## Installation

SwiftStomp is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftStomp'
```

## Author

Ahmad Daneshvar, romixery@gmail.com

## License

SwiftStomp is available under the Apache, Version 2.0 license. See the LICENSE file for more info.
