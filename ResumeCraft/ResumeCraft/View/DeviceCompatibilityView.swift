//
//  DeviceCompatibilityView.swift
//  Eris.
//
//  Created by Ignacio Palacio on 19/6/25.
//

import SwiftUI

struct DeviceCompatibilityView: View {
    var body: some View {
        VStack(spacing: 25) {
            // Icon based on device status
            Image(systemName: iconName)
                .font(.system(size: 70))
                .foregroundColor(iconColor)
            
            // Device info
            VStack(spacing: 10) {
                Text(DeviceUtils.deviceDescription)
                    .font(.title)
                    .fontWeight(.bold)
                
                if DeviceUtils.chipFamily != .unknown && DeviceUtils.chipFamily != .unsupported {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.secondary)
                        Text(DeviceUtils.chipDescription)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if DeviceUtils.isSimulator {
                    Label("Running in Simulator", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            // Compatibility message
            Text(DeviceUtils.compatibilityMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Compatible devices list
            if !DeviceUtils.canRunMLX {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Compatible Devices:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        DeviceRow(icon: "iphone", title: "iPhone", subtitle: "11 Pro/Pro Max, SE 2nd gen, 12 series or newer")
                        DeviceRow(icon: "ipad", title: "iPad", subtitle: "M1/M2/M4 iPad Pro, M1/M2 iPad Air")
                        DeviceRow(icon: "macbook", title: "Mac", subtitle: "Any Mac with Apple Silicon")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Debug info
            if !DeviceUtils.isSimulator {
                Text("Device Model: \(DeviceUtils.deviceModel)")
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .padding(.top)
            }
        }
        .padding()
    }
    
    private var iconName: String {
        if DeviceUtils.canRunMLX {
            return "checkmark.circle.fill"
        } else if DeviceUtils.isSimulator {
            return "xmark.octagon.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        if DeviceUtils.canRunMLX {
            return .green
        } else if DeviceUtils.isSimulator {
            return .red
        } else {
            return .orange
        }
    }
}

struct DeviceRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

