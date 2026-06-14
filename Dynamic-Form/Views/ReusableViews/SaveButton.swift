//
//  SaveButton.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import SwiftUI

struct SaveButton: View {
    let theme: ThemeColors
    let action: () -> Void
 
    var body: some View {
        Button(action: action) {
            Text("Save")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.text)
                .foregroundStyle(theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    SaveButton(theme: ThemeColors(Theme.default), action: {})
}
