//
//  FormViewModel.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import Foundation
import SwiftUI
import Combine

/// One slot per field. Keeps the dynamic state strongly typed.
enum FieldValue: Equatable {
    case text(String)
    case bool(Bool)
    case selection(Set<String>)   // set of option ids
}

@MainActor
final class FormViewModel: ObservableObject {
    let schema: FormSchema
    let theme: ThemeColors

    @Published private var values: [String: FieldValue] = [:]
    @Published var errors: [String: String] = [:]
    @Published var submissionResult: String?
    @Published var showResult = false

    init(schema: FormSchema) {
        self.schema = schema
        self.theme = ThemeColors(schema.theme)
        seedDefaults()
    }

    // MARK: Defaults

    private func seedDefaults() {
        for field in schema.fields {
            switch field.kind {
            case .text(let spec):
                values[field.id] = .text(spec.defaultValue ?? "")

            case .dropdown(let spec):
                // Keep only defaults that actually exist in the options list.
                let valid = Set(spec.options.map(\.id))
                let defaults = Set(spec.defaultValues).intersection(valid)
                let initial = spec.allowMultiple ? defaults : Set(defaults.prefix(1))
                values[field.id] = .selection(initial)

            case .toggle(let spec):
                values[field.id] = .bool(spec.defaultValue)

            case .checkbox(let spec):
                values[field.id] = .bool(spec.defaultValue)
            }
        }
    }

    // MARK: Text bindings

    /// `sanitize` runs first (e.g. numeric filtering), then `maxLength` truncates.
    func textBinding(_ id: String,
                     maxLength: Int? = nil,
                     sanitize: @escaping (String) -> String = { $0 }) -> Binding<String> {
        Binding(
            get: {
                if case .text(let s) = self.values[id] { return s }
                return ""
            },
            set: { raw in
                var v = sanitize(raw)
                if let max = maxLength, v.count > max { v = String(v.prefix(max)) }
                self.values[id] = .text(v)
                self.clearError(id)
            }
        )
    }

    /// Digits plus a single optional decimal separator.
    static func numericSanitizer(_ input: String) -> String {
        var result = ""
        var hasDot = false
        for ch in input {
            if ch.isNumber {
                result.append(ch)
            } else if ch == "." && !hasDot {
                hasDot = true
                result.append(ch)
            }
        }
        return result
    }

    // MARK: Boolean bindings (toggle + checkbox)

    func boolBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: {
                if case .bool(let b) = self.values[id] { return b }
                return false
            },
            set: { newValue in
                self.values[id] = .bool(newValue)
                self.clearError(id)
            }
        )
    }

    func toggleBool(_ id: String) {
        let current = boolBinding(id).wrappedValue
        boolBinding(id).wrappedValue = !current
    }

    // MARK: Selection (dropdown)

    func isSelected(_ id: String, optionID: String) -> Bool {
        if case .selection(let set) = values[id] { return set.contains(optionID) }
        return false
    }

    /// For multi-select Toggle rows inside a Menu.
    func selectionToggle(_ id: String, optionID: String) -> Binding<Bool> {
        Binding(
            get: { self.isSelected(id, optionID: optionID) },
            set: { isOn in
                guard case .selection(var set) = self.values[id] else { return }
                if isOn { set.insert(optionID) } else { set.remove(optionID) }
                self.values[id] = .selection(set)
                self.clearError(id)
            }
        )
    }

    /// For single-select Button rows.
    func selectSingle(_ id: String, optionID: String) {
        values[id] = .selection([optionID])
        clearError(id)
    }

    func selectedLabels(for field: FormComponent, spec: DropdownSpec) -> [String] {
        spec.options
            .filter { isSelected(field.id, optionID: $0.id) }
            .map(\.label)
    }

    private func clearError(_ id: String) {
        if errors[id] != nil { errors[id] = nil }
    }

    // MARK: Validation

    @discardableResult
    func validate() -> Bool {
        var newErrors: [String: String] = [:]
        for field in schema.fields where field.required {
            let isEmpty: Bool
            switch values[field.id] {
            case .text(let s):
                isEmpty = s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .selection(let set):
                isEmpty = set.isEmpty
            case .bool(let b):
                isEmpty = (b == false)            // a required toggle/checkbox must be ON
            case .none:
                isEmpty = true
            }
            if isEmpty {
                newErrors[field.id] = field.errorMessage ?? "\(field.label) is required."
            }
        }
        errors = newErrors
        return newErrors.isEmpty
    }

    // MARK: Submission

    func save() {
        guard validate() else { return }
        let payload = outputPayload()

        if let data = try? JSONSerialization.data(
                withJSONObject: payload,
                options: [.prettyPrinted, .sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            print("✅ Form submitted:\n\(json)")
            submissionResult = json
        } else {
            submissionResult = "\(payload)"
        }
        showResult = true
    }

    /// Builds the final key→value map. Dropdown returns option id(s); the UI
    /// only ever showed labels, but state tracked ids throughout.
    private func outputPayload() -> [String: Any] {
        var out: [String: Any] = [:]
        for field in schema.fields {
            guard let value = values[field.id] else { continue }
            switch (field.kind, value) {
            case (.dropdown(let spec), .selection(let set)):
                // Preserve the original option order in the output.
                let ordered = spec.options.map(\.id).filter(set.contains)
                out[field.id] = spec.allowMultiple ? ordered : (ordered.first ?? "")

            case (.text(let spec), .text(let s)):
                if spec.subtype == .number, let n = Double(s) {
                    out[field.id] = n
                } else {
                    out[field.id] = s
                }

            case (.toggle, .bool(let b)), (.checkbox, .bool(let b)):
                out[field.id] = b

            default:
                break
            }
        }
        return out
    }
}
