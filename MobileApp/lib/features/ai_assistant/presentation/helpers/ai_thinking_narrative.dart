import 'dart:math';

/// Builds a rich, locale-aware thinking narrative (~10 lines) that varies per request.
/// Never exposes tools, JSON, or model chain-of-thought — only user-facing progress prose.
class AiThinkingNarrative {
  AiThinkingNarrative._();

  static List<String> generate({
    required String userQuery,
    required bool isAr,
    required int seed,
  }) {
    final rng = Random(seed ^ userQuery.hashCode);
    final theme = _detectTheme(userQuery);
    final pools = isAr ? _poolsAr : _poolsEn;
    final themeLines = List<String>.from(pools[theme] ?? pools[_Theme.general]!);
    final shared = List<String>.from(pools[_Theme.shared]!);

    themeLines.shuffle(rng);
    shared.shuffle(rng);

    final out = <String>[];
    out.add(isAr ? _openingAr(rng, userQuery) : _openingEn(rng, userQuery));

    void take(List<String> source, int count) {
      for (final line in source) {
        if (out.length >= 10) return;
        if (out.contains(line)) continue;
        out.add(line);
        if (out.length - 1 >= count && out.length >= 4) break;
      }
    }

    take(themeLines, 6);
    take(shared, 4);

    while (out.length < 10) {
      final filler = shared[rng.nextInt(shared.length)];
      if (!out.contains(filler)) {
        out.add(filler);
      } else {
        out.add(
          isAr
              ? _extraAr[rng.nextInt(_extraAr.length)]
              : _extraEn[rng.nextInt(_extraEn.length)],
        );
      }
      // Prevent infinite loop if pools collide.
      if (out.length > 12) break;
    }

    // Keep exactly ~10 unique-ish lines.
    final trimmed = <String>[];
    for (final line in out) {
      if (trimmed.length >= 10) break;
      if (trimmed.isEmpty || trimmed.last != line) trimmed.add(line);
    }
    while (trimmed.length < 10) {
      trimmed.add(
        isAr
            ? _extraAr[rng.nextInt(_extraAr.length)]
            : _extraEn[rng.nextInt(_extraEn.length)],
      );
    }
    return trimmed.take(10).toList(growable: false);
  }

  /// Merge live backend activity into narrative without exposing technical text.
  static List<String> mergeBackendHints({
    required List<String> narrative,
    required Iterable<String> backendSteps,
    required bool isAr,
  }) {
    if (backendSteps.isEmpty) return narrative;
    final hints = <String>[];
    for (final raw in backendSteps) {
      final hint = _hintFromBackend(raw, isAr: isAr);
      if (hint == null) continue;
      if (hints.isEmpty || hints.last != hint) hints.add(hint);
    }
    if (hints.isEmpty) return narrative;

    final merged = List<String>.from(narrative);
    // Sprinkle backend-aligned hints into the middle without shrinking richness.
    var insertAt = (merged.length / 3).floor().clamp(1, merged.length - 1);
    for (final hint in hints.take(3)) {
      if (merged.contains(hint)) continue;
      merged.insert(insertAt.clamp(1, merged.length), hint);
      insertAt += 2;
    }
    return merged.take(12).toList(growable: false);
  }

  static _Theme _detectTheme(String query) {
    final q = query.toLowerCase();
    if (_hasAny(q, [
      'سعر',
      'اسعار',
      'أرخص',
      'ارخص',
      'أغلى',
      'اغلى',
      'price',
      'cheap',
      'expensive',
      'cost',
    ])) {
      return _Theme.price;
    }
    if (_hasAny(q, [
      'طلب',
      'اوردر',
      'شحن',
      'سلة',
      'order',
      'cart',
      'shipping',
      'track',
    ])) {
      return _Theme.order;
    }
    if (_hasAny(q, [
      'إعلان',
      'اعلان',
      'أنشئ',
      'انشئ',
      'نشر',
      'ad',
      'listing',
      'publish',
      'create',
    ])) {
      return _Theme.ads;
    }
    if (_hasAny(q, [
      'ابحث',
      'دور',
      'منتج',
      'كاردamom',
      'cardamom',
      'find',
      'search',
      'product',
      'show',
    ])) {
      return _Theme.search;
    }
    return _Theme.general;
  }

