//
//  ContentView.swift
//  TestUDP
//
//  Created by Extollite on 15/10/2020.
//

import SwiftUI
import NIO

class EventLoopGroupModel : ObservableObject {
    @Published var group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
}

struct ContentView: View {
    @StateObject var groupModel = EventLoopGroupModel()
    
    var body: some View {
        Button(action: {
            DispatchQueue.global(qos: .background).async {
                UDPTest().run(self.groupModel.group)
            }
        }) {
            Text( "RUN" )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
