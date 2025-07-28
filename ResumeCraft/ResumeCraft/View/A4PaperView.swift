//
//  A4PaperView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct A4PaperView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        ZStack {
            Color.white
            content // No extra padding here
        }
        .frame(width: 595, height: 842)
        .cornerRadius(8)
        .shadow(radius: 4)
        .border(.gray.opacity(0.4), width: 1)
    }
}

