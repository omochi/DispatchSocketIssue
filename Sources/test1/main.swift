import Foundation
import DispatchSocketIssue

let mainQueue = DispatchQueue.main
let queue = DispatchQueue(label: "driver")
var socket: Socket!

func f1() {
    socket = Socket(queue: queue)
    
    // if DispatchSource is suspended, it will crash when release it.
    // if resume them before, it will not crash.
    
//    socket.read.resume()
//    socket.write.resume()
    
    socket.close()
    socket = nil
    
    print("ok")
}

queue.async {
    f1()
}

dispatchMain()

