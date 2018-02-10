import Foundation

// must access from queue
public class Socket {
    public convenience init(queue: DispatchQueue) {
        let fd = Darwin.socket(PF_INET, SOCK_STREAM, 0)
        precondition(fd != -1)
        self.init(queue: queue, fd: fd)
    }
    
    public init(queue: DispatchQueue,
                fd: Int32)
    {
        self.queue = queue
        self.fd = fd
        self.read = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        self.write = DispatchSource.makeWriteSource(fileDescriptor: fd, queue: queue)
        
        let st = Darwin.fcntl(fd, F_SETFL, O_NONBLOCK)
        precondition(st != -1)
    }
    
    public let queue: DispatchQueue
    public let fd: Int32
    public let read: DispatchSourceRead
    public let write: DispatchSourceWrite
    
    public func close() {
        let st = Darwin.close(fd)
        if st == -1 {
            let str = String(cString: Darwin.strerror(errno))
            print(str, errno)
        }
        precondition(st != -1)
    }
    
    public func listen(port: Int) {
        var yes: CInt = 1
        
        var st = Darwin.setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, UInt32(MemoryLayout<CInt>.size))
        precondition(st != -1)
        
        var addr = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                               sin_family: UInt8(AF_INET),
                               sin_port: NSSwapHostShortToBig(UInt16(port)),
                               sin_addr: in_addr(s_addr: UInt32(INADDR_ANY)),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        st = UnsafeMutablePointer(&addr).withMemoryRebound(to: sockaddr.self, capacity: 1) { p in
            Darwin.bind(fd, p, UInt32(MemoryLayout<sockaddr_in>.size))
        }
        precondition(st != -1)
        
        st = Darwin.listen(fd, 8)
        precondition(st != -1)
    }
    
    public func accept() -> Socket {
        let fd = Darwin.accept(self.fd, nil, nil)
        precondition(fd != -1)
        
        return Socket(queue: queue, fd: fd)
    }
    
    public func connect(addr: String, port: Int) {
        var addr = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                               sin_family: UInt8(AF_INET),
                               sin_port: NSSwapHostShortToBig(UInt16(port)),
                               sin_addr: in_addr.init(s_addr: inet_addr(addr)),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        let st = UnsafeMutablePointer(&addr).withMemoryRebound(to: sockaddr.self, capacity: 1) { p in
            Darwin.connect(fd, p, UInt32(MemoryLayout<sockaddr_in>.size))
        }
        if st == -1 {
            if errno != EINPROGRESS {
                preconditionFailure()
            }
        }
    }
    
    public func receive(size: Int) -> Data {
        var data = Data(count: size)
        let st = data.withUnsafeMutableBytes { p in
            Darwin.recv(fd, p, size, 0)
        }
        data.count = st
        return data
    }
    
    public func receiveString() -> String {
        let data = receive(size: 1024)
        return String(data: data, encoding: .utf8)!
    }
    
    public func send(data: Data) {
        let st = data.withUnsafeBytes { p in
            Darwin.send(fd, p, data.count, 0)
        }
        precondition(st != -1)
    }
    
    public func send(string: String) {
        send(data: string.data(using: .utf8)!)
    }
}
