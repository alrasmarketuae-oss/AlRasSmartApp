namespace BusinessLayer.Helpers;

using BusinessLayer.Interfaces;

public static class NotificationMessages
{
    public static bool IsArabic(string? language) =>
        string.Equals(language?.Trim(), "ar", StringComparison.OrdinalIgnoreCase);

    public static string NormalizeLanguage(string? language) =>
        IsArabic(language) ? "ar" : "en";

    public static string NormalizeLanguageOrThrow(string? language)
    {
        if (string.IsNullOrWhiteSpace(language))
        {
            return "en";
        }

        var normalized = language.Trim().ToLowerInvariant();
        if (normalized is not ("en" or "ar"))
        {
            throw new ArgumentException("Language must be 'en' or 'ar'.");
        }

        return normalized;
    }

    public static (string Title, string Body) Pick(
        string? language,
        string titleEn,
        string bodyEn,
        string titleAr,
        string bodyAr) =>
        IsArabic(language) ? (titleAr, bodyAr) : (titleEn, bodyEn);

    public static (string Title, string Body) PickOptional(
        string? language,
        string titleEn,
        string bodyEn,
        string? titleAr,
        string? bodyAr)
    {
        if (IsArabic(language)
            && !string.IsNullOrWhiteSpace(titleAr)
            && !string.IsNullOrWhiteSpace(bodyAr))
        {
            return (titleAr.Trim(), bodyAr.Trim());
        }

        return (titleEn, bodyEn);
    }

    public static (string Title, string Body) NewOrderAdmin(
        string? language,
        long orderId,
        string productName,
        string quantityLabel,
        string? details = null)
    {
        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultProductName(language) : productName.Trim();
        var qty = string.IsNullOrWhiteSpace(quantityLabel) ? "—" : quantityLabel.Trim();
        var detailsPart = string.IsNullOrWhiteSpace(details) ? string.Empty : $" · {details.Trim()}";
        return Pick(
            language,
            "New order received",
            $"Order #{orderId}: {safeName} · Qty {qty}{detailsPart}",
            "طلب جديد",
            $"طلب #{orderId}: {safeName} · الكمية {qty}{detailsPart}");
    }

    public static (string Title, string Body) SellerApprovedOrderAdmin(
        string? language,
        long orderId,
        string productName)
    {
        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultProductName(language) : productName.Trim();
        return Pick(
            language,
            "Advertiser approved order",
            $"The advertiser approved order #{orderId} for {safeName}.",
            "موافقة صاحب الإعلان",
            $"وافق صاحب الإعلان على الطلب رقم {orderId} للمنتج {safeName}.");
    }

    public static (string Title, string Body) OrderPlacedBuyer(string? language, long orderId) =>
        Pick(
            language,
            "Order placed",
            $"Your order #{orderId} was placed successfully. Track it in My Orders.",
            "تم تأكيد الطلب",
            $"تم تأكيد طلبك رقم {orderId}. يمكنك تتبعه من صفحة طلباتي.");

    public static (string Title, string Body) OrderStatusUpdatedBuyer(
        string? language,
        long orderId,
        string statusEn,
        string statusAr) =>
        Pick(
            language,
            "Order status updated",
            $"Your order #{orderId} is now: {statusEn}.",
            "تحديث حالة الطلب",
            $"تم تحديث طلبك رقم {orderId} إلى: {statusAr}.");

    public static (string Title, string Body) OrderStatusUpdatedSeller(
        string? language,
        long orderId,
        string statusEn,
        string statusAr) =>
        Pick(
            language,
            "Order status updated",
            $"Order #{orderId} is now: {statusEn}.",
            "تحديث حالة الطلب",
            $"تم تحديث الطلب رقم {orderId} إلى: {statusAr}.");

    public static (string Title, string Body) OrderAcceptedBySellerBuyer(string? language, long orderId) =>
        Pick(
            language,
            "Offer accepted",
            $"Your offer #{orderId} was accepted by the advertiser.",
            "تم قبول العرض",
            $"تم قبول عرضك رقم {orderId} من قبل المعلن.");

