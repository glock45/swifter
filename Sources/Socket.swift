//
//  Socket.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation


public enum SocketError: Error {
    case socketCreationFailed(String)
    case socketSettingReUseAddrFailed(String)
    case localPathTooLong(String)
    case bindFailed(String)
    case listenFailed(String)
    case writeFailed(String)
    case getPeerNameFailed(String)
    case convertingPeerNameFailed
    case getNameInfoFailed(String)
    case acceptFailed(String)
    case recvFailed(String)
    case getSockNameFailed(String)
    case notNetworkSocket
    case notLocalSocket
}

open class Socket: Hashable, Equatable {
        
    let socketFileDescriptor: Int32
    private var shutdown = false

    
    public init(socketFileDescriptor: Int32) {
        self.socketFileDescriptor = socketFileDescriptor
    }
    
    deinit {
        close()
    }
    
    public var hashValue: Int { return Int(self.socketFileDescriptor) }
    
    public func close() {
        if shutdown {
            return
        }
        shutdown = true
        Socket.close(self.socketFileDescriptor)
    }

    private func getSockaddrIn() throws -> sockaddr_in {
        var addr = sockaddr_in()
        try withUnsafePointer(to: &addr) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(socketFileDescriptor, UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw SocketError.getSockNameFailed(Errno.description())
            }
        }
        guard (Int32(addr.sin_family) == AF_INET) || (Int32(addr.sin_family) == AF_INET6) else {
            throw SocketError.notNetworkSocket
        }
        return addr
    }
    
    private func getSockaddrUn() throws -> sockaddr_un {
        var addr = sockaddr_un()
        try withUnsafePointer(to: &addr) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_un>.size)
            if getsockname(socketFileDescriptor, UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw SocketError.getSockNameFailed(Errno.description())
            }
        }
        guard Int32(addr.sun_family) == AF_LOCAL else {
            throw SocketError.notLocalSocket
        }
        return addr
    }

    public func port() throws -> in_port_t {
        var addr = try getSockaddrIn()
        return try withUnsafePointer(to: &addr) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(socketFileDescriptor, UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw SocketError.getSockNameFailed(Errno.description())
            }
            #if os(Linux)
                return ntohs(addr.sin_port)
            #else
                return Int(OSHostByteOrder()) != OSLittleEndian ? addr.sin_port.littleEndian : addr.sin_port.bigEndian
            #endif
        }
    }
    
    public func isIPv4() throws -> Bool {
        var addr: sockaddr_in
        do {
            addr = try getSockaddrIn()
        } catch SocketError.notNetworkSocket {
            return false
        } catch {
            throw error
        }
        return Int32(addr.sin_family) == AF_INET
    }

    public func localPath() throws -> String {
        var addr = try getSockaddrUn()
        return try withUnsafePointer(to: &addr) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_un>.size)
            if getsockname(socketFileDescriptor, UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw SocketError.getSockNameFailed(Errno.description())
            }
            return withUnsafePointer(to: &addr.sun_path) { path in
                let pathLen = MemoryLayout.size(ofValue: addr.sun_path)
                return path.withMemoryRebound(to: UInt8.self, capacity: pathLen) { bytes in
                    return String(cString: bytes)
                }
            }
        }
    }

    public func isLocal() throws -> Bool {
        do {
            let _ = try getSockaddrUn()
        } catch SocketError.notLocalSocket {
            return false
        } catch {
            throw error
        }
        return true
    }
    
    public func writeUTF8(_ string: String) throws {
        try writeUInt8(ArraySlice(string.utf8))
    }
    
    public func writeUInt8(_ data: [UInt8]) throws {
        try writeUInt8(ArraySlice(data))
    }
    
    public func writeUInt8(_ data: ArraySlice<UInt8>) throws {
        try data.withUnsafeBufferPointer {
            try writeBuffer($0.baseAddress!, length: data.count)
        }
    }

    public func writeData(_ data: NSData) throws {
        try writeBuffer(data.bytes, length: data.length)
    }
    
    public func writeData(_ data: Data) throws {
        try data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> Void in
            try self.writeBuffer(pointer, length: data.count)
        }
    }

    private func writeBuffer(_ pointer: UnsafeRawPointer, length: Int) throws {
        var sent = 0
        while sent < length {
            #if os(Linux)
                let s = send(self.socketFileDescriptor, pointer + sent, Int(length - sent), Int32(MSG_NOSIGNAL))
            #else
                let s = write(self.socketFileDescriptor, pointer + sent, Int(length - sent))
            #endif
            if s <= 0 {
                throw SocketError.writeFailed(Errno.description())
            }
            sent += s
        }
    }
    
    open func read() throws -> UInt8 {
        var buffer = [UInt8](repeating: 0, count: 1)
        let next = recv(self.socketFileDescriptor as Int32, &buffer, Int(buffer.count), 0)
        if next <= 0 {
            throw SocketError.recvFailed(Errno.description())
        }
        return buffer[0]
    }
    
    private static let CR = UInt8(13)
    private static let NL = UInt8(10)
    
    public func readLine() throws -> String {
        var characters: String = ""
        var n: UInt8 = 0
        repeat {
            n = try self.read()
            if n > Socket.CR { characters.append(Character(UnicodeScalar(n))) }
        } while n != Socket.NL
        return characters
    }
    
    public func peername() throws -> String {
        var addr = sockaddr(), len: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
        if getpeername(self.socketFileDescriptor, &addr, &len) != 0 {
            throw SocketError.getPeerNameFailed(Errno.description())
        }
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) != 0 {
            throw SocketError.getNameInfoFailed(Errno.description())
        }
        return String(cString: hostBuffer)
    }
    
    public class func setNoSigPipe(_ socket: Int32) {
        #if os(Linux)
            // There is no SO_NOSIGPIPE in Linux (nor some other systems). You can instead use the MSG_NOSIGNAL flag when calling send(),
            // or use signal(SIGPIPE, SIG_IGN) to make your entire application ignore SIGPIPE.
        #else
            // Prevents crashes when blocking calls are pending and the app is paused ( via Home button ).
            var no_sig_pipe: Int32 = 1
            setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(MemoryLayout<Int32>.size))
        #endif
    }
    
    public class func close(_ socket: Int32) {
        #if os(Linux)
            let _ = Glibc.close(socket)
        #else
            let _ = Darwin.close(socket)
        #endif
    }
}

public func == (socket1: Socket, socket2: Socket) -> Bool {
    return socket1.socketFileDescriptor == socket2.socketFileDescriptor
}
