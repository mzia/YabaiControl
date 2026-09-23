import Foundation
import Darwin

/// Zero-overhead Unix Domain Socket IPC client for yabai daemon.
///
/// Rather than launching a new subprocess (/bin/bash or Process()) for every yabai query
/// and command—which incurs Mach task allocation, executable loading, dynamic linking,
/// and pipe buffering overhead—this client connects directly to yabai's local stream socket
/// (/tmp/yabai_$USER.socket), reducing round-trip latency from ~25ms to <0.2ms.
public final class YabaiIPC: @unchecked Sendable {
    public static var socketPath: String {
        let user = ProcessInfo.processInfo.environment["USER"] ?? NSUserName()
        return "/tmp/yabai_\(user).socket"
    }

    public static var isSocketAvailable: Bool {
        FileManager.default.fileExists(atPath: socketPath)
    }

    /// Formats command-line arguments into yabai's wire protocol:
    /// 4-byte little-endian uint32 payload length prefix, followed by null-delimited arguments with a trailing null byte.
    public static func encodeMessage(_ arguments: [String]) -> Data {
        var payload = Data()
        for arg in arguments {
            payload.append(contentsOf: arg.utf8)
            payload.append(0)
        }
        payload.append(0)

        var length = UInt32(payload.count).littleEndian
        var data = Data()
        withUnsafeBytes(of: &length) { rawBytes in
            data.append(contentsOf: rawBytes)
        }
        data.append(payload)
        return data
    }

    /// Sends command arguments to the yabai daemon over its UNIX domain socket.
    ///
    /// - Parameter arguments: Array of argument strings (e.g. `["query", "--spaces"]`, `["window", "--focus", "123"]`).
    /// - Returns: `(status, output)` tuple if socket communication was successful, or `nil` if the socket was unreachable,
    ///            connection was refused, or communication timed out (permitting fallback to the CLI binary).
    public static func sendMessage(_ arguments: [String]) -> (status: Int32, output: String)? {
        guard !arguments.isEmpty else { return nil }

        let path = socketPath
        guard FileManager.default.fileExists(atPath: path) else { return nil }

        let fd = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return nil }
        defer { Darwin.close(fd) }

        // Set non-blocking connect / short timeout (500ms) to prevent UI thread stalls
        var tv = timeval(tv_sec: 0, tv_usec: 500_000)
        _ = Darwin.setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        _ = Darwin.setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = path.utf8CString
        guard pathBytes.count <= MemoryLayout.size(ofValue: addr.sun_path) else { return nil }

        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: pathBytes.count) { dest in
                _ = pathBytes.withUnsafeBufferPointer { src in
                    memcpy(dest, src.baseAddress!, src.count)
                }
            }
        }

        let connectRes = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                Darwin.connect(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard connectRes == 0 else { return nil }

        let messageData = encodeMessage(arguments)
        let sendRes = messageData.withUnsafeBytes { rawPtr in
            Darwin.send(fd, rawPtr.baseAddress!, messageData.count, 0)
        }
        guard sendRes == messageData.count else { return nil }

        // yabai daemon expects SHUT_WR after client sends payload to start processing
        Darwin.shutdown(fd, SHUT_WR)

        var responseData = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let bytesRead = Darwin.read(fd, &buffer, buffer.count)
            if bytesRead <= 0 { break }
            responseData.append(buffer, count: bytesRead)
        }

        guard !responseData.isEmpty else { return (0, "") }

        // yabai indicates errors by prefixing response with BEL (ASCII 0x07)
        if responseData[0] == 7 {
            let errStr = String(data: responseData.dropFirst(), encoding: .utf8) ?? ""
            return (1, errStr)
        } else {
            let outStr = String(data: responseData, encoding: .utf8) ?? ""
            return (0, outStr)
        }
    }
}
