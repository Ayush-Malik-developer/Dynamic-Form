//
//  DynamicFormView.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import SwiftUI

struct DynamicFormView: View {
    @StateObject private var viewModel: FormViewModel
 
    init(schema: FormSchema) {
        _viewModel = StateObject(wrappedValue: FormViewModel(schema: schema))
    }
 
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !viewModel.schema.title.isEmpty {
                    Text(viewModel.schema.title)
                        .font(.title.bold())
                        .foregroundStyle(viewModel.theme.text)
                }
 
                ForEach(viewModel.schema.fields) { field in
                    ComponentView(field: field, viewModel: viewModel)
                }
 
                SaveButton(theme: viewModel.theme) { viewModel.save() }
                    .padding(.top, 8)
            }
            .padding()
        }
        .background(viewModel.theme.background.ignoresSafeArea())
        .alert("Submitted", isPresented: $viewModel.showResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.submissionResult ?? "")
        }
    }
}


