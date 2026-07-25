# UI Architecture Rules — Flutter Project

---

## 1. Overview

This document defines the complete UI architecture rules for the project.

The UI layer is responsible only for:

* rendering widgets
* composing pages
* displaying state
* delegating actions to Cubits

> UI MUST NOT contain business logic or state decisions.

---

# 2. Page Structure Rules

## 2.1 Page Responsibility

Each page is:

* a **composition layer only**
* responsible for arranging widgets
* not responsible for logic or state management

---

## 2.2 Page Size Rule

* Maximum page size: **150 lines**
* If exceeded:

  * split into sub-widgets
  * move logic to Cubits
  * extract reusable components

---

## 2.3 Page Structure Pattern

Every page must follow:

```
Page
 ├── Header Widget
 ├── Form / Content Widget
 ├── Action Widgets
 ├── Footer Widget
```

---

## 2.4 Forbidden in Pages

❌ Business logic
❌ API calls
❌ State decisions
❌ Controller creation
❌ FormKey creation
❌ Dependency injection calls
❌ Complex conditions

---

# 3. Sub-Widgets Rules

## 3.1 Purpose

Sub-widgets are used to:

* split UI into readable blocks
* improve reuse
* reduce page size

---

## 3.2 Structure Rule

Each feature has:

```
views/{feature}/widgets/
```

Example:

```
login/
 ├── login_header_widget.dart
 ├── login_form_widget.dart
 ├── login_button_widget.dart
 ├── login_footer_widget.dart
```

---

## 3.3 Widget Responsibility

Widgets are:

* purely UI
* stateless when possible
* receive all dependencies via constructor

---

## 3.4 Forbidden in Widgets

❌ Cubit creation
❌ Service calls
❌ Business logic
❌ Navigation logic decisions
❌ State mutation

---

# 4. State Management Rules (UI Side)

## 4.1 Bloc Usage Rule

* Use `BlocBuilder` ONLY where UI must rebuild
* Never wrap full page unless required

---

## 4.2 Scoped Rebuild Rule

✔ Rebuild only affected widget areas
❌ Do not wrap entire page with BlocBuilder unless necessary

---

## 4.3 State Consumption Rule

UI only reads state:

* success
* loading
* error
* empty

UI MUST NOT:

* interpret business rules
* transform data logic-heavy
* modify cubit state

---

## 4.4 DataStateBuilderWidget Rule

All async UI must use:

* `DataStateBuilderWidget`

It handles:

* loading
* empty
* error
* success

---

# 5. Dependency Injection Rules (UI Layer)

## 5.1 Forbidden Rule

❌ NO `sl<T>()` inside UI

---

## 5.2 Correct Pattern

Dependencies must be injected from outside:

```dart
ProductsPage(
  cubit: cubit,
  actionsCubit: actionsCubit,
)
```

---

## 5.3 Responsibility Split

| Layer             | Responsibility       |
| ----------------- | -------------------- |
| Composition Layer | inject dependencies  |
| UI Layer          | consume dependencies |

---

# 6. Controllers & Form Rules

## 6.1 Rule

❌ No controllers inside UI
❌ No FormKey inside UI

---

## 6.2 Correct Location

All must live inside Cubit:

* TextEditingController
* FocusNode
* GlobalKey<FormState>

---

## 6.3 UI Usage

UI only receives:

```dart
controller: cubit.emailController
formKey: cubit.formKey
```

---

# 7. Core Widgets Usage Rules

## 7.1 Core First Rule

Before creating any widget:

✔ CHECK `core/components` first

---

## 7.2 Reuse Rule

If widget exists in core:

❌ DO NOT recreate it
✔ ALWAYS reuse it

---

## 7.3 Core vs Feature Decision

| Type                                | Location                |
| ----------------------------------- | ----------------------- |
| Shared UI (button, input, dropdown) | core/components         |
| Feature-specific UI                 | views/{feature}/widgets |

---

## 7.4 Migration Rule

If a feature widget becomes reusable:

✔ Move to core/components
✔ Replace all duplicates

---

# 8. Extensions Usage Rules

UI MUST use extensions instead of raw logic:

Examples:

* `.paddingOnly()`
* `.vrSpace`
* `context.crossAxisCount`
* `context.padding`

---

❌ No manual padding repetition
❌ No duplicated layout calculations

---

# 9. Navigation Rules (UI Side)

## 9.1 Rule

❌ No raw Navigator usage inside UI

---

## 9.2 Rule

Navigation must use centralized system:

* `AppRoutes.push`
* `AppRoutes.pop`

---

## 9.3 Rule

❌ No navigation decision logic inside widgets
✔ Navigation triggered via callbacks or Cubit

---

# 10. UI Composition Philosophy

UI follows:

> “Compose, don’t compute”

Meaning:

* UI composes widgets
* Cubits compute logic
* Core handles reuse
* Extensions handle styling

---

# 11. Anti-Patterns (STRICTLY FORBIDDEN)

❌ Business logic in UI
❌ API calls in UI
❌ Cubit instantiation in UI
❌ Duplicate widgets
❌ Hardcoded styling
❌ Direct navigation logic
❌ Controllers inside widgets
❌ Complex conditional rendering in page

---

# 12. Final Architecture Summary

## UI Layer Responsibilities:

✔ Render widgets
✔ Compose layout
✔ Display state
✔ Pass user actions
✔ Use core components

---

## UI Layer MUST NOT:

❌ Handle logic
❌ Create dependencies
❌ Manage state
❌ Implement business rules
❌ Duplicate components

---

# 13. Design Goal

This architecture ensures:

* high readability
* scalability
* low coupling
* reusable UI system
* predictable structure
* AI-friendly code generation

---