    public static (string Title, string Body) OrderRejectedBySellerBuyer(string? language, long orderId) =>
        Pick(
            language,
            "Offer declined",
            $"Your offer #{orderId} was rejected by the advertiser.",
            "تم رفض العرض",
            $"تم رفض عرضك رقم {orderId} من قبل المعلن.");

    public static (string Title, string Body) OfferRejectedByAdmin(
        string? language,
        long orderId,
        string? reasonEn,
        string? reasonAr)
    {
        var reasonE = string.IsNullOrWhiteSpace(reasonEn)
            ? "Please review your offer details and resubmit."
            : reasonEn.Trim();
        var reasonA = string.IsNullOrWhiteSpace(reasonAr)
            ? "يرجى مراجعة تفاصيل عرضك وإعادة الإرسال."
            : reasonAr.Trim();

        return Pick(
            language,
            "Offer not approved",
            $"Your offer #{orderId} was not approved. Reason: {reasonE}",
            "لم تتم الموافقة على العرض",
            $"لم تتم الموافقة على عرضك رقم {orderId}. السبب: {reasonA}");
    }

    public static (string Title, string Body) OrderRejectedByAdmin(
        string? language,
        long orderId,
        string? reasonEn,
        string? reasonAr)
    {
        var reasonE = string.IsNullOrWhiteSpace(reasonEn)
            ? "Please review your order details and resubmit."
            : reasonEn.Trim();
        var reasonA = string.IsNullOrWhiteSpace(reasonAr)
            ? "يرجى مراجعة تفاصيل طلبك وإعادة الإرسال."
            : reasonAr.Trim();

        return Pick(
            language,
            "Order not approved",
            $"Your order #{orderId} was not approved. Reason: {reasonE}",
            "لم تتم الموافقة على الطلب",
            $"لم تتم الموافقة على طلبك رقم {orderId}. السبب: {reasonA}");
    }

    public static (string Title, string Body) OrderRefundProcessedBuyer(string? language, long orderId) =>
        Pick(
            language,
            "Refund processed",
            $"Your refund for order #{orderId} has been processed to your original payment method.",
            "تم استرداد المبلغ",
            $"تم استرداد المبلغ لطلبك رقم {orderId} إلى طريقة الدفع الأصلية.");

    public static (string Title, string Body) OrderReturnRequestedAdmin(string? language, long orderId) =>
        Pick(
            language,
            "Return request",
            $"Order #{orderId} has a new return request. Support will review it.",
            "طلب استرجاع",
            $"طلب استرجاع جديد على الطلب رقم {orderId}. سيفحصه الدعم الفني.");

    public static (string Title, string Body) OrderReturnRequestedSupplier(
        string? language,
        long orderId,
        string productName)
    {
        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultProductName(language) : productName.Trim();
        return Pick(
            language,
            "Customer requested a return",
            $"A customer requested a return for order #{orderId} ({safeName}). Support is reviewing the case.",
            "طلب استرجاع من العميل",
            $"طلب العميل استرجاع المنتج للطلب رقم {orderId} ({safeName}). الدعم الفني يفحص الحالة.");
    }

    public static (string Title, string Body) OrderReturnResponseBuyer(
        string? language,
        long orderId,
        string response) =>
        Pick(
            language,
            "Return request update",
            $"Reply on order #{orderId}: {response}",
            "رد على طلب الاسترجاع",
            $"رد على طلب الاسترجاع للطلب رقم {orderId}: {response}");

    public static (string Title, string Body) OrderReturnApprovedOnlineBuyer(string? language, long orderId) =>
        Pick(
            language,
            "Return approved",
            $"Your return for order #{orderId} was approved and the product is marked as returned. The online refund will be processed by support separately; once issued, funds typically appear within 1–5 business days depending on your bank.",
            "تمت الموافقة على الاسترجاع",
            $"تمت الموافقة على استرجاع طلبك رقم {orderId} وتم تسجيل إرجاع المنتج. سيتم استرداد المبلغ الإلكتروني من قبل الدعم لاحقاً؛ وبعد إصدار الاسترداد عادةً يظهر المبلغ خلال 1–5 أيام عمل حسب البنك.");

