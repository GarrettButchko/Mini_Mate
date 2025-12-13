//
//  NetworkChecker.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/16/25.
//

import Network

/// Singleton utility to monitor real-time internet connectivity
class NetworkChecker {
    /// Shared instance for global access
    static let shared = NetworkChecker()
    
    /// Network monitor from Apple's Network framework
    private let monitor = NWPathMonitor()
    
    /// Background queue on which the monitor runs
    private let queue = DispatchQueue(label: "InternetConnectionMonitor")

    /// Flag indicating whether the device is currently connected to the internet
    var isConnected: Bool = false

    /// Initializes the network monitor and starts listening for changes
    init() {
        monitor.pathUpdateHandler = { path in
            // Update the `isConnected` flag based on current network status
            self.isConnected = (path.status == .satisfied)
            // Log result to console for debugging
            print(self.isConnected ? "✅ Internet is available" : "❌ No internet")
        }
        
        // Start monitoring on the background queue
        monitor.start(queue: queue)
    }
}
