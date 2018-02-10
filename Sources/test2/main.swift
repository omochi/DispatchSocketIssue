import Foundation
import DispatchSocketIssue

// This is normal scinario.
// server: listen
// client: connect
// client: send
// server: receive
// close all

// okが出た後にポーズするとたまに固まる

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

    serverClientSocket.read.setEventHandler {
        serverClientSocket.read.suspend()
        f3()
    }
    serverClientSocket.read.resume()
}

func f3() {
    let str = serverClientSocket.receiveString()
    print("receive: [\(str)]")
    
    clientSocket.read.resume()
    clientSocket.write.resume()
    clientSocket.close()
    clientSocket = nil

    serverClientSocket.read.resume()
    serverClientSocket.write.resume()
    serverClientSocket.close()
    serverClientSocket = nil

    serverListenSocket.read.resume()
    serverListenSocket.write.resume()
    serverListenSocket.close()
    serverListenSocket = nil
    
    print("ok")
}

queue.async {
    f1()
}

dispatchMain()

