//
//  DropdownComponentView.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import SwiftUI

// MARK: - DROPDOWN (single + multi-select)
 
struct DropdownComponentView: View {
    let field: FormComponent
    let spec: DropdownSpec
    @ObservedObject var viewModel: FormViewModel
 
    private var hasError: Bool { viewModel.errors[field.id] != nil }
 
    private var summary: String {
        let labels = viewModel.selectedLabels(for: field, spec: spec)
        return labels.isEmpty ? "Select…" : labels.joined(separator: ", ")
    }
 
    var body: some View {
        FieldShell(label: field.label,
                   required: field.required,
                   error: viewModel.errors[field.id],
                   theme: viewModel.theme) {
            Menu {
                if spec.allowMultiple {
                    // Toggle rows keep the menu open and show checkmarks.
                    ForEach(spec.options) { option in
                        Toggle(option.label,
                               isOn: viewModel.selectionToggle(field.id, optionID: option.id))
                    }
                } else {
                    ForEach(spec.options) { option in
                        Button {
                            viewModel.selectSingle(field.id, optionID: option.id)
                        } label: {
                            if viewModel.isSelected(field.id, optionID: option.id) {
                                Label(option.label, systemImage: "checkmark")
                            } else {
                                Text(option.label)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(summary)
                        .foregroundStyle(viewModel.theme.text)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(viewModel.theme.text.opacity(0.6))
                }
                .borderedField(theme: viewModel.theme, isError: hasError)
            }
        }
    }
}

