//
//  UDPServer.swift
//  TestUDP
//
//  Created by Extollite on 15/10/2020.
//

import Foundation
import NIO


private final class EchoHandler: ChannelInboundHandler {
    public typealias InboundIn = AddressedEnvelope<ByteBuffer>
    public typealias OutboundOut = AddressedEnvelope<ByteBuffer>
    
    let listener : UDPTest
    
    public init(_ listener : UDPTest){
        self.listener = listener
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        NSLog("\(data)")
        let packet = self.unwrapInboundIn(data)
        listener.client = packet.remoteAddress
        listener.data = data
        context.write(data, promise: nil)
    }

    public func channelReadComplete(context: ChannelHandlerContext) {
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.flush()
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        NSLog("error: \(error)")

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }
}

class UDPTest {
    var task : RepeatedTask?
    var channel : Channel?
    var client : SocketAddress?
    var data : NIOAny?
    
    func run(_ group : EventLoopGroup){
        // We don't need more than one thread, as we're creating only one datagram channel.
        var bootstrap = DatagramBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

            // Set the handlers that are applied to the bound channel
            .channelInitializer { channel in
                // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
                channel.pipeline.addHandler(EchoHandler(self))
            }

        let defaultHost = "0.0.0.0"
        let defaultPort = 9999

        enum BindTo {
            case ip(host: String, port: Int)
            case unixDomainSocket(path: String)
        }

        let bindTarget: BindTo = .ip(host: defaultHost, port: defaultPort)

        do {
            channel = try { () -> Channel in
                switch bindTarget {
                case .ip(let host, let port):
                    return try bootstrap.bind(host: host, port: port).wait()
                case .unixDomainSocket(let path):
                    return try bootstrap.bind(unixDomainSocketPath: path).wait()
                }
                }()
            
            tick()
            
            print("Server started and listening on \(channel!.localAddress!)")
            
            try channel!.closeFuture.wait()

            print("Server closed")
        } catch {
            NSLog("\(error)")
        }

    }
    
    func tick(){
        task = channel!.eventLoop.next().scheduleRepeatedTask(initialDelay: TimeAmount.milliseconds(0), delay: TimeAmount.milliseconds(Int64(0.01 * 1000)), {
            repeatedTask in
            if self.client != nil {
                self.channel!.writeAndFlush(self.data!)
            }
        })
    }
}
