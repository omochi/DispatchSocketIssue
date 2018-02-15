import Foundation
import DispatchSocketIssue

// main loop suppress freeze issue

let mainQueue = DispatchQueue.main
let queue = DispatchQueue(label: "driver")
var serverListenSocket: Socket!
var serverClientSocket: Socket!
var clientSocket: Socket!
let port = 29876

func f1() {
    serverListenSocket = Socket(queue: queue)
    clientSocket = Socket(queue: queue)
    
    let group = DispatchGroup()
    
    group.enter()
    serverListenSocket.listen(port: port)
    serverListenSocket.read.setEventHandler {
        print("accept")
        serverListenSocket.read.suspend()
        
        serverClientSocket = serverListenSocket.accept()
        group.leave()
    }
    serverListenSocket.read.resume()
    
    group.enter()
    clientSocket.connect(addr: "127.0.0.1", port: port)
    clientSocket.write.setEventHandler {
        print("connected")
        clientSocket.write.suspend()
        
        group.leave()
    }
    clientSocket.write.resume()
    
    group.notify(queue: queue) {
        f2()
    }
}

func f2() {
    let msg = "hello socket"
    print("send: [\(msg)]")
    clientSocket.send(string: msg)

    serverClientSocket.read.resume()
    serverClientSocket.write.resume()
    serverClientSocket = nil
    
    clientSocket.read.resume()
    clientSocket.write.resume()
    clientSocket = nil
}

queue.async {
    f1()
}

func loop() {
    let c = Darwin.getchar()
    print(c)
    DispatchQueue.main.async {
        loop()
    }
}

loop()

dispatchMain()

