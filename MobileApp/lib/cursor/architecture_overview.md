# Project Architecture Rules

## Overview

The project follows a strict feature-based architecture with clear separation between:

* `core/` → shared infrastructure and reusable app-wide logic
* `models/` → data layer only (handled in a separate rules file)
* `views/` → feature-based UI + controllers + feature widgets

Each file must belong to its correct layer. No mixing between layers is allowed.

---

# Root Structure

```txt id="a1b2c3"
lib/
├── core/
├── models/
├── views/
├── firebase_options.dart
└── main.dart
```

---

# 1. Core Layer

The `core/` folder contains shared infrastructure used across the entire application.

Nothing inside `core/` should belong to a single feature.

```txt id="d4e5f6"
core/
├── components/
├── constants/
├── errors/
├── network/
├── services/
└── theme/
```

---

## 1.1 Core Components

Reusable UI widgets across multiple features.

```txt id="g7h8i9"
components/
├── buttons/
├── text_fields/
├── dialogs/
├── loading/
├── appbars/
├── cards/
└── ...
```

### Rules

* Must be reusable across features
* Must be generic
* Must not contain feature-specific logic
* If widget becomes feature-specific → move it to feature folder

---

## 1.2 Constants

```txt id="j1k2l3"
constants/
├── extensions/
├── enums/
├── strings/
├── api/
├── firebase/
└── app_constants.dart
```

### Rules

* All constants must be centralized
* No raw strings anywhere in code
* No duplicated constants

---

### Extensions

```txt id="m4n5o6"
extensions/
├── double_ex.dart
├── string_ex.dart
├── context_ex.dart
└── ...
```

---

### Enums

```txt id="p7q8r9"
enums/
├── login_options_enum.dart
├── user_role_enum.dart
├── request_status_enum.dart
└── ...
```

---

### Strings

```txt id="s1t2u3"
strings/
├── app_strings.dart
├── firestore_strings.dart
├── validation_strings.dart
└── ...
```

---

### API Endpoints

```txt id="v4w5x6"
api/
└── api_endpoints.dart
```

* All endpoints must be centralized
* No hardcoded URLs anywhere in code

---

### Firebase Collections

```txt id="y7z8a9"
firebase/
└── firebase_collections.dart
```

* All collection names must be centralized
* No raw Firestore collection strings anywhere

---

### App Constants

```txt id="b1c2d3"
app_constants.dart
```

Contains:

* App configuration
* Support numbers
* Global fixed values

---

## 1.3 Errors

```txt id="e4f5g6"
errors/
└── error_handler.dart
```

* Centralized error transformation
* Converts exceptions into user-friendly messages

---

## 1.4 Network

```txt id="h7i8j9"
network/
├── api_handler.dart
├── cache_manager.dart
├── caching.dart
└── ...
```

### Rules

* No direct API calls from UI
* No direct SharedPreferences usage outside cache manager
* All networking centralized here

---

## 1.5 Services

```txt id="k1l2m3"
services/
├── location_service.dart
├── notification_service.dart
├── permission_service.dart
├── logging_service.dart
└── ...
```

### Rules

* Shared logic across multiple features
* Encapsulate external integrations
* Must not depend on UI layer

---

## 1.6 Theme

```txt id="n4o5p6"
theme/
├── app_theme.dart
├── app_colors.dart
├── app_dimens.dart
├── app_text_styles.dart
└── ...
```

### Rules

* No hardcoded colors
* No hardcoded spacing
* No inline text styles

---

# 2. Views Layer

The `views/` folder contains all application features.

Each feature is fully isolated.

```txt id="q7r8s9"
views/
├── auth/
├── home/
├── invoices/
└── ...
```

---

# Feature Structure

```txt id="t1u2v3"
views/{feature}/
├── controllers/
├── pages/
└── widgets/
```

---

## 2.1 Controllers

```txt id="w4x5y6"
controllers/
├── login/
│   ├── login_cubit.dart
│   └── login_states.dart
└── register/
    ├── register_cubit.dart
    └── register_states.dart
```

### Rules

* Business logic only
* API + Firebase calls only
* No UI code allowed

---

## 2.2 Pages

```txt id="z1a2b3"
pages/
├── login_page.dart
├── register_page.dart
└── ...
```

### Rules

* Only UI rendering
* Call cubits only
* No business logic

---

## 2.3 Widgets

Widgets are grouped by page.

```txt id="c4d5e6"
widgets/
├── login/
│   ├── login_form_widget.dart
│   ├── login_header_widget.dart
│   └── ...
├── register/
│   └── register_form_widget.dart
└── shared/
    └── auth_background_widget.dart
```

### Rules

* Page-specific widgets stay inside page folder
* Shared feature widgets go to `shared/`
* Only move to `core/components/` if reused across app

---

# Architecture Principles

The system enforces:

* strict layer separation
* feature isolation
* reusable shared components
* predictable file structure
* scalability without refactoring chaos

---

# AI Development Rules

The AI must always:

* place files in correct layer
* follow existing patterns only
* avoid introducing new architecture styles
* prefer reuse over creation
* keep features fully isolated
