# UI Core Widgets Reuse Rules

## Overview

The project follows a **centralized UI components system** to prevent duplication and enforce consistency.

All UI must reuse existing components from `core/components` whenever possible.

---

# 1. Core Widgets First Rule (MOST IMPORTANT)

Before creating ANY new widget:

## MUST CHECK:

* `core/components/buttons`
* `core/components/text_fields`
* `core/components/dropdowns`
* `core/components/data_state_widgets`
* `core/components/list_widgets`
* `core/components/dialogs`
* `core/components/shimmer_widgets`

---

## Rule:

> If a component already exists in Core → MUST reuse it

❌ Never recreate UI that already exists
❌ Never duplicate styling or behavior

---

# 2. Widget Creation Decision Rule

When creating a new widget:

## Step 1 — Check reuse

Ask:

* Does a similar widget already exist in core?
* Can it be extended instead of recreated?

---

## Step 2 — Decide location

### A) Core Widget (SHARED ACROSS APP)

Move to:

```txt id="core1"
lib/core/components/
```

If:

* used in 2+ features
* generic (button, input, list, dialog)
* reusable design

---

### B) Feature Widget (LOCAL ONLY)

Keep in:

```txt id="feat1"
views/{feature}/widgets/
```

If:

* used in only one feature
* contains feature-specific UI
* not reusable elsewhere

---

# 3. No Duplicate UI Rule

## Forbidden:

* Creating new button style when `BtnWidget` exists ❌
* Creating new dropdown when core dropdown exists ❌
* Rewriting list views manually ❌
* Rebuilding empty/error/loading states ❌

---

# 4. Extension Rule (IMPORTANT)

Before creating UI logic:

## MUST CHECK:

* `BuildContextExtensions`
* `StringExtensions`
* `IntExtensions`
* `DoubleExtensions`
* `WidgetExtensions`

If functionality exists → MUST use it.

---

# 5. Core Widget Evolution Rule

If a new widget is created in feature and later:

## Condition:

> Used in 2 or more features

## Action:

✔ Move it to `core/components`
✔ Refactor imports
✔ Replace local versions

---

# 6. Design Consistency Rule

All UI must follow:

* `AppTheme`
* `AppColors`
* `AppConstants`
* Core spacing system
* Core border radius system

❌ No hardcoded styling in feature widgets

---

# 7. Import Cleanliness Rule

UI files must NOT:

* import multiple duplicated UI versions
* recreate logic that exists in core
* bypass core components

---

# 8. Core Philosophy

> “If it exists in Core, use it.
> If it doesn't exist, ask: should it live in Core?”

---

# Summary

| Case                               | Action              |
| ---------------------------------- | ------------------- |
| Widget exists in core              | reuse it            |
| Widget used in multiple features   | move to core        |
| Widget feature-specific            | keep inside feature |
| Styling logic exists in extensions | use extension       |
| Duplicate UI                       | forbidden           |
