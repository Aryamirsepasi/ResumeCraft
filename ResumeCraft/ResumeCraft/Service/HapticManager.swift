//
//  HapticManager.swift
//  Eris.
//
//  Created by Ignacio Palacio on 19/6/25.
//

import UIKit
import CoreHaptics
import SwiftUI

class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    private var engine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // User preference for haptics
    @Published var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled")
        }
    }
    
    private init() {
        // Load user preference
        self.hapticsEnabled = UserDefaults.standard.bool(forKey: "hapticsEnabled")
        if !UserDefaults.standard.bool(forKey: "hapticsPreferenceSet") {
            // Default to true on first launch
            self.hapticsEnabled = true
            UserDefaults.standard.set(true, forKey: "hapticsEnabled")
            UserDefaults.standard.set(true, forKey: "hapticsPreferenceSet")
        }
        
        // Prepare generators
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
        
        // Setup Core Haptics for custom patterns
        setupCoreHaptics()
    }
    
    private func setupCoreHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine creation error: \(error)")
        }
    }
    
    // MARK: - Basic Haptics
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactSoft.impactOccurred()
        case .rigid:
            impactRigid.impactOccurred()
        @unknown default:
            impactMedium.impactOccurred()
        }
    }
    
    func selection() {
        guard hapticsEnabled else { return }
        selectionFeedback.selectionChanged()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        notificationFeedback.notificationOccurred(type)
    }
    
    // MARK: - Semantic Haptics
    
    func buttonTap() {
        impact(.light)
    }
    
    func toggleSwitch() {
        impact(.medium)
    }
    
    func messageReceived() {
        impact(.soft)
    }
    
    func messageSent() {
        impact(.light)
    }
    
    func modelDownloadComplete() {
        notification(.success)
    }
    
    func error() {
        notification(.error)
    }
    
    func warning() {
        notification(.warning)
    }
    
    func modelSelected() {
        selection()
    }
    
    func navigationPop() {
        impact(.soft)
    }
    
    func pullToRefresh() {
        impact(.medium)
    }
    
    func longPressStarted() {
        impact(.heavy)
    }
    
    func dragStarted() {
        impact(.light)
    }
    
    func dragEnded() {
        impact(.medium)
    }
    
    // MARK: - Custom Haptic Patterns
    
    func typing() {
        guard hapticsEnabled else { return }
        
        // Very light tap for typing
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            // Fallback to simple impact
            impact(.light)
        }
    }
    
    func processingStart() {
        guard hapticsEnabled else { return }
        
        // Double tap pattern for processing start
        impact(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.light)
        }
    }
    
    func processingComplete() {
        guard hapticsEnabled else { return }
        
        // Success pattern: light -> medium -> light
        impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impact(.light)
            }
        }
    }
    
    func bounce() {
        guard hapticsEnabled else { return }
        
        // Bouncing effect
        let events: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0.15),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ], relativeTime: 0.25)
        ]
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            // Fallback
            impact(.medium)
        }
    }
    
    // MARK: - Prepare Haptics
    
    func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    func hapticFeedback(_ type: HapticType, trigger: some Equatable) -> some View {
        self.onChange(of: trigger) { _, _ in
            HapticManager.shared.performHaptic(type)
        }
    }
    
    func onTapWithHaptic(perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            HapticManager.shared.buttonTap()
            action()
        }
    }
}

enum HapticType {
    case buttonTap
    case toggle
    case selection
    case success
    case error
    case warning
    case messageSent
    case messageReceived
    case modelSelected
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case custom(() -> Void)
}

extension HapticManager {
    func performHaptic(_ type: HapticType) {
        switch type {
        case .buttonTap:
            buttonTap()
        case .toggle:
            toggleSwitch()
        case .selection:
            selection()
        case .success:
            notification(.success)
        case .error:
            error()
        case .warning:
            warning()
        case .messageSent:
            messageSent()
        case .messageReceived:
            messageReceived()
        case .modelSelected:
            modelSelected()
        case .impact(let style):
            impact(style)
        case .custom(let action):
            if hapticsEnabled {
                action()
            }
        }
    }
}