  static String _openingAr(Random rng, String query) {
    final short = _shortQuery(query, 28);
    final options = [
      'بفهم طلبك: «$short»…',
      'تمام، براجع اللي طلبته بخصوص «$short».',
      'خليني أفكّك السؤال وأرتّب الخطوات…',
      'بدأنا: بحدد أفضل طريقة أساعدك في «$short».',
    ];
    return options[rng.nextInt(options.length)];
  }

  static String _openingEn(Random rng, String query) {
    final short = _shortQuery(query, 36);
    final options = [
      'Understanding your request: “$short”…',
      'Got it — sorting the best path for “$short”.',
      'Breaking the question into clear steps…',
      'Starting: choosing how to help with “$short”.',
    ];
    return options[rng.nextInt(options.length)];
  }

  static String _shortQuery(String query, int max) {
    final cleaned = query
        .replaceAll(RegExp(r'\[.*?\]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= max) return cleaned;
    return '${cleaned.substring(0, max - 1)}…';
  }

  static String? _hintFromBackend(String raw, {required bool isAr}) {
    final lower = raw.toLowerCase();
    if (lower.contains('search') || lower.contains('بدوّر') || lower.contains('بدور')) {
      return isAr ? 'بدوّر في الكتالوج المناسب…' : 'Searching the matching catalog…';
    }
    if (lower.contains('price') || lower.contains('سعر')) {
      return isAr ? 'بقارن الأسعار والوحدات…' : 'Comparing prices and units…';
    }
    if (lower.contains('order') || lower.contains('طلب')) {
      return isAr ? 'براجع تفاصيل الطلب…' : 'Checking order details…';
    }
    if (lower.contains('upload') || lower.contains('رفع')) {
      return isAr ? 'بجهّز رفع الوسائط…' : 'Preparing media upload…';
    }
    return null;
  }

  static bool _hasAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n.toLowerCase())) return true;
    }
    return false;
  }
}

enum _Theme { search, price, order, ads, general, shared }

const _extraAr = [
  'برتّب النتائج بشكل أوضح…',
  'بتأكد إن الرد مناسب لحسابك…',
  'بلمّ الخلاصة النهائية…',
  'براجع التفاصيل الحساسة بسرعة…',
];

const _extraEn = [
  'Organizing the answer more clearly…',
  'Checking the reply fits your account…',
  'Gathering the final summary…',
  'Double-checking sensitive details…',
];