    public static (string Title, string Body) OrderReturnApprovedCodBuyer(string? language, long orderId) =>
        Pick(
            language,
            "Return approved",
            $"Your return for order #{orderId} was approved and the product is marked as returned. This order was cash on delivery, so no online refund applies — payment was collected on delivery.",
            "تمت الموافقة على الاسترجاع",
            $"تمت الموافقة على استرجاع طلبك رقم {orderId} وتم تسجيل إرجاع المنتج. الطلب كان الدفع عند الاستلام، لذلك لا يوجد استرداد إلكتروني — تم الدفع عند التسليم.");

    public static (string Title, string Body) OrderReturnApprovedSupplier(
        string? language,
        long orderId,
        string productName)
    {
        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultProductName(language) : productName.Trim();
        return Pick(
            language,
            "Return approved by support",
            $"Support approved the return for order #{orderId} ({safeName}).",
            "موافقة الدعم على الاسترجاع",
            $"وافق الدعم الفني على استرجاع الطلب رقم {orderId} ({safeName}).");
    }

    public static (string Title, string Body) OrderReturnRejectedBuyer(
        string? language,
        long orderId,
        string response) =>
        Pick(
            language,
            "Return request update",
            $"Your return request for order #{orderId} was not approved. {response}",
            "تحديث طلب الاسترجاع",
            $"لم تتم الموافقة على طلب استرجاع الطلب رقم {orderId}. {response}");

    public static (string Title, string Body) NewProductOrderSeller(string? language, string productName)
    {
        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultProductName(language) : productName.Trim();
        return Pick(
            language,
            "New Order available",
            $"You have a new order for \"{safeName}\". Open My Orders to review it.",
            "طلب جديد متاح",
            $"لديك طلب جديد على منتج \"{safeName}\". افتح طلباتي لمراجعته.");
    }

    public static (string Title, string Body) NewProductOrderSeller(
        string? language,
        string productName,
        int pendingCount)
    {
        if (pendingCount <= 1)
        {
            return NewProductOrderSeller(language, productName);
        }

        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultProductName(language) : productName.Trim();
        return Pick(
            language,
            "New Order available",
            $"You have {pendingCount} pending orders on \"{safeName}\". Open My Orders to review them.",
            "طلب جديد متاح",
            $"لديك {pendingCount} طلبات معلقة على \"{safeName}\". افتح طلباتي لمراجعتها.");
    }

    public static (string Title, string Body) NewOfferOnRequest(string? language, string productName)
    {
        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultProductName(language) : productName.Trim();
        return Pick(
            language,
            "New offer on your request",
            $"You received a new offer on \"{safeName}\". Open My Orders to review it.",
            "عرض جديد على طلبك",
            $"وصلك عرض جديد على طلب \"{safeName}\". افتح طلباتي لمراجعته.");
    }

    public static (string Title, string Body) NewOfferOnRequest(
        string? language,
        string productName,
        int offerCount)
    {
        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultProductName(language) : productName.Trim();
        if (offerCount <= 1)
        {
            return NewOfferOnRequest(language, productName);
        }

        return Pick(
            language,
            "New offer on your request",
            $"You have {offerCount} offers on \"{safeName}\". Open My Orders to review them.",
            "عرض جديد على طلبك",
            $"لديك {offerCount} عروض على \"{safeName}\". افتح طلباتي لمراجعتها.");
    }

