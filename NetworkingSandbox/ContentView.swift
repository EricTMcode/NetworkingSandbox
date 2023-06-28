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
    var path: String
    var type: T.Type
    var method = HTTPMethod.get
    var headers = [String: String]()
}

extension Endpoint where T == [News] {
    static let headlines = Endpoint(path: "headlines.json", type: [News].self)
}

extension Endpoint where T == [Message] {
    static let messages = Endpoint(path: "messages.json", type: [Message].self)
}

enum HTTPMethod: String {
    case delete, get, patch, post, put
    
    var rawValue: String {
        String(describing: self).uppercased()
    }
}

struct AppEnvironment {
    var name: String
    var baseURL: URL
    var session: URLSession
    
    static let production = AppEnvironment(
        name: "Production",
        baseURL: URL(string: "https://hws.dev")!,
        session: {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = [
                "APIKey": "production-key-from-keychain"
            ]
            return URLSession(configuration: configuration)
        }()
    )
    
    #if DEBUG
    static let testing = AppEnvironment(
        name: "Testing",
        baseURL: URL(string: "https://hws.dev")!,
        session: {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            configuration.httpAdditionalHeaders = [
                "APIKey": "test-key"
            ]
            return URLSession(configuration: configuration)
        }()
    )
    #endif
}

struct NetworkManager {
    var environment: AppEnvironment
    
    func fetch<T>(_ resource: Endpoint<T>, with data: Data? = nil) async throws -> T {
        guard let url = URL(string: resource.path, relativeTo: environment.baseURL) else {
            throw URLError(.unsupportedURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = resource.method.rawValue
        request.httpBody = data
        request.allHTTPHeaderFields = resource.headers
        
        var (data, _) = try await environment.session.data(for: request)
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    func fetch<T>(_ resource: Endpoint<T>, with data: Data? = nil, attempts: Int, retryDelay: Double = 1) async throws -> T {
        do {
            print("Attempting to fetch (Attemps remaining: \(attempts)")
            return try await fetch(resource, with: data)
        } catch {
            if attempts > 1 {
                try await Task.sleep(for: .microseconds(Int(retryDelay * 1000)))
                return try await fetch(resource, with: data, attempts: attempts - 1, retryDelay: retryDelay)
            } else {
                throw error
            }
        }
    }
    
    func fetch<T>(_ resource: Endpoint<T>, with data: Data? = nil, defaultValue: T) async throws -> T {
        do {
            return try await fetch(resource, with: data)
        } catch {
            return defaultValue
        }
    }
}

struct NetworkManagerKey: EnvironmentKey {
    static var defaultValue = NetworkManager(environment: .testing)
}

extension EnvironmentValues {
    var networkManager: NetworkManager {
        get { self[NetworkManagerKey.self] }
        set { self[NetworkManagerKey.self] = newValue }
    }
}

struct ContentView: View {
    @State private var headlines = [News]()
    @State private var messages = [Message]()
    
    @Environment(\.networkManager) var networkManager
    
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
