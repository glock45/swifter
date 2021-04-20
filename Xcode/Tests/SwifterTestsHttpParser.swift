//
//  SwifterTests.swift
//  SwifterTests
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
@testable import Swifter

class SwifterTestsHttpParser: XCTestCase {

    /// A specialized Socket which creates a linked socket pair with a pipe, and
    /// immediately writes in fixed data. This enables tests to static fixture
    /// data into the regular Socket flow.
    class TestSocket: Socket {
        init(_ content: String) {
            /// Create an array to hold the read and write sockets that pipe creates
            var fds = [Int32](repeating: 0, count: 2)
            fds.withUnsafeMutableBufferPointer { ptr in
                let received = pipe(ptr.baseAddress!)
                guard received >= 0 else { fatalError("Pipe error!") }
            }

            // Extract the read and write handles into friendly variables
            let fdRead = fds[0]
            let fdWrite = fds[1]

            // Set non-blocking I/O on both sockets. This is required!
            _ = fcntl(fdWrite, F_SETFL, O_NONBLOCK)
            _ = fcntl(fdRead, F_SETFL, O_NONBLOCK)

            // Push the content bytes into the write socket.
            content.withCString { stringPointer in
                // Count will be either >=0 to indicate bytes written, or -1
                // if the bytes will be written later (non-blocking).
                let count = write(fdWrite, stringPointer, content.lengthOfBytes(using: .utf8) + 1)
                guard count != -1 || errno == EAGAIN else { fatalError("Write error!") }
            }

            // Close the write socket immediately. The OS will add an EOF byte
            // and the read socket will remain open.
            #if os(Linux)
            Glibc.close(fdWrite)
            #else
            Darwin.close(fdWrite) // the super instance will close fdRead in deinit!
            #endif

            super.init(socketFileDescriptor: fdRead)
        }
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    func testParser() {
        let parser = HttpParser()

        do {
            _ = try parser.readHttpRequest(TestSocket(""))
            XCTAssert(false, "Parser should throw an error if socket is empty.")
        } catch { }

        do {
            _ = try parser.readHttpRequest(TestSocket("12345678"))
            XCTAssert(false, "Parser should throw an error if status line has single token.")
        } catch { }

        do {
            _ = try parser.readHttpRequest(TestSocket("GET HTTP/1.0"))
            XCTAssert(false, "Parser should throw an error if status line has not enough tokens.")
        } catch { }

        do {
            _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0"))
            XCTAssert(false, "Parser should throw an error if there is no next line symbol.")
        } catch { }

        do {
            _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0"))
            XCTAssert(false, "Parser should throw an error if there is no next line symbol.")
        } catch { }

        do {
            _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\r"))
            XCTAssert(false, "Parser should throw an error if there is no next line symbol.")
        } catch { }

        do {
            _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\n"))
            XCTAssert(false, "Parser should throw an error if there is no 'Content-Length' header.")
        } catch { }

        do {
            _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\r\nContent-Length: 0\r\n\r\n"))
        } catch {
            XCTAssert(false, "Parser should not throw any errors if there is a valid 'Content-Length' header.")
        }

        do {
            _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nContent-Length: 0\r\n\n"))
        } catch {
            XCTAssert(false, "Parser should not throw any errors if there is a valid 'Content-Length' header.")
        }

        do {
            _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\r\nContent-Length: -1\r\n\r\n"))
        } catch let error {
            let error = error as? HttpParserError
            XCTAssertNotNil(error)
            XCTAssertEqual(error!, HttpParserError.negativeContentLength)
        }

        do {
            _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nContent-Length: 5\n\n12345"))
        } catch {
            XCTAssert(false, "Parser should not throw any errors if there is a valid 'Content-Length' header.")
        }

        do {
            _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nContent-Length: 10\r\n\n"))
            XCTAssert(false, "Parser should throw an error if request' body is too short.")
        } catch { }

        do { // test payload less than 1 read segmant
            let contentLength = Socket.kBufferLength - 128
            let bodyString = [String](repeating: "A", count: contentLength).joined(separator: "")

            let payload = "GET / HTTP/1.0\nContent-Length: \(contentLength)\n\n".appending(bodyString)
            let request = try parser.readHttpRequest(TestSocket(payload))

            XCTAssert(bodyString.lengthOfBytes(using: .utf8) == contentLength, "Has correct request size")

            let unicodeBytes = bodyString.utf8.map { return $0 }
            XCTAssert(request.body == unicodeBytes, "Request body must be correct")
        } catch { }

        do { // test payload equal to 1 read segmant
            let contentLength = Socket.kBufferLength
            let bodyString = [String](repeating: "B", count: contentLength).joined(separator: "")
            let payload = "GET / HTTP/1.0\nContent-Length: \(contentLength)\n\n".appending(bodyString)
            let request = try parser.readHttpRequest(TestSocket(payload))

            XCTAssert(bodyString.lengthOfBytes(using: .utf8) == contentLength, "Has correct request size")

            let unicodeBytes = bodyString.utf8.map { return $0 }
            XCTAssert(request.body == unicodeBytes, "Request body must be correct")
        } catch { }

        do { // test very large multi-segment payload
            let contentLength = Socket.kBufferLength * 4
            let bodyString = [String](repeating: "C", count: contentLength).joined(separator: "")
            let payload = "GET / HTTP/1.0\nContent-Length: \(contentLength)\n\n".appending(bodyString)
            let request = try parser.readHttpRequest(TestSocket(payload))

            XCTAssert(bodyString.lengthOfBytes(using: .utf8) == contentLength, "Has correct request size")

            let unicodeBytes = bodyString.utf8.map { return $0 }
            XCTAssert(request.body == unicodeBytes, "Request body must be correct")
        } catch { }

        var resp = try? parser.readHttpRequest(TestSocket("GET /open?link=https://www.youtube.com/watch?v=D2cUBG4PnOA HTTP/1.0\nContent-Length: 10\n\n1234567890"))

        XCTAssertEqual(resp?.queryParams.filter({ $0.0 == "link"}).first?.1, "https://www.youtube.com/watch?v=D2cUBG4PnOA")
        XCTAssertEqual(resp?.method, "GET", "Parser should extract HTTP method name from the status line.")
        XCTAssertEqual(resp?.path, "/open", "Parser should extract HTTP path value from the status line.")
        XCTAssertEqual(resp?.headers["content-length"], "10", "Parser should extract Content-Length header value.")

        resp = try? parser.readHttpRequest(TestSocket("POST / HTTP/1.0\nContent-Length: 10\n\n1234567890"))
        XCTAssertEqual(resp?.method, "POST", "Parser should extract HTTP method name from the status line.")

        resp = try? parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nHeader1: 1:1:34\nHeader2: 12345\nContent-Length: 0\n\n"))
        XCTAssertEqual(resp?.headers["header1"], "1:1:34", "Parser should properly extract header name and value in case the value has ':' character.")

        resp = try? parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nHeader1: 1\nHeader2: 2\nContent-Length: 0\n\n"))
        XCTAssertEqual(resp?.headers["header1"], "1", "Parser should extract multiple headers from the request.")
        XCTAssertEqual(resp?.headers["header2"], "2", "Parser should extract multiple headers from the request.")

        resp = try? parser.readHttpRequest(TestSocket("GET /some/path?subscript_query[]=1&subscript_query[]=2 HTTP/1.0\nContent-Length: 10\n\n1234567890"))
        var queryPairs = resp?.queryParams ?? []
        XCTAssertEqual(queryPairs.count, 2)
        XCTAssertEqual(queryPairs.first?.0, "subscript_query[]")
        XCTAssertEqual(queryPairs.first?.1, "1")
        XCTAssertEqual(queryPairs.last?.0, "subscript_query[]")
        XCTAssertEqual(queryPairs.last?.1, "2")
        XCTAssertEqual(resp?.method, "GET", "Parser should extract HTTP method name from the status line.")
        XCTAssertEqual(resp?.path, "/some/path", "Parser should extract HTTP path value from the status line.")
        XCTAssertEqual(resp?.headers["content-length"], "10", "Parser should extract Content-Length header value.")

        resp = try? parser.readHttpRequest(TestSocket("GET /path[]/param?a[]=1&a[]=2&b=%20 HTTP/1.0\r\nContent-Length: 0\r\n\r\n"))
        queryPairs = resp?.queryParams ?? []

        XCTAssertEqual(resp?.path, "/path[]/param")
        if queryPairs.count == 3 {
            XCTAssertEqual(queryPairs[0].0, "a[]")
            XCTAssertEqual(queryPairs[0].1, "1")
            XCTAssertEqual(queryPairs[1].0, "a[]")
            XCTAssertEqual(queryPairs[1].1, "2")
            XCTAssertEqual(queryPairs[2].0, "b")
            XCTAssertEqual(queryPairs[2].1, " ")
        } else {
            XCTFail("queryPairs count should be 3")
        }
    }
}