    public static (string EmailSubject, string EmailHtml, string FcmTitle, string FcmBody) AdApproved(
        string? language,
        string productName,
        string? adminNotes)
    {
        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultAdName(language) : productName.Trim();
        var hasNotes = !string.IsNullOrWhiteSpace(adminNotes);
        var notes = adminNotes?.Trim() ?? string.Empty;

        if (IsArabic(language))
        {
            var body = hasNotes
                ? $"تمت الموافقة على إعلانك \"{safeName}\". ملاحظات الإدارة: {notes}"
                : $"تمت الموافقة على إعلانك \"{safeName}\" وهو متاح الآن على تطبيق الراس الذكي.";

            return (
                "تمت الموافقة على إعلانك - Al Ras Smart",
                BuildAdDecisionEmailHtml(true, safeName, adminNotes, body, language),
                "تمت الموافقة على الإعلان",
                body);
        }

        var bodyEn = hasNotes
            ? $"Your ad \"{safeName}\" has been approved. Admin notes: {notes}"
            : $"Your ad \"{safeName}\" has been approved and is now live on Al Ras Smart.";

        return (
            "Your ad was approved - Al Ras Smart",
            BuildAdDecisionEmailHtml(true, safeName, adminNotes, bodyEn, language),
            "Ad Approved",
            bodyEn);
    }

    public static (string EmailSubject, string EmailHtml, string FcmTitle, string FcmBody) AdResubmittedForReview(
        string? language,
        string productName)
    {
        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultAdName(language) : productName.Trim();

        if (IsArabic(language))
        {
            var body = $"تم استلام تعديلاتك على إعلان \"{safeName}\". الإعلان قيد المراجعة وسنُبلغك عند الموافقة أو الرفض.";
            return (
                "تم إرسال تعديلات الإعلان للمراجعة - تطبيق الراس الذكي",
                BrandEmailLayout.Headline("الإعلان قيد المراجعة") +
                BrandEmailLayout.Paragraph(body) +
                BrandEmailLayout.InfoCard("الإعلان", safeName) +
                BrandEmailLayout.StatusPill("قيد المراجعة", BrandEmailLayout.Blue),
                "إعلان قيد المراجعة",
                body);
        }

        var bodyEn = $"Your edits to \"{safeName}\" were received. The ad is under review and we will notify you when it is approved or rejected.";
        return (
            "Ad edits submitted for review - Al Ras Smart",
            BrandEmailLayout.Headline("Ad under review") +
            BrandEmailLayout.Paragraph(bodyEn) +
            BrandEmailLayout.InfoCard("Ad", safeName) +
            BrandEmailLayout.StatusPill("Under review", BrandEmailLayout.Blue),
            "Ad Under Review",
            bodyEn);
    }

    public static (string EmailSubject, string EmailHtml, string FcmTitle, string FcmBody) AdRejected(
        string? language,
        string productName,
        string? adminNotesEn,
        string? adminNotesAr)
    {
        var safeName = string.IsNullOrWhiteSpace(productName) ? DefaultAdName(language) : productName.Trim();
        var reasonEn = string.IsNullOrWhiteSpace(adminNotesEn)
            ? "Please edit your ad details and resubmit."
            : adminNotesEn.Trim();
        var reasonAr = string.IsNullOrWhiteSpace(adminNotesAr)
            ? "يرجى تعديل تفاصيل إعلانك وإعادة الإرسال."
            : adminNotesAr.Trim();

        if (IsArabic(language))
        {
            var body =
                $"لم تتم الموافقة على إعلانك \"{safeName}\". السبب: {reasonAr} يمكنك تعديله وإعادة الإرسال.";
            return (
                "لم تتم الموافقة على إعلانك - Al Ras Smart",
                BuildAdDecisionEmailHtml(false, safeName, reasonAr, body, language),
                "لم تتم الموافقة على الإعلان",
                body);
        }

        var bodyEn =
            $"Your ad \"{safeName}\" was not approved. Reason: {reasonEn} You can edit it and resubmit.";
        return (
            "Your ad was not approved - Al Ras Smart",
            BuildAdDecisionEmailHtml(false, safeName, reasonEn, bodyEn, language),
            "Ad Not Approved",
            bodyEn);
    }

