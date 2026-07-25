# Models & Classes Classification Rules

## Overview

Not every class in the project is a Model.

There are **3 types of classes** in the architecture:

* Data Models (Backend / Firebase / Cache)
* UI Entities (UI-only objects)
* Plain Classes (Utilities / Helpers / Configs)

Each type has strict rules.

---

# 1. Data Models

(Already defined)

Used for:

* API
* Firebase
* Cache

Must include:

* fromJson
* toJson
* copyWith
* Equatable

---

# 2. UI Entities

(Already defined)

Used for:

* UI representation only
* No persistence

Naming ends with:

```txt id="e1"
Entity
```

Example:

```dart id="e2"
HomeCardEntity
SettingsItemEntity
```

---

# 3. Plain Classes (IMPORTANT ADDITION)

## Definition

Plain Classes are normal Dart classes that are NOT Models and NOT Entities.

They are used for:

* helpers
* services
* config objects
* internal logic containers
* UI logic helpers (non-persistent)

---

## Naming Rule

No suffix required.

Examples:

```txt id="p1"
LocationService
ValidationHelper
AuthManager
ThemeConfig
PaginationController
```

---

## Structure Rules

Plain classes:

* DO NOT require fromJson
* DO NOT require toJson
* DO NOT require copyWith
* DO NOT require Equatable

---

## Rules

* Can contain logic
* Can contain methods
* Can hold internal state
* Can be used across app or feature scope

---

## Examples

### Service Class

```dart id="p2"
class LocationService {
  Future<void> getCurrentLocation() async {}
}
```

---

### Helper Class

```dart id="p3"
class ValidationHelper {
  static bool isValidPhone(String phone) => phone.length > 10;
}
```

---

### Config Class

```dart id="p4"
class ThemeConfig {
  final double borderRadius;

  const ThemeConfig({required this.borderRadius});
}
```

---

# 4. Decision Rules (CRITICAL)

When creating any class, ask:

## 1. Is it backend data?

→ Use Model

## 2. Is it UI-only display?

→ Use Entity

## 3. Is it logic/helper/service/config?

→ Use Plain Class

---

# 5. Forbidden Mixing Rules

Never mix:

* Model logic inside Plain Class ❌
* Entity with API parsing ❌
* Plain Class with fromJson/toJson unless needed ❌

---

# 6. Architecture Consistency Rule

The AI must ALWAYS classify classes before creation:

1. Identify purpose
2. Choose correct type:

   * Model
   * Entity
   * Plain Class
3. Apply correct rules
4. Place in correct folder

---

# Summary

| Type        | Purpose        | Serialization |
| ----------- | -------------- | ------------- |
| Model       | Backend data   | YES           |
| Entity      | UI data        | NO            |
| Plain Class | Logic / helper | NO            |