const Map<_Theme, List<String>> _poolsAr = {
  _Theme.search: [
    'بحدد نوع المنتج من كلامك…',
    'بدوّر في الإعلانات المعتمدة فقط…',
    'بفلتر النتائج حسب التوفر…',
    'بشيك الصور والمواصفات…',
    'برتّب أقرب المنتجات لطلبك…',
    'بستبعد النتائج الضعيفة أو النافدة…',
    'بقارن الوحدات والكميات المتاحة…',
    'بجهّز بطاقات المنتج للعرض…',
  ],
  _Theme.price: [
    'بجمع الأسعار الحالية من السوق…',
    'بقارن سعر الوحدة مش الإجمالي…',
    'براجع نوع السعر (محلي / إعادة تصدير)…',
    'بشيك فروقات العملة إن وجدت…',
    'برتّب من الأرخص للأنسب…',
    'بتأكد إن السعر مرتبط بالوحدة الصحيحة…',
    'بستبعد العروض المنتهية…',
    'بلخّص أفضل الخيارات السعرية…',
  ],
  _Theme.order: [
    'بفتح سجل الطلبات المرتبطة بحسابك…',
    'براجع حالة آخر تحديث…',
    'بتأكد من بيانات الشحن والتسليم…',
    'بشيك إن في تأخير أو إجراء مطلوب…',
    'بربط التفاصيل بالمنتج الصحيح…',
    'بلمّ ملخص واضح للحالة…',
    'بتأكد من الصلاحيات قبل أي إجراء…',
    'بجهّز الرد بخطوات عملية…',
  ],
  _Theme.ads: [
    'براجع نوع الإعلان المطلوب…',
    'بجمع الحقول الناقصة بهدوء…',
    'بتأكد من الوحدات والدول والموانئ…',
    'براجع شروط النشر لحسابك…',
    'برتّب مسودة واضحة قبل التنفيذ…',
    'بتأكد من الصور والمواصفات…',
    'بجهز خطوات الإنشاء بالترتيب…',
    'بلمّ تأكيد نهائي قبل الحفظ…',
  ],
  _Theme.general: [
    'بحدد إن السؤال داخل نطاق الراس الذكي…',
    'بختار أفضل مسار للإجابة…',
    'براجع المعلومات المتاحة لحسابك…',
    'بربط السياق بالمحادثة الحالية…',
    'بستبعد أي تفاصيل تقنية عنك…',
    'بصيغ الرد بلغة بسيطة ومباشرة…',
    'بتأكد إن فيه خطوة تالية واضحة…',
    'براجع إن تحتاج دعم بشري ولا لأ…',
  ],
  _Theme.shared: [
    'براجع جودة البيانات قبل العرض…',
    'بتأكد إن الرد مختصر ومفيد…',
    'بربط النتيجة بما سألت عنه…',
    'بجهز العرض النهائي في الشات…',
    'بلمسة أخيرة على الصياغة…',
    'بجهز الخلاصة الآن…',
  ],
};

const Map<_Theme, List<String>> _poolsEn = {
  _Theme.search: [
    'Identifying the product from your wording…',
    'Searching approved listings only…',
    'Filtering by availability…',
    'Checking images and specifications…',
    'Ranking the closest matches…',
    'Dropping weak or sold-out results…',
    'Comparing units and available quantity…',
    'Preparing product cards for chat…',
  ],
  _Theme.price: [
    'Collecting current market prices…',
    'Comparing unit price, not stock totals…',
    'Checking price type (Local / Rexport)…',
    'Reviewing currency differences if any…',
    'Sorting from cheapest to best fit…',
    'Confirming the price matches the unit…',
    'Skipping expired offers…',
    'Summarizing the strongest price options…',
  ],
  _Theme.order: [
    'Opening order history for your account…',
    'Checking the latest status update…',
    'Reviewing shipping and delivery details…',
    'Looking for delays or required actions…',
    'Linking details to the correct product…',
    'Building a clear status summary…',
    'Verifying permissions before any action…',
    'Preparing practical next steps…',
  ],
  _Theme.ads: [
    'Identifying the ad type you need…',
    'Collecting missing fields carefully…',
    'Checking units, countries, and ports…',
    'Reviewing publish rules for your account…',
    'Drafting a clear plan before execution…',
    'Validating photos and specifications…',
    'Ordering create steps correctly…',
    'Preparing a final confirmation…',
  ],
  _Theme.general: [
    'Checking the question is in Al-Ras scope…',
    'Choosing the best answer path…',
    'Reviewing information available to your account…',
    'Connecting context from this chat…',
    'Keeping technical internals hidden…',
    'Shaping a simple, direct reply…',
    'Making sure the next step is clear…',
    'Checking if human support is needed…',
  ],
  _Theme.shared: [
    'Validating data quality before showing it…',
    'Keeping the answer short and useful…',
    'Linking the result back to your question…',
    'Preparing the final chat presentation…',
    'Polishing the wording one last time…',
    'Wrapping the summary now…',
  ],
};
