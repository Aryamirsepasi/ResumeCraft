//
//  GlassEffectHelpers.swift
//  ResumeCraft
//
//  Glass effect wrappers and helpers for modern UI
//

import SwiftUI

/// Container view that enables Liquid Glass effects to merge and blend
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(spacing: CGFloat = 40.0, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        // SwiftUI's native glass container - available in iOS 26+
        if #available(iOS 26, *) {
            SwiftUI.GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            // Fallback for older iOS versions
            content()
                .background(.ultraThinMaterial)
        }
    }
}

/// Glass button style for interactive elements
extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle {
        GlassButtonStyle()
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            configuration.label
                .glassEffect(.regular.interactive())
        } else {
            configuration.label
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}

/// Card view with glass effect
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool
    @ViewBuilder let content: () -> Content
    
    init(
        cornerRadius: CGFloat = 16,
        tint: Color? = nil,
        interactive: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.interactive = interactive
        self.content = content
    }
    
    var body: some View {
        if #available(iOS 26, *) {
            content()
                .padding()
                .glassEffect(
                    glassConfig,
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            content()
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
    
    @available(iOS 26, *)
    private var glassConfig: Glass {
        var glass = Glass.regular
        if let tint = tint {
            glass = glass.tint(tint)
        }
        if interactive {
            glass = glass.interactive()
        }
        return glass
    }
}
