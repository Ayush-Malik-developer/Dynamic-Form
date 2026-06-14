//
//  CheckboxComponentView.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import SwiftUI

// MARK: - CHECKBOX (with tappable metadata links)
 
struct CheckboxComponentView: View {
    let field: FormComponent
    let spec: CheckboxSpec
    @ObservedObject var viewModel: FormViewModel
    @Environment(\.openURL) private var openURL
 
    private var isOn: Bool { viewModel.boolBinding(field.id).wrappedValue }
 
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    viewModel.toggleBool(field.id)
                } label: {
                    Image(systemName: isOn ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(isOn ? viewModel.theme.text
                                              : viewModel.theme.border)
                }
                .buttonStyle(.plain)
 
                Text(attributedLabel)
                    .font(.subheadline)
                    .foregroundStyle(viewModel.theme.text)
            }
 
            if let error = viewModel.errors[field.id] {
                Text(error).font(.caption).foregroundStyle(viewModel.theme.error)
            }
        }
    }
 
    /// Turns each `metadata` key found in the label into a colored, tappable link.
    private var attributedLabel: AttributedString {
        var attr = AttributedString(field.label)
        let linkColor = spec.clickableTextColor
            .map { Color(hex: $0, fallback: .blue) } ?? .blue
 
        for (phrase, urlString) in spec.metadata {
            guard let range = attr.range(of: phrase),
                  let url = URL(string: urlString) else { continue }
            attr[range].link = url
            attr[range].foregroundColor = linkColor
            attr[range].underlineStyle = .single
        }
        return attr
    }
}

