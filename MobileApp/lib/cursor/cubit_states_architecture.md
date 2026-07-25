# Cubit & States Architecture System

---

# 1. Overview

This system defines how ALL Cubits and States should be designed across the application.

It ensures:
- Predictable logic flow
- Clean separation from UI
- Reusable patterns
- Scalable state handling
- Consistent API handling

---

# 2. Core Principle

Cubit = Business Logic Layer  
UI = Presentation Layer Only  

### Cubit is responsible for:
- API calls
- Firebase streams
- Validation
- Controllers
- Filtering / Searching
- Caching
- State decisions
- Navigation triggers (via callbacks)

### UI is responsible for:
- Rendering widgets
- Listening to states
- Triggering Cubit methods only

---

# 3. State Status System (RequestStatus)

Used for async operations only:

```dart
enum RequestStatus {
  loading,
  success,
  failure,
}
````

### Used in:

* GET requests
* POST requests
* Firebase calls
* Heavy async operations

### NOT used in:

* simple UI interactions
* local selections
* filters without API calls

---

# 4. Standard State Structure

Each async state should follow:

```dart
class ExampleState {
  final RequestStatus status;
  final dynamic error;
  final String? message;
  final VoidCallback? onSuccess;

  ExampleState({
    required this.status,
    this.error,
    this.message,
    this.onSuccess,
  });
}
```

---

# 5. Side Effects System

## Allowed Side Effects:

* Toast messages
* Navigation
* Cache updates
* Logging
* Dialogs (via services)

## Execution Rules:

* Side effects MUST NOT be inside UI
* Side effects are triggered inside Cubit OR State callback
* UI only reacts, never decides

---

# 6. POST Request Pattern

### Flow:

1. Emit loading state
2. Call API
3. Parse response once
4. Decide result

### Example:

```dart
Future<void> completeSignUp() async {
  emit(CompleteSignUpState(status: RequestStatus.loading));

  try {
    final response = await ApiServices.post(
      endpoint: ApiEndpoints.completeSignUp,
      body: {
        "name": nameCtr?.text.trim(),
      },
    );

    if (response.isSuccess) {
      emit(
        CompleteSignUpState(
          status: RequestStatus.success,
          onSuccess: () {
            CacheManager.setUser(UserModel.fromJson(jsonDecode(response.body)));
            AppRoutes.push(ProfilePage());
          },
        ),
      );
    } else {
      emit(
        CompleteSignUpState(
          status: RequestStatus.failure,
          error: jsonDecode(response.body),
        ),
      );
    }
  } catch (e) {
    emit(
      CompleteSignUpState(
        status: RequestStatus.failure,
        error: e,
      ),
    );
  }
}
```

---

# 7. GET Request Pattern

### Rules:

* Use nullable cache inside Cubit
* Support refresh flag
* Avoid unnecessary API calls

### Example:

```dart
List<CompoundModel>? compounds;

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
      emit(
        GetCompoundsState(
          status: RequestStatus.failure,
          error: jsonDecode(response.body),
        ),
      );
    }
  } catch (e) {
    emit(
      GetCompoundsState(
        status: RequestStatus.failure,
        error: e,
      ),
    );
  }
}
```

---

# 8. Firebase / Stream Pattern

### Rules:

* Use private StreamSubscription
* Keep raw data in private variable
* Expose via getter only

### Example:

```dart
StreamSubscription? _sub;

Map<String, PersonModel> _people = {};
Map<String, PersonModel> _filtered = {};

Map<String, PersonModel> get people =>
    searchController?.text.isNotEmpty == true ? _filtered : _people;

void listenPeople() {
  _sub = FirebaseService.watchCollection(
    collectionName: FirebaseCollections.people,
  ).listen((snapshot) {
    _people = {
      for (var doc in snapshot.docs)
        doc.id: PersonModel.fromJson(doc.data())
    };

    emit(GetPeopleState(status: RequestStatus.success));
  });
}
```

### Must:

* cancel subscription in close()
* never expose stream to UI directly

---

# 9. Search & Filtering Pattern

### Rules:

* Search logic inside Cubit only
* UI only sends input

### Example:

```dart
void filterPeople() {
  final query = searchController?.text.toLowerCase() ?? '';

  _filtered = Map.fromEntries(
    _people.entries.where(
      (e) => e.value.name.toLowerCase().contains(query),
    ),
  );

  emit(GetPeopleState(status: RequestStatus.success));
}
```

---

# 10. Controllers Rule

* Controllers MUST be inside Cubit
* Never inside UI
* Always disposed in `close()`

---

# 11. Validation System

### Rule:

Validation is Cubit responsibility

### Example:

```dart
bool get canSubmit =>
    nameCtr?.text.isNotEmpty == true &&
    selectedCompound != null;
```

UI only listens to result.

---

# 12. Dependency Injection Rule

### Rules:

* Prefer constructor injection
* sl() allowed ONLY inside Cubit
* NEVER inside UI

---

# 13. Error Handling Strategy

* All errors handled via `ErrorHandler`
* API response parsed once in Cubit
* UI never parses raw JSON

---

# 14. GET vs POST Behavior

## GET:

* caching allowed
* nullable data allowed
* refresh supported
* UI may show empty/error widgets

## POST:

* always status-based
* usually triggers toast or navigation
* no caching needed normally

---

# 15. State Philosophy

States are not only UI triggers.

They can:

* carry error info
* carry success callbacks
* represent flow stages
* trigger side effects

BUT:

* no UI logic inside state
* must remain deterministic

---

# 16. Performance Rule

* Emit only when needed
* Avoid redundant state emissions
* Keep Cubit lightweight and predictable

---

# 17. Final Architecture Rule

Cubit = Brain (Logic + Decisions)
UI = Renderer (Display Only)
States = Communication Layer (Status + Data + Effects)

````

---
