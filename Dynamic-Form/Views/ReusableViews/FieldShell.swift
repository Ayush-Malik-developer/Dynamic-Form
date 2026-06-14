//
//  FieldShell.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import SwiftUI

/// Label (+ required asterisk) on top, content in the middle, error below.
struct FieldShell<Content: View>: View {
    let label: String
    let required: Bool
    let error: String?
    let theme: ThemeColors
    @ViewBuilder var content: () -> Content
 
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !label.isEmpty {
                HStack(spacing: 2) {
                    Text(label).fontWeight(.medium)
                    if required { Text("*").foregroundStyle(theme.error) }
                }
                .font(.subheadline)
                .foregroundStyle(theme.text)
            }
            content()
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(theme.error)
            }
        }
    }
}

#Preview {
    FieldShell(label: "Hi", required: true, error: "Hello", theme: ThemeColors(Theme.default), content: {
        
    })
}
