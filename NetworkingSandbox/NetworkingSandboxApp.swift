//
//  NetworkingSandboxApp.swift
//  NetworkingSandbox
//
//  Created by Eric on 27/06/2023.
//

import SwiftUI

@main
struct NetworkingSandboxApp: App {
    @State private var networkManager = NetworkManager(environment: .testing)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.networkManager, networkManager)
        }
    }
}
