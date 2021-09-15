# SwiftStomp

## An elegent Stomp client for swift, Base on [Starscream](https://github.com/daltoniam/Starscream) websocket library.

<!-- [![CI Status](https://img.shields.io/travis/Romixery/SwiftStomp.svg?style=flat)](https://travis-ci.org/Romixery/SwiftStomp) -->
[![Version](https://img.shields.io/cocoapods/v/SwiftStomp.svg?style=flat)](https://cocoapods.org/pods/SwiftStomp)
[![License](https://img.shields.io/cocoapods/l/SwiftStomp.svg?style=flat)](https://cocoapods.org/pods/SwiftStomp)
[![Platform](https://img.shields.io/cocoapods/p/SwiftStomp.svg?style=flat)](https://cocoapods.org/pods/SwiftStomp)

![SwiftStomp](https://raw.githubusercontent.com/Romixery/SwiftStomp/assets/Example/SwiftStomp/Assets/SS-Logo.jpg)

## Fetures
- Easy to setup, Very light-weight
- Support all STOMP V1.2 frames. CONNECT, SUBSCRIBE, RECEIPT and ....
- Auto object serialize using native JSON `Encoder`.
- Send and receive `Data` and `Text`
- Auto reconnect
- Logging

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

- iOS 10 or above

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

## License

SwiftStomp is available under the MIT license. See the LICENSE file for more info.
