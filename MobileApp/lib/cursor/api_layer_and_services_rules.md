تمام، خلينا نكمّلها بشكل منظّم على نفس فكرة الـ architecture اللي بنيناها، بس نضيف **API layer + session flow + طريقة الاستدعاء الصح من الـ cubit** بشكل reusable ومش مكرر.

هديك ملف جاهز للنسخ 👇

---

# 📄 `api_layer_and_services_rules.md`

````md
# API Layer & Network Architecture Rules

This document defines how API calls, session handling, and network layer usage should be structured across the application.

---

## 1. API Layer Structure

The API layer is centralized inside a single service:

### Core File
- `ApiServices`

This class is responsible for:
- GET / POST / PUT / PATCH / DELETE requests
- Multipart/form-data requests
- Logging requests & responses
- Injecting headers automatically
- Handling session expiration check

---

## 2. Endpoints Handling

All endpoints MUST be defined in a single constants file:

```dart
ApiEndpoints
````

Rules:

* No hardcoded URLs inside Cubits or Services
* All endpoints must be centralized
* Example:

```dart
ApiEndpoints.login
ApiEndpoints.getCompounds()
ApiEndpoints.completeSignUp
```

---

## 3. Core Network Rule

All requests MUST go through:

```dart
ApiServices
```

Never use:

* http directly inside Cubits
* dio directly inside UI or Cubits
* manual Uri parsing outside ApiServices

---

## 4. Standard API Call Pattern (Cubit Side)

### GET Example

```dart
Future<void> getCompounds({bool refresh = false}) async {
  if (compounds != null && !refresh) return;

  emit(GetCompoundsState(status: RequestStatus.loading));

  try {
    final response = await ApiServices.get(
      endpoint: ApiEndpoints.compounds(),
    );

    if (response.isSuccess) {
      compounds = (jsonDecode(response.body)['data'] as List)
          .map((e) => CompoundModel.fromJson(e))
          .toList();

      emit(GetCompoundsState(status: RequestStatus.success));
    } else {
      emit(GetCompoundsState(
        status: RequestStatus.failure,
        error: ErrorHandler.error(jsonDecode(response.body)),
      ));
    }
  } catch (e) {
    emit(GetCompoundsState(
      status: RequestStatus.failure,
      error: ErrorHandler.error(e),
    ));
  }
}
```

---

### POST Example (Action / Submit)

```dart
Future<void> completeSignUp() async {
  emit(CompleteSignUpState(status: RequestStatus.loading));

  try {
    final response = await ApiServices.post(
      endpoint: ApiEndpoints.completeSignUp,
      body: {
        "name": name,
        "phone": phone,
      },
    );

    if (response.isSuccess) {
      emit(CompleteSignUpState(
        status: RequestStatus.success,
        successMessage: "Success",
      ));
    } else {
      emit(CompleteSignUpState(
        status: RequestStatus.failure,
        error: jsonDecode(response.body),
        showToast: true,
      ));
    }
  } catch (e) {
    emit(CompleteSignUpState(
      status: RequestStatus.failure,
      error: e,
      showToast: true,
    ));
  }
}
```

---

## 5. RequestStatus Usage Rule

Use `RequestStatus` ONLY when:

* API request is involved
* Loading / success / failure UI is needed
* Data is coming from server or Firebase

DO NOT use RequestStatus for:

* UI selection (e.g select country)
* Local state changes
* simple toggles
* search filters

---

## 6. Session Handling Flow

Session is managed globally via:

```dart
UserSessionService
```

### Responsibilities:

* Get cached user
* Validate token expiration
* Redirect to login on expiry
* Clear cache safely

---

### Auto session check happens inside ApiServices:

Every API response triggers:

```dart
UserSessionService.validateSessionExpire()
```

So Cubits NEVER handle:

* token expiry
* logout logic
* cache clearing manually

---

## 7. Routing Based on Session

Main entry point:

```dart
UserSessionService.kGetMainRoute
```

Returns:

* ProfilePage if user exists
* SignInPage if not authenticated

---

## 8. API Service Rules

### Allowed inside ApiServices:

* logging
* headers injection
* session validation
* request execution

### NOT allowed:

* UI logic
* Cubit logic
* business rules
* model transformation beyond raw response

---

## 9. Logging Rule

Every request MUST log:

* URL
* status code
* request body
* response body

But logging MUST stay inside ApiServices only.

---

## 10. Cubit Responsibility Rule

Cubit responsibilities:

* call ApiServices only
* parse response
* update state
* hold UI-related state
* NO HTTP logic inside UI

---
