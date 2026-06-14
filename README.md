# Dynamic Form (JSON-Driven UI)

A single-screen iOS app whose entire UI is driven by a local JSON payload. The engine parses the JSON, renders the correct SwiftUI components in order, applies global theming from hex codes, and manages form state and validation — fully offline, no network.

## Requirements

- iOS 16.0+
- Swift / SwiftUI
- Xcode 15+

## Setup

1. Create a new iOS App project (SwiftUI lifecycle) and set the **minimum deployment target to iOS 16.0**.
2. Add these files to the app target:
   - `DynamicFormApp.swift` — app entry point + bundle loader
   - `Models.swift` — schema, polymorphic component model, resilient decoders
   - `Theme.swift` — theme model + `Color(hex:)`
   - `FormViewModel.swift` — observable state, bindings, validation, output
   - `FormViews.swift` — root view, dispatcher, reusable building blocks
   - `Components.swift` — the four concrete component views
   - `form.json` — the form definition
3. **Important:** make sure `form.json` is included in **Build Phases → Copy Bundle Resources** (check Target Membership). This is the most common setup mistake.
4. Build and run.

## How it works

The app reads `form.json` from the bundle, decodes it into a `FormSchema`, and renders it. Editing the JSON changes the form with no code changes.

```
form.json ─▶ SchemaLoader ─▶ FormSchema ─▶ FormViewModel ─▶ DynamicFormView
                                                                  │
                                                          ComponentView (dispatcher)
                                                                  │
                       ┌──────────────┬──────────────┬───────────┴──────────┐
                     TEXT          DROPDOWN         TOGGLE               CHECKBOX
```

## Supported components

| Type       | Notes |
|------------|-------|
| `TEXT`     | Subtypes: `PLAIN`, `MULTILINE`, `NUMBER`, `URI`, `SECURE` |
| `DROPDOWN` | Single- or multi-select (`allow_multiple`); UI shows labels, state tracks ids |
| `TOGGLE`   | Boolean switch |
| `CHECKBOX` | Checkbox with optional tappable metadata links |

### Field reference

Shared keys: `id`, `order`, `type`, `label`, `required`, `error_message`.

- **TEXT** — `subtype`, and optionally `placeholder`, `max_length`, `supporting_text`, `default_value`. When `max_length` is present, typing/pasting past the limit is blocked and a character counter appears.
- **DROPDOWN** — `options` (`[{ id, label }]`), `allow_multiple`, `default_values`.
- **TOGGLE** — `default_value`.
- **CHECKBOX** — `default_value`, `metadata` (`{ "Phrase": "https://…" }`), `clickable_text_color`. Any metadata phrase found in the label becomes a colored, tappable link.

Optional fields only take effect when present in the JSON.

## Design decisions

**Polymorphic decoding.** Each field is a `FormComponent` holding shared attributes plus a `kind: ComponentKind` enum carrying the type-specific payload (`.text`, `.dropdown`, `.toggle`, `.checkbox`). A custom `init(from:)` reads the `type` discriminator and builds the matching variant.

**Typed dynamic state.** The view model stores `[String: FieldValue]` where `FieldValue` is `.text | .bool | .selection(Set<String>)` — no `[String: Any]`. Dropdowns hold the set of selected option **ids**; the UI only ever displays labels.

**Ordering.** Fields are sorted by their `order` integer at decode time, never by array index.

**Theming.** Theme hex codes are parsed once into resolved `Color`s used for background, borders/accents, text, and errors. `Color(hex:)` accepts `#RGB`, `#RRGGBB`, and `#RRGGBBAA`.

## Validation & output

Pressing **Save** validates all `required` fields. Missing fields show their `error_message` inline (or a generated fallback) and the field border turns the theme's error color. A required `TOGGLE`/`CHECKBOX` must be **on** (consent semantics).

On success, the final key→value map is printed to the Xcode console and shown in a confirmation alert:

```json
{
  "accept_legal": true,
  "ad_networks": ["net_meta"],
  "campaign_name": "Summer Sale",
  "daily_budget": 50
}
```

Dropdowns emit an id array when `allow_multiple`, otherwise a single id string. Numeric text fields emit a `Double` when parseable.

## Resilience

Resilience is structural, not bolted on:

- **Unknown component type** (e.g. `DATE_PICKER`) → the decoder throws → a `FailableDecodable` wrapper collapses it to `nil` → `compactMap` drops it. The same path catches a *known* type with a malformed body, so partial corruption degrades instead of crashing.
- **Unknown text subtype** falls back to `PLAIN`.
- **Missing arrays/objects** (`fields`, `options`, `theme`) default to empty or sensible values.
- **Invalid hex** falls back to a default color.
- **Dropdown defaults** not present in `options` are discarded.
- A **top-level decode failure** shows a non-crashing error screen.

To see it in action, add a `DATE_PICKER` field and a field with a bogus `subtype` to `form.json` — both degrade gracefully.

## File overview

| File | Responsibility |
|------|----------------|
| `DynamicFormApp.swift` | App entry, root view, bundle JSON loader |
| `Models.swift` | Schema + polymorphic model + resilient decoders |
| `Theme.swift` | Theme model and hex → `Color` parsing |
| `FormViewModel.swift` | State, typed bindings, validation, output payload |
| `FormViews.swift` | Root view, component dispatcher, shared UI pieces |
| `Components.swift` | TEXT / DROPDOWN / TOGGLE / CHECKBOX views |
| `form.json` | The form definition |

## Known extension points

- Multi-select uses the `Toggle`-inside-`Menu` pattern to keep the menu open; a custom popover would be a richer alternative.
- `required` on a boolean is treated as "must be on" — change in `FormViewModel.validate()` if "just present" is wanted.
