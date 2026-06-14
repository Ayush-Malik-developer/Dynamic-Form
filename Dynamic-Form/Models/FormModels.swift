//
//  FormModels.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import Foundation

// MARK: - Top-level schema

struct FormSchema: Decodable {
    let title: String
    let theme: Theme
    let fields: [FormComponent]

    enum CodingKeys: String, CodingKey {
        case theme
        case title  = "form_title"
        case fields
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        theme = (try? c.decode(Theme.self, forKey: .theme)) ?? .default

        // Decode each element leniently: a thrown error (unknown type or a
        // malformed-but-known field) collapses to nil and is dropped, so a
        // single bad field never breaks the rest of the form.
        let raw = (try? c.decode([FailableDecodable<FormComponent>].self, forKey: .fields)) ?? []
        fields = raw
            .compactMap(\.value)
            .sorted { $0.order < $1.order }   // order by `order`, never by index
    }
}

// MARK: - Component types

enum ComponentType: String {
    case text     = "TEXT"
    case dropdown = "DROPDOWN"
    case toggle   = "TOGGLE"
    case checkbox = "CHECKBOX"
}

enum TextSubtype: String, Decodable {
    case plain     = "PLAIN"
    case multiline = "MULTILINE"
    case number    = "NUMBER"
    case uri       = "URI"
    case secure    = "SECURE"

    /// Unknown subtype falls back to PLAIN instead of failing.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TextSubtype(rawValue: raw) ?? .plain
    }
}

// MARK: - Polymorphic component

/// Shared attributes live here; the variant-specific payload lives in `kind`.
struct FormComponent: Identifiable {
    let id: String
    let order: Int
    let label: String
    let required: Bool
    let errorMessage: String?
    let kind: ComponentKind
}

enum ComponentKind {
    case text(TextSpec)
    case dropdown(DropdownSpec)
    case toggle(ToggleSpec)
    case checkbox(CheckboxSpec)
}

struct TextSpec {
    let subtype: TextSubtype
    let placeholder: String?
    let maxLength: Int?
    let supportingText: String?
    let defaultValue: String?
}

struct DropdownSpec {
    let allowMultiple: Bool
    let options: [Option]
    let defaultValues: [String]
}

struct ToggleSpec {
    let defaultValue: Bool
}

struct CheckboxSpec {
    let metadata: [String: String]
    let clickableTextColor: String?
    let defaultValue: Bool
}

struct Option: Decodable, Identifiable, Hashable {
    let id: String
    let label: String
}

// MARK: - Decoding

extension FormComponent: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, order, label, type, subtype, required, placeholder, options, metadata
        case errorMessage       = "error_message"
        case maxLength          = "max_length"
        case supportingText     = "supporting_text"
        case defaultValue       = "default_value"
        case defaultValues      = "default_values"
        case allowMultiple      = "allow_multiple"
        case clickableTextColor = "clickable_text_color"
    }

    /// Thrown for unrecognized component types so `FailableDecodable` drops them.
    struct UnsupportedComponentError: Error { let type: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        let rawType = try c.decode(String.self, forKey: .type)
        guard let type = ComponentType(rawValue: rawType) else {
            throw UnsupportedComponentError(type: rawType)   // e.g. DATE_PICKER
        }

        id           = try c.decode(String.self, forKey: .id)
        order        = (try? c.decode(Int.self, forKey: .order)) ?? .max
        label        = (try? c.decode(String.self, forKey: .label)) ?? ""
        required     = (try? c.decode(Bool.self, forKey: .required)) ?? false
        errorMessage = try? c.decode(String.self, forKey: .errorMessage)

        switch type {
        case .text:
            kind = .text(TextSpec(
                subtype:        (try? c.decode(TextSubtype.self, forKey: .subtype)) ?? .plain,
                placeholder:    try? c.decode(String.self, forKey: .placeholder),
                maxLength:      try? c.decode(Int.self, forKey: .maxLength),
                supportingText: try? c.decode(String.self, forKey: .supportingText),
                defaultValue:   try? c.decode(String.self, forKey: .defaultValue)
            ))

        case .dropdown:
            kind = .dropdown(DropdownSpec(
                allowMultiple:  (try? c.decode(Bool.self, forKey: .allowMultiple)) ?? false,
                options:        (try? c.decode([Option].self, forKey: .options)) ?? [],
                defaultValues:  (try? c.decode([String].self, forKey: .defaultValues)) ?? []
            ))

        case .toggle:
            kind = .toggle(ToggleSpec(
                defaultValue: (try? c.decode(Bool.self, forKey: .defaultValue)) ?? false
            ))

        case .checkbox:
            kind = .checkbox(CheckboxSpec(
                metadata:           (try? c.decode([String: String].self, forKey: .metadata)) ?? [:],
                clickableTextColor: try? c.decode(String.self, forKey: .clickableTextColor),
                defaultValue:       (try? c.decode(Bool.self, forKey: .defaultValue)) ?? false
            ))
        }
    }
}

/// Decodes `T` but swallows any error into `nil`. Used to make arrays lossy.
struct FailableDecodable<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}
