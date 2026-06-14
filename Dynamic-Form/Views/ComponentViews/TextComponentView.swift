//
//  TextComponentView.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import SwiftUI

// MARK: - TEXT (PLAIN / MULTILINE / NUMBER / URI / SECURE)
 
struct TextComponentView: View {
    let field: FormComponent
    let spec: TextSpec
    @ObservedObject var viewModel: FormViewModel
 
    private var hasError: Bool { viewModel.errors[field.id] != nil }
 
    private var binding: Binding<String> {
        viewModel.textBinding(
            field.id,
            maxLength: spec.maxLength,
            sanitize: spec.subtype == .number ? FormViewModel.numericSanitizer : { $0 }
        )
    }
 
    var body: some View {
        FieldShell(label: field.label,
                   required: field.required,
                   error: viewModel.errors[field.id],
                   theme: viewModel.theme) {
            VStack(alignment: .leading, spacing: 4) {
                input
                    .foregroundStyle(viewModel.theme.text)
                    .tint(viewModel.theme.text)
                    .borderedField(theme: viewModel.theme, isError: hasError)
 
                if spec.supportingText != nil || spec.maxLength != nil {
                    HStack {
                        if let supporting = spec.supportingText {
                            Text(supporting)
                                .foregroundStyle(viewModel.theme.text.opacity(0.6))
                        }
                        Spacer()
                        if let max = spec.maxLength {
                            // Character counter (only present when max_length is)
                            Text("\(binding.wrappedValue.count)/\(max)")
                                .foregroundStyle(viewModel.theme.text.opacity(0.6))
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }
 
    @ViewBuilder private var input: some View {
        let placeholder = spec.placeholder ?? ""
        switch spec.subtype {
        case .plain:
            TextField(placeholder, text: binding)
 
        case .multiline:
            TextField(placeholder, text: binding, axis: .vertical)
                .lineLimit(3...8)
 
        case .number:
            TextField(placeholder, text: binding)
                .keyboardType(.decimalPad)
 
        case .uri:
            TextField(placeholder, text: binding)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
 
        case .secure:
            SecureField(placeholder, text: binding)
        }
    }
}

