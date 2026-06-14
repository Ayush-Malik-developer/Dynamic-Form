//
//  ContentView.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import SwiftUI

/// Loads and decodes the schema once, then hands it to the form.
/// If loading/parsing fails entirely, we show a non-crashing error state.
struct ContentView: View {
    private let schema = SchemaLoader.load(named: "form")
 
    var body: some View {
        if let schema {
            DynamicFormView(schema: schema)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "doc.questionmark")
                    .font(.largeTitle)
                Text("Could not load form.json")
                    .font(.headline)
                Text("Make sure form.json is added to the app target's bundle resources.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

 
enum SchemaLoader {
    static func load(named name: String) -> FormSchema? {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        // A top-level decode failure returns nil rather than crashing.
        return try? JSONDecoder().decode(FormSchema.self, from: data)
    }
}