    public static (string EmailSubject, string EmailHtml, string FcmTitle, string FcmBody) CompanyApproved(
        string? language)
    {
        if (IsArabic(language))
        {
            return (
                "تمت الموافقة على حساب شركتك - تطبيق الراس الذكي",
                BrandEmailLayout.Headline("تمت الموافقة على حسابك") +
                BrandEmailLayout.StatusPill("موافَق", BrandEmailLayout.Green) +
                BrandEmailLayout.Paragraph("تمت الموافقة على حساب شركتك. يمكنك تسجيل الدخول واستخدام تطبيق الراس الذكي الآن."),
                "تمت الموافقة على الحساب",
                "تمت الموافقة على حساب شركتك. يمكنك تسجيل الدخول الآن.");
        }

        return (
            "Your company account has been approved - Al Ras Smart",
            BrandEmailLayout.Headline("Your account is approved") +
            BrandEmailLayout.StatusPill("Approved", BrandEmailLayout.Green) +
            BrandEmailLayout.Paragraph("Your company account is now approved. You can log in and start using Al Ras Smart."),
            "Account Approved",
            "Your company account is approved. You can now log in.");
    }

    public static (string EmailSubject, string EmailHtml, string FcmTitle, string FcmBody) CompanyProfileUpdateApproved(
        string? language)
    {
        if (IsArabic(language))
        {
            return (
                "تمت الموافقة على تحديث بيانات شركتك - تطبيق الراس الذكي",
                BrandEmailLayout.Headline("تم اعتماد تحديث البيانات") +
                BrandEmailLayout.StatusPill("موافَق", BrandEmailLayout.Green) +
                BrandEmailLayout.Paragraph("تمت الموافقة على التعديلات التي طلبتها. ستظهر البيانات الجديدة مباشرة في حسابك."),
                "تم اعتماد تحديث البيانات",
                "تمت الموافقة على تعديلات ملفك. افتح الملف الشخصي لرؤيتها.");
        }

        return (
            "Your profile update was approved - Al Ras Smart",
            BrandEmailLayout.Headline("Profile update approved") +
            BrandEmailLayout.StatusPill("Approved", BrandEmailLayout.Green) +
            BrandEmailLayout.Paragraph("Your requested profile changes were approved. The new data is now active on your account."),
            "Profile update approved",
            "Your profile changes were approved. Open your profile to see them.");
    }

    public static (string EmailSubject, string EmailHtml, string FcmTitle, string FcmBody) CompanyProfileUpdateRejected(
        string? language,
        string reason)
    {
        var safeReason = reason.Trim();

        if (IsArabic(language))
        {
            return (
                "رفض تحديث بيانات شركتك - تطبيق الراس الذكي",
                BrandEmailLayout.Headline("لم تتم الموافقة على التحديث") +
                BrandEmailLayout.StatusPill("مرفوض", BrandEmailLayout.Red) +
                BrandEmailLayout.Paragraph("لم تتم الموافقة على تعديلات ملفك.") +
                BrandEmailLayout.InfoCard("السبب", safeReason) +
                BrandEmailLayout.Paragraph("سيتم الإبقاء على بياناتك الحالية المعتمدة."),
                "رفض تحديث البيانات",
                $"لم تتم الموافقة على تعديلات ملفك. السبب: {safeReason}");
        }

        return (
            "Your profile update was rejected - Al Ras Smart",
            BrandEmailLayout.Headline("Profile update not approved") +
            BrandEmailLayout.StatusPill("Rejected", BrandEmailLayout.Red) +
            BrandEmailLayout.Paragraph("Your requested profile changes were not approved.") +
            BrandEmailLayout.InfoCard("Reason", safeReason) +
            BrandEmailLayout.Paragraph("Your currently approved data remains unchanged."),
            "Profile update rejected",
            $"Your profile changes were rejected. Reason: {safeReason}");
    }

