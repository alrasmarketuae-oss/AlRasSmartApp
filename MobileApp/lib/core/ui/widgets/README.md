# Design System Widgets

مجموعة من الـ Widgets القابلة لإعادة الاستخدام والتي تتبع Design System pattern.

## البنية

```
core/ui/widgets/
├── form/
│   ├── app_text_field.dart      # TextField مرن
│   ├── app_password_field.dart  # Password Field
│   └── app_primary_button.dart  # Primary Button
├── feedback/
│   ├── app_loading.dart         # Loading Indicator
│   └── app_toast.dart           # Toast Messages
└── widgets.dart                 # Barrel file للاستيراد السهل
```

## الاستخدام

### 1. AppTextField - TextField مرن

```dart
import 'package:louqta/core/ui/widgets/widgets.dart';

// استخدام بسيط
AppTextField(
  controller: _emailController,
  hintText: 'البريد الإلكتروني',
  prefixIcon: Icons.email_outlined,
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    return null;
  },
)

// مع تخصيصات إضافية
AppTextField(
  controller: _nameController,
  hintText: 'الاسم الكامل',
  labelText: 'الاسم',
  prefixIcon: Icons.person_outlined,
  borderRadius: 16,
  fillColor: Colors.grey.shade50,
  focusedBorderColor: Colors.blue,
)
```

### 2. AppPasswordField - Password Field

```dart
AppPasswordField(
  controller: _passwordController,
  hintText: 'كلمة المرور',
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  },
)
```

### 3. AppPrimaryButton - Primary Button

```dart
AppPrimaryButton(
  text: 'دخول',
  onPressed: () {
    // Handle login
  },
)

// مع loading state
AppPrimaryButton(
  text: 'جاري التسجيل...',
  isLoading: true,
  onPressed: null,
)

// مع icon
AppPrimaryButton(
  text: 'إنشاء حساب',
  icon: Icons.person_add,
  onPressed: () {},
)
```

### 4. AppLoading - Loading Indicator

```dart
AppLoading()

// مع تخصيصات
AppLoading(
  size: 50,
  color: Colors.blue,
  strokeWidth: 4,
)
```

### 5. AppToast - Toast Messages

```dart
AppToast.showSuccess(context, 'Done');
AppToast.showError(context, 'حدث خطأ');
AppToast.showInfo(context, 'معلومة');
```

## المميزات

✅ **RTL Support** - دعم كامل للغة العربية  
✅ **Customizable** - قابل للتخصيص بالكامل  
✅ **Consistent Design** - تصميم موحد عبر التطبيق  
✅ **Easy to Use** - استخدام بسيط (سطرين)  
✅ **Type Safe** - آمن من ناحية الأنواع  
✅ **No Coupling** - لا يعتمد على Cubit أو Business Logic

## القواعد

1. **UI Widgets** → `core/ui/widgets/`
2. **Validators/Helpers** → `core/utils/` أو `core/validation/`
3. **Feature-specific Widgets** → `features/<feature>/presentation/widgets/`
4. **Shared Domain Widgets** → `shared/ui/widgets/`

