//
//  ComponentView.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import SwiftUI

/// Renders the correct view for each component's kind.
struct ComponentView: View {
    let field: FormComponent
    @ObservedObject var viewModel: FormViewModel
 
    var body: some View {
        switch field.kind {
        case .text(let spec):
            TextComponentView(field: field, spec: spec, viewModel: viewModel)
        case .dropdown(let spec):
            DropdownComponentView(field: field, spec: spec, viewModel: viewModel)
        case .toggle(let spec):
            ToggleComponentView(field: field, spec: spec, viewModel: viewModel)
        case .checkbox(let spec):
            CheckboxComponentView(field: field, spec: spec, viewModel: viewModel)
        }
    }
}

