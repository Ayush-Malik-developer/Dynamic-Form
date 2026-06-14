//
//  ToggleComponentView.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import SwiftUI

// MARK: - TOGGLE
 
struct ToggleComponentView: View {
    let field: FormComponent
    let spec: ToggleSpec
    @ObservedObject var viewModel: FormViewModel
 
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: viewModel.boolBinding(field.id)) {
                Text(field.label)
                    .font(.subheadline)
                    .foregroundStyle(viewModel.theme.text)
            }
            .tint(viewModel.theme.text)
 
            if let error = viewModel.errors[field.id] {
                Text(error).font(.caption).foregroundStyle(viewModel.theme.error)
            }
        }
    }
}

