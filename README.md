# SwiftStomp

## An elegent Stomp client for swift, based on iOS `URLSessionWebSocketTask`.

<!-- [![CI Status](https://img.shields.io/travis/Romixery/SwiftStomp.svg?style=flat)](https://travis-ci.org/Romixery/SwiftStomp) -->
[![Version](https://img.shields.io/cocoapods/v/SwiftStomp.svg?style=flat)](https://cocoapods.org/pods/SwiftStomp)
[![License](https://img.shields.io/cocoapods/l/SwiftStomp.svg?style=flat)](https://cocoapods.org/pods/SwiftStomp)
[![Platform](https://img.shields.io/cocoapods/p/SwiftStomp.svg?style=flat)](https://cocoapods.org/pods/SwiftStomp)

|SwiftStomp|
|---------|
|<img width=400 src="https://raw.githubusercontent.com/Romixery/SwiftStomp/assets/Example/SwiftStomp/Assets/SS-Logo.jpg" />|
|<img width=400 src="https://raw.githubusercontent.com/Romixery/SwiftStomp/assets/Example/SwiftStomp/Assets/Screenshot.gif" />|

# TOC
- [SwiftStomp](#swiftstomp)
  - [An elegent Stomp client for swift, based on iOS `URLSessionWebSocketTask`.](#an-elegent-stomp-client-for-swift-based-on-ios-urlsessionwebsockettask)
- [TOC](#toc)
  - [Fetures](#fetures)
  - [Usage](#usage)
    - [Setup](#setup)
    - [Delegate](#delegate)
    - [Upstreams](#upstreams)
    - [Connect](#connect)
    - [Subscription](#subscription)
    - [Send Message](#send-message)
    - [Connection Status check](#connection-status-check)
    - [Manual Pinging](#manual-pinging)
    - [Auto Pinging](#auto-pinging)
  - [Test Environment](#test-environment)
  - [Example](#example)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [CocoaPods](#cocoapods)
    - [Swift Package Manager](#swift-package-manager)
  - [Author](#author)
  - [Contributors](#contributors)
  - [License](#license)


## Fetures
- Easy to setup, Very light-weight
- Support all STOMP V1.2 frames. CONNECT, SUBSCRIBE, RECEIPT and ....
- Auto object serialize using native JSON `Encoder`.
- Send and receive `Data` and `Text`
- Auto reconnect
- Logging
- Reactive programming ready.

## Usage

### Setup
Quick initialize with minimum requirements:
```Swift
let url = URL(string: "ws://192.168.88.252:8081/socket")!
        
self.swiftStomp = SwiftStomp(host: url) //< Create instance
self.swiftStomp.delegate = self //< Set delegate
self.swiftStomp.autoReconnect = true //< Auto reconnect on error or cancel

self.swiftStomp.connect() //< Connect
```

### Delegate
Implement all delegate methods to handle all STOMP events!
```swift
func onConnect(swiftStomp : SwiftStomp, connectType : StompConnectType)
    
func onDisconnect(swiftStomp : SwiftStomp, disconnectType : StompDisconnectType)

func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers : [String : String])

func onReceipt(swiftStomp : SwiftStomp, receiptId : String)

func onError(swiftStomp : SwiftStomp, briefDescription : String, fullDescription : String?, receiptId : String?, type : StompErrorType)
```

### Upstreams
In the case that you are more comfort to use `Combine` publishers, instead of delegate, SwiftStomp can report all `event`s, `message`s and `receiptId`s through upstreams. This functionality shines, especially, when you want to use SwiftStomp in the SwiftUI projects. Please check the example project, to see how we can use upstreams, in SwiftUI projects.

```swift
// ** Subscribe to events: [Connect/Disconnect/Errors]
swiftStomp.eventsUpstream
    .receive(on: RunLoop.main)
    .sink { event in
               
        switch event {
        case let .connected(type):
            print("Connected with type: \(type)")
        case .disconnected(_):
            print("Disconnected with type: \(type)")
        case let .error(error):
            print("Error: \(error)")
        }
    }
    .store(in: &subscriptions)

// ** Subscribe to messages: [Text/Data]
swiftStomp.messagesUpstream
    .receive(on: RunLoop.main)
    .sink { message in
               
        switch message {
        case let .text(message, messageId, destination, _):
            print("\(Date().formatted()) [id: \(messageId), at: \(destination)]: \(message)\n")
        case let .data(data, messageId, destination, _):
            print("Data message with id `\(messageId)` and binary length `\(data.count)` received at destination `\(destination)`")
        }
    }
    .store(in: &subscriptions)

// ** Subscribe to receipts: [Receipt IDs]
swiftStomp.receiptUpstream
    .sink { receiptId in
        print("SwiftStop: Receipt received: \(receiptId)")
    }
    .store(in: &subscriptions)
```

### Connect
Full `Connect` signature:
```Swift
self.swiftStomp.connect(timeout: 5.0, acceptVersion: "1.1,1.2")
```
If you want to reconnect after any un-expected disconnections, enable `autoReconnect` property.
```swift
self.swiftStomp.autoReconnect = true
```
> <b><i>Notice:</b> If you disconnect manually using `disconnect()` function, and `autoReconnect` is enable, socket will try to reconnect after disconnection. If this is not thing you want, please disable `autoReconnect` before call the `disconnect()`.</i>
 
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

### Connection Status check
You can check the status of the SwiftStomp by using `connectionStatus` property:

```swift
switch self.swiftStomp.connectionStatus {
case .connecting:
    print("Connecting to the server...")
case .socketConnected:
    print("Scoket is connected but STOMP as sub-protocol is not connected yet.")
case .fullyConnected:
    print("Both socket and STOMP is connected. Ready for messaging...")
case .socketDisconnected:
    print("Socket is disconnected")
}
```

### Manual Pinging
You control for sending WebSocket 'Ping' messages. Full signature is as follows:
```swift
func ping(data: Data = Data(), completion: (() -> Void)? = nil)
```
You will receive 'Pong' message as a response.

### Auto Pinging
If you want to ensure your connection will still alive, you can use 'Auto Ping' feature. Full signature is as follows:
```swift
func enableAutoPing(pingInterval: TimeInterval = 10)
```
The 'autoPing' feature, will send `ping` command to websocket server, after `pingInterval` time ellapsed from last sent `sendFrame` commands (ex: `connect`, `ack`, `send` ....).

> <b><i>Notice:</b> Auto ping is disabled by default. So you have to enable it after you connected to the server. Also please consider, if you disconnect from the server or call `disconnect()` explicitly, you must call `enableAutoPing()` again.</i>

To disable the 'Auto Ping' functionality, use `disableAutoPing()`.


## Test Environment
This example was test with a <b>[Spring Boot](https://spring.io)</b> websocket server with <b>[RabbitMQ](https://www.rabbitmq.com/)</b> as an external message broker.

## Example
Please refer to the Example for more functionalities

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- iOS 13 or above, macOS 10.15 or above, tvOS 13 or above

## Installation

### CocoaPods
SwiftStomp is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftStomp'
```
### Swift Package Manager
From Xcode 11, you can use [Swift Package Manager](https://swift.org/package-manager/) to add SwiftStomp to your project.

1. Select File > Swift Packages > Add Package Dependency. Enter `https://github.com/Romixery/SwiftStomp.git` in the "Choose Package Repository" dialog.
2. In the next page, specify the version resolving rule as "Up to Next Major" with "1.0.4" as its earliest version.
3. After Xcode checking out the source and resolving the version, you can choose the "SwiftStomp" library and add it to your app target.


## Author

Ahmad Daneshvar, romixery@gmail.com

## Contributors
Very special thanks to:
@stuartcamerondeakin, @hunble, @aszter

## License

SwiftStomp is available under the MIT license. See the LICENSE file for more info.
