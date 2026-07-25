using System.Text.RegularExpressions;

namespace BusinessLayer.Helpers;

public static class UserMessages
{
    private static readonly Dictionary<string, string> ArabicByEnglish = new(StringComparer.Ordinal)
    {
        // Auth & login
        ["Invalid credentials."] = "بيانات الدخول غير صحيحة.",
        ["Human verification is required."] = "يجب إكمال التحقق من أنك لست روبوتًا.",
        ["Human verification failed."] = "فشل التحقق من أنك لست روبوتًا. أعد المحاولة.",
        ["Email and password are required."] = "البريد الإلكتروني وكلمة المرور مطلوبان.",
        ["Email and password are required for local login."] = "البريد الإلكتروني وكلمة المرور مطلوبان لتسجيل الدخول.",
        ["Email already exists."] = "البريد الإلكتروني مستخدم بالفعل.",
        ["Email is required."] = "البريد الإلكتروني مطلوب.",
        ["Invalid OTP."] = "رمز التحقق غير صحيح.",
        ["OTP expired."] = "انتهت صلاحية رمز التحقق.",
        ["No account found for this email."] = "لا يوجد حساب بهذا البريد الإلكتروني.",
        ["Please verify your email before logging in."] = "يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.",
        ["Your account is suspended or deactivated."] = "حسابك موقوف أو غير مفعّل.",
        ["Your account registration was rejected."] = "تم رفض تسجيل حسابك.",
        ["Your company account has not been approved yet. It is pending admin approval."] =
            "لم تتم الموافقة على حساب شركتك بعد. الحساب قيد مراجعة الإدارة.",
        ["Your company account has not been approved yet."] = "لم تتم الموافقة على حساب شركتك بعد.",
        ["Company account is not verified yet."] = "حساب الشركة غير مفعّل بعد.",
        ["Account is not a company account."] = "الحساب ليس حساب شركة.",
        ["Account not found."] = "الحساب غير موجود.",
        ["Account registration was rejected."] = "تم رفض تسجيل الحساب.",
        ["Account is approved."] = "تمت الموافقة على الحساب.",
        ["Account is pending admin approval."] = "الحساب قيد موافقة الإدارة.",
        ["Account is not approved."] = "لم تتم الموافقة على الحساب.",
        ["Email verified successfully."] = "تم تأكيد البريد الإلكتروني بنجاح.",
        ["Email verified. Your company account is pending admin approval."] =
            "تم تأكيد البريد الإلكتروني. حساب شركتك قيد موافقة الإدارة.",
        ["Current and new password are required."] = "كلمة المرور الحالية والجديدة مطلوبتان.",
        ["Current password is incorrect."] = "كلمة المرور الحالية غير صحيحة.",
        ["Password changed successfully."] = "تم تغيير كلمة المرور بنجاح.",
        ["ProviderName and destination are required."] = "اسم المزود والوجهة مطلوبان.",
        ["User not found for provided destination."] = "لم يتم العثور على مستخدم للوجهة المحددة.",
        ["Password reset code sent successfully."] = "تم إرسال رمز إعادة تعيين كلمة المرور بنجاح.",
        ["ProviderName, destination, code and new password are required."] =
            "اسم المزود والوجهة والرمز وكلمة المرور الجديدة مطلوبة.",
        ["Invalid reset code."] = "رمز إعادة التعيين غير صحيح.",
        ["Reset code expired."] = "انتهت صلاحية رمز إعادة التعيين.",
        ["Login provider returned: Email"] = "مزود تسجيل الدخول يجب أن يكون: Email",

        // Users & profile
        ["Invalid user id."] = "معرّف المستخدم غير صالح.",
        ["User not found."] = "المستخدم غير موجود.",
        ["Invalid authenticated user."] = "المستخدم المصادق عليه غير صالح.",
        ["Authenticated user not found."] = "المستخدم المصادق عليه غير موجود.",
        ["Invalid company user id."] = "معرّف مستخدم الشركة غير صالح.",
        ["Company user not found."] = "مستخدم الشركة غير موجود.",
        ["Rejection reason is required."] = "سبب الرفض مطلوب.",
        ["Company is already approved."] = "تمت الموافقة على الشركة مسبقاً.",
        ["Admin accounts cannot be deactivated."] = "لا يمكن إيقاف حسابات الإدارة.",
        ["Use reject to decline a pending supplier registration."] =
            "استخدم الرفض لرفض تسجيل مورد قيد الانتظار.",
        ["Language must be 'en' or 'ar'."] = "اللغة يجب أن تكون en أو ar.",

        // Products
        ["Invalid product id."] = "معرّف المنتج غير صالح.",
        ["Product not found."] = "المنتج غير موجود.",
        ["Product is already approved."] = "تمت الموافقة على المنتج مسبقاً.",
        ["Product has no owner."] = "المنتج ليس له مالك.",
        ["Product image not found."] = "صورة المنتج غير موجودة.",
        ["You can only update your own products."] = "يمكنك تحديث منتجاتك فقط.",
        ["You can only manage your own listings."] = "يمكنك إدارة إعلاناتك فقط.",
        ["You can delete files only from your own product."] = "يمكنك حذف الملفات من منتجك فقط.",
        ["Product could not be saved to the database."] = "تعذّر حفظ المنتج في قاعدة البيانات.",
        ["Product save verification failed."] = "فشل التحقق من حفظ المنتج.",
        ["Cannot delete this product because it has related orders."] =
            "لا يمكن حذف هذا المنتج لأنه مرتبط بطلبات.",
        ["Cannot delete this product because it is linked to other records."] =
            "لا يمكن حذف هذا المنتج لأنه مرتبط بسجلات أخرى.",
        ["Product deleted successfully."] = "تم حذف المنتج بنجاح.",
        ["Only paused listings can be reactivated."] = "يمكن إعادة تفعيل الإعلانات المتوقفة فقط.",
        ["Only active listings can be paused."] = "يمكن إيقاف الإعلانات النشطة فقط.",
        ["Invalid owner id."] = "معرّف المالك غير صالح.",
        ["Owner user not found."] = "مالك المنتج غير موجود.",
        ["Only company accounts can manage products."] = "حسابات الشركات فقط يمكنها إدارة المنتجات.",
        ["You are not allowed to delete this product."] = "غير مسموح لك بحذف هذا المنتج.",
        ["USDPrice must be greater than zero."] = "سعر الدولار يجب أن يكون أكبر من صفر.",
        ["Quantity must be greater than zero."] = "الكمية يجب أن تكون أكبر من صفر.",
        ["UnitName is required."] = "اسم الوحدة مطلوب.",
        ["Currency must be USD or AED."] = "العملة يجب أن تكون USD أو AED.",
        ["DiscountDays is required when DiscountPercentage is set."] =
            "أيام الخصم مطلوبة عند تحديد نسبة الخصم.",
        ["DiscountDays must be greater than zero."] = "أيام الخصم يجب أن تكون أكبر من صفر.",
        ["ShippingDuration must be at most 20 characters."] = "مدة الشحن يجب ألا تتجاوز 20 حرفاً.",
        ["Invalid address id."] = "معرّف العنوان غير صالح.",
        ["Address not found for this user."] = "العنوان غير موجود لهذا المستخدم.",
        ["Product video file is empty."] = "ملف فيديو المنتج فارغ.",
        ["VideoDurationSeconds is required when ProductVideoFile is provided."] =
            "مدة الفيديو مطلوبة عند رفع ملف فيديو المنتج.",
        ["Product video duration must be between 1 and 60 seconds."] =
            "مدة فيديو المنتج يجب أن تكون بين 1 و 180 ثانية.",
        ["Product video duration must be between 1 and 180 seconds."] =
            "مدة فيديو المنتج يجب أن تكون بين 1 و 180 ثانية.",
        ["Product video duration must be between 1 and 20 seconds."] =
            "مدة فيديو المنتج يجب أن تكون بين 1 و 180 ثانية.",
        ["A product can have at most 15 images."] =
            "يمكن للمنتج أن يحتوي على 15 صورة كحد أقصى.",
        ["An order can have at most 15 images."] =
            "يمكن للطلب أن يحتوي على 15 صورة كحد أقصى.",
        ["WebRootPath is required for product video upload."] =
            "مسار WebRoot مطلوب لرفع فيديو المنتج.",
        ["Unsupported product video format. Allowed: .mp4, .mov, .webm, .m4v"] =
            "صيغة فيديو المنتج غير مدعومة. المسموح: .mp4, .mov, .webm, .m4v",
        ["Page must be greater than or equal to 1."] = "رقم الصفحة يجب أن يكون 1 أو أكثر.",
        ["PageSize must be between 1 and 100."] = "حجم الصفحة يجب أن يكون بين 1 و 100.",
        ["Search query is required."] = "نص البحث مطلوب.",
        ["Search query must be at least 2 characters."] = "نص البحث يجب أن يكون حرفين على الأقل.",
        ["ProductTypeName is required."] = "نوع المنتج مطلوب.",
        ["CategoryId is required."] = "معرّف الفئة مطلوب.",
        ["At least one product name is required."] = "اسم منتج واحد على الأقل مطلوب.",

        // Orders
        ["ToUserId is required."] = "معرّف المستخدم المستلم مطلوب.",
        ["ToUserId must be a valid guid."] = "معرّف المستخدم المستلم يجب أن يكون GUID صالحاً.",
        ["ProductId is required."] = "معرّف المنتج مطلوب.",
        ["ProductId must be a valid guid."] = "معرّف المنتج يجب أن يكون GUID صالحاً.",
        ["UnitPrice must be greater than zero."] = "سعر الوحدة يجب أن يكون أكبر من صفر.",
        ["TotalPrice must be greater than zero."] = "السعر الإجمالي يجب أن يكون أكبر من صفر.",
        ["Online payment is not available right now."] = "الدفع الإلكتروني غير متاح حالياً.",
        ["ToUserId does not match the product owner."] = "المستخدم المستلم لا يطابق مالك المنتج.",
        ["You cannot place an order on your own product."] = "لا يمكنك طلب منتجك الخاص.",
        ["Supplier user not found."] = "مورد المنتج غير موجود.",
        ["SupplierEmail does not match the product owner."] = "بريد المورد لا يطابق مالك المنتج.",
        ["UnitName does not match the product unit."] = "اسم الوحدة لا يطابق وحدة المنتج.",
        ["Product is not available for ordering."] = "المنتج غير متاح للطلب.",
        ["Invalid order status."] = "حالة الطلب غير صالحة.",
        ["Order not found."] = "الطلب غير موجود.",
        ["Address not found for the given city and address line."] =
            "العنوان غير موجود للمدينة وسطر العنوان المحددين.",
        ["Cart is empty."] = "سلة التسوق فارغة.",
        ["Cart contains an invalid product."] = "السلة تحتوي على منتج غير صالح.",
        ["Pending order not found."] = "الطلب المعلق غير موجود.",
        ["Pending order payment is not completed yet."] = "لم يكتمل دفع الطلب المعلق بعد.",
        ["Video file is required."] = "ملف الفيديو مطلوب.",
        ["WebRootPath is required."] = "مسار WebRoot مطلوب.",
        ["Unsupported video format. Allowed: .mp4, .mov, .webm, .m4v"] =
            "صيغة الفيديو غير مدعومة. المسموح: .mp4, .mov, .webm, .m4v",
        ["Order video not found."] = "فيديو الطلب غير موجود.",
        ["Image file is required."] = "ملف الصورة مطلوب.",
        ["Unsupported image format. Allowed: .jpg, .jpeg, .png, .webp"] =
            "صيغة الصورة غير مدعومة. المسموح: .jpg, .jpeg, .png, .webp",
        ["Order image not found."] = "صورة الطلب غير موجودة.",
        ["Order quantity must be greater than zero."] = "كمية الطلب يجب أن تكون أكبر من صفر.",
        ["Port is only allowed for booking orders."] = "الميناء مسموح لطلبات الحجز فقط.",
        ["PortName is required for booking orders."] = "اسم الميناء مطلوب لطلبات الحجز.",
        ["You are not allowed to update the order to this status."] =
            "غير مسموح لك بتحديث الطلب إلى هذه الحالة.",
        ["You are not allowed to access this order."] = "غير مسموح لك بالوصول إلى هذا الطلب.",

        // Payments
        ["Invalid order id."] = "معرّف الطلب غير صالح.",
        ["You can only pay for your own orders."] = "يمكنك الدفع لطلباتك فقط.",
        ["Order payment method is not online."] = "طريقة دفع الطلب ليست إلكترونية.",
        ["Order payment is already completed."] = "تم دفع الطلب مسبقاً.",
        ["You can only view your own checkout status."] = "يمكنك عرض حالة الدفع لطلباتك فقط.",
        ["Only online payments can be refunded."] = "يمكن استرداد المدفوعات الإلكترونية فقط.",
        ["Only cancelled or return-approved orders can be refunded manually."] =
            "يمكن استرداد الطلبات الملغاة أو الموافق على استرجاعها يدوياً فقط.",
        ["Only cancelled orders can be refunded manually."] =
            "يمكن استرداد الطلبات الملغاة يدوياً فقط.",
        ["No completed online payment was found for this order."] =
            "لم يُعثر على دفع إلكتروني مكتمل لهذا الطلب.",
        ["This online payment is not completed yet."] = "لم يكتمل هذا الدفع الإلكتروني بعد.",
        ["This order payment has already been refunded."] = "تم استرداد دفع هذا الطلب مسبقاً.",
        ["Payment intent is missing for this order."] = "معرّف الدفع مفقود لهذا الطلب.",
        ["Stripe payment intent was not found."] = "لم يُعثر على Stripe payment intent.",
        ["No captured payment amount was found for this order."] =
            "لم يُعثر على مبلغ محصّل لهذا الطلب.",

        // Cart
        ["Invalid cart item id."] = "معرّف عنصر السلة غير صالح.",
        ["Cart item not found."] = "عنصر السلة غير موجود.",
        ["You can only modify items in your own cart."] = "يمكنك تعديل عناصر سلتك فقط.",
        ["Product unit is not set."] = "وحدة المنتج غير محددة.",
        ["Requested quantity exceeds available product quantity."] =
            "الكمية المطلوبة تتجاوز الكمية المتاحة للمنتج.",
        ["Product price is not available."] = "سعر المنتج غير متاح.",

        // Chat
        ["Cannot send a message to yourself."] = "لا يمكنك إرسال رسالة لنفسك.",
        ["Message not found."] = "الرسالة غير موجودة.",
        ["Only the sender can edit this message."] = "يمكن للمرسل فقط تعديل هذه الرسالة.",
        ["Only text messages can be edited."] = "يمكن تعديل الرسائل النصية فقط.",
        ["Content is required."] = "المحتوى مطلوب.",
        ["Upload supports image, voice, and video messages only."] =
            "الرفع يدعم رسائل الصور والصوت والفيديو فقط.",
        ["At least one image file is required."] = "ملف صورة واحد على الأقل مطلوب.",
        ["You can upload up to 10 images at once."] = "يمكنك رفع حتى 10 صور دفعة واحدة.",
        ["At least one valid image file is required."] = "ملف صورة صالح واحد على الأقل مطلوب.",
        ["Video file must be 30 MB or smaller."] = "ملف الفيديو يجب ألا يتجاوز 30 ميغابايت.",
        ["Only MP4, MOV, and WebM videos are supported."] = "فيديو MP4 و MOV و WebM فقط مدعومة.",
        ["Image content must be a chat image path or images JSON payload."] =
            "محتوى الصورة يجب أن يكون مسار صورة دردشة أو JSON للصور.",
        ["Location content must include lat and lng."] = "محتوى الموقع يجب أن يتضمن lat و lng.",
        ["Location content must be valid JSON."] = "محتوى الموقع يجب أن يكون JSON صالحاً.",
        ["Video content must be a chat video path."] = "محتوى الفيديو يجب أن يكون مسار فيديو دردشة.",

        // Files & assets
        ["File is required."] = "الملف مطلوب.",
        ["At least one image path is required."] = "مسار صورة واحد على الأقل مطلوب.",

        // Addresses
        ["AddressLine1 is required."] = "سطر العنوان الأول مطلوب.",
        ["City not found."] = "المدينة غير موجودة.",

        // Offers
        ["Invalid from user id."] = "معرّف المرسل غير صالح.",
        ["Invalid to user id."] = "معرّف المستلم غير صالح.",
        ["From user and to user must be different."] = "المرسل والمستلم يجب أن يكونا مختلفين.",
        ["CountryName, PortName, DeliveryWindow and UnitName are required."] =
            "اسم الدولة والميناء ونافذة التسليم واسم الوحدة مطلوبة.",
        ["RequestedQuantity must be greater than zero."] = "الكمية المطلوبة يجب أن تكون أكبر من صفر.",
        ["From user not found."] = "المرسل غير موجود.",
        ["To user not found."] = "المستلم غير موجود.",
        ["Offers can only be submitted for request products."] =
            "العروض مسموحة لمنتجات الطلب فقط.",
        ["OfferedPrice, BaseUnitPrice and RequestedQuantity must be greater than zero."] =
            "السعر المعروض وسعر الوحدة والكمية المطلوبة يجب أن تكون أكبر من صفر.",

        // Categories & banners
        ["NameEn is required."] = "الاسم بالإنجليزية مطلوب.",
        ["Category not found."] = "الفئة غير موجودة.",
        ["Only admin can manage categories."] = "الإدارة فقط يمكنها إدارة الفئات.",
        ["Banner image file is required."] = "ملف صورة البanner مطلوب.",
        ["LinkUrl is required."] = "رابط URL مطلوب.",
        ["Banner not found."] = "البانر غير موجود.",
        ["Only admin can manage home banners."] = "الإدارة فقط يمكنها إدارة بanners الصفحة الرئيسية.",

        // Notifications
        ["Target user has no FCM token."] = "المستخدم المستهدف ليس لديه رمز FCM.",
        ["Notification sent successfully."] = "تم إرسال الإشعار بنجاح.",
        ["Audience is required."] = "الجمهور مطلوب.",
        ["Title is required."] = "العنوان مطلوب.",
        ["Body is required."] = "نص الإشعار مطلوب.",
        ["Invalid audience. Allowed: All, Suppliers, Clients, Shipping, SingleUser."] =
            "جمهور غير صالح. المسموح: All, Suppliers, Clients, Shipping, SingleUser.",
        ["Target user id is required for single-user notifications."] =
            "معرّف المستخدم مطلوب للإشعارات الفردية.",
        ["Target user not found."] = "المستخدم المستهدف غير موجود.",

        // Shipping & settings
        ["At least one emirate rate is required."] = "سعر إمارة واحدة على الأقل مطلوب.",
        ["One or more emirates were not found."] = "إمارة واحدة أو أكثر غير موجودة.",
        ["Shipping price cannot be negative."] = "سعر الشحن لا يمكن أن يكون سالباً.",
        ["Emirate name is required."] = "اسم الإمارة مطلوب.",
        ["Internal domestic shipping rates are not loaded."] = "أسعار الشحن الداخلي غير محمّلة.",
        ["Invalid provider user id."] = "معرّف مزود الشحن غير صالح.",
        ["Shipping provider not found."] = "مزود الشحن غير موجود.",
        ["CompanyName is required."] = "اسم الشركة مطلوب.",
        ["FullName is required."] = "الاسم الكامل مطلوب.",
        ["AppName is required."] = "اسم التطبيق مطلوب.",
        ["AdDisplayDurationDays cannot be negative."] = "مدة عرض الإعلان لا يمكن أن تكون سالبة.",
        ["FeaturedAdPriceAed cannot be negative."] = "سعر الإعلان المميز لا يمكن أن يكون سالباً.",

        // System
        ["Login provider returned invalid result."] = "مزود تسجيل الدخول أعاد نتيجة غير صالحة.",
        ["SmsSettings are not configured."] = "إعدادات الرسائل القصيرة غير مهيأة.",
        ["Failed to send SMS notification."] = "فشل إرسال إشعار SMS.",
        ["Static reference cache is not loaded yet."] = "ذاكرة المراجع الثابتة غير محمّلة بعد.",
        ["Order total must be greater than zero."] = "إجمالي الطلب يجب أن يكون أكبر من صفر.",
    };

