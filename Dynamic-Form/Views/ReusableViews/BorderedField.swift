//
//  BorderedField.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import SwiftUI

/// Themed rounded border that turns red on error.
struct BorderedField: ViewModifier {
    let theme: ThemeColors
    let isError: Bool
 
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isError ? theme.error : theme.border, lineWidth: 1)
            )
    }
}
 
extension View {
    func borderedField(theme: ThemeColors, isError: Bool) -> some View {
        modifier(BorderedField(theme: theme, isError: isError))
    }
}

