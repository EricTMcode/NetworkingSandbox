//
//  ContentView.swift
//  NetworkingSandbox
//
//  Created by Eric on 27/06/2023.
//

import SwiftUI

struct News: Decodable, Identifiable {
    var id: Int
    var title: String
    var strap: String
    var url: URL
}

struct Message: Decodable, Identifiable {
    var id: Int
    var from: String
    var text: String
}

struct Endpoint <T: Decodable> {
    var url: URL
    var type: T.Type
}

extension Endpoint where T == [News] {
    static let headlines = Endpoint(url: URL(string: "https://hws.dev/headlines.json")!, type: [News].self)
}

extension Endpoint where T == [Message] {
    static let messages = Endpoint(url: URL(string: "https://hws.dev/messages.json")!, type: [Message].self)
}

struct NetworkManager {
    func fetch<T>(_ resource: Endpoint<T>) async throws -> T {
        var request = URLRequest(url: resource.url)
        var (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

struct ContentView: View {
    @State private var headlines = [News]()
    @State private var messages = [Message]()
    
    let networkManager = NetworkManager()
    
    var body: some View {
        List {
            Section("Headlines") {
                ForEach(headlines) { headline in
                    VStack(alignment: .leading) {
                        Text(headline.title)
                            .font(.headline)
                        
                        Text(headline.strap)
                    }
                }
            }
            
            Section("Messages") {
                ForEach(messages) { message in
                    VStack(alignment: .leading) {
                        Text(message.from)
                            .font(.headline)
                        
                        Text(message.text)
                    }
                }
            }
        }
        .task {
            do {
                headlines = try await networkManager.fetch(.headlines)
                messages = try await networkManager.fetch(.messages)
            } catch {
                print("Error handling is a smart move!")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