    private static readonly (Regex Pattern, Func<Match, string> Translate)[] Patterns =
    [
        (new Regex("^Unit '(.+)' was not found\\.$"), m => $"الوحدة '{m.Groups[1].Value}' غير موجودة."),
        (new Regex("^City '(.+)' was not found\\.$"), m => $"المدينة '{m.Groups[1].Value}' غير موجودة."),
        (new Regex("^Port '(.+)' was not found\\.$"), m => $"الميناء '{m.Groups[1].Value}' غير موجود."),
        (new Regex("^Category '(.+)' was not found\\.$"), m => $"الفئة '{m.Groups[1].Value}' غير موجودة."),
        (new Regex("^Product type '(.+)' was not found\\.$"), m => $"نوع المنتج '{m.Groups[1].Value}' غير موجود."),
        (new Regex("^Product '(.+)' was not found\\.$"), m => $"المنتج '{m.Groups[1].Value}' غير موجود."),
        (new Regex("^Product '(.+)' has no valid unit\\.$"), m => $"المنتج '{m.Groups[1].Value}' ليس له وحدة صالحة."),
        (new Regex("^Product '(.+)' has no owner\\.$"), m => $"المنتج '{m.Groups[1].Value}' ليس له مالك."),
        (new Regex("^Requested quantity exceeds available stock for '(.+)'\\.$"),
            m => $"الكمية المطلوبة تتجاوز المخزون المتاح لـ '{m.Groups[1].Value}'."),
        (new Regex("^Country '(.+)' was not found\\.$"), m => $"الدولة '{m.Groups[1].Value}' غير موجودة."),
        (new Regex("^Country id '(.+)' was not found\\.$"), m => $"معرّف الدولة '{m.Groups[1].Value}' غير موجود."),
        (new Regex("^Emirate '(.+)' was not found\\.$"), m => $"الإمارة '{m.Groups[1].Value}' غير موجودة."),
        (new Regex("^Emirate id (\\d+) was not found in cache\\.$"),
            m => $"معرّف الإمارة {m.Groups[1].Value} غير موجود في الذاكرة المؤقتة."),
        (new Regex("^Origin country '(.+)' was not found\\.$"), m => $"بلد المنشأ '{m.Groups[1].Value}' غير موجود."),
        (new Regex("^Destination country '(.+)' was not found\\.$"), m => $"بلد الوجهة '{m.Groups[1].Value}' غير موجود."),
        (new Regex("^From country '(.+)' was not found\\.$"), m => $"بلد المغادرة '{m.Groups[1].Value}' غير موجود."),
        (new Regex("^To country '(.+)' was not found\\.$"), m => $"بلد الوصول '{m.Groups[1].Value}' غير موجود."),
        (new Regex("^Port '(.+)' was not found for country '(.+)'\\.$"),
            m => $"الميناء '{m.Groups[1].Value}' غير موجود في الدولة '{m.Groups[2].Value}'."),
        (new Regex("^From port '(.+)' was not found for country '(.+)'\\.$"),
            m => $"ميناء المغادرة '{m.Groups[1].Value}' غير موجود في الدولة '{m.Groups[2].Value}'."),
        (new Regex("^To port '(.+)' was not found for country '(.+)'\\.$"),
            m => $"ميناء الوصول '{m.Groups[1].Value}' غير موجود في الدولة '{m.Groups[2].Value}'."),
        (new Regex("^Category '(.+)' already exists\\.$"), m => $"الفئة '{m.Groups[1].Value}' موجودة مسبقاً."),
        (new Regex("^DisplayOrder '(.+)' already exists\\.$"), m => $"ترتيب العرض '{m.Groups[1].Value}' موجود مسبقاً."),
        (new Regex("^Cannot change order status from '(.+)' to '(.+)'\\.$"),
            m => $"لا يمكن تغيير حالة الطلب من '{m.Groups[1].Value}' إلى '{m.Groups[2].Value}'."),
        (new Regex("^Your account registration was rejected\\. Reason: (.+)$"),
            m => $"تم رفض تسجيل حسابك. السبب: {m.Groups[1].Value}"),
        (new Regex("^(.+) must be between 0 and 100\\.$"),
            m => $"{m.Groups[1].Value} يجب أن يكون بين 0 و 100."),
    ];

    public static string Localize(string? message, string? language)
    {
        if (string.IsNullOrWhiteSpace(message) || !NotificationMessages.IsArabic(language))
        {
            return message ?? string.Empty;
        }

        var trimmed = message.Trim();
        if (ArabicByEnglish.TryGetValue(trimmed, out var exact))
        {
            return exact;
        }

        foreach (var (pattern, translate) in Patterns)
        {
            var match = pattern.Match(trimmed);
            if (match.Success)
            {
                return translate(match);
            }
        }

        return trimmed;
    }

    public static string AccountRejected(string? language, string? reason)
    {
        if (string.IsNullOrWhiteSpace(reason))
        {
            return Localize("Your account registration was rejected.", language);
        }

        return Localize($"Your account registration was rejected. Reason: {reason.Trim()}", language);
    }
}