    public static (string EmailSubject, string EmailHtml, string FcmTitle, string FcmBody) CompanyRejected(
        string? language,
        string reason)
    {
        var safeReason = reason.Trim();

        if (IsArabic(language))
        {
            return (
                "لم تتم الموافقة على حساب شركتك - تطبيق الراس الذكي",
                BrandEmailLayout.Headline("لم تتم الموافقة على التسجيل") +
                BrandEmailLayout.StatusPill("مرفوض", BrandEmailLayout.Red) +
                BrandEmailLayout.Paragraph("لم تتم الموافقة على تسجيل حساب شركتك على تطبيق الراس الذكي.") +
                BrandEmailLayout.InfoCard("السبب", safeReason) +
                BrandEmailLayout.Paragraph("يرجى تحديث مستنداتك وإعادة التسجيل، أو التواصل مع الدعم إذا كان لديك أي استفسار."),
                "لم تتم الموافقة على الحساب",
                safeReason);
        }

        return (
            "Your company account was not approved - Al Ras Smart",
            BrandEmailLayout.Headline("Registration not approved") +
            BrandEmailLayout.StatusPill("Rejected", BrandEmailLayout.Red) +
            BrandEmailLayout.Paragraph("Your company account registration on Al Ras Smart was not approved.") +
            BrandEmailLayout.InfoCard("Reason", safeReason) +
            BrandEmailLayout.Paragraph("Please update your documents and register again, or contact support if you have questions."),
            "Account Not Approved",
            safeReason);
    }

    public static string ChatFallbackSenderName(string? language) =>
        IsArabic(language) ? "رسالة جديدة" : "New message";

    public static string ChatAdminSenderName(string? language) =>
        IsArabic(language) ? "تطبيق الراس الذكي - الإدارة" : "Al Ras Smart - Admin";

    public static string ChatUserFallbackName(string? language) =>
        IsArabic(language) ? "مستخدم" : "User";

    public static string BuildChatPushBody(string? language, ChatApiMessageType messageType, string content)
    {
        if (ChatE2eContentHelper.IsEncryptedEnvelope(content))
        {
            return IsArabic(language) ? "🔒 رسالة مشفرة جديدة" : "🔒 New encrypted message";
        }

        return messageType switch
        {
            ChatApiMessageType.Text => TruncateChatPreview(content, 160),
            ChatApiMessageType.Image => IsArabic(language) ? "📷 صورة" : "📷 Photo",
            ChatApiMessageType.Voice => IsArabic(language) ? "🎤 رسالة صوتية" : "🎤 Voice message",
            ChatApiMessageType.Location => IsArabic(language) ? "📍 موقع" : "📍 Location",
            ChatApiMessageType.Video => IsArabic(language) ? "🎬 فيديو" : "🎬 Video",
            ChatApiMessageType.File => ChatFileContentHelper.TryParse(content, out var fileContent)
                ? $"📎 {TruncateChatPreview(fileContent.FileName, 60)}"
                : IsArabic(language) ? "📎 ملف" : "📎 File",
            _ => ChatFallbackSenderName(language)
        };
    }

    private static string DefaultProductName(string? language) =>
        IsArabic(language) ? "منتجك" : "your product";

    private static string DefaultAdName(string? language) =>
        IsArabic(language) ? "إعلانك" : "Your ad";

    private static string TruncateChatPreview(string content, int maxLength)
    {
        var trimmed = content.Trim();
        if (trimmed.Length <= maxLength)
        {
            return trimmed;
        }

        return trimmed[..maxLength] + "…";
    }

    private static string BuildAdDecisionEmailHtml(
        bool approved,
        string productName,
        string? adminNotes,
        string summary,
        string? language)
    {
        var arabic = IsArabic(language);
        var headline = approved
            ? (arabic ? "تمت الموافقة على إعلانك" : "Your ad was approved")
            : (arabic ? "لم تتم الموافقة على إعلانك" : "Your ad was not approved");
        var pill = approved
            ? BrandEmailLayout.StatusPill(arabic ? "موافَق" : "Approved", BrandEmailLayout.Green)
            : BrandEmailLayout.StatusPill(arabic ? "مرفوض" : "Not approved", BrandEmailLayout.Red);
        var notesBlock = string.IsNullOrWhiteSpace(adminNotes)
            ? string.Empty
            : BrandEmailLayout.InfoCard(arabic ? "ملاحظات الإدارة" : "Admin notes", adminNotes.Trim());

        return
            BrandEmailLayout.Headline(headline) +
            pill +
            BrandEmailLayout.Paragraph(summary) +
            BrandEmailLayout.InfoCard(arabic ? "الإعلان" : "Ad", productName) +
            notesBlock;
    }
}
