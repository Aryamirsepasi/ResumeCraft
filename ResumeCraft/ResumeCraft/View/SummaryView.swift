//
//  SummaryView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 07.08.25.
//

import SwiftUI

struct SummaryView: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary").font(.headline)
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No summary yet.").foregroundStyle(.secondary)
            } else {
                Text(text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
