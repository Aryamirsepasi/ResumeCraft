//
//  NetworkMonitor.swift
//  Eris.
//
//  Created by Ignacio Palacio on 22/6/25.
//

import Foundation
import Network
import SwiftUI

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var isExpensive = false // Cellular or personal hotspot
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    static let shared = NetworkMonitor()
    
    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
        
        var displayName: String {
            switch self {
            case .wifi:
                return "Wi-Fi"
            case .cellular:
                return "Cellular"
            case .wired:
                return "Wired"
            case .unknown:
                return "Unknown"
            }
        }
        
        var icon: String {
            switch self {
            case .wifi:
                return "wifi"
            case .cellular:
                return "antenna.radiowaves.left.and.right"
            case .wired:
                return "cable.connector"
            case .unknown:
                return "questionmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .wifi, .wired:
                return .green
            case .cellular:
                return .orange
            case .unknown:
                return .gray
            }
        }
    }
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wired
                } else {
                    self?.connectionType = .unknown
                }
                
                print("Network status - Connected: \(path.status == .satisfied), Type: \(self?.connectionType.displayName ?? "unknown"), Expensive: \(path.isExpensive)")
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func shouldShowCellularWarning() -> Bool {
        return connectionType == .cellular
    }
    
    deinit {
        monitor.cancel()
    }
}

