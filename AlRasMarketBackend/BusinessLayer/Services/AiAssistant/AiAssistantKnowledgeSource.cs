using System.Security.Cryptography;
using System.Text;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services.AiAssistant;

/// <summary>
/// The assistant's entire grounding corpus. Every user-visible behaviour claimed here
/// must match the running code (statuses, currencies, permissions), because the model
/// is forbidden from answering outside this text.
/// </summary>
internal static class AiAssistantKnowledgeSource
{
    public static IReadOnlyList<AiKnowledgeChunk> Build()
    {
        var chunks = new List<AiKnowledgeChunk>();

        AddPlatformAndLegal(chunks);
        AddAccountTypesAndCapabilities(chunks);
        AddNavigation(chunks);
        AddRegistrationAndSignIn(chunks);
        AddProfileAndSettings(chunks);
        AddSearch(chunks);
        AddBrowsingAndListings(chunks);
        AddBuyingAndPayments(chunks);
        AddOrdersAndTracking(chunks);
        AddRecentOrdersAndAdsUpdates(chunks);
        AddReturnsAndRefunds(chunks);
        AddSupplierAdCreation(chunks);
        AddAdManagement(chunks);
        AddRequestsAndOffers(chunks);
        AddShippingCompany(chunks);
        AddSupport(chunks);
        AddCommonQuestions(chunks);
        AddTroubleshooting(chunks);

        return chunks;
    }

    // ---------------------------------------------------------------------
    // 1. Platform, terms, privacy, trust
    // ---------------------------------------------------------------------

    private static void AddPlatformAndLegal(ICollection<AiKnowledgeChunk> chunks)
    {
        // Short identity questions score badly against long chunks, so these are
        // written with the phrasings users actually type.
        Add(chunks, "assistant-identity", "من أنت؟ عرفني بنفسك، انت مين، مين انت", "ar", All,
            """
            سؤال: من أنت؟ انت مين؟ عرفني بنفسك؟ ايه انت؟ مين بيكلمني؟ ما اسمك؟ بتعرف تعمل ايه؟ تقدر تعمل ايه؟
            الإجابة: أنا الراس الذكي (Alras Smart)، المساعد الرسمي داخل تطبيق الراس الذكي.
            اسمي بالعربية: الراس الذكي. واسمي بالإنجليزية: Alras Smart.
            أقدر بدقة (حسب نوع حسابك): إضافة إعلانات، تعديل الأسعار والكميات لعدة إعلانات في نفس الرسالة عند الطلب، البحث في المنتجات ومقارنة الأسعار، جلب الأرخص والأغلى، معرفة أسعار الشحن إلى دولة معيّنة، جلب تفاصيل إعلاناتك وطلباتك، ومعرفة مبيعاتك والطلبات المعلّقة على إعلاناتك.
            ما أقدر أعمله يعتمد على نوع الحساب: المورد ينشئ أنواع إعلانات متعددة ويدير الإعلانات والمبيعات؛ عميل الشركة ينشئ Request فقط؛ شركة الشحن تنشئ إعلان شحن فقط؛ العميل الفردي يشتري ويتابع الطلبات ولا ينشئ إعلانات.
            إذا طلب أحد إنشاء إعلان وهو غير مخوّل، أرفض فوراً قبل جمع أي حقول.
            أنا لست موظف دعم بشري: للحالات الفردية التي تحتاج تدخلاً بشرياً استخدم Live Chat من الملف الشخصي.
            أفهم وأتكلم أي لغة يكتب بها المستخدم (عربية بأي لهجة، إنجليزية، فرنسية، هندية، أوردو، فلبينية، وغيرها) وأرد بنفس لغة رسالته فوراً دون تقييد بالعربية أو الإنجليزية فقط.
            """);
        Add(chunks, "assistant-identity", "Who are you? Introduce yourself, what are you", "en", All,
            """
            Question: who are you? What are you? Introduce yourself. Who am I talking to? What is your name? What can you do?
            Answer: I am Alras Smart (الراس الذكي), the official AI agent inside the Al Ras Smart app.
            My English name is Alras Smart. My Arabic name is الراس الذكي.
            Precisely, I can (depending on your account type): create ads, update prices and quantities on multiple ads in the same message when asked, search products and compare prices, fetch the cheapest and most expensive listings, look up shipping prices to a country, fetch details of your ads and orders, and report your sales and pending orders on your ads.
            What I can do depends on account type: suppliers can create multiple ad types and manage ads and sales; company customers can create Request only; shipping companies create shipping ads only; personal customers buy and track orders and cannot create ads.
            If someone tries to create an ad they are not authorized for, I refuse immediately before collecting any fields.
            I am not a human support agent: for individual cases needing human action, use Live Chat from Profile.
            I understand and reply in ANY language the user writes (any Arabic dialect, English, French, Hindi, Urdu, Tagalog, Spanish, and more). Match their message language immediately — never force only Arabic or English.
            """);

        Add(chunks, "app-introduction", "عرفني عن التطبيق، ما هي هذه المنصة، ايه هو الراس الذكي", "ar", All,
            """
            سؤال: عرفني عن التطبيق؟ ما هي هذه المنصة؟ ايه هو الراس الذكي؟ التطبيق ده بيعمل ايه؟ ما فائدة هذا التطبيق؟ اشرح لي المنصة؟
            الإجابة: الراس الذكي تطبيق ومنصة سوق إلكترونية لتجارة المواد الغذائية والبضائع، تربط بين الموردين والمشترين في مكان واحد.
            تشغّل المنصة شركة ميرج سبايس لتجارة المواد الغذائية، وتعمل كوسيط ينظم العملية التجارية بين البائع والمشتري.
            من خلال التطبيق يمكنك: تصفح المنتجات داخل الأصناف، والبحث بالاسم أو بالصورة، وشراء منتجات التجزئة، وطلب البضائع بالجملة، وعرض بضائعك للبيع إن كنت مورداً، ونشر طلب شراء إن كنت شركة، وعرض خدمات الشحن إن كنت شركة شحن.
            كما يوفر التطبيق تتبع الطلبات خطوة بخطوة، وسياسة استرجاع للحالات المؤهلة، ودعماً بشرياً مباشراً عبر Live Chat، ومساعداً ذكياً للإجابة عن أسئلتك.
            التطبيق يدعم العربية والإنجليزية، والعملات المستخدمة هي الدرهم الإماراتي والدولار الأمريكي.
            ما تراه داخل التطبيق يختلف حسب نوع حسابك: مورد، أو عميل فردي، أو عميل شركة، أو شركة شحن.
            """);
        Add(chunks, "app-introduction", "Tell me about the app, what is this platform, what is Al Ras Smart", "en", All,
            """
            Question: tell me about the app? What is this platform? What is Al Ras Smart? What does this app do? What is this app for? Explain the platform to me.
            Answer: Al Ras Smart is an app and electronic marketplace for foodstuff and goods trading that connects suppliers and buyers in one place.
            It is operated by Merge Spice Foodstuff Trading LLC, which acts as an intermediary organising the trade process between seller and buyer.
            Through the app you can: browse products inside categories, search by name or by image, buy retail products, source goods wholesale, list your goods for sale if you are a supplier, publish a purchase request if you are a company, and publish freight services if you are a shipping company.
            The app also provides step-by-step order tracking, a returns policy for eligible cases, direct human support via Live Chat, and an AI Assistant to answer your questions.
            It supports Arabic and English, and the currencies used are the UAE Dirham and the US Dollar.
            What you see inside the app depends on your account type: supplier, personal customer, company customer, or shipping company.
            """);

        Add(chunks, "how-to-start", "كيف أبدأ استخدام التطبيق، ماذا أفعل أولاً", "ar", All,
            """
            سؤال: كيف أبدأ؟ ماذا أفعل أولاً؟ من أين أبدأ في التطبيق؟ كيف أستخدم التطبيق؟
            الإجابة: ابدأ بتسجيل الدخول أو إنشاء حساب، لأن معظم الإجراءات تحتاج حساباً.
            إن كنت مشترياً فرداً فأنشئ حسابك بجوجل أو أبل في ثوانٍ، ثم تصفح منتجات التجزئة في الصفحة الرئيسية أو ابحث عما تريد بالاسم أو بالصورة، ثم أضف إلى السلة وأكمل الشراء، وتابع طلبك من صفحة طلباتي.
            إن كنت مورداً فأكمل التسجيل بالرخصة التجارية وصور الشركة وانتظر الاعتماد، ثم أنشئ إعلاناتك من زر إنشاء إعلان، وتابعها من صفحة الحساب. المورد يستطيع أيضاً الشراء وطلب البضائع مثل أي مشتري ويتابع مشترياته من صفحة طلباتي، بالإضافة لمتابعة الطلبات الواردة على إعلاناته.
            إن كنت شركة تشتري بالجملة فتصفح الأصناف، وإن لم تجد ما تريد فانشر إعلان Request من صفحة إنشاء طلب واستقبل العروض.
            إن كنت شركة شحن فأضف إعلان الشحن من الصفحة الرئيسية وأدر إعلاناتك من نفس المكان.
            في أي وقت يمكنك سؤالي عن أي خطوة، أو التواصل مع Live Chat لمساعدة بشرية.
            """);
        Add(chunks, "how-to-start", "How do I start using the app, what should I do first", "en", All,
            """
            Question: how do I start? What should I do first? Where do I begin in the app? How do I use the app?
            Answer: start by signing in or creating an account, because most actions require one.
            If you are an individual buyer, create your account with Google or Apple in seconds, then browse retail products on home or search by name or image, add to cart and complete the purchase, and follow your order from My Orders.
            If you are a supplier, complete registration with your trade license and company images and wait for approval, then create listings from the Create Ad button, follow them from the Account page. Suppliers can also buy and place orders like any buyer and track those purchases from My Orders, in addition to incoming orders on their ads.
            If you are a company buying wholesale, browse the categories, and if you cannot find what you need publish a Request ad from the Create Order page and receive offers.
            If you are a shipping company, add your shipping ad from Home and manage your ads from the same place.
            At any time you can ask me about any step, or use Live Chat for human help.
            """);

        Add(chunks, "who-operates", "من يملك المنصة ومن يديرها ومن بناها", "ar", All,
            """
            سؤال: من صاحب التطبيق؟ من بنى المنصة؟ من يدير المنصة؟ ما هي الشركة المشغلة؟
            الإجابة: بنى وصمّم وبرمج تطبيقات ومنصة الراس الذكي ناصر مصطفى محمد البربري، وهو أيضاً من درّب نموذج الذكاء الاصطناعي الخاص بها.
            أما تشغيل منصة الراس الذكي وإدارة عمليات السوق فتتولاهما شركة ميرج سبايس لتجارة المواد الغذائية.
            دور الشركة هو الوساطة وتنظيم العمليات التجارية بين الموردين والعملاء، وهي ليست مالكة للبضائع المعروضة على المنصة.
            المورد هو المسؤول عن بضاعته من حيث الجودة والكمية والوزن والتغليف ومطابقتها لوصف الإعلان.
            تخضع الشروط لقوانين دولة الإمارات العربية المتحدة وتختص محاكم دبي بالنزاعات.
            """);
        Add(chunks, "who-operates", "Who built, owns, and operates the platform", "en", All,
            """
            Question: who owns the app? Who built the platform? Who runs it? Which company operates it?
            Answer: Nasser Mostafa Mohamed Elbarbary built, designed, and programmed the Al Ras Smart apps and platform, and he also trained its AI model.
            The Al Ras Smart marketplace and its commercial operations are operated by Merge Spice Foodstuff Trading LLC.
            The company's role is intermediation and organising trade between suppliers and customers; it does not own the goods listed on the platform.
            The supplier is responsible for their goods in terms of quality, quantity, weight, packaging, and matching the listing description.
            The Terms are governed by UAE law and Dubai courts have jurisdiction over disputes.
            """);

        Add(chunks, "app-developer", "مين عامل البرنامج، مين المطور، مين صانع التطبيق، من برمج أو بنى الراس الذكي، من درب النموذج", "ar", All,
            """
            سؤال: مين عامل البرنامج ده؟ مين المطور؟ مين الصانع؟ من برمج التطبيق أو بنى المنصة؟ من صمم وطور الراس الذكي؟ من درّب نموذج الذكاء الاصطناعي؟ عاوز أتواصل مع المطور.
            الإجابة: ناصر مصطفى محمد البربري هو الذي بنى وصمّم وبرمج تطبيقات ومنصة الراس الذكي، وهو أيضاً الذي درّب نموذج الذكاء الاصطناعي الخاص بها.
            رقم الهاتف وواتساب: +971 56 916 6263.
            البريد الإلكتروني: nasermostafa.ma122@gmail.com
            للتواصل عبر واتساب يجب إظهار هذا الرابط بهذه الصيغة بالضبط: [اضغط هنا للتواصل عبر واتساب](https://wa.me/971569166263)
            للتواصل عبر البريد يجب إظهار هذا الرابط بهذه الصيغة بالضبط: [اضغط هنا لإرسال بريد إلكتروني](mailto:nasermostafa.ma122@gmail.com)
            يجب أن تكون عبارة «اضغط هنا» قابلة للضغط، ولا تعرض الرابط الخام وحده بدلاً منها.
            تنبيه مهم: ناصر هو باني ومصمم ومبرمج التطبيقات والمنصة ومدرّب نموذج الذكاء الاصطناعي، أما الشركة التي تشغّل السوق وتدير عملياته التجارية فهي شركة ميرج سبايس لتجارة المواد الغذائية. لا تخلط بين البناء والتطوير والتدريب وبين التشغيل التجاري.
            للاستفسارات التقنية والتواصل مع المطوّر استخدم بيانات ناصر أعلاه، أما مشكلات الطلبات والاسترجاع والحساب فتُتابع مع دعم الراس الذكي عبر Live Chat.
            """);
        Add(chunks, "app-developer", "Who made the program, developed or built Al Ras Smart, who trained the AI model", "en", All,
            """
            Question: who made this program? Who is the developer? Who built or programmed the app or platform? Who designed and developed Al Ras Smart? Who trained its AI model? I want to contact the developer.
            Answer: Nasser Mostafa Mohamed Elbarbary built, designed, and programmed the Al Ras Smart apps and platform, and he also trained its AI model.
            Phone and WhatsApp: +971 56 916 6263.
            Email: nasermostafa.ma122@gmail.com
            For WhatsApp, show exactly: [Click here to contact via WhatsApp](https://wa.me/971569166263)
            For email, show exactly: [Click here to send an email](mailto:nasermostafa.ma122@gmail.com)
            “Click here” must be clickable; do not replace it with a raw URL alone.
            Important distinction: Nasser built and developed the apps and platform and trained the AI model, while Merge Spice Foodstuff Trading LLC operates the marketplace and its commercial activities. Do not confuse building, development, and AI training with commercial operation.
            Use Nasser's details above for technical enquiries or contacting the developer; order, return, and account issues should go to Al Ras Smart support through Live Chat.
            """);

        Add(chunks, "what-can-i-do", "ماذا يمكنني أن أفعل في التطبيق بحسابي", "ar", SignedIn,
            """
            سؤال: ماذا أستطيع أن أفعل هنا؟ ما الميزات المتاحة لي؟ ما الذي يمكنني فعله بحسابي؟
            الإجابة: كل مستخدم مسجل يستطيع: تصفح المنتجات المتاحة لنوع حسابه، والبحث بالنص أو بالصورة، وفتح تفاصيل الإعلانات، وحفظ الإعلانات المفضلة، وإدارة العناوين المحفوظة، وتعديل ملفه الشخصي وكلمة السر واللغة والبصمة، والتواصل مع Live Chat، وتصفح المساعدة والدعم.
            المشترون إضافة إلى ذلك: يشترون ويتابعون طلباتهم من صفحة طلباتي ويطلبون الاسترجاع للحالات المؤهلة.
            المورد داخل الإمارات ينشئ كل أنواع الإعلانات تقريباً. أما المورد المسجل برقم هاتف غير إماراتي والموجود خارج الإمارات فينشئ Booking فقط. ويدير المورد إعلانه من قسم إعلاناتي، ويتابع عروضه من قسم عروضي.
            مهم: المورد يستطيع أيضاً الشراء وطلب المنتجات ومتابعة مشترياته من صفحة طلباتي مثل أي مشتري، فهذا غير مقتصر على العملاء فقط.
            عميل الشركة إضافة إلى ذلك: ينشر إعلانات Request ويستقبل العروض ويقبل أو يرفض.
            شركة الشحن: تضيف إعلانات الشحن وتديرها فقط.
            """);
        Add(chunks, "what-can-i-do", "What can I do in the app with my account", "en", SignedIn,
            """
            Question: what can I do here? What features are available to me? What can I do with my account?
            Answer: every signed-in user can browse the products available to their account type, search by text or image, open listing details, save favourite listings, manage saved addresses, edit their profile, password, language, and biometric unlock, use Live Chat, and read Help and Support.
            Buyers additionally purchase, follow their orders from My Orders, and request returns for eligible cases.
            UAE-based suppliers additionally create almost all ad types. A supplier registered with a non-UAE phone number and located outside the UAE can create Booking ads only. Suppliers manage listings in My Ads, follow bids in My Offers.
            Important: suppliers can also buy products, place orders, and track their purchases from My Orders like any buyer — buying is not limited to customer accounts.
            Company customers additionally publish Request ads and receive, accept, or reject offers.
            Shipping companies add and manage shipping ads only.
            """);

        Add(chunks, "platform-overview", "شرح منصة الراس الذكي", "ar", All,
            """
            الراس الذكي منصة سوق إلكترونية تربط الموردين والعملاء الأفراد وعملاء الشركات وشركات الشحن.
            تعرض المنصة المنتجات داخل الأصناف (Categories)، وتدعم أنواع إعلانات هي: Retail (تجزئة) وBooking (حجز/شحنات) وOffers (عروض بخصم) وRequests (طلبات شراء) وShipping (شحن).
            ما يظهر لك وما يمكنك تنفيذه يختلف حسب نوع حسابك.
            توفر المنصة بحثاً نصياً واقتراحات فورية وبحثاً بالصورة، وسلة شراء وطلبات وتتبع حالة الطلب، ودعماً بشرياً عبر Live Chat، ومساعد ذكاء اصطناعي لشرح المنصة وسياساتها.
            تعمل شركة ميرج سبايس لتجارة المواد الغذائية كوسيط لتنظيم العمليات التجارية، وليست مالكة للبضائع المعروضة.
            """);
        Add(chunks, "platform-overview", "Al Ras Smart platform overview", "en", All,
            """
            Al Ras Smart is an electronic marketplace connecting suppliers, personal customers, company customers, and shipping companies.
            It lists products under Categories and supports ad types: Retail, Booking, Offers (discounted), Requests, and Shipping.
            What you can see and do depends on your account type.
            The platform provides text search, instant suggestions, image search, a cart, orders with status tracking, human Live Chat support, and an AI Assistant for platform knowledge and policies.
            Merge Spice Foodstuff Trading LLC operates as an intermediary that organises the trade process and does not own the listed goods.
            """);

        Add(chunks, "app-walkthrough-home", "شرح الصفحة الرئيسية وأقسام التطبيق، الطلبات، العروض، الحجز، البيع المحلي، الشحن", "ar", All,
            """
            سؤال: اشرح لي التطبيق؟ ما هي أقسام الصفحة الرئيسية؟ ما هي الطلبات والعروض والحجز والبيع المحلي وأسعار الشحن؟ كيف أستخدم الراس الذكي؟
            الإجابة: تطبيق الراس الذكي منصة B2B ذكية لتجارة المواد الغذائية بالجملة، تربط المشترين والموردين وتجار الجملة وشركات الشحن في منصة واحدة.
            عند فتح التطبيق يظهر في الأعلى شريط إعلاني متحرك لأخبار السوق والمنتجات الجديدة والفرص والعروض المميزة.
            أسفل الشريط خمسة أقسام رئيسية:
            1) الطلبات Requests: طلبات منتجات ينشرها مشترون أو موردون يبحثون عن بضائع؛ يمكنك متابعة طلباتك أو تقديم عرض إذا كان المطلوب متوفراً لديك.
            2) العروض Offers: للموردين الذين يريدون بيع بضائع بسرعة أو بأسعار مميزة؛ لاكتشاف عروض الجملة والبضائع المخفضة.
            3) الحجز Booking: منتجات بأسعار حجز للتجارة الدولية؛ المورد ينشر السعر والمنشأ والوجهة وشروط الشحن.
            4) البيع المحلي Retail: بيع المنتجات داخل دولة الإمارات بسعر محلي إضافي.
            5) أسعار الشحن Shipping Prices: أسعار وتحديثات شركات الشحن للمقارنة عند التخطيط للاستيراد أو التصدير.
            بعد ذلك أقسام المواد الغذائية: توابل، هيل، بقوليات، أعشاب، أرز، منتجات حليب، قهوة، مكسرات، بذور، فواكه مجففة وغيرها.
            أسفل الأقسام تظهر العروض المميزة Featured Offers.
            في أسفل التطبيق شريط التنقل: الصفحة الرئيسية، الحساب، وإنشاء إعلان جديد أو طلب منتج.
            """);

        Add(chunks, "app-walkthrough-home", "Home screen sections: Requests, Offers, Booking, Retail, Shipping", "en", All,
            """
            Question: explain the app home screen? What are Requests, Offers, Booking, Retail, and Shipping Prices sections?
            Answer: Al Ras Smart is a smart B2B wholesale food trading platform connecting buyers, suppliers, wholesalers, and shipping companies in one place.
            At the top is a scrolling news banner for market news, new products, opportunities, and featured offers.
            Below it are five main sections:
            1) Requests: product requests posted by buyers or suppliers looking for goods; follow your own requests or submit an offer if you have the product.
            2) Offers: for suppliers who want to sell quickly or at special prices; discover wholesale deals and discounted goods.
            3) Booking: products listed at booking prices for international trade; suppliers publish price, origin, destination, and shipping terms.
            4) Retail: sell products inside the UAE with a local retail price.
            5) Shipping Prices: freight rates and updates from shipping companies for import/export planning.
            Then food categories: spices, cardamom, legumes, herbs, rice, dairy, coffee, nuts, seeds, dried fruits, and more.
            Featured Offers appear below the categories.
            The bottom navigation bar gives Home, Account, and Create Ad / Create Request.
            """);

        Add(chunks, "app-walkthrough-create-ads", "كيف أنشئ إعلان، حجز، طلب، عرض، التعبئة، النشر والمراجعة", "ar", All,
            """
            سؤال: كيف أنشئ إعلان؟ كيف أنشئ حجز أو طلب أو عرض؟ ما خطوات النشر؟
            الإجابة: من شريط التنقل اضغط إنشاء إعلان جديد.
            للمورد: ارفع صور المنتج، اكتب الاسم والكمية والسعر، حدد إن كان للسوق المحلي داخل الإمارات أو لإعادة التصدير، ثم اختر نوع الإعلان: منتج، حجز Booking، بيع محلي Retail، طلب Request، أو عرض Offer، وأضف المواصفات.
            للحجز Booking: ارفع الصور، أدخل السعر والعملة ووحدة القياس، اختر نوع السعر FOB أو CNF أو CIF، حدد بلد المنشأ وميناء الشحن ودولة الوجهة وميناء الوصول، وعدد أيام الشحن المتوقعة ونوع التعبئة والمواصفات.
            إذا لم تجد المنتج: أنشئ طلب Request — ارفع صورة أو اكتب الاسم، وهل السعر قابل للتفاوض، وللسوق المحلي أو إعادة التصدير، وأضف المواصفات والتعبئة؛ الموردون يقدمون عروضهم بعد النشر.
            السعر المستهدف والكمية المطلوبة والوحدة والعملة اختيارية في طلب Request — لا تطلبها إلا إذا أرادها المستخدم.
            نوع التعبئة Packing: اختر التعبئة الأساسية أو أضف خيارات تعبئة متعددة إن وُجدت.
            للعرض Offer: ارفع الصور، أدخل السعر قبل وبعد الخصم، حدد العملة والوحدة، محلي أو تصدير، قابل للتفاوض أم لا، ومدة العرض بالأيام والتعبئة والمواصفات.
            بعد إدخال البيانات اضغط نشر Publish؛ يُرسل الإعلان للمراجعة من الإدارة، وبعد الموافقة يظهر داخل التطبيق.
            """);

        Add(chunks, "app-walkthrough-create-ads", "How to create ads: Booking, Request, Offer, packing, publish", "en", All,
            """
            Question: how do I create an ad? How to create Booking, Request, or Offer listings? What are the publish steps?
            Answer: from the bottom bar tap Create Ad.
            As a supplier: upload product photos, enter name, quantity, and price, choose local UAE market or re-export, pick ad type Product, Booking, Retail, Request, or Offer, and add specifications.
            For Booking: upload photos, enter price, currency, and unit, choose FOB, CNF, or CIF, set origin country and port, destination country and port, expected shipping days, packing type, and specs.
            If the product is not listed: create a Request — upload a photo or type the name, set negotiable or fixed, local or re-export, packing, and specs; suppliers can submit offers after you publish.
            Target price, required quantity, unit, and currency are OPTIONAL on Request ads — only collect them when the user wants them.
            Packing: choose the primary pack type or add multiple packing options when available.
            For Offer: upload photos, enter price before and after discount, currency and unit, local or export, negotiable or not, offer duration in days, packing, and specs.
            Tap Publish; the ad goes to admin review and appears in the app after approval.
            """);

        Add(chunks, "app-walkthrough-b2b-outro", "منصة B2B متكاملة، حمّل التطبيق، من دبي إلى أسواق العالم", "ar", All,
            """
            سؤال: لماذا أستخدم الراس الذكي؟ ما فائدة المنصة؟ حمّل التطبيق
            الإجابة: مع تطبيق الراس الذكي تصبح تجارة المواد الغذائية بالجملة أسهل: المشتري يصل للمورد، والمورد يصل للمشترين، والموردون يتعاملون مع بعضهم.
            يمكنك البحث عن البضائع، طلب منتجات غير متوفرة، عرض مخزونك، نشر أسعار الحجز، إنشاء عروض خاصة، البيع داخل الإمارات، ومتابعة أسعار الشحن — كل ذلك من منصة واحدة.
            من دبي إلى أسواق العالم: اكتشف الفرص، ابحث عن منتجاتك، اشترِ، بع، وتواصل مع موردين وعملاء جدد.
            تطبيق الراس الذكي — بوابتك الذكية إلى عالم تجارة المواد الغذائية بالجملة.
            حمّل تطبيق الراس الذكي الآن على iOS وAndroid.
            """);

        Add(chunks, "app-walkthrough-b2b-outro", "Integrated B2B platform, download the app", "en", All,
            """
            Question: why use Al Ras Smart? What is the platform value? Download the app
            Answer: Al Ras Smart makes wholesale food trading easier: buyers reach suppliers, suppliers reach buyers, and suppliers can trade with each other.
            Search goods, request unavailable products, list your stock, publish booking prices, create special offers, sell locally in the UAE, and track shipping rates — all in one platform.
            From Dubai to global markets: discover opportunities, find your products, buy, sell, and connect with new suppliers and customers.
            Al Ras Smart — your smart gateway to wholesale food trading.
            Download Al Ras Smart now on iOS and Android.
            """);

        Add(chunks, "terms-privacy", "الشروط والأحكام: طبيعة المنصة والمسؤولية", "ar", All,
            """
            الراس الذكي منصة إلكترونية تعمل فيها شركة ميرج سبايس لتجارة المواد الغذائية كوسيط بين المورد والعميل لتنظيم العمليات التجارية.
            المورد مسؤول عن صحة بيانات الشركة والرخصة، وتوافر البضائع، والجودة والكمية والوزن والتغليف ومطابقة المنتج لوصف الإعلان.
            يُمنع نشر منتجات محظورة أو مقلدة، ويُمنع وضع بيانات اتصال أو هوية المورد داخل صور أو وصف الإعلان.
            استخدام المنصة يعني الموافقة على الشروط. تخضع الشروط لقوانين دولة الإمارات العربية المتحدة وتختص محاكم دبي بالنزاعات.
            """);
        Add(chunks, "terms-privacy", "Terms of use: platform nature and liability", "en", All,
            """
            Al Ras Smart is an electronic marketplace operated by Merge Spice Foodstuff Trading LLC as an intermediary between suppliers and customers.
            Suppliers are responsible for accurate company and license data, stock availability, quality, quantity, weight, packaging, and matching the listing description.
            Illegal or counterfeit goods are prohibited, and supplier contact details or identity must not appear inside listing images or descriptions.
            Using the platform means accepting the Terms. UAE law applies and Dubai courts have jurisdiction over disputes.
            """);

        Add(chunks, "terms-prohibited", "المحتوى والمنتجات الممنوعة", "ar", All,
            """
            يُمنع على المنصة: المنتجات غير القانونية أو المحظورة، المنتجات المقلدة أو المخالفة للعلامات التجارية، السلع منتهية الصلاحية أو غير الصالحة للاستهلاك، والمنتجات التي لا تطابق وصف الإعلان.
            يُمنع أيضاً وضع رقم هاتف أو بريد أو اسم الشركة أو أي وسيلة تواصل داخل صور الإعلان أو الوصف بهدف تحويل الصفقة خارج المنصة.
            كما يُمنع ظهور شعارات الشركات أو ماركات تجارية واضحة على العبوات في صور الإعلان.
            مسموح ذكر بلد المنشأ والمواصفات في الاسم والوصف (مثل: حبوب سودانية، هيل هندي، أرز مصري، درجة أولى).
            يُمنع استخدام صور لا يملك المعلن حقوقها أو صور مضللة لا تمثل المنتج الحقيقي.
            مخالفة هذه القواعد قد تؤدي إلى رفض الإعلان أو إيقافه أو تعليق الحساب.
            """);
        Add(chunks, "terms-prohibited", "Prohibited content and products", "en", All,
            """
            Prohibited on the platform: illegal or restricted products, counterfeit or trademark-infringing goods, expired or unsafe food, and products that do not match the listing description.
            Also prohibited: placing a phone number, email, company name, or any contact channel inside listing images or descriptions in order to move the deal off-platform.
            Product brand logos or clear commercial trademarks on packaging in listing photos are prohibited.
            Origin country and product specifications in the title/description are allowed
            (e.g. Sudanese peanuts, Indian cardamom, Egyptian rice, Grade A).
            Using images the advertiser does not own, or misleading images that do not represent the actual product, is not allowed.
            Violations can lead to listing rejection, listing suspension, or account suspension.
            """);

        Add(chunks, "privacy", "سياسة الخصوصية واستخدام البيانات", "ar", All,
            """
            تجمع المنصة بيانات الحساب والتواصل والجهاز والبحث والطلبات والدفع والدعم لتشغيل الخدمة وتأمينها وتحسينها.
            لا تبيع المنصة البيانات الشخصية لأغراض تسويق خارجي.
            بيانات البطاقة الكاملة يعالجها مزود دفع معتمد ولا تخزنها المنصة.
            يمكنك طلب تصحيح بياناتك أو حذف حسابك، ويُنفَّذ ذلك ضمن الالتزامات القانونية وبعد إغلاق الطلبات والمستحقات القائمة.
            البحث بالصور يستخدم الصورة لتنفيذ المطابقة وتحسين الخدمة وفق الشروط، ولا يُستخدم للتعرف على هوية الأشخاص.
            """);
        Add(chunks, "privacy", "Privacy and data use", "en", All,
            """
            The platform processes account, contact, device, search, order, payment, and support data to operate, secure, and improve the service.
            Personal data is not sold for external marketing.
            Full card details are handled by an approved payment provider and are not stored by the platform.
            You can request correction of your data or deletion of your account, subject to legal obligations and after open orders are settled.
            Image-search uploads are used for matching and service improvement under the Terms, not to identify people.
            """);

        Add(chunks, "platform-trust", "هل منصة الراس الذكي موثوقة وآمنة؟", "ar", All,
            """
            تبني المنصة الثقة عبر: مراجعة بيانات الشركات والرخص قبل اعتماد حساب المورد، ومراجعة الإعلانات قبل النشر، وقواعد تمنع المنتجات المحظورة والمقلدة، وتنظيم الدفع والتحصيل عبر المنصة، وتتبع حالة الطلب خطوة بخطوة، ودعم بشري عبر Live Chat، وسياسة استرجاع للحالات المؤهلة.
            مع ذلك لا يمكن تقديم ضمان مطلق بخلو التعامل من أي مخاطرة: ميرج سبايس وسيط وليست مالكة للبضائع، والمورد يظل مسؤولاً عن الجودة والكمية والمطابقة.
            ننصح بمراجعة تفاصيل الإعلان والصور والمواصفات، وإتمام الدفع عبر قنوات المنصة فقط، وعدم التعامل خارج المنصة، والإبلاغ فوراً عن أي مشكلة عبر Live Chat.
            """);
        Add(chunks, "platform-trust", "Is Al Ras Smart trustworthy and safe?", "en", All,
            """
            Trust is supported by: company and trade-license review before a supplier account is approved, listing review before publication, rules against illegal and counterfeit goods, payment and collection organised through the platform, step-by-step order status tracking, human Live Chat support, and a returns policy for eligible cases.
            It cannot be described as risk-free: Merge Spice is an intermediary rather than the owner of listed goods, and suppliers remain responsible for quality, quantity, and conformity.
            Recommended practice: review listing details, images, and specifications, pay only through platform channels, avoid off-platform deals, and report any problem immediately via Live Chat.
            """);

        Add(chunks, "currency", "العملات المستخدمة في المنصة", "ar", All,
            """
            المنصة تستخدم عملتين: الدرهم الإماراتي AED والدولار الأمريكي USD.
            إعلانات Retail (التجزئة) تكون بالدرهم AED دائماً ولا يمكن تغييرها، لأن البيع بالتجزئة داخل دولة الإمارات.
            إعلانات Booking تكون بالدولار USD دائماً ولا يمكن تغييرها، لأنها شحنات دولية من ميناء إلى ميناء.
            باقي الإعلانات مثل منتجات الأصناف وOffers وRequests يمكن للمعلن اختيار AED أو USD، والافتراضي هو AED.
            عند الشراء تُعرض القيمة للعميل بحسب قناة البيع وسعر التحويل المعتمد في المنصة.
            """);
        Add(chunks, "currency", "Currencies used on the platform", "en", All,
            """
            The platform uses two currencies: UAE Dirham (AED) and US Dollar (USD).
            Retail ads are always priced in AED and this cannot be changed, because retail selling happens inside the UAE.
            Booking ads are always priced in USD and this cannot be changed, because they are international port-to-port shipments.
            Other listings such as category products, Offers, and Requests let the advertiser pick AED or USD, with AED as the default.
            At checkout the amount is presented according to the sales channel and the platform's applied conversion rate.
            """);

        Add(chunks, "units", "وحدات القياس والكميات", "ar", All,
            """
            عند إنشاء إعلان تُختار وحدة القياس المناسبة للمنتج، ومن الوحدات المتاحة: طن، كيلوجرام، كيس، كرتون، عبوة، صندوق، حزمة، درزن، برميل، زجاجة، علبة معدنية، شوال، كرتونة، طبلية، لتر، ملليلتر، جرام، برطمان، قطعة.
            الكمية المدخلة هي المخزون المتاح للبيع، وعندما تصل إلى صفر يصبح الإعلان نافد المخزون ولا يمكن الشراء منه.
            يمكن للمعلن تحديد حد أدنى للطلب (Minimum Order Quantity) وحد أقصى، فلا يستطيع المشتري طلب كمية أقل من الحد الأدنى أو أكثر من الحد الأقصى.
            إذا كان المنتج مفعّلاً للبيع بالتجزئة أيضاً، فله وحدة وكمية وسعر تجزئة منفصلة عن بيانات الجملة، وله كود تجزئة (RetailCode) منفصل عن كود الجملة (ProductCode).
            """);
        Add(chunks, "units", "Units of measure and quantities", "en", All,
            """
            When creating an ad you choose the unit that fits the product; available units include ton, kilogram, bag, carton, packet, box, bundle, dozen, drum, bottle, tin, sack, case, pallet, liter, ml, gram, jar, and piece.
            The quantity entered is the sellable stock; when it reaches zero the listing becomes out of stock and cannot be purchased.
            The advertiser can set a Minimum Order Quantity and a maximum, so a buyer cannot order below the minimum or above the maximum.
            If the product is also enabled for retail selling, it has a separate retail unit, retail quantity, retail price, and a separate RetailCode distinct from the wholesale ProductCode.
            """);
    }

    // ---------------------------------------------------------------------
    // 2. Account types, permissions, and shared capabilities
    // ---------------------------------------------------------------------

    private static void AddAccountTypesAndCapabilities(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "account-types", "أنواع الحسابات في الراس الذكي", "ar", All,
            """
            توجد خمس حالات للمستخدم: الزائر (غير مسجل)، والمورد (Supplier)، والعميل الفردي (Personal customer)، وعميل الشركة (Company customer)، وشركة الشحن (Shipping company).
            المورد: شركة تبيع وتعرض بضائعها؛ المورد داخل الإمارات ينشئ معظم أنواع الإعلانات، والمورد خارج الإمارات المسجل برقم غير إماراتي ينشئ Booking فقط. والمورد يستطيع أيضاً الشراء والطلب من المنصة ومتابعة مشترياته من طلباتي.
            العميل الفردي: مشترٍ أفراد، يشتري منتجات التجزئة فقط ولا ينشئ إعلانات.
            عميل الشركة: شركة تشتري بالجملة، تتصفح الأصناف وأنواع الإعلانات وتنشئ إعلان طلب (Request) فقط.
            شركة الشحن: تعرض خدمات الشحن من ميناء إلى ميناء فقط.
            كل نوع حساب يرى واجهة مختلفة وصلاحيات مختلفة.
            """);
        Add(chunks, "account-types", "Account types on Al Ras Smart", "en", All,
            """
            There are five user states: Guest (not signed in), Supplier, Personal customer, Company customer, and Shipping company.
            Supplier: a company that sells and lists goods. A UAE-based supplier can create most ad types, while an overseas supplier registered with a non-UAE phone number can create Booking only. Suppliers can also buy from the marketplace and track their purchases in My Orders.
            Personal customer: an individual buyer who purchases retail products and cannot create ads.
            Company customer: a company that buys wholesale, browses categories and ad types, and can create Request ads only.
            Shipping company: publishes port-to-port shipping services only.
            Each account type sees a different interface and has different permissions.
            """);

        Add(chunks, "common-capabilities", "ما يستطيع كل مستخدم مسجل فعله بغض النظر عن نوع الحساب", "ar", SignedIn,
            """
            هذه الميزات متاحة لكل المستخدمين المسجلين (مورد، عميل فردي، عميل شركة) ولا تحتاج نوع حساب خاص:
            تصفح المنتجات والإعلانات المتاحة لنوع حسابك، والبحث النصي، والبحث بالصورة، وفتح تفاصيل أي إعلان.
            تتبع الطلبات من صفحة My Orders (طلباتي) ومعرفة حالة كل طلب.
            حفظ الإعلانات المفضلة والرجوع إليها من الإعلانات المحفوظة.
            إدارة العناوين المحفوظة.
            تعديل الملف الشخصي وتغيير كلمة السر وتغيير اللغة وتفعيل البصمة/بصمة الوجه.
            التواصل مع الدعم البشري عبر Live Chat ومن صفحة المساعدة والدعم.
            طلب استرجاع للحالات المؤهلة، وحذف الحساب أو تسجيل الخروج.
            مهم: القيود على أنواع الحسابات تخص إنشاء ونشر الإعلانات فقط، ولا تمنع أي مستخدم من تتبع طلباته أو البحث أو استخدام الدعم.
            """);
        Add(chunks, "common-capabilities", "What every signed-in user can do regardless of account type", "en", SignedIn,
            """
            These features are available to every signed-in user (supplier, personal customer, company customer) and need no special account type:
            browsing products and listings available to your account type, text search, image search, and opening any listing's details.
            Tracking orders from the My Orders page and seeing each order's status.
            Saving favourite listings and reopening them from saved ads.
            Managing saved addresses.
            Editing the profile, changing the password, changing the language, and enabling fingerprint/face unlock.
            Contacting human support through Live Chat and the Help & Support page.
            Requesting a return for eligible cases, and deleting the account or signing out.
            Important: account-type restrictions apply only to creating and publishing ads. They never prevent a user from tracking their orders, searching, or using support.
            """);

        Add(chunks, "ad-types-matrix", "من يستطيع إنشاء كل نوع إعلان", "ar", All,
            """
            صلاحيات إنشاء الإعلانات حسب نوع الحساب:
            المورد داخل الإمارات يستطيع إنشاء إعلان داخل صنف (Category) وإعلان Retail وإعلان Booking وإعلان Offer بخصم وإعلان Request. المورد المسجل برقم هاتف غير إماراتي والموجود خارج الإمارات يستطيع إنشاء Booking فقط، ولا تظهر له بقية أنواع الإنشاء.
            عميل الشركة يستطيع إنشاء Request فقط، ولا يستطيع إنشاء Booking أو Retail أو Category أو Offer بخصم.
            العميل الفردي لا يستطيع إنشاء أي إعلان إطلاقاً، وهو مشترٍ فقط.
            شركة الشحن تنشئ إعلان شحن فقط من ميناء إلى ميناء بأسعار 20ft و40ft، ولا تنشئ أي نوع آخر.
            الزائر لا ينشئ أي شيء قبل تسجيل الدخول.
            عند سؤال مثل «كيف أضيف إعلان Booking؟» يجب أولاً تحديد هل نوع الحساب الحالي مسموح له؛ إن لم يكن مسموحاً يُقال فوراً إن الحساب غير مخوّل قبل أي قائمة حقول.
            هذا القيد يخص إنشاء الإعلانات فقط ولا يخص التصفح أو الشراء أو تتبع الطلبات.
            """);
        Add(chunks, "ad-types-matrix", "Who can create each ad type", "en", All,
            """
            Ad creation permissions by account type:
            A UAE-based supplier can create Category listings, Retail ads, Booking ads, discounted Offer ads, and Request ads. A supplier registered with a non-UAE phone number and located outside the UAE can create Booking only; the other creation types are unavailable.
            Company customer can create Request ads only and cannot create Booking, Retail, Category, or discounted Offer ads.
            Personal customer cannot create any ad at all and is a buyer only.
            Shipping company creates shipping ads only (port-to-port with 20ft and 40ft prices) and no other type.
            Guests cannot create anything before signing in.
            For a question like "how do I add a Booking ad?", first determine whether the current account type is allowed; if it is not, say this account cannot create Booking and that suppliers can.
            This restriction applies to ad creation only, never to browsing, buying, or order tracking.
            """);

        Add(chunks, "ad-properties", "خصائص الإعلان حسب النوع — أضف إعلان / عاوز أنشر إعلان", "ar",
            ["supplier", "company_customer", "shipping", "personal", "guest", "public"],
            """
            سؤال: أضف إعلان / عاوز أنشر إعلان / هنضيف إعلان / هل تقدر تضيف إعلان؟ / ساعدني أعمل إعلان.
            الإجابة تعتمد على نوع الحساب الحالي:

            المورد داخل الإمارات: يستطيع إضافة إعلانات Category وRetail وBooking وOffer بخصم وRequest.
            إذا طلب نشر إعلان داخل شات الراس الذكي والجمهور الحالي supplier، ساعده مباشرة عبر أدوات create_*_ad (مثل create_booking_ad لـ Booking) — لا ترفض ولا تقل "حسابك لا يسمح".
            استخدم وضع الخطة بالحوار: اعرض قائمة الحقول المطلوبة، ولو نسي المستخدم شيئاً في رده أخبره صراحة بالحقول الناقصة، ثم استدعِ الأداة بعد اكتمالها. يمكن أيضاً الإنشاء يدوياً من زر إنشاء إعلان في البار السفلي.
            المورد خارج الإمارات برقم غير إماراتي: Booking فقط — أخبره بذلك ولا تعرض بقية الأنواع، لكن Booking مسموح عبر create_booking_ad في الشات.

            عميل الشركة: يضيف إعلان Request فقط (لا Booking ولا Retail ولا Category ولا Offer بخصم).
            أخبره بذلك ووضّح المطلوب: اسم المنتج، المواصفات، قابل للتفاوض، محلي أو إعادة تصدير، عنوان التسليم من العناوين المحفوظة، والتعبئة. السعر المستهدف والكمية والوحدة والعملة اختيارية — لا تسأل عنها إلا إذا ذكرها المستخدم أو طلب تضمينها. تاريخ التسليم والصور اختياريان، ثم النشر من إنشاء طلب أو شات الراس الذكي.

            شركة الشحن: تضيف إعلان شحن فقط من الصفحة الرئيسية (ميناء إلى ميناء وأسعار 20ft و40ft).

            العميل الفردي: لا يستطيع إنشاء أي إعلان؛ هو مشترٍ فقط. اشرح له أنه يتصفح ويشتري ويتابع طلباتي.

            الزائر: يجب تسجيل الدخول أو إنشاء حساب أولاً قبل أي إنشاء إعلان.

            لا تخترع صلاحيات غير موجودة في نوع الحساب، ولا تخلط بين إنشاء الإعلان والشراء أو تتبع الطلبات.
            """);
        Add(chunks, "ad-properties", "Ad creation by account type — add or publish an ad", "en",
            ["supplier", "company_customer", "shipping", "personal", "guest", "public"],
            """
            Question: Add an ad / I want to publish an ad / can you add an ad? / help me create a listing.
            Answer depends on the current account type:

            UAE supplier: can create Category, Retail, Booking, discounted Offer, and Request.
            If they ask to publish in Alras Smart chat and the current audience is supplier, help via create_*_ad tools (e.g. create_booking_ad for Booking) — never refuse or say the account is not allowed.
            Use conversational Plan Mode: list required fields, explicitly call out anything still missing in their reply, then call the tool when complete. They may also use Create Ad in the bottom bar manually.
            Overseas supplier with a non-UAE phone: Booking only — say so and do not offer the other types, but Booking is allowed via create_booking_ad in chat.

            Company customer: Request ads only (not Booking, Retail, Category, or discounted Offer).
            Tell them that and list what a Request needs: product name, specifications, negotiable, Local or Reexport, delivery address from saved addresses (required for company_customer). Target price, quantity, unit, and currency are OPTIONAL unless the user provides a target price (then also collect currency USD/AED and unit). Optional delivery date and images. Publish from Create Order or Alras Smart chat.

            Shipping company: shipping ads only from Home (port-to-port with 20ft and 40ft prices).

            Personal customer: cannot create any ad; buyer only — browse, buy, and track My Orders.

            Guest: must sign in or register before creating any ad.

            Never invent permissions outside the account type, and never confuse creating an ad with buying or tracking orders.
            """);

        Add(chunks, "create-ad-via-chat-supplier", "إنشاء إعلان Booking وغيره من شات الراس الذكي — مورد", "ar", ["supplier"],
            """
            سؤال: عاوز انشر إعلان Booking / أنشئ بوكينج / اضف إعلان booking / ساعدني أنشر إعلان.
            إذا كان نوع الحساب الحالي مورد (supplier) فهذا مسموح تماماً.
            لا تقل "حسابك لا يسمح" ولا ترفض ولا تطلب فتح فورم أو شاشة إنشاء إعلان.
            ادخل وضع الخطة بالحوار: في أول رد اذكر قائمة الحقول المطلوبة لنوع الإعلان.
            Booking المطلوب: اسم المنتج، الدولة المصدرة، نوع السعر FOB/CNF/CIF، مدة الشحن بالأيام، السعر بالدولار، الكمية والوحدة، هل السعر قابل للتفاوض، المواصفات (اختياري)، الوسائط (اختياري). بلد الوجهة والموانئ مطلوبة فقط مع CNF أو CIF — ولا تُطلب أبداً مع FOB.
            لو رد المستخدم ناقص، قل صراحة: "نسيت / لسه ناقص:" واذكر الحقول الناقصة فقط. لا تستدعِ create_booking_ad قبل اكتمال المطلوب.
            بعد اكتمال الحقول استدعِ create_booking_ad مرة واحدة. عملة Booking دائماً USD.
            نفس أسلوب الخطة الحوارية لـ Offer وRetail وCategory وRequest مع الحقول المناسبة لكل نوع.
            """);
        Add(chunks, "create-ad-via-chat-supplier", "Create Booking and other ads via Alras Smart chat — supplier", "en", ["supplier"],
            """
            Question: I want to publish a Booking ad / create booking / help me post a listing.
            If the current account audience is supplier, this is fully allowed.
            Never say the account is not allowed, and never ask the user to open a Create Ad form.
            Use conversational Plan Mode: first reply with the full checklist of required fields for that ad type.
            Booking needs: product name, origin/exporting country, FOB/CNF/CIF, shipping days, USD price, quantity and unit, negotiable yes/no, specs optional, media optional. Destination country and ports are required only for CNF/CIF — never for FOB.
            If the user reply is incomplete, say clearly: "You still need to provide:" and list only the missing required fields. Do not call create_booking_ad until complete.
            When complete, call create_booking_ad once. Booking currency is always USD.
            Same conversational Plan Mode for Offer, Retail, Category, and Request with each type's fields.
            """);

        Add(chunks, "guest", "صلاحيات الزائر غير المسجل", "ar", ["guest", "public"],
            """
            الزائر يستطيع مشاهدة البانرات وأنواع الإعلانات والأصناف والمنتجات، واستخدام البحث النصي والبحث بالصورة، وفتح تفاصيل الإعلانات.
            قد تظهر له مداخل مثل طلباتي وإنشاء طلب والحساب والملف الشخصي في البار السفلي، لكن عند تنفيذ أي إجراء يتطلب حساباً (الشراء، إنشاء إعلان، الحفظ، فتح بيانات الحساب، التواصل مع الدعم) يتم توجيهه إلى صفحة تسجيل الدخول.
            لكي يشتري أو يتتبع طلباً أو يحفظ إعلاناً، يجب على الزائر إنشاء حساب أو تسجيل الدخول أولاً.
            """);
        Add(chunks, "guest", "Guest (not signed in) permissions", "en", ["guest", "public"],
            """
            A guest can view banners, ad types, categories, and products, use text search and image search, and open listing details.
            Entry points such as My Orders, Create Order, Account, and Profile may be visible, but any action that requires an account (buying, creating an ad, saving, opening account data, contacting support) redirects to the sign-in screen.
            To buy, track an order, or save a listing, a guest must create an account or sign in first.
            """);
    }

    // ---------------------------------------------------------------------
    // 3. Navigation per account type
    // ---------------------------------------------------------------------

    private static void AddNavigation(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "supplier-nav", "واجهة المورد والتنقل بين الصفحات", "ar", ["supplier"],
            """
            الصفحة الرئيسية للمورد تعرض اسمه في الأعلى ثم شريط البحث والبحث بالصورة، ثم البانرات، ثم أنواع الإعلانات (Booking, Retail, Offers, Shipping, Requests)، ثم الأصناف، ثم المنتجات.
            منتجات الصفحة الرئيسية هي منتجات الأصناف فقط، أي المنتجات التي لها CategoryId، وليست أنواع الخدمات وحدها.
            البار السفلي للمورد يشمل: الصفحة الرئيسية، إنشاء إعلان، طلباتي (My Orders)، الحساب (Account)، الملف الشخصي (Profile).
            صفحة الحساب تنقسم إلى قسمين: إعلاناتي (My Ads) وعروضي (My Offers).
            صفحة طلباتي للمورد فيها تبويبان: الواردة (طلبات وعروض واردة على إعلاناتك — تقبل أو ترفض) والمشتريات (الطلبات التي اشتراها المورد كمشتري).
            على أيقونة طلباتي في البار السفلي تظهر شارة حمراء بعدد الطلبات الواردة التي بانتظار موافقتك كبائع.
            """);
        Add(chunks, "supplier-nav", "Supplier interface and navigation", "en", ["supplier"],
            """
            The supplier home shows the account name at the top, then the search bar with image search, banners, ad types (Booking, Retail, Offers, Shipping, Requests), categories, and then products.
            Home products are category products only, meaning items that have a CategoryId, not the service types alone.
            The supplier bottom bar includes: Home, Create Ad, My Orders, Account, and Profile.
            The Account page has two sections: My Ads and My Offers.
            My Orders for a supplier has two tabs: Incoming (orders and offers received on your ads — accept or reject) and Purchases (orders the supplier placed as a buyer).
            A red badge on the My Orders icon shows how many incoming orders are awaiting your approval as seller.
            """);

        Add(chunks, "personal-nav", "واجهة العميل الفردي والتنقل", "ar", ["personal"],
            """
            الصفحة الرئيسية للعميل الفردي تعرض اسمه في الأعلى ثم شريط البحث والبحث بالصورة، ثم منتجات Retail فقط.
            العميل الفردي لا يرى الأصناف (Categories) في الصفحة الرئيسية ولا يرى منتجات الجملة، لأنه يشتري بالتجزئة.
            البار السفلي للعميل الفردي يحتوي على ثلاث صفحات فقط: الصفحة الرئيسية (Home)، وطلباتي (My Orders)، والملف الشخصي (Profile).
            لا يظهر له زر إنشاء إعلان ولا صفحة الحساب الخاصة بالإعلانات.
            صفحة طلباتي للعميل الفردي تعرض المشتريات فقط (بدون تبويبات): كل الطلبات التي اشتراها كمشتري.
            الملف الشخصي يحتوي على كل الإعدادات والدعم.
            """);
        Add(chunks, "personal-nav", "Personal customer interface and navigation", "en", ["personal"],
            """
            The personal customer home shows the account name at the top, then the search bar with image search, then Retail products only.
            A personal customer does not see Categories on home and does not see wholesale products, because this account buys at retail.
            The bottom bar has three pages only: Home, My Orders, and Profile.
            There is no Create Ad button, no ads Account page.
            My Orders for a personal customer shows Purchases only (no tabs): every order they placed as a buyer.
            Profile contains all settings and support.
            """);

        Add(chunks, "company-nav", "واجهة عميل الشركة والتنقل", "ar", ["company_customer"],
            """
            الصفحة الرئيسية لعميل الشركة تعرض اسم الشركة في الأعلى ثم شريط البحث والبحث بالصورة، ثم البانرات، ثم أنواع الإعلانات، ثم الأصناف، ثم منتجات الأصناف.
            منتجات الصفحة الرئيسية لعميل الشركة ليست Retail فقط كما في حساب الفرد، بل منتجات الأصناف مثل المورد، لأنه يشتري بالجملة.
            البار السفلي: الصفحة الرئيسية (Home)، وإنشاء طلب (Create Order)، والحساب (Account)، وطلباتي (My Orders)، والملف الشخصي (Profile).
            صفحة Create Order مخصصة لإنشاء إعلان Request فقط لأنه عملية شراء/طلب بضاعة.
            صفحة الحساب (Account) لعميل الشركة تعرض إعلاناتي فقط — إعلانات Request التي نشرها، بدون قسم عروضي (My Offers).
            صفحة طلباتي لعميل الشركة فيها تبويبان: طلباتي (Requests — إعلانات Request التي نشرها + العروض الواردة عليها) والمشتريات (Orders — مشترياتك كمشتري).
            """);
        Add(chunks, "company-nav", "Company customer interface and navigation", "en", ["company_customer"],
            """
            The company customer home shows the company name at the top, then the search bar with image search, banners, ad types, categories, and category products.
            Home products are not Retail-only as they are for a personal account; they are category products like the supplier home, because this account buys wholesale.
            Bottom bar: Home, Create Order, Account, My Orders, and Profile.
            Create Order is dedicated to creating Request ads only, since a request is a purchase/sourcing action.
            The Account page for a company customer shows My Ads only — Request ads they published, with no My Offers section.
            My Orders for a company customer has two tabs: Requests (Request ads you published plus incoming supplier offers) and Orders (your purchases as a buyer).
            """);

        Add(chunks, "shipping-nav", "واجهة شركة الشحن والتنقل", "ar", ["shipping"],
            """
            شركة الشحن لديها صفحتان فقط في البار السفلي: الصفحة الرئيسية (Home) والملف الشخصي (Profile).
            الصفحة الرئيسية لا تحتوي على متجر أو منتجات، بل على خيارين: إضافة إعلان شحن (Add shipping ad) وإدارة إعلاناتك (Manage your ads).
            الملف الشخصي يحتوي على الدعم الفني، وتعديل المعلومات الشخصية، واختيار اللغة، وعدد الإعلانات.
            شركة الشحن لا تشتري منتجات ولا تنشئ Booking أو Retail أو Request، ولا يوجد لديها صفحة طلبات.
            """);
        Add(chunks, "shipping-nav", "Shipping company interface and navigation", "en", ["shipping"],
            """
            A shipping company has only two pages in the bottom bar: Home and Profile.
            Home has no storefront or products; it offers two actions: Add shipping ad and Manage your ads.
            Profile contains support, personal information editing, language selection, and the ad count.
            A shipping company does not buy products and cannot create Booking, Retail, or Request ads; it has no orders page.
            """);
    }

    // ---------------------------------------------------------------------
    // 4. Registration and sign-in
    // ---------------------------------------------------------------------

    private static void AddRegistrationAndSignIn(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "signup-personal", "كيف ينشئ العميل الفردي حساباً", "ar", All,
            """
            العميل الفردي ينشئ حسابه أو يسجل دخوله عبر جوجل أو أبل مباشرة دون رخصة تجارية أو صور شركة أو عنوان.
            يضغط على زر جوجل أو أبل حسب نوع الجهاز، وإذا لم يكن لديه حساب سابق ينشئ النظام له حساباً تلقائياً ويدخل مباشرة.
            كما يمكنه التسجيل بالبريد الإلكتروني وكلمة سر إن رغب.
            حساب العميل الفردي لا يحتاج أي مراجعة أو اعتماد ويعمل فوراً.
            """);
        Add(chunks, "signup-personal", "How a personal customer creates an account", "en", All,
            """
            A personal customer signs up or signs in directly with Google or Apple, with no trade license, company images, or address required.
            Tapping Google or Apple (depending on the device) creates the account automatically if none exists and signs the user straight in.
            Registering with an email address and password is also possible.
            A personal customer account needs no review or approval and works immediately.
            """);

        Add(chunks, "signup-supplier", "كيف ينشئ المورد حساباً ومتطلبات التسجيل", "ar", All,
            """
            المورد لا يستطيع إنشاء الحساب لأول مرة باستخدام جوجل أو أبل، لأن التسجيل يتطلب بيانات أساسية لا توفرها هذه الطريقة، وهي: الرخصة التجارية وصور الشركة وبيانات الشركة الأساسية.
            لذلك يجب على المورد إتمام نموذج التسجيل الكامل وإرفاق الرخصة التجارية وصور الشركة.
            بعد إرسال الطلب تتم مراجعة البيانات واعتماد الحساب من فريق الراس الذكي.
            بعد إنشاء الحساب واعتماده يستطيع المورد تسجيل الدخول لاحقاً عن طريق جوجل أو أبل حسب نوع الجهاز المستخدم، أو بالبريد وكلمة السر.
            """);
        Add(chunks, "signup-supplier", "How a supplier creates an account and registration requirements", "en", All,
            """
            A supplier cannot create the initial account with Google or Apple, because registration requires core data that those methods do not provide: the trade license, company images, and company details.
            The supplier must therefore complete the full registration form and attach the trade license and company images.
            After submission, the Al Ras Smart team reviews the data and approves the account.
            Once the account exists and is approved, the supplier can sign in later with Google or Apple depending on the device, or with email and password.
            """);

        Add(chunks, "signup-company", "كيف ينشئ عميل الشركة حساباً", "ar", All,
            """
            حساب عميل الشركة مخصص للشركات التي تشتري بالجملة، ويتطلب بيانات الشركة عند التسجيل مثل اسم الشركة ووسائل التواصل، وقد يُطلب توثيق الشركة حسب سياسة المنصة.
            بعد التسجيل يمر الحساب على مراجعة فريق الراس الذكي قبل التفعيل الكامل.
            بعد التفعيل يستطيع عميل الشركة تصفح الأصناف ومنتجات الجملة وإنشاء إعلانات Request واستقبال العروض عليها.
            """);
        Add(chunks, "signup-company", "How a company customer creates an account", "en", All,
            """
            A company customer account is for companies buying wholesale and requires company details at registration such as company name and contact channels; company verification may be requested per platform policy.
            After registration the account passes through Al Ras Smart team review before full activation.
            Once activated, the company customer can browse categories and wholesale products, create Request ads, and receive offers on them.
            """);

        Add(chunks, "signup-shipping", "كيف تنشئ شركة الشحن حساباً", "ar", All,
            """
            حساب شركة الشحن مخصص لمقدمي خدمات الشحن البحري من ميناء إلى ميناء، ويتطلب بيانات الشركة عند التسجيل.
            بعد المراجعة والاعتماد تستطيع الشركة إضافة إعلانات الشحن وإدارتها من الصفحة الرئيسية.
            هذا الحساب لا يشتري ولا يبيع منتجات، بل يعرض خدمة شحن بأسعار حاويات 20ft و40ft ومدة الرحلة.
            """);
        Add(chunks, "signup-shipping", "How a shipping company creates an account", "en", All,
            """
            A shipping company account is for sea-freight providers offering port-to-port service and requires company details at registration.
            After review and approval, the company can add and manage shipping ads from Home.
            This account does not buy or sell products; it publishes a shipping service with 20ft and 40ft container prices and transit time.
            """);

        Add(chunks, "signin-social", "تسجيل الدخول بجوجل أو أبل", "ar", All,
            """
            تسجيل الدخول بجوجل أو أبل متاح حسب نوع الجهاز: أبل تظهر عادة على أجهزة iPhone وiPad، وجوجل على أجهزة أندرويد وأيضاً على iOS.
            العملاء الأفراد يستطيعون إنشاء الحساب وتسجيل الدخول بهذه الطريقة مباشرة.
            الموردون لا يستطيعون إنشاء الحساب لأول مرة بهذه الطريقة بسبب متطلبات الرخصة وصور الشركة، لكن يمكنهم استخدامها لتسجيل الدخول بعد اعتماد الحساب.
            إذا سجلت دخولك بجوجل أو أبل فلن يكون لديك كلمة سر قديمة، ولذلك تظهر لك شاشة مبسطة لتعيين كلمة سر جديدة بحقلين فقط بدل ثلاثة.
            """);
        Add(chunks, "signin-social", "Signing in with Google or Apple", "en", All,
            """
            Google and Apple sign-in availability depends on the device: Apple typically appears on iPhone and iPad, Google on Android and also on iOS.
            Personal customers can create the account and sign in this way directly.
            Suppliers cannot create the first account this way because of the license and company image requirements, but they can use it to sign in after approval.
            If you signed in with Google or Apple you have no existing password, so the password screen is simplified to two fields for setting a new password instead of three.
            """);

        Add(chunks, "account-approval", "مراجعة الحساب ومدة الاعتماد", "ar", ["supplier", "company_customer", "shipping", "public"],
            """
            حسابات الشركات (المورد وعميل الشركة وشركة الشحن) تمر على مراجعة من فريق الراس الذكي للتحقق من البيانات والرخصة قبل التفعيل الكامل.
            أثناء المراجعة قد تكون بعض الصفحات أو إمكانية النشر غير متاحة حتى يُعتمد الحساب.
            إذا تأخر اعتماد الحساب أو رُفض، يمكنك التواصل مع الدعم عبر Live Chat من الملف الشخصي أو من صفحة المساعدة والدعم لمعرفة السبب واستكمال المطلوب.
            """);
        Add(chunks, "account-approval", "Account review and approval", "en", ["supplier", "company_customer", "shipping", "public"],
            """
            Company accounts (supplier, company customer, shipping company) go through Al Ras Smart team review to verify details and the trade license before full activation.
            During review some pages or publishing may be unavailable until the account is approved.
            If approval is delayed or rejected, contact support through Live Chat in Profile or the Help & Support page to learn the reason and complete what is missing.
            """);
    }

    // ---------------------------------------------------------------------
    // 5. Profile and settings
    // ---------------------------------------------------------------------

    private static void AddProfileAndSettings(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "profile", "محتويات صفحة الملف الشخصي", "ar", ["supplier", "personal", "company_customer", "public"],
            """
            صفحة الملف الشخصي (لغير شركة الشحن) تعرض في الأعلى اسم الشركة أو المستخدم، ثم البريد الإلكتروني أسفله، ثم رقم الهاتف، ثم صورة الشركة.
            أسفلها زر تعديل الملف الشخصي (Edit profile).
            ثم Live Chat للمحادثة المباشرة مع أحد موظفي الدعم.
            ثم زر تغيير كلمة السر.
            ثم العناوين المحفوظة، والإعلانات المحفوظة، وزر إعلاناتي الذي ينقلك إلى صفحة الحساب في البار السفلي.
            ثم المساعدة والدعم (Help and support).
            ثم حذف الحساب، وتسجيل الخروج، وتفعيل البصمة أو بصمة الوجه، وتغيير اللغة.
            """);
        Add(chunks, "profile", "What the Profile page contains", "en", ["supplier", "personal", "company_customer", "public"],
            """
            The Profile page (for non-shipping accounts) shows the company or user name at the top, then the email below it, then the phone number, then the company image.
            Below that is the Edit profile button.
            Then Live Chat for a direct conversation with a support agent.
            Then the change password button.
            Then saved addresses, saved ads, and a My Ads button that navigates to the Account page in the bottom bar.
            Then Help and support.
            Then delete account, sign out, biometric (fingerprint/face) unlock, and language selection.
            """);

        Add(chunks, "profile-edit", "تعديل بيانات الملف الشخصي والمراجعة", "ar", ["supplier", "personal", "company_customer", "public"],
            """
            من زر Edit profile يمكنك تعديل بياناتك.
            تغيير صورة الشركة يُطبَّق مباشرة دون مراجعة.
            أما أي تعديل آخر مثل اسم الشركة أو الرخصة التجارية أو الرقم الضريبي أو رقم الهاتف فيذهب إلى المراجعة أولاً، ولا يظهر التغيير حتى يوافق عليه فريق الراس الذكي.
            سبب المراجعة هو حماية المشترين والتأكد من أن بيانات الشركة المعروضة صحيحة وموثقة.
            إذا تأخرت الموافقة على التعديل يمكنك متابعتها مع الدعم عبر Live Chat.
            """);
        Add(chunks, "profile-edit", "Editing profile data and the review step", "en", ["supplier", "personal", "company_customer", "public"],
            """
            Use Edit profile to change your details.
            Changing the company image applies immediately with no review.
            Any other edit such as company name, trade license, tax number, or phone number goes to review first, and the change is not shown until the Al Ras Smart team approves it.
            The review exists to protect buyers and keep published company data accurate and verified.
            If an edit approval is delayed you can follow it up with support via Live Chat.
            """);

        Add(chunks, "password-change", "تغيير كلمة السر", "ar", SignedIn,
            """
            من الملف الشخصي اضغط زر تغيير كلمة السر.
            إذا كان حسابك بكلمة سر عادية ستجد ثلاثة حقول: كلمة السر الحالية، وكلمة السر الجديدة، وتأكيد كلمة السر الجديدة.
            إذا كنت قد سجلت الدخول بجوجل أو أبل فلا توجد كلمة سر حالية، ولذلك ستجد حقلين فقط لإدخال كلمة السر الجديدة وتأكيدها.
            بعد الحفظ تُستخدم كلمة السر الجديدة في تسجيل الدخول التالي.
            """);
        Add(chunks, "password-change", "Changing your password", "en", SignedIn,
            """
            From Profile, tap the change password button.
            If your account uses a normal password you will see three fields: current password, new password, and confirm new password.
            If you signed in with Google or Apple there is no current password, so you will see only two fields for the new password and its confirmation.
            After saving, the new password is used at the next sign-in.
            """);

        Add(chunks, "password-forgot", "نسيت كلمة السر واستعادة الحساب", "ar", All,
            """
            في شاشة تغيير كلمة السر أو تسجيل الدخول يوجد خيار نسيت كلمة السر (Forget password).
            عند اختياره نرسل رمز تحقق OTP إلى بريدك الإلكتروني. الإرسال عبر رقم الهاتف سيكون متاحاً قريباً، أما حالياً فالرمز يصل على البريد فقط.
            أدخل رمز OTP ثم عيّن كلمة السر الجديدة.
            إذا لم يصلك الرمز تحقق من مجلد الرسائل غير المرغوب فيها وانتظر قليلاً ثم أعد المحاولة.
            إذا فقدت الوصول إلى بريدك الإلكتروني نهائياً فلا يمكن استعادة الحساب ذاتياً، ويجب التواصل مع الدعم الفني عبر Live Chat أو صفحة المساعدة والدعم.
            """);
        Add(chunks, "password-forgot", "Forgot password and account recovery", "en", All,
            """
            The change password and sign-in screens include a Forget password option.
            Choosing it sends an OTP code to your email address. Phone delivery is coming soon; for now the code is sent to email only.
            Enter the OTP and then set your new password.
            If the code does not arrive, check the spam folder, wait a moment, and try again.
            If you have permanently lost access to your email, self-service recovery is not possible and you must contact support through Live Chat or the Help & Support page.
            """);

        Add(chunks, "biometric", "تفعيل البصمة وبصمة الوجه", "ar", SignedIn,
            """
            من الملف الشخصي يمكنك تفعيل الدخول بالبصمة أو بصمة الوجه (Biometric).
            بعد التفعيل يمكنك فتح التطبيق أو تأكيد هويتك باستخدام بصمة الإصبع أو التعرف على الوجه بدل كتابة كلمة السر في كل مرة.
            تعتمد الميزة على دعم جهازك لها وتفعيلها في إعدادات الجهاز أولاً.
            يمكنك إيقاف الميزة في أي وقت من نفس المكان.
            """);
        Add(chunks, "biometric", "Enabling fingerprint and face unlock", "en", SignedIn,
            """
            From Profile you can enable biometric unlock using fingerprint or face recognition.
            Once enabled you can open the app or confirm your identity with your fingerprint or face instead of typing your password each time.
            The feature depends on your device supporting it and having it enabled in the device settings first.
            You can turn it off at any time from the same place.
            """);

        Add(chunks, "language", "تغيير لغة التطبيق", "ar", All,
            """
            التطبيق يدعم العربية والإنجليزية.
            لتغيير اللغة افتح الملف الشخصي واختر زر اللغة ثم اختر العربية أو الإنجليزية، وتتغير واجهة التطبيق فوراً.
            شركة الشحن تجد خيار اللغة أيضاً داخل ملفها الشخصي.
            مساعد الذكاء الاصطناعي يرد بأي لغة يكتب بها المستخدم (عربية بأي لهجة، إنجليزية، فرنسية، هندية، أوردو، فلبينية، وغيرها) — نفس لغة الرسالة فوراً.
            """);
        Add(chunks, "language", "Changing the app language", "en", All,
            """
            The app supports Arabic and English.
            To change the language, open Profile, tap the language button, and choose Arabic or English; the interface updates immediately.
            Shipping companies also find the language option inside their Profile.
            The AI Assistant replies in ANY language the user writes (any Arabic dialect, English, French, Hindi, Urdu, Tagalog, Spanish, and more) — match the message language immediately.
            """);

        Add(chunks, "addresses", "العناوين المحفوظة", "ar", Buyers,
            """
            من الملف الشخصي يوجد قسم العناوين المحفوظة.
            يمكنك إضافة عنوان جديد وتعديل عنوان قائم أو حذفه.
            العناوين المحفوظة تُستخدم عند إتمام الشراء لتحديد مكان التسليم دون إعادة كتابة البيانات في كل طلب.
            تأكد من صحة العنوان ورقم الهاتف لتفادي تأخير التوصيل.
            """);
        Add(chunks, "addresses", "Saved addresses", "en", Buyers,
            """
            Profile includes a saved addresses section.
            You can add a new address and edit or delete an existing one.
            Saved addresses are used at checkout to set the delivery location without retyping the details for every order.
            Keep the address and phone number accurate to avoid delivery delays.
            """);

        Add(chunks, "saved-ads", "الإعلانات المحفوظة والمفضلة", "ar", SignedIn,
            """
            يمكنك حفظ أي إعلان يهمك للرجوع إليه لاحقاً.
            الإعلانات المحفوظة تظهر في قسم الإعلانات المحفوظة داخل الملف الشخصي.
            من هناك يمكنك فتح الإعلان مباشرة أو إزالته من المحفوظات.
            الحفظ يتطلب تسجيل الدخول؛ الزائر يُوجَّه إلى تسجيل الدخول عند محاولة الحفظ.
            """);
        Add(chunks, "saved-ads", "Saved and favourite listings", "en", SignedIn,
            """
            You can save any listing you are interested in to return to it later.
            Saved listings appear in the saved ads section inside Profile.
            From there you can open the listing directly or remove it from your saved items.
            Saving requires sign-in; guests are redirected to sign-in when they try to save.
            """);

        Add(chunks, "delete-account", "حذف الحساب وتسجيل الخروج", "ar", SignedIn,
            """
            زر تسجيل الخروج في الملف الشخصي ينهي الجلسة الحالية فقط ويحتفظ ببياناتك، ويمكنك الدخول مرة أخرى في أي وقت.
            زر حذف الحساب يطلب إزالة حسابك من المنصة.
            الحذف إجراء نهائي ويؤثر على وصولك إلى سجل طلباتك وإعلاناتك.
            يُنفَّذ الحذف ضمن الالتزامات القانونية وبعد إغلاق الطلبات القائمة وتسوية أي مستحقات.
            إذا واجهت مشكلة في الحذف تواصل مع الدعم عبر Live Chat.
            """);
        Add(chunks, "delete-account", "Deleting your account and signing out", "en", SignedIn,
            """
            The sign-out button in Profile ends the current session only and keeps your data; you can sign back in at any time.
            The delete account button requests removal of your account from the platform.
            Deletion is permanent and affects your access to your order history and listings.
            It is carried out subject to legal obligations and after open orders are closed and any dues are settled.
            If you have trouble deleting the account, contact support via Live Chat.
            """);
    }

    // ---------------------------------------------------------------------
    // 6. Search
    // ---------------------------------------------------------------------

    private static void AddSearch(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "search-text", "البحث النصي داخل التطبيق", "ar", All,
            """
            شريط البحث يظهر لكل المستخدمين أعلى الصفحة الرئيسية أسفل الاسم.
            اكتب اسم المنتج أو جزءاً منه وستظهر لك اقتراحات فورية ثم نتائج البحث.
            نتائج البحث تعرض الإعلانات المتاحة لنوع حسابك فقط؛ فمثلاً العميل الفردي يرى نتائج التجزئة، بينما المورد وعميل الشركة يريان منتجات الأصناف وأنواع الإعلانات.
            يمكنك فتح أي نتيجة لعرض تفاصيل الإعلان والصور والمواصفات والسعر والكمية.
            البحث يعمل بالعربية والإنجليزية.
            """);
        Add(chunks, "search-text", "Text search in the app", "en", All,
            """
            The search bar appears for all users at the top of home, below the name.
            Type a product name or part of it to see instant suggestions and then search results.
            Results only include listings available to your account type; a personal customer sees retail results, while suppliers and company customers see category products and ad types.
            Open any result to view listing details, images, specifications, price, and quantity.
            Search works in both Arabic and English.
            """);

        Add(chunks, "search-image", "كيف أبحث بالصورة", "ar", All,
            """
            البحث بالصورة متاح لكل المستخدمين بما فيهم الزائر، ويوجد داخل شريط البحث أعلى الصفحة الرئيسية.
            اضغط أيقونة الكاميرا أو الصورة في شريط البحث، ثم التقط صورة للمنتج أو اخترها من معرض الصور.
            يقوم النظام بتحليل الصورة ومقارنتها بصور المنتجات المنشورة، ثم يعرض لك أقرب المنتجات شبهاً.
            البحث بالصورة مكمل للبحث النصي وليس بديلاً عنه، ويفيد عندما لا تعرف اسم المنتج بدقة.
            """);
        Add(chunks, "search-image", "How to search by image", "en", All,
            """
            Image search is available to everyone including guests and sits inside the search bar at the top of home.
            Tap the camera or image icon in the search bar, then take a photo of the product or pick one from your gallery.
            The system analyses the image, compares it with published product images, and shows the closest matches.
            Image search complements text search rather than replacing it and is useful when you do not know the exact product name.
            """);

        Add(chunks, "search-image-tips", "نصائح للحصول على أفضل نتائج بحث بالصور", "ar", All,
            """
            لتحسين دقة البحث بالصورة: صوّر المنتج في إضاءة جيدة وواضحة.
            اجعل المنتج في وسط الصورة وقلل العناصر الأخرى في الخلفية.
            صوّر العبوة أو الكرتونة كاملة إن أمكن لأن الشكل واللون والتعبئة تساعد على المطابقة.
            تجنب الصور الضبابية أو البعيدة جداً أو المائلة بشدة.
            إذا لم تظهر نتائج مناسبة جرّب زاوية مختلفة أو استخدم البحث النصي باسم المنتج.
            """);
        Add(chunks, "search-image-tips", "Tips for better image search results", "en", All,
            """
            To improve image-search accuracy: photograph the product in good, clear lighting.
            Keep the product centred and reduce clutter in the background.
            Capture the full package or carton where possible, because shape, colour, and packaging all help matching.
            Avoid blurry, very distant, or heavily angled photos.
            If the results are not relevant, try a different angle or switch to text search using the product name.
            """);

        Add(chunks, "image-training", "كيف يتدرب نموذج البحث بالصور", "ar", All,
            """
            البحث بالصورة يكمل البحث النصي: يحول صورة المنتج إلى بصمة رقمية (تمثيل رقمي) تلخص الشكل واللون والتعبئة والنوع، ثم يقارنها بفهرس متجهي يضم صور المنتجات المنشورة ويعرض الأقرب.
            المصدر الأساسي لتحسين النموذج هو صور إعلانات الموردين المنشورة على المنصة.
            وفق الشروط، بعد نشر الإعلان تمنح المنصة الحق في استخدام صور المنتج لتشغيل وتحسين وتدريب البحث بالصورة داخل المنصة.
            كلما زادت جودة الصور وتنوع زواياها تحسنت دقة المطابقة لكل المستخدمين.
            المورد مسؤول عن صحة الصور وعن عدم تضمين بيانات تعريفية أو وسائل تواصل داخلها.
            الهدف من التدريب هو الوصول لنتائج مطابقة أدق، وليس التعرف على هوية الأشخاص.
            """);
        Add(chunks, "image-training", "How the image-search model is trained", "en", All,
            """
            Image search complements text search: it converts a product photo into an embedding that summarises shape, colour, packaging, and type, then compares it against a vector index of published listing images and returns the closest matches.
            The primary improvement source is the supplier listing images published on the platform.
            Under the Terms, publishing a listing grants the platform the right to use the product images to operate, improve, and train in-platform image search.
            Better image quality and more varied angles improve matching accuracy for everyone.
            Suppliers remain responsible for image accuracy and for not embedding identifying details or contact channels in them.
            The purpose of this training is more accurate product matching, not identifying people.
            """);

        Add(chunks, "search-no-results", "لماذا لا تظهر نتائج للبحث", "ar", All,
            """
            قد لا تظهر نتائج للأسباب التالية: المنتج غير متوفر حالياً على المنصة، أو الإعلان لم يُعتمد بعد من المراجعة، أو الإعلان متوقف أو نفد مخزونه، أو الكلمة المكتوبة بها خطأ إملائي.
            سبب مهم آخر: النتائج تُفلتر حسب نوع حسابك، فالعميل الفردي يرى منتجات التجزئة فقط ولن تظهر له منتجات الجملة.
            جرّب كلمة أعم أو بالإنجليزية بدل العربية والعكس، أو استخدم البحث بالصورة، أو تصفح الأصناف مباشرة.
            إن كنت تبحث عن بضاعة جملة غير متوفرة ويسمح حسابك بذلك، يمكنك نشر إعلان Request ليقدم الموردون عروضهم عليك.
            """);
        Add(chunks, "search-no-results", "Why a search returns no results", "en", All,
            """
            Results can be empty because: the product is not currently listed, the listing is still awaiting review approval, the listing is paused or out of stock, or the search term contains a typo.
            Another important reason: results are filtered by account type, so a personal customer sees retail products only and will not see wholesale listings.
            Try a broader term, switch between Arabic and English, use image search, or browse the categories directly.
            If you are sourcing wholesale goods that are not listed and your account allows it, publish a Request ad so suppliers can send you offers.
            """);
    }

    // ---------------------------------------------------------------------
    // 7. Browsing and listing types
    // ---------------------------------------------------------------------

    private static void AddBrowsingAndListings(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "listing-types", "أنواع الإعلانات ومعانيها", "ar", All,
            """
            Retail (تجزئة): بيع بكميات صغيرة داخل دولة الإمارات، السعر بالدرهم، ويمكن للعميل الفردي الشراء منه.
            Booking (حجز/شحنة): عرض شحنة دولية من ميناء إلى ميناء بالدولار مع الدولة المصدرة وميناء التحميل وبلد الوجهة وميناء الوصول ونوع السعر FOB أو CNF أو CIF.
            Offers (عروض): إعلانات عليها نسبة خصم لمدة محددة.
            Requests (طلبات): إعلان يطلب فيه صاحبه بضاعة غير متوفرة لديه، ويتقدم الآخرون بعروضهم عليه.
            Shipping (شحن): خدمة شحن تنشرها شركة الشحن من ميناء إلى ميناء بسعر 20ft و40ft ومدة الرحلة.
            بالإضافة إلى ذلك توجد منتجات الأصناف (Categories) وهي المنتجات التي لها CategoryId وتظهر داخل الصنف في الصفحة الرئيسية.
            """);
        Add(chunks, "listing-types", "Ad types and what they mean", "en", All,
            """
            Retail: small-quantity selling inside the UAE, priced in AED, and purchasable by personal customers.
            Booking: an international port-to-port shipment priced in USD with origin country, loading port, destination country, arrival port, and price type FOB, CNF, or CIF.
            Offers: listings carrying a discount percentage for a limited period.
            Requests: a listing where the owner asks for goods they do not have, and others submit offers on it.
            Shipping: a freight service published by a shipping company from port to port with 20ft and 40ft prices and transit time.
            In addition there are Category products, which are items with a CategoryId shown inside their category on the home page.
            """);

        Add(chunks, "offer-meaning", "الفرق بين نوعي كلمة Offer", "ar", All,
            """
            كلمة Offer لها معنيان مختلفان داخل المنصة ويجب عدم الخلط بينهما.
            الأول: إعلان Offer، وهو نوع إعلان يعرض منتجاً عليه نسبة خصم لمدة محددة، ويظهر ضمن قسم Offers في الصفحة الرئيسية.
            الثاني: تقديم عرض (offer) على إعلان Request، أي أن تتقدم بسعر وكمية لتلبية طلب شركة أخرى تبحث عن بضاعة، وتتم متابعته من قسم عروضي (My Offers).
            الأول عملية بيع بخصم، والثاني عملية مزايدة أو تسعير على طلب شراء.
            """);
        Add(chunks, "offer-meaning", "The two different meanings of Offer", "en", All,
            """
            The word Offer has two distinct meanings on the platform and they must not be confused.
            First: an Offer ad, an ad type showing a product with a discount percentage for a limited period, listed under the Offers section on home.
            Second: submitting an offer on a Request ad, meaning you propose a price and quantity to fulfil another company's sourcing request, tracked in the My Offers section.
            The first is a discounted sale; the second is a quotation or bid against a purchase request.
            """);

        Add(chunks, "listing-details", "ماذا تحتوي صفحة تفاصيل الإعلان", "ar", All,
            """
            صفحة تفاصيل الإعلان تعرض صور المنتج والفيديو إن وُجد، واسم المنتج ووصفه ومواصفاته، والسعر والعملة، والكمية المتاحة والوحدة، والحد الأدنى للطلب إن وُجد، وتفاصيل التعبئة إن أضافها المعلن.
            في إعلانات Booking تظهر إضافة إلى ذلك الدولة المصدرة وميناء التحميل وبلد الوجهة وميناء الوصول ونوع السعر FOB أو CNF أو CIF.
            في إعلانات Offers تظهر نسبة الخصم ومدته.
            في إعلانات الشحن يظهر الميناءان ومدة الرحلة وسعر 20ft وسعر 40ft.
            من صفحة التفاصيل يمكنك الشراء أو الإضافة إلى السلة أو حفظ الإعلان حسب نوع الإعلان ونوع حسابك.
            """);
        Add(chunks, "listing-details", "What the listing details page shows", "en", All,
            """
            The listing details page shows product images and video if available, the name, description, and specifications, price and currency, available quantity and unit, minimum order quantity if set, and packaging details if the advertiser added them.
            Booking ads additionally show origin country, loading port, destination country, arrival port, and the price type FOB, CNF, or CIF.
            Offer ads show the discount percentage and its duration.
            Shipping ads show both ports, transit time, 20ft price, and 40ft price.
            From the details page you can buy, add to cart, or save the listing, depending on the ad type and your account type.
            """);

        Add(chunks, "categories", "الأصناف وكيف تتصفحها", "ar", ["supplier", "company_customer", "shipping", "guest", "public"],
            """
            الأصناف (Categories) تصنف المنتجات حسب نوعها لتسهيل التصفح.
            تظهر الأصناف في الصفحة الرئيسية للمورد وعميل الشركة والزائر، ويمكن الضغط على أي صنف لعرض منتجاته.
            منتجات الصفحة الرئيسية هي منتجات الأصناف، أي المنتجات التي لها CategoryId، وليست أنواع الإعلانات وحدها.
            العميل الفردي لا يرى الأصناف في صفحته الرئيسية لأنه يشتري منتجات التجزئة فقط.
            """);
        Add(chunks, "categories", "Categories and how to browse them", "en", ["supplier", "company_customer", "shipping", "guest", "public"],
            """
            Categories group products by type to make browsing easier.
            They appear on the home page for suppliers, company customers, and guests, and tapping a category shows its products.
            Home products are category products, meaning items with a CategoryId, not the ad types alone.
            Personal customers do not see categories on their home page because they buy retail products only.
            """);
    }

    // ---------------------------------------------------------------------
    // 8. Buying, checkout, payments
    // ---------------------------------------------------------------------

    private static void AddBuyingAndPayments(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "buy-retail", "كيف أشتري منتج تجزئة", "ar", Buyers,
            """
            افتح المنتج من الصفحة الرئيسية أو من نتائج البحث.
            راجع السعر والكمية والوحدة والمواصفات في صفحة التفاصيل.
            حدد الكمية المطلوبة ثم أضف المنتج إلى السلة أو اضغط الشراء مباشرة.
            اختر عنوان التسليم من العناوين المحفوظة أو أضف عنواناً جديداً.
            عند إضافة عنوان Retail داخل الإمارات: أدخل السطر الأول للشارع/المنطقة، ورقم الغرفة أو المكتب، واسم المبنى؛ يُحفظ تلقائياً بصيغة "رقم X في اسم المبنى".
            يظهر تنبيه أن رسوم الشحن الإضافية قد تُحسب إذا تجاوز وزن المنتجات 10 كيلو (2 درهم لكل كيلو فوق 10، وأول 10 كيلو مجاناً).
            اختر طريقة الدفع: بطاقة إلكترونية أو الدفع عند الاستلام.
            أكد الطلب، وبعدها يمكنك متابعة حالته من صفحة طلباتي (My Orders).
            """);
        Add(chunks, "buy-retail", "How to buy a retail product", "en", Buyers,
            """
            Open the product from home or from search results.
            Review the price, quantity, unit, and specifications on the details page.
            Choose the quantity you need, then add the product to the cart or buy it directly.
            Select a delivery address from your saved addresses or add a new one.
            When adding a Retail address inside the UAE: enter street/area line 1, room or unit number, and building name; it is saved automatically as "Room number X at {building name}".
            A note explains that extra shipping fees may apply if total weight exceeds 10 kg (AED 2 per kg above 10; the first 10 kg are free).
            Choose the payment method: card payment or cash on delivery.
            Confirm the order, then follow its status from the My Orders page.
            """);

        Add(chunks, "cart", "سلة الشراء", "ar", Buyers,
            """
            يمكنك إضافة أكثر من منتج إلى السلة قبل إتمام الطلب.
            داخل السلة يمكنك تعديل الكمية أو حذف منتج قبل تأكيد الطلب.
            تأكد من احترام الحد الأدنى للطلب المحدد في الإعلان، وإلا لن يُقبل الطلب.
            بعد مراجعة السلة تنتقل إلى اختيار العنوان وطريقة الدفع ثم تأكيد الطلب.
            في طلبات Retail مع التوصيل للمنزل يُعرض تنبيه: رسوم إضافية محتملة إذا الوزن أكثر من 10 كيلو (2 درهم/كيلو فوق 10، وأول 10 كيلو مجاناً).
            """);
        Add(chunks, "cart", "The shopping cart", "en", Buyers,
            """
            You can add more than one product to the cart before placing the order.
            Inside the cart you can change quantities or remove an item before confirming.
            Respect the minimum order quantity set on the listing, otherwise the order will not be accepted.
            After reviewing the cart you move to address selection, payment method, and order confirmation.
            For Retail home delivery, a note warns that extra shipping may apply above 10 kg total weight (AED 2 per kg above 10; first 10 kg free).
            """);

        Add(chunks, "payment-methods", "طرق الدفع المتاحة", "ar", Buyers,
            """
            الدفع الإلكتروني بالبطاقة متاح لطلبات Retail (التجزئة) فقط.
            الدفع عند الاستلام متاح لباقي التدفقات حسب آلية المنصة وفريق الراس الذكي.
            صفقات الجملة وأنواع الإعلانات غير Retail تتم معالجتها ومتابعتها بواسطة فريق الراس الذكي وليس بالدفع الذاتي داخل التطبيق.
            بيانات البطاقة الكاملة يعالجها مزود دفع معتمد ولا تخزنها المنصة.
            استخدم قنوات الدفع داخل المنصة فقط، ولا تحوّل أي مبلغ خارج المنصة.
            """);
        Add(chunks, "payment-methods", "Available payment methods", "en", Buyers,
            """
            Online card payment is available for Retail orders only.
            Cash on delivery applies to the other flows according to the platform process and the Al Ras Smart team.
            Wholesale deals and non-Retail ad types are processed and followed up by the Al Ras Smart team rather than through self-service payment in the app.
            Full card details are handled by an approved payment provider and are not stored by the platform.
            Use in-platform payment channels only and never transfer money outside the platform.
            """);

        Add(chunks, "payment-cod", "الدفع عند الاستلام", "ar", Buyers,
            """
            في الدفع عند الاستلام تدفع قيمة الطلب نقداً عند تسليم البضاعة إليك.
            حالة الطلب تنتقل عبر مراحل حتى تصل إلى تم التسليم بعد استلامك للبضاعة ودفع قيمتها.
            من ناحية المورد، مستحقاته في هذه الحالة تُتابع بعد تحصيل الأموال فعلياً.
            تأكد من فحص البضاعة عند الاستلام، لأن مهلة الإبلاغ عن مشكلة تبدأ من تأكيد الاستلام.
            """);
        Add(chunks, "payment-cod", "Cash on delivery", "en", Buyers,
            """
            With cash on delivery you pay the order value in cash when the goods are handed to you.
            The order status moves through its stages until it reaches Delivered after you receive the goods and pay.
            On the supplier side, dues in this case are followed after the funds are actually collected.
            Inspect the goods at delivery, because the window for reporting a problem starts from confirmed receipt.
            """);

        Add(chunks, "payment-card", "الدفع بالبطاقة الإلكترونية", "ar", Buyers,
            """
            الدفع بالبطاقة متاح لطلبات Retail، وتتم العملية عبر مزود دفع معتمد.
            بعد نجاح الدفع تتحدث حالة الطلب وتستطيع متابعتها من صفحة طلباتي.
            المنصة لا تخزن بيانات بطاقتك الكاملة.
            إذا خُصم المبلغ ولم يظهر الطلب، انتظر قليلاً لتحديث الحالة، فإن استمرت المشكلة تواصل مع الدعم عبر Live Chat مع ذكر وقت العملية.
            """);
        Add(chunks, "payment-card", "Card payment", "en", Buyers,
            """
            Card payment is available for Retail orders and is processed through an approved payment provider.
            After a successful payment the order status updates and you can follow it from My Orders.
            The platform does not store your full card details.
            If an amount was charged but the order does not appear, wait briefly for the status to refresh; if the problem persists contact support via Live Chat and mention the transaction time.
            """);

        Add(chunks, "wholesale-flow", "كيف تتم صفقات الجملة", "ar", ["supplier", "company_customer", "public"],
            """
            الدفع الذاتي عبر المنصة مخصص لتجارة التجزئة (Retail).
            أما طلبات الأنواع الأخرى مثل الجملة وBooking وRequests فتتم متابعتها ومعالجتها بواسطة فريق الراس الذكي، الذي ينسق بين المشتري والمورد ويتابع التحصيل والتسليم.
            الدفع في تجارة الجملة يتم عبر فريق الراس الذكي.
            يمكنك متابعة حالة الطلب من صفحة طلباتي، والتواصل مع الدعم عبر Live Chat لأي استفسار عن الصفقة.
            """);
        Add(chunks, "wholesale-flow", "How wholesale deals are handled", "en", ["supplier", "company_customer", "public"],
            """
            Self-service payment inside the platform is dedicated to Retail trade.
            Orders of other types such as wholesale, Booking, and Requests are followed up and processed by the Al Ras Smart team, which coordinates between buyer and supplier and manages collection and delivery.
            Wholesale payment runs through the Al Ras Smart team.
            You can still follow the order status from My Orders and contact support via Live Chat with any question about the deal.
            """);
    }

    // ---------------------------------------------------------------------
    // 9. Orders and tracking  (high-priority: users ask this constantly)
    // ---------------------------------------------------------------------

    private static void AddOrdersAndTracking(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "orders-track", "كيف أتتبع طلباتي", "ar", Buyers,
            """
            تتبع الطلبات متاح لكل حساب يستطيع الشراء: العميل الفردي وعميل الشركة والمورد.
            افتح صفحة طلباتي (My Orders) من البار السفلي.
            شكل الصفحة يختلف حسب نوع حسابك: العميل الفردي يرى المشتريات فقط (بدون تبويبات)؛ المورد يرى تبويبي الواردة والمشتريات؛ عميل الشركة يرى تبويبي طلباتي (Requests) والمشتريات (Orders).
            ستجد قائمة بكل طلباتك، ولكل طلب حالته الحالية وتاريخه وتفاصيله.
            اضغط على أي طلب لفتح تفاصيله ورؤية سجل تغير الحالة خطوة بخطوة من لحظة الطلب حتى التسليم.
            يمكنك أيضاً التمييز بين الطلبات المفتوحة الجارية والطلبات المكتملة.
            تصلك إشعارات عند تغير حالة طلبك، وتُحدَّث قائمة الطلبات تلقائياً داخل التطبيق دون الحاجة لإعادة فتح الصفحة.
            ملاحظة مهمة: تتبع الطلبات ليس مقيداً بنوع الحساب؛ العميل الفردي لديه صفحة طلباتي كاملة ويستطيع تتبع مشترياته بشكل طبيعي.
            """);
        Add(chunks, "orders-track", "How to track my orders", "en", Buyers,
            """
            Order tracking is available to every account that can buy: personal customers, company customers, and suppliers.
            Open the My Orders page from the bottom bar.
            The page layout depends on your account type: personal customers see Purchases only (no tabs); suppliers see Incoming and Purchases tabs; company customers see Requests and Orders (Purchases) tabs.
            You will see a list of all your orders, each with its current status, date, and details.
            Tap any order to open its details and see the status history step by step from placement to delivery.
            You can also distinguish open, in-progress orders from completed ones.
            Notifications are sent when your order status changes, and the order list refreshes automatically inside the app without reopening the page.
            Important note: order tracking is not restricted by account type; a personal customer has a full My Orders page and can track purchases normally.
            """);

        Add(chunks, "orders-track-personal", "تتبع الطلبات لحساب العميل الفردي", "ar", ["personal"],
            """
            نعم، حسابك كعميل فردي يستطيع تتبع طلباته بشكل كامل.
            صفحة طلباتي (My Orders) موجودة في البار السفلي بجوار الصفحة الرئيسية والملف الشخصي.
            افتحها لترى كل مشترياتك وحالة كل طلب، واضغط على الطلب لعرض تفاصيله وسجل حالته.
            القيود على حساب العميل الفردي تخص إنشاء الإعلانات فقط، ولا علاقة لها بتتبع الطلبات أو الشراء أو البحث.
            """);
        Add(chunks, "orders-track-personal", "Order tracking for a personal customer account", "en", ["personal"],
            """
            Yes, a personal customer account can fully track its orders.
            The My Orders page is in the bottom bar next to Home and Profile.
            Open it to see all your purchases and each order's status, and tap an order to view its details and status history.
            The restrictions on a personal customer account apply only to creating ads; they have nothing to do with order tracking, buying, or searching.
            """);

        Add(chunks, "orders-track-supplier", "تتبع الطلبات والمبيعات للمورد", "ar", ["supplier"],
            """
            المورد لديه صفحة طلباتي (My Orders) في البار السفلي فيها تبويبان: الواردة (طلبات وعروض واردة على إعلاناتك) والمشتريات (ما اشتراه المورد كمشتري).
            تابع الطلبات الواردة من تبويب الواردة؛ الطلبات التي تحتاج موافقتك كبائع تظهر بحالة بانتظار موافقة البائع، وفي تطبيق الجوال قد ترى نصاً مختصراً "بانتظار موافقتك".
            على أيقونة طلباتي في البار السفلي تظهر شارة حمراء بعدد الطلبات الواردة التي بانتظار موافقتك.
            القائمة تُحدَّث تلقائياً عند تغير حالة أي طلب.
            في الطلبات غير التجزئة قد تحتاج بعض الطلبات موافقة البائع، وتظهر بحالة بانتظار موافقة البائع حتى يقبلها أو يرفضها.
            صفحة الحساب (Account) منفصلة عن الطلبات وتخص إعلاناتك وعروضك.
            """);
        Add(chunks, "orders-track-supplier", "Order and sales tracking for suppliers", "en", ["supplier"],
            """
            A supplier has a My Orders page in the bottom bar with two tabs: Incoming (orders and offers received on your ads) and Purchases (orders the supplier placed as a buyer).
            Follow incoming orders from the Incoming tab; orders needing your approval as seller show as Awaiting seller approval, and on the mobile app you may see the shorter label "Awaiting your approval".
            A red badge on the My Orders icon shows how many incoming orders are awaiting your approval.
            The list refreshes automatically when any order status changes.
            For non-retail orders, some orders need seller approval and appear as Awaiting seller approval until accepted or rejected.
            The Account page is separate from orders and covers the supplier's ads and offers.
            """);

        Add(chunks, "order-statuses", "معاني حالات الطلب", "ar", Buyers,
            """
            حالات الطلب في المنصة ومعناها:
            تم الطلب (Ordered): تم إنشاء الطلب وتسجيله في النظام.
            تمت الموافقة (Approved): تمت الموافقة على الطلب ليدخل مرحلة التنفيذ.
            بانتظار موافقة البائع (Awaiting seller approval): تمت الموافقة المبدئية ويُنتظر قبول البائع، وتخص الطلبات غير التجزئة.
            مدفوع (Paid to Merge Spice): تم استلام قيمة الطلب لدى المنصة.
            قيد الشحن (Shipping): الطلب في الطريق إليك.
            تم التسليم (Delivered): تم تسليم الطلب واستلامه.
            ملغي (Cancelled): تم إلغاء الطلب.
            تم الدفع للمورد (Paid to supplier): حوّلت المنصة مستحقات المورد بعد التحصيل.
            طلب استرجاع (Return requested): قدّم المشتري طلب إرجاع، ويخص طلبات التجزئة.
            تمت الموافقة على الاسترجاع (Return approved): وافق الدعم على الإرجاع ويُنفَّذ رد الأموال.
            """);
        Add(chunks, "order-statuses", "Order status meanings", "en", Buyers,
            """
            Order statuses on the platform and what they mean:
            Ordered: the order has been created and recorded.
            Approved: the order is approved to move into fulfilment.
            Awaiting seller approval: pre-approved and waiting for the seller to accept; this applies to non-retail orders.
            Paid to Merge Spice: the order value has been received by the platform.
            Shipping: the order is on its way to you.
            Delivered: the order has been delivered and received.
            Cancelled: the order was cancelled.
            Paid to supplier: the platform transferred the supplier's dues after collection.
            Return requested: the buyer submitted a return request; this applies to retail orders.
            Return approved: support approved the return and the refund is being applied.
            """);

        Add(chunks, "order-details", "تفاصيل الطلب وسجل الحالة", "ar", Buyers,
            """
            عند فتح أي طلب من صفحة طلباتي تظهر تفاصيله: المنتجات والكميات والأسعار والإجمالي وطريقة الدفع وعنوان التسليم.
            يظهر أيضاً سجل تغير الحالة (Status history) الذي يوضح كل مرحلة مر بها الطلب وتاريخها، فتعرف بالضبط أين وصل طلبك.
            يمكن أن يحتوي الطلب على صور أو ملاحظات مرتبطة به.
            إذا لاحظت بياناً غير صحيح في الطلب تواصل مع الدعم عبر Live Chat في أسرع وقت.
            """);
        Add(chunks, "order-details", "Order details and status history", "en", Buyers,
            """
            Opening an order from My Orders shows its details: products, quantities, prices, total, payment method, and delivery address.
            It also shows the status history listing every stage the order passed through with its date, so you know exactly where your order stands.
            An order may also carry related images or notes.
            If you notice incorrect information on an order, contact support via Live Chat as soon as possible.
            """);

        Add(chunks, "order-cancel", "إلغاء الطلب", "ar", Buyers,
            """
            إمكانية الإلغاء تعتمد على المرحلة التي وصل إليها الطلب.
            قبل الشحن يكون الإلغاء أسهل، أما بعد بدء الشحن فيحتاج التنسيق مع الدعم.
            عند إلغاء الطلب تتحول حالته إلى ملغي (Cancelled).
            إذا كنت قد دفعت بالبطاقة يُعالج رد المبلغ وفق سياسة الاسترجاع وردود مزود الدفع.
            لطلب الإلغاء تواصل مع الدعم عبر Live Chat من الملف الشخصي مع ذكر رقم الطلب.
            المساعد الذكي لا يستطيع إلغاء طلب نيابة عنك؛ الإلغاء يتم عبر الدعم أو من داخل التطبيق حسب المرحلة.
            """);
        Add(chunks, "order-cancel", "Cancelling an order", "en", Buyers,
            """
            Whether an order can be cancelled depends on the stage it has reached.
            Cancellation is straightforward before shipping; after shipping starts it requires coordination with support.
            When cancelled, the order status becomes Cancelled.
            If you paid by card, the refund is processed according to the returns policy and the payment provider's process.
            To request cancellation, contact support via Live Chat from Profile and include the order number.
            The AI Assistant cannot cancel an order for you; cancellation happens through support or in the app depending on the stage.
            """);

        Add(chunks, "order-delayed", "طلبي متأخر أو لم يصل", "ar", Buyers,
            """
            أولاً افتح صفحة طلباتي وتحقق من الحالة الحالية وسجل الحالة لمعرفة المرحلة التي وصل إليها الطلب.
            إذا كانت الحالة قيد الشحن فالطلب في الطريق وقد يتأخر بسبب المسافة أو ظروف التوصيل.
            إذا مرت مدة طويلة دون تحديث للحالة، تواصل مع الدعم عبر Live Chat وأرفق رقم الطلب وتاريخه.
            تأكد أيضاً من صحة العنوان ورقم الهاتف المسجلين في الطلب، لأن بيانات خاطئة قد تؤخر التسليم.
            """);
        Add(chunks, "order-delayed", "My order is late or has not arrived", "en", Buyers,
            """
            First open My Orders and check the current status and the status history to see which stage the order has reached.
            If the status is Shipping, the order is on its way and may be delayed by distance or delivery conditions.
            If a long time has passed with no status update, contact support via Live Chat with the order number and date.
            Also confirm that the address and phone number on the order are correct, since wrong details can delay delivery.
            """);

        Add(chunks, "notifications", "الإشعارات", "ar", SignedIn,
            """
            ترسل المنصة إشعارات عند الأحداث المهمة مثل تغير حالة الطلب، واعتماد الإعلان أو رفضه، وقبول أو رفض العرض المقدم.
            تأكد من السماح بالإشعارات لتطبيق الراس الذكي في إعدادات جهازك حتى تصلك التنبيهات.
            حتى إن لم تصلك الإشعارات يمكنك دائماً متابعة الحالة يدوياً من صفحة طلباتي أو صفحة الحساب؛ قائمة الطلبات في التطبيق تُحدَّث تلقائياً عند تغير أي حالة.
            """);
        Add(chunks, "notifications", "Notifications", "en", SignedIn,
            """
            The platform sends notifications for important events such as order status changes, listing approval or rejection, acceptance or rejection of a submitted offer.
            Make sure notifications are allowed for the Al Ras Smart app in your device settings so alerts reach you.
            Even without notifications you can always check status manually from My Orders or the Account page; the order list in the app refreshes automatically when any status changes.
            """);
    }

    // ---------------------------------------------------------------------
    // 9b. Recent orders & ads UX (My Orders tabs, realtime, retail address)
    // ---------------------------------------------------------------------

    private static void AddRecentOrdersAndAdsUpdates(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "my-orders-tabs", "تبويبات صفحة طلباتي حسب نوع الحساب", "ar", Buyers,
            """
            سؤال: وين الطلبات الواردة؟ وين المشتريات؟ كم تبويب في طلباتي؟
            صفحة طلباتي (My Orders) في البار السفلي تعرض محتوى مختلفاً حسب نوع حسابك:
            العميل الفردي (Personal): قائمة واحدة فقط للمشتريات — كل طلبات Retail التي اشتراها، بدون تبويبات.
            المورد (Supplier): تبويبان — الواردة (Incoming): الطلبات والعروض الواردة على إعلاناته التي يحتاج قبولها أو رفضها كبائع؛ والمشتريات (Purchases): ما اشتراه المورد كمشتري.
            عميل الشركة (Company customer): تبويبان — طلباتي (Requests): شبكة إعلانات Request التي نشرها ثم قائمة العروض الواردة من الموردين عليها (قبول/رفض)؛ والمشتريات (Orders): مشترياته كمشتري (Retail أو Booking أو غيرها).
            شركة الشحن ليس لديها صفحة طلباتي.
            """);
        Add(chunks, "my-orders-tabs", "My Orders tabs by account type", "en", Buyers,
            """
            Question: where are incoming orders? where are purchases? how many tabs in My Orders?
            The My Orders page in the bottom bar shows different content by account type:
            Personal customer: a single Purchases list — all Retail orders they bought, no tabs.
            Supplier: two tabs — Incoming: orders and offers received on their ads that need accept/reject as seller; Purchases: orders the supplier placed as a buyer.
            Company customer: two tabs — Requests: a grid of Request ads you published, then incoming supplier offers on them (accept/reject); Orders (Purchases): their buyer purchases (Retail, Booking, etc.).
            Shipping companies do not have a My Orders page.
            """);

        Add(chunks, "orders-realtime-badge", "تحديث الطلبات تلقائياً والشارة الحمراء", "ar", ["supplier", "company_customer", "personal"],
            """
            سؤال: ليه في رقم أحمر على طلباتي؟ ليه القائمة تتحدث لوحدها؟
            عند تغير حالة أي طلب مرتبط بحسابك تُحدَّث قائمة طلباتي في التطبيق تلقائياً دون إعادة فتح الصفحة (تحديث فوري).
            للمورد: تظهر شارة حمراء على أيقونة طلباتي في البار السفلي بعدد الطلبات الواردة التي بانتظار موافقتك كبائع (حالة بانتظار موافقة البائع).
            الشارة تختفي أو ينقص العدد بعد قبولك أو رفضك للطلبات.
            عميل الشركة والعميل الفردي لا يرون هذه الشارة؛ هم يتابعون مشترياتهم فقط (أو تبويب المشتريات لعميل الشركة).
            """);
        Add(chunks, "orders-realtime-badge", "Automatic order refresh and red badge", "en", ["supplier", "company_customer", "personal"],
            """
            Question: why is there a red number on My Orders? why does the list update by itself?
            When any order linked to your account changes status, the My Orders list in the app refreshes automatically without reopening the page (live update).
            For suppliers: a red badge on the My Orders icon in the bottom bar shows how many incoming orders are awaiting your approval as seller (Awaiting seller approval status).
            The badge clears or the count drops after you accept or reject those orders.
            Company and personal customers do not see this badge; they follow their purchases only (or the Purchases tab for company customers).
            """);

        Add(chunks, "seller-awaiting-label", "نص بانتظار موافقتك للمورد في الجوال", "ar", ["supplier"],
            """
            سؤال: معنى "بانتظار موافقتك" على الطلب؟
            في تطبيق الجوال، عندما يكون الطلب الوارد على إعلانك في حالة بانتظار موافقة البائع، قد يظهر نص مختصر "بانتظار موافقتك" على بطاقة الطلب.
            هذا يعني أن العميل قدّم الطلب ويُنتظر قبولك أو رفضك كبائع (يخص الطلبات غير التجزئة عادةً).
            افتح تبويب الواردة في طلباتي لقبول الطلب أو رفضه.
            النص الكامل للحالة في النظام هو "بانتظار موافقة البائع"؛ الاختصار للعرض في الجوال فقط.
            """);
        Add(chunks, "seller-awaiting-label", "Awaiting your approval label for suppliers on mobile", "en", ["supplier"],
            """
            Question: what does "Awaiting your approval" mean on an order?
            On the mobile app, when an incoming order on your listing is in Awaiting seller approval status, the order card may show the shorter label "Awaiting your approval".
            This means the customer placed the order and your accept or reject decision as seller is pending (usually for non-retail orders).
            Open the Incoming tab in My Orders to accept or reject the order.
            The full system status is "Awaiting seller approval"; the shorter label is for mobile display only.
            """);

        Add(chunks, "retail-address-checkout", "عنوان التوصيل Retail عند الدفع", "ar", ["personal", "public"],
            """
            سؤال: كيف أدخل عنوان التوصيل للتجزئة؟ رقم الغرفة والمبنى؟
            عند شراء Retail والتوصيل للمنزل داخل الإمارات، يمكنك اختيار عنوان محفوظ أو إضافة عنوان جديد.
            في نموذج العنوان Retail: أدخل السطر الأول (الشارع/المنطقة)، ورقم الغرفة أو المكتب، واسم المبنى.
            يُحفظ العنوان تلقائياً بصيغة "رقم X في اسم المبنى" (Room number X at building name).
            يظهر تنبيه رمادي: رسوم شحن إضافية محتملة إذا تجاوز وزن المنتجات 10 كيلو — 2 درهم لكل كيلو فوق 10، وأول 10 كيلو مجاناً.
            في لوحة الإدارة، عند طباعة أمر التسليم لطلب Retail، يظهر عنوان التسليم الكامل (المدينة + العنوان).
            """);
        Add(chunks, "retail-address-checkout", "Retail delivery address at checkout", "en", ["personal", "public"],
            """
            Question: how do I enter a Retail delivery address? room and building?
            When buying Retail with home delivery inside the UAE, you can pick a saved address or add a new one.
            In the Retail address form: enter line 1 (street/area), room or unit number, and building name.
            The address is saved automatically as "Room number X at {building name}".
            A gray note warns that extra shipping may apply if total product weight exceeds 10 kg — AED 2 per kg above 10; the first 10 kg are free.
            In the admin dashboard, printing a Retail delivery sheet shows the full delivery address (city + address line).
            """);

        Add(chunks, "ads-vs-orders-company", "الفرق بين إعلانات Request والطلبات لعميل الشركة", "ar", ["company_customer"],
            """
            سؤال: وين إعلاناتي؟ وين طلباتي؟ الفرق بين الحساب وطلباتي؟
            عميل الشركة ينشر إعلانات Request فقط (طلب بضاعة يريد شراءها بالجملة).
            صفحة الحساب (Account): إعلاناتي فقط — كل إعلانات Request التي نشرتها؛ لا يوجد قسم عروضي (My Offers) لعميل الشركة.
            صفحة طلباتي — تبويب طلباتي (Requests): إعلانات Request التي نشرتها (في الأعلى) والعروض الواردة من الموردين عليها (في الأسفل) مع قبولها أو رفضها.
            صفحة طلباتي — تبويب المشتريات (Orders): الطلبات التي أكملتها كمشتري (شراء Retail أو Booking أو غيره)، وليست إعلانات Request.
            إذا سألت عن "إعلان Request" فالجواب من الحساب أو تبويب Requests؛ إذا سألت عن "طلب شراء" أو "مشترياتي" فالجواب من تبويب المشتريات.
            """);
        Add(chunks, "ads-vs-orders-company", "Request ads vs orders for company customers", "en", ["company_customer"],
            """
            Question: where are my ads? where are my orders? Account vs My Orders?
            A company customer publishes Request ads only (wholesale sourcing requests).
            Account page: My Ads only — every Request ad you published; there is no My Offers section for company customers.
            My Orders — Requests tab: your published Request ads (at the top) and incoming supplier offers on them (below), with accept/reject actions.
            My Orders — Orders (Purchases) tab: orders you completed as a buyer (Retail, Booking, etc.), not Request ads.
            If you ask about a "Request ad" the answer is Account or the Requests tab; if you ask about a "purchase" or "my orders" the answer is the Purchases tab.
            """);

        Add(chunks, "ads-vs-orders-supplier", "الفرق بين الإعلانات والطلبات للمورد", "ar", ["supplier"],
            """
            سؤال: وين إعلاناتي؟ وين الطلبات الواردة؟
            المورد ينشر إعلانات Booking و Retail و Offers و Shipping (لا ينشر Request).
            صفحة الحساب (Account): إعلاناتي — إعلاناتك المنشورة؛ عروضي — عروضك على إعلانات Request للشركات.
            صفحة طلباتي — تبويب الواردة: الطلبات والعروض الواردة على إعلاناتك (قبول/رفض كبائع).
            صفحة طلباتي — تبويب المشتريات: ما اشتراه المورد كمشتري.
            تعديل السعر أو الكمية في الإعلان من الحساب → إعلاناتي؛ متابعة طلب وارد على إعلانك من طلباتي → الواردة.
            """);
        Add(chunks, "ads-vs-orders-supplier", "Ads vs orders for suppliers", "en", ["supplier"],
            """
            Question: where are my ads? where are incoming orders?
            A supplier publishes Booking, Retail, Offers, and Shipping ads (not Request ads).
            Account page: My Ads — your published listings; My Offers — your offers on companies' Request ads.
            My Orders — Incoming tab: orders and offers received on your ads (accept/reject as seller).
            My Orders — Purchases tab: orders the supplier placed as a buyer.
            Edit price or quantity from Account → My Ads; follow an incoming order on your listing from My Orders → Incoming.
            """);
    }

    // ---------------------------------------------------------------------
    // 10. Returns and refunds
    // ---------------------------------------------------------------------

    private static void AddReturnsAndRefunds(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "returns", "سياسة الاسترجاع والاسترداد", "ar", All,
            """
            يجب الإبلاغ عن طلب الاسترجاع خلال 24 ساعة عمل من تأكيد الاستلام، مع صور أو فيديو للمشكلة وسبب واضح.
            الحالات المقبولة عادة: بضاعة تالفة أو فاسدة، بضاعة منتهية الصلاحية بخلاف ما ذُكر في الإعلان، منتج مختلف جوهرياً عن الوصف، أو نقص واضح في الكمية.
            الحالات غير المقبولة عادة: تغيير الرأي دون وجود عيب، سوء التخزين أو التعامل بعد التسليم، أو استهلاك معظم الكمية دون عيب مثبت.
            إذا وافق الدعم الفني على الإرجاع يتم رد الأموال خلال يوم عمل واحد من الموافقة.
            """);
        Add(chunks, "returns", "Returns and refunds policy", "en", All,
            """
            A return must be reported within 24 business hours of confirmed receipt, with photos or video of the problem and a clear reason.
            Typically accepted: damaged or spoiled goods, goods expired contrary to the listing, an item materially different from the description, or a clear quantity shortage.
            Typically not accepted: change of mind with no defect, poor storage or handling after delivery, or consuming most of the goods without a proven defect.
            If support approves the return, the refund is issued within one business day of approval.
            """);

        Add(chunks, "returns-how", "كيف أقدم طلب استرجاع خطوة بخطوة", "ar", Buyers,
            """
            افحص البضاعة فور استلامها.
            صوّر المشكلة بوضوح: صور أو فيديو تُظهر التلف أو تاريخ الصلاحية أو اختلاف المنتج أو نقص الكمية.
            افتح صفحة طلباتي واختر الطلب المعني.
            قدّم طلب الاسترجاع مع إرفاق الصور وكتابة السبب بوضوح، أو تواصل مع الدعم عبر Live Chat من الملف الشخصي إن احتجت مساعدة.
            التزم بمهلة 24 ساعة عمل من تأكيد الاستلام، لأن التأخير قد يؤدي إلى رفض الطلب.
            تتحول حالة الطلب إلى طلب استرجاع، ثم إلى تمت الموافقة على الاسترجاع إذا قبله الدعم.
            بعد الموافقة يتم رد الأموال خلال يوم عمل واحد.
            """);
        Add(chunks, "returns-how", "How to submit a return request step by step", "en", Buyers,
            """
            Inspect the goods as soon as you receive them.
            Photograph the problem clearly: images or video showing the damage, the expiry date, the different item, or the quantity shortage.
            Open My Orders and select the affected order.
            Submit the return request with the attached photos and a clear written reason, or contact support via Live Chat from Profile if you need help.
            Stay within the 24 business hours window from confirmed receipt, because delay can cause rejection.
            The order status becomes Return requested, then Return approved if support accepts it.
            After approval the refund is issued within one business day.
            """);

        Add(chunks, "returns-damaged", "بضاعة تالفة أو منتهية الصلاحية", "ar", All,
            """
            إذا وصلتك بضاعة تالفة أو فاسدة أو منتهية الصلاحية بخلاف ما هو مذكور في الإعلان، فهذه من الحالات المؤهلة للاسترجاع.
            بلّغ خلال 24 ساعة عمل من تأكيد الاستلام مع صور أو فيديو واضح يوضح التلف أو تاريخ انتهاء الصلاحية على العبوة.
            لا تتخلص من البضاعة أو العبوة قبل انتهاء مراجعة الدعم، لأنها دليل الحالة.
            إذا وافق الدعم يتم رد الأموال خلال يوم عمل واحد من الموافقة.
            المورد مسؤول عن مطابقة البضاعة للوصف وعن صلاحيتها.
            """);
        Add(chunks, "returns-damaged", "Damaged or expired goods", "en", All,
            """
            If you receive damaged, spoiled, or expired goods contrary to the listing, this is an eligible return case.
            Report it within 24 business hours of confirmed receipt with clear photos or video showing the damage or the expiry date on the packaging.
            Do not dispose of the goods or packaging before support finishes its review, as they are the evidence.
            If support approves, the refund is issued within one business day of approval.
            The supplier is responsible for the goods matching the description and for their validity.
            """);

        Add(chunks, "returns-rejected", "لماذا قد يُرفض طلب الاسترجاع", "ar", All,
            """
            الأسباب الشائعة لرفض طلب الاسترجاع: الإبلاغ بعد انتهاء مهلة 24 ساعة عمل من تأكيد الاستلام، أو عدم إرفاق صور أو فيديو تثبت المشكلة، أو تغيير الرأي دون وجود عيب في المنتج، أو تلف ناتج عن سوء التخزين أو التعامل بعد التسليم، أو استهلاك معظم الكمية دون عيب مثبت.
            لتفادي الرفض: افحص البضاعة فور الاستلام، وصوّر المشكلة مباشرة، وقدّم الطلب داخل المهلة مع سبب واضح.
            إذا رُفض طلبك وتعتقد أن القرار غير صحيح يمكنك مناقشة الأمر مع الدعم عبر Live Chat وتقديم أدلة إضافية.
            """);
        Add(chunks, "returns-rejected", "Why a return request may be rejected", "en", All,
            """
            Common rejection reasons: reporting after the 24 business hours window from confirmed receipt, not attaching photos or video proving the problem, change of mind with no product defect, damage caused by poor storage or handling after delivery, or consuming most of the quantity without a proven defect.
            To avoid rejection: inspect the goods on receipt, photograph the problem immediately, and submit within the window with a clear reason.
            If your request is rejected and you believe the decision is wrong, discuss it with support via Live Chat and provide additional evidence.
            """);

        Add(chunks, "refund-timing", "متى تُرد الأموال بعد الموافقة", "ar", All,
            """
            بعد موافقة الدعم الفني على طلب الاسترجاع يتم رد الأموال خلال يوم عمل واحد من الموافقة.
            في الدفع الإلكتروني يُرد المبلغ عبر مزود الدفع، وقد يستغرق ظهوره في كشف حسابك البنكي وقتاً إضافياً حسب البنك.
            في الدفع عند الاستلام تتم التسوية وفق آلية المنصة وفريق الراس الذكي.
            """);
        Add(chunks, "refund-timing", "When the refund is issued after approval", "en", All,
            """
            After support approves the return, the refund is issued within one business day of approval.
            For card payments the amount is refunded through the payment provider, and it may take extra time to appear on your bank statement depending on your bank.
            For cash on delivery, settlement follows the platform process and the Al Ras Smart team.
            """);
    }

    // ---------------------------------------------------------------------
    // 11. Supplier ad creation
    // ---------------------------------------------------------------------

    private static void AddSupplierAdCreation(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "overseas-supplier-ads", "المورد خارج الإمارات أو المسجل برقم غير إماراتي: ما الإعلانات المسموحة؟", "ar", ["supplier", "public"],
            """
            سؤال: أنا مورد خارج الإمارات، ما نوع الإعلان الذي أستطيع إضافته؟ رقمي غير إماراتي، لماذا لا تظهر أنواع الإعلانات؟ هل المورد الدولي يستطيع إضافة Retail أو Offer أو Request؟
            الإجابة: إذا كان حساب المورد مسجلاً برقم هاتف غير إماراتي وكان موقعه خارج دولة الإمارات، فإن نوع الإعلان المتاح له هو Booking فقط.
            لا يستطيع هذا المورد إنشاء Category أو Retail أو Offer بخصم أو Request، ولذلك لا تظهر له هذه الأنواع في صفحة إنشاء الإعلان.
            إعلان Booking مناسب للتجارة والشحنات الدولية، ويجب فيه إدخال الدولة المصدرة وميناء التحميل وبلد الوجهة وميناء الوصول، واختيار FOB أو CNF أو CIF، وتكون العملة بالدولار USD.
            أما المورد داخل الإمارات والمسجل برقم إماراتي فتتاح له أنواع الإعلانات الأخرى بحسب صلاحيات حساب المورد.
            هذا القيد يخص إنشاء الإعلانات فقط؛ ولا يمنع المورد خارج الإمارات من إدارة حسابه أو متابعة طلباته وإعلانات Booking الخاصة به أو استخدام الدعم.
            """);
        Add(chunks, "overseas-supplier-ads", "Overseas supplier or non-UAE phone number: which ads are allowed?", "en", ["supplier", "public"],
            """
            Question: I am a supplier outside the UAE; which ad can I create? My phone number is non-UAE; why are the other ad types missing? Can an international supplier create Retail, Offer, or Request ads?
            Answer: If the supplier account is registered with a non-UAE phone number and the supplier is located outside the UAE, Booking is the only ad type available.
            This supplier cannot create Category, Retail, discounted Offer, or Request ads, so those creation types are not shown on the Create Ad page.
            Booking fits international trade and shipments: enter the origin country, loading port, destination country, arrival port, choose FOB, CNF, or CIF, and use USD.
            A UAE-based supplier registered with a UAE phone number can access the other supplier ad types according to the account permissions.
            This restriction applies only to creating ads; it does not prevent an overseas supplier from managing the account, tracking orders and Booking ads, or using support.
            """);

        Add(chunks, "supplier-create-overview", "صفحة إنشاء الإعلان للمورد", "ar", ["supplier"],
            """
            من البار السفلي اختر إنشاء إعلان.
            المورد داخل الإمارات يستطيع إنشاء إعلان داخل صنف (Category)، أو Retail، أو Booking، أو Offer بخصم، أو Request. أما المورد المسجل برقم غير إماراتي والموجود خارج الإمارات فيستطيع إنشاء Booking فقط.
            في كل الأنواع تُضاف صور المنتج والفيديو والمواصفات، والتعبئة اختيارية.
            بعد الحفظ يدخل الإعلان مرحلة المراجعة (تحت المعالجة) قبل الظهور للجمهور.
            بعد الاعتماد يصبح الإعلان نشطاً ويظهر في القسم المناسب له.
            """);
        Add(chunks, "supplier-create-overview", "The supplier Create Ad page", "en", ["supplier"],
            """
            Choose Create Ad from the bottom bar.
            A UAE-based supplier can create a Category listing, Retail, Booking, a discounted Offer, or a Request. A supplier registered with a non-UAE phone number and located outside the UAE can create Booking only.
            All types take product images, video, and specifications, with packaging optional.
            After saving, the ad enters review (under review) before becoming publicly visible.
            Once approved it becomes active and appears in its matching section.
            """);

        Add(chunks, "create-category-ad", "كيف ينشئ المورد إعلاناً داخل صنف", "ar", ["supplier"],
            """
            افتح إنشاء إعلان واختر النوع صنف (Category).
            اختر الصنف المناسب للمنتج.
            أدخل اسم المنتج والوصف والمواصفات.
            أدخل الكمية المتاحة واختر الوحدة المناسبة: طن أو كيلوجرام أو كيس أو كرتون أو عبوة أو صندوق أو حزمة أو درزن أو برميل أو زجاجة أو علبة معدنية أو شوال أو كرتونة أو طبلية أو لتر أو ملليلتر أو جرام أو برطمان أو قطعة.
            أدخل السعر واختر العملة درهم AED أو دولار USD.
            اختر نوع التلبية: محلي أو إعادة تصدير (إلزامي).
            اسأل عن التعبئة بالكيلو جرام في كل إعلان (المستخدم قد يقول بدون).
            إذا فعّل التجزئة (هجين): اجمع أيضاً سعر وكمية ووحدة ومواصفات التجزئة منفصلة قبل النشر — لا تنسَ مواصفات التجزئة.
            يمكنك اختيارياً تحديد حد أدنى وحد أقصى للطلب.
            أضف صور المنتج والفيديو إن وُجد، والتعبئة اختيارية.
            احفظ الإعلان، وسيدخل المراجعة ثم يظهر داخل الصنف الذي اخترته في الصفحة الرئيسية.
            """);
        Add(chunks, "create-category-ad", "How a supplier creates a category listing", "en", ["supplier"],
            """
            Open Create Ad and choose the Category type.
            Select the category that fits the product.
            Enter the product name, description, and specifications.
            Enter the available quantity and choose the unit: ton, kilogram, bag, carton, packet, box, bundle, dozen, drum, bottle, tin, sack, case, pallet, liter, ml, gram, jar, or piece.
            Enter the price and choose the currency, AED or USD.
            Choose fulfillment type: Local or Reexport (required).
            Always ask packaging in kg for every ad (user may say none).
            If enabling retail (hybrid): also collect separate retail price, quantity, unit, and retail specifications before publish — never skip retail specs.
            Optionally set a minimum and maximum order quantity.
            Add product images and a video if available; packaging details are optional.
            Save the ad; it enters review and then appears inside the category you selected on the home page.
            """);

        Add(chunks, "create-retail-ad", "كيف يفعّل المورد البيع بالتجزئة", "ar", ["supplier"],
            """
            أثناء إنشاء إعلان داخل صنف يمكن للمورد اختيارياً تفعيل البيع بالتجزئة لنفس المنتج (إعلان هجين جملة+تجزئة).
            عند التفعيل يجب إدخال بيانات التجزئة منفصلة قبل النشر: كمية التجزئة، وسعر التجزئة (AED)، ووحدة التجزئة، ومواصفات التجزئة — لا تُنسخ مواصفات الجملة تلقائياً.
            اسأل أيضاً عن تعبئة الجملة وتعبئة التجزئة (كجم) حتى لو قال المستخدم لاحقاً بدون.
            سعر التجزئة بالدرهم AED دائماً.
            بعد التفعيل يظهر المنتج في مكانين: داخل الصنف ببيانات الجملة، وداخل قسم Retail ببيانات التجزئة.
            في شات الراس الذكي: لا تستدعِ create_category_ad مع enable_retail_pricing قبل جمع مواصفات التجزئة.
            """);
        Add(chunks, "create-retail-ad", "How a supplier enables retail selling", "en", ["supplier"],
            """
            While creating a category listing, a supplier can optionally enable retail selling (hybrid wholesale+retail).
            When enabled, collect separate retail data BEFORE publishing: retail quantity, retail price (AED), retail unit, and retail specifications — do not silently copy wholesale specs.
            Also ask for wholesale packaging and retail packaging (kg); the user may answer none.
            Retail price is always AED.
            Once enabled, the product appears in the category (wholesale) and in Retail (retail).
            In Alras Smart chat: never call create_category_ad with enable_retail_pricing until retail_specifications is collected.
            """);

        Add(chunks, "create-booking-ad", "كيف ينشئ المورد إعلان Booking", "ar", ["supplier"],
            """
            لإضافة إعلان Booking كمورد: افتح إنشاء إعلان واختر نوع Booking.
            العملة في Booking هي الدولار USD دائماً ولا يمكن تحويلها إلى درهم.
            اختر نوع السعر أولاً: FOB أو CNF أو CIF.
            أدخل الدولة المصدرة.
            إذا كان النوع CNF أو CIF فأدخل أيضاً بلد الوجهة وميناء التحميل وميناء الوصول. أما FOB فلا تظهر بلد الوجهة ولا الموانئ ولا تُطلب.
            أدخل الكمية والوحدة والسعر.
            أضف صور المنتج والفيديو والمواصفات، والتعبئة اختيارية.
            احفظ وانشر الإعلان ليدخل المراجعة ثم يظهر ضمن قسم Booking.
            هذا الإجراء متاح للمورد فقط؛ الحسابات الأخرى لا تستطيع إنشاء إعلان Booking.
            """);
        Add(chunks, "create-booking-ad", "How a supplier creates a Booking ad", "en", ["supplier"],
            """
            To create a Booking ad as a supplier: open Create Ad and choose Booking.
            Booking currency is always USD and cannot be switched to AED.
            Choose the price type first: FOB, CNF, or CIF.
            Enter the exporting/origin country.
            If the type is CNF or CIF, also enter the destination country, loading port, and arrival port. For FOB, destination country and ports are hidden and not required.
            Enter the quantity, unit, and price.
            Add product images, video, and specifications; packaging is optional.
            Save and publish so the ad enters review and then appears under the Booking section.
            This action is available to suppliers only; other account types cannot create Booking ads.
            """);

        Add(chunks, "create-offer-ad", "كيف ينشئ المورد إعلان Offer بخصم", "ar", ["supplier"],
            """
            افتح إنشاء إعلان واختر نوع Offer.
            أدخل بيانات المنتج المعتادة: الاسم والوصف والمواصفات والكمية والوحدة والسعر والعملة.
            اختر محلي أو إعادة تصدير (إلزامي).
            حدد نسبة الخصم ومدة الخصم بالأيام.
            أضف الصور والفيديو والمواصفات، والتعبئة اختيارية.
            بعد الاعتماد يظهر الإعلان في قسم Offers مع نسبة الخصم.
            انتبه أن Offer هنا تعني إعلان خصم، وهي غير تقديم عرض على إعلان Request.
            """);
        Add(chunks, "create-offer-ad", "How a supplier creates a discounted Offer ad", "en", ["supplier"],
            """
            Open Create Ad and choose the Offer type.
            Enter the usual product data: name, description, specifications, quantity, unit, price, and currency.
            Choose Local or Reexport (required).
            Set the discount percentage and the discount duration in days.
            Add images, video, and specifications; packaging is optional.
            After approval the ad appears in the Offers section with its discount.
            Note that Offer here means a discount ad, which is different from submitting an offer on a Request ad.
            """);

        Add(chunks, "ad-media-rules", "قواعد صور وفيديو ومواصفات الإعلان", "ar", ["supplier", "company_customer", "shipping", "public"],
            """
            صور المنتج والفيديو والمواصفات مطلوبة في كل أنواع الإعلانات، أما تفاصيل التعبئة فاختيارية.
            يجب أن تمثل الصور المنتج الحقيقي المعروض ولا تكون مضللة.
            يُمنع منعاً باتاً وضع رقم هاتف أو بريد أو اسم شركة أو أي وسيلة تواصل داخل الصور أو الوصف.
            كما يُمنع ظهور شعارات الشركات أو ماركات تجارية واضحة على العبوات في صور الإعلان.
            مسموح ذكر بلد المنشأ والمواصفات في الاسم والوصف (مثل: حبوب سودانية، هيل هندي، أرز مصري، درجة أولى).
            يجب أن تكون الصور واضحة وبإضاءة جيدة، فهي تُستخدم أيضاً في تحسين البحث بالصور مما يزيد ظهور منتجك.
            الإعلان الذي يخالف هذه القواعد قد يُرفض في المراجعة.
            """);
        Add(chunks, "ad-media-rules", "Rules for listing images, video, and specifications", "en", ["supplier", "company_customer", "shipping", "public"],
            """
            Product images, video, and specifications are required across all ad types, while packaging details are optional.
            Images must represent the actual product on offer and must not be misleading.
            Placing a phone number, email, company name, or any contact channel inside the images or description is strictly prohibited.
            Product brand logos or clear commercial trademarks on packaging must not appear in listing photos.
            Origin country and product specifications in the title/description are allowed
            (e.g. Sudanese peanuts, Indian cardamom, Egyptian rice, Grade A).
            Images should be clear and well lit, since they also feed image-search quality, which increases your product's visibility.
            A listing that breaks these rules can be rejected during review.
            """);

        Add(chunks, "moq", "الحد الأدنى والأقصى للطلب", "ar", ["supplier", "company_customer", "public"],
            """
            يمكن للمعلن تحديد حد أدنى للطلب (Minimum Order Quantity) وحد أقصى عند إنشاء الإعلان.
            الحد الأدنى يمنع المشترين من طلب كمية صغيرة جداً لا تناسب البيع بالجملة.
            الحد الأقصى يحمي المخزون من طلب كمية أكبر من المتاح.
            المشتري يرى هذه الحدود في صفحة تفاصيل الإعلان ولا يستطيع تجاوزها عند الطلب.
            """);
        Add(chunks, "moq", "Minimum and maximum order quantity", "en", ["supplier", "company_customer", "public"],
            """
            The advertiser can set a Minimum Order Quantity and a maximum when creating the listing.
            The minimum prevents buyers from ordering a quantity too small for wholesale trade.
            The maximum protects stock from orders larger than what is available.
            Buyers see these limits on the listing details page and cannot exceed them when ordering.
            """);
    }

    // ---------------------------------------------------------------------
    // 12. Ad management and statuses
    // ---------------------------------------------------------------------

    private static void AddAdManagement(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "my-ads", "قسم إعلاناتي والفلترة", "ar", ["supplier"],
            """
            قسم إعلاناتي داخل صفحة الحساب يعرض كل الإعلانات التي نشرها المورد.
            يمكنك الفلترة حسب حالة الإعلان: نشط، متوقف، نفد المخزون، تحت المعالجة (قيد المراجعة)، مرفوض.
            يمكنك أيضاً الفلترة حسب نوع الإعلان مثل Category أو Retail أو Booking أو Offers أو Requests.
            من هنا تفتح أي إعلان لتعديله أو إيقافه أو تفعيله أو تحديث كميته.
            """);
        Add(chunks, "my-ads", "The My Ads section and its filters", "en", ["supplier"],
            """
            The My Ads section inside the Account page lists every ad the supplier published.
            You can filter by listing status: active, paused, out of stock, under review, and rejected.
            You can also filter by ad type such as Category, Retail, Booking, Offers, or Requests.
            From here you open any listing to edit it, pause or activate it, or update its quantity.
            """);

        Add(chunks, "my-last-first-ad", "آخر إعلان وأول إعلان نزلته", "ar", ["supplier", "company_customer", "shipping"],
            """
            سؤال: هات آخر إعلان نزلته / آخر إعلان نشرته / آخر إعلان أضفته / أجدّ إعلان عندي؟
            الإجابة: المقصود آخر إعلان أنشأته أنت (بحسب تاريخ الإنشاء)، وليس آخر طلب شراء ولا آخر طلب على إعلانك.
            الوكيل يستدعي get_my_last_ad ويعرض الاسم والكود والحالة والسعر/الكمية وتاريخ الإنشاء من بياناتك الحية.

            سؤال: هات أول إعلان نزلته / أول إعلان نشرته / أول إعلان أضفته / أقدم إعلان عندي؟
            الإجابة: المقصود أول إعلان أنشأته (أقدم تاريخ إنشاء)، وليس أول طلب.
            الوكيل يستدعي get_my_first_ad ويعرض نفس التفاصيل من بياناتك الحية.

            لا تخلط بين «آخر إعلان» و«آخر اوردر / آخر طلب». إن كان السؤال غامضاً اسأل: تقصد آخر إعلان نشرته ولا آخر طلب؟
            """);
        Add(chunks, "my-last-first-ad", "My last ad and first ad I posted", "en", ["supplier", "company_customer", "shipping"],
            """
            Question: What is the last ad I posted / my newest listing / show my latest ad?
            Answer: That means the seller's most recently created listing by creation date — not their last purchase order and not the last order on their ads.
            The assistant calls get_my_last_ad and reports name, code, status, price/quantity, and created date from live data.

            Question: What is the first ad I posted / my oldest listing?
            Answer: That means the earliest created listing. The assistant calls get_my_first_ad.
            Do not confuse "last ad" with "last order". If ambiguous, ask whether they mean a listing they published or an order.
            """);

        Add(chunks, "ad-statuses", "معاني حالات الإعلان", "ar", ["supplier", "company_customer", "shipping", "public"],
            """
            حالات الإعلان ومعناها:
            تحت المعالجة / قيد المراجعة (Under review): الإعلان مرسل للمراجعة ولم يُعتمد بعد، ولا يظهر للجمهور.
            نشط (Active): الإعلان معتمد ومنشور ويظهر للمستخدمين ويمكن الشراء منه.
            متوقف (Paused): أوقفت عرض الإعلان مؤقتاً فلا يظهر للجمهور، ويمكنك إعادة تفعيله في أي وقت.
            مرفوض (Rejected): رفضت المراجعة الإعلان، وعادة يكون هناك سبب أو ملاحظة توضح المطلوب تعديله.
            نفد المخزون: الكمية وصلت إلى صفر فلا يمكن الشراء حتى تحدّث الكمية.
            لا يمكن إيقاف أو تفعيل إعلان قبل اعتماده من المراجعة.
            """);
        Add(chunks, "ad-statuses", "Listing status meanings", "en", ["supplier", "company_customer", "shipping", "public"],
            """
            Listing statuses and what they mean:
            Under review: the listing was submitted for review and is not approved yet, so it is not publicly visible.
            Active: the listing is approved and published, visible to users and available for purchase.
            Paused: you temporarily stopped showing the listing, so it is hidden from the public and can be reactivated at any time.
            Rejected: review rejected the listing, usually with a reason or note explaining what must be corrected.
            Out of stock: the quantity reached zero, so it cannot be purchased until you update the quantity.
            A listing cannot be paused or activated before it has been approved by review.
            """);

        Add(chunks, "ad-edit", "تعديل الإعلان وإعادة المراجعة", "ar", ["supplier"],
            """
            يمكنك تعديل إعلانك من قسم إعلاناتي أو عبر مساعد الراس الذكي في الشات.
            تعديل السعر فقط لا يُخرج الإعلان من حالة الاعتماد ويبقى ظاهراً.
            أما التعديلات الجوهرية مثل الاسم أو الوصف أو الصور أو المواصفات أو النوع فتُعيد الإعلان إلى حالة تحت المعالجة حتى يعتمده الفريق مرة أخرى.
            أثناء إعادة المراجعة قد لا يظهر التعديل للجمهور حتى الموافقة.
            هذا الإجراء يحمي المشترين من تغيير محتوى الإعلان بعد اعتماده.
            في الشات: يمكن تنفيذ أكثر من تعديل في نفس الرسالة (أسعار، كميات، إيقاف، تفعيل، نفاد، حذف) عندما يطلب المستخدم ذلك صراحة، مثل «احذف كل الإعلانات ما عدا …» بعد تأكيد واحد واضح.
            """);
        Add(chunks, "ad-edit", "Editing a listing and re-review", "en", ["supplier"],
            """
            You can edit your listing from the My Ads section or via Alras Smart chat.
            A price-only change keeps the listing approved and visible.
            Substantive edits such as the name, description, images, specifications, or type send the listing back to under review until the team approves it again.
            While it is being re-reviewed, the edit may not be publicly visible until approval.
            This protects buyers from listing content being changed after approval.
            In chat: several edits can run in the same message (prices, quantities, pause, activate, sold-out, delete) when the user clearly asks, e.g. “delete all ads except …” after one clear confirmation.
            """);

        Add(chunks, "ad-pause", "إيقاف الإعلان وإعادة تفعيله", "ar", ["supplier"],
            """
            من قسم إعلاناتي يمكنك إيقاف إعلان نشط مؤقتاً فيتحول إلى حالة متوقف ويختفي من نتائج المستخدمين.
            يمكنك إعادة تفعيل الإعلان المتوقف في أي وقت ليعود نشطاً.
            لا يمكن إيقاف أو تفعيل إعلان لم يُعتمد بعد من المراجعة.
            الإيقاف مفيد عند نفاد البضاعة مؤقتاً أو عند مراجعة السعر قبل الاستمرار في البيع.
            """);
        Add(chunks, "ad-pause", "Pausing and reactivating a listing", "en", ["supplier"],
            """
            From My Ads you can temporarily pause an active listing; it becomes paused and disappears from user results.
            You can reactivate a paused listing at any time to make it active again.
            A listing that has not yet been approved by review cannot be paused or activated.
            Pausing is useful when stock is temporarily unavailable or while you revise pricing before continuing to sell.
            """);

        Add(chunks, "ad-rejected", "لماذا رُفض إعلاني", "ar", ["supplier", "company_customer", "shipping"],
            """
            أسباب شائعة لرفض الإعلان: صور غير واضحة أو مضللة أو لا تمثل المنتج، أو وجود رقم هاتف أو بريد أو اسم شركة داخل الصور أو الوصف، أو بيانات ناقصة في المواصفات أو الكمية أو السعر، أو منتج محظور أو مقلد، أو تصنيف المنتج في صنف غير مناسب.
            عند الرفض تظهر عادة ملاحظة توضح السبب والمطلوب تعديله.
            صحّح المشكلة ثم أعد إرسال الإعلان للمراجعة.
            إذا لم يكن السبب واضحاً تواصل مع الدعم عبر Live Chat.
            """);
        Add(chunks, "ad-rejected", "Why my listing was rejected", "en", ["supplier", "company_customer", "shipping"],
            """
            Common rejection reasons: unclear, misleading, or unrepresentative images; a phone number, email, or company name inside the images or description; missing data in specifications, quantity, or price; a prohibited or counterfeit product; or the product placed in the wrong category.
            A rejection usually comes with a note explaining the reason and what must be fixed.
            Correct the issue and resubmit the listing for review.
            If the reason is unclear, contact support via Live Chat.
            """);

        Add(chunks, "ad-out-of-stock", "الإعلان نفد مخزونه", "ar", ["supplier"],
            """
            عندما تصل كمية الإعلان إلى صفر يصبح نافد المخزون ولا يستطيع المشترون الطلب منه.
            لإعادة البيع افتح الإعلان من قسم إعلاناتي وحدّث الكمية المتاحة.
            يمكنك تصفية إعلاناتك حسب حالة نفد المخزون لمعرفة ما يحتاج تحديثاً بسرعة.
            حافظ على تحديث الكميات باستمرار لتفادي إلغاء الطلبات بعد استلامها.
            """);
        Add(chunks, "ad-out-of-stock", "A listing that is out of stock", "en", ["supplier"],
            """
            When a listing's quantity reaches zero it becomes out of stock and buyers cannot order it.
            To sell again, open the listing from My Ads and update the available quantity.
            You can filter your listings by out-of-stock status to quickly see what needs updating.
            Keep quantities current to avoid cancelling orders after they are placed.
            """);

        Add(chunks, "ad-review-time", "متى يظهر إعلاني بعد النشر", "ar", ["supplier", "company_customer", "shipping"],
            """
            بعد حفظ الإعلان يدخل حالة تحت المعالجة ويراجعه فريق الراس الذكي قبل النشر للجمهور.
            بعد الاعتماد يتحول إلى نشط ويظهر في القسم أو الصنف الذي اخترته.
            تأكد من اكتمال رفع الصور والفيديو، لأن الإعلان قد لا يُرسل للمراجعة قبل اكتمال الرفع.
            إذا طالت مدة المراجعة أكثر من المعتاد تواصل مع الدعم عبر Live Chat.
            """);
        Add(chunks, "ad-review-time", "When my listing goes live after publishing", "en", ["supplier", "company_customer", "shipping"],
            """
            After saving, the listing enters under review and the Al Ras Smart team checks it before public publication.
            Once approved it becomes active and appears in the section or category you chose.
            Make sure image and video uploads finished, because a listing may not be submitted for review until uploads complete.
            If review takes longer than usual, contact support via Live Chat.
            """);

        Add(chunks, "ai-tools-voice-actions", "تعديل سعر أو كمية الإعلان بالصوت، أرخص منتج، مبيعاتي، فويس شات للذكاء الاصطناعي", "ar", All,
            """
            يمكن للمساعد الذكي تنفيذ إجراءات مباشرة عبر أدوات (MCP-style tools) عندما تكون مسجلاً دخولك:
            1) تعديل سعر و/أو كمية إعلانك: اذكر اسم الإعلان أو ProductCode مع السعر أو الكمية الجديدة. إذا كان لديك أكثر من إعلان بنفس الاسم سيطلب منك المساعد ProductCode.
            2) البحث عن أرخص منتج معتمد في السوق باسم المنتج.
            3) معرفة عدد مبيعاتك كمورد: عدد الطلبات التي أنت مالك منتجها (ProductOwner / ToUserId) وحالتها تم الاستلام أو تم التسليم.
            الفويس مع المساعد: المساعد هو من يستمع ويعالج الكلام؛ يظهر النص مباشرة أثناء الحديث، وبعد الانتهاء يصحّح الأخطاء اللغوية/الإملائية الناتجة عن التعرف على الصوت ثم يعرض النص النهائي في حقل الكتابة لتختار إرسال أو إلغاء.
            شات المساعد يقبل حالياً النص والفويس فقط، ولا يدعم الصور أو الفيديو أو الملفات أو الموقع الآن، ومن المتوقع دعم الصور مستقبلاً. لإرسال صور/فيديو/ملفات/موقع استخدم Live Chat.
            """);
        Add(chunks, "ai-tools-voice-actions", "Update ad price quantity by voice, cheapest product, my sales, AI voice chat", "en", All,
            """
            The AI assistant can run live marketplace actions via tools when you are signed in:
            1) Update your own ad price and/or quantity by ad name or ProductCode. If several of your ads share the same name, the assistant asks for the ProductCode.
            2) Find the cheapest approved marketplace product by name.
            3) Report your seller sales count: orders where you are the product owner (ToUserId) and status is received/delivered.
            Voice with the assistant: the AI listens and processes speech; text appears live while you talk, then the AI corrects speech-recognition mistakes and puts the cleaned text in the field so you can send or cancel.
            The AI chat currently accepts text and voice only — not images, video, files, or location yet; image support is expected later. To send images/video/files/location use Live Chat.
            """);
    }

    // ---------------------------------------------------------------------
    // 13. Requests and offers
    // ---------------------------------------------------------------------

    private static void AddRequestsAndOffers(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "request-meaning", "ما هو إعلان Request", "ar", All,
            """
            إعلان Request هو إعلان يطلب فيه صاحبه بضاعة غير متوفرة لديه ويبحث عمن يوفرها.
            ينشره المورد أو عميل الشركة، ويظهر في قسم Requests.
            يتقدم الموردون الآخرون بعروضهم (offers) على هذا الطلب بأسعار وكميات.
            ثم يراجع صاحب الطلب العروض ويقبل الأنسب أو يرفض غيره.
            بالنسبة لعميل الشركة يعتبر Request عملية شراء، ولذلك هو النوع الوحيد المسموح له بإنشائه.
            العميل الفردي وشركة الشحن لا ينشئان إعلانات Request.
            """);
        Add(chunks, "request-meaning", "What a Request ad is", "en", All,
            """
            A Request ad is a listing where the owner asks for goods they do not have and looks for someone to supply them.
            It is published by suppliers or company customers and appears in the Requests section.
            Other suppliers submit offers on that request with their prices and quantities.
            The request owner then reviews the offers and accepts the most suitable one or rejects the others.
            For a company customer a Request is a purchasing action, which is why it is the only type they may create.
            Personal customers and shipping companies do not create Request ads.
            """);

        Add(chunks, "create-request-company", "كيف ينشئ عميل الشركة إعلان Request", "ar", ["company_customer"],
            """
            من البار السفلي اختر إنشاء طلب (Create Order)، أو انشر من شات الراس الذكي عبر create_request_ad.
            الحقول المطلوبة:
            اسم المنتج، المواصفات، هل السعر قابل للتفاوض،
            نوع التلبية: محلي أو إعادة تصدير (إلزامي)، عنوان التسليم من العناوين المحفوظة (إلزامي — إن لم يوجد عنوان أضفه من الملف الشخصي أولاً).
            اختياري: الكمية والوحدة، السعر المستهدف والعملة (USD أو AED) — إذا أدخل المستخدم سعراً مستهدفاً يُطلب أيضاً العملة والوحدة.
            تاريخ التسليم المطلوب (اختياري)، صور توضيحية (اختياري).
            بعد اكتمال الحقول انشر الطلب؛ وبعد المراجعة يظهر في قسم Requests ليتقدم الموردون بعروضهم.
            تابع العروض من صفحة الحساب واقبل العرض المناسب أو ارفضه.
            حسابك يستطيع إنشاء Request فقط ولا يستطيع إنشاء Booking أو Retail أو Category أو Offer بخصم.
            """);
        Add(chunks, "create-request-company", "How a company customer creates a Request ad", "en", ["company_customer"],
            """
            From the bottom bar choose Create Order, or publish in Alras Smart chat via create_request_ad.
            Required fields:
            product name, specifications, negotiable yes/no,
            fulfillment type: Local or Reexport (required), delivery address from saved addresses (required — add one in Profile first if empty).
            Optional: quantity and unit, target price and currency (USD or AED) — if the user provides a target price, also collect currency and unit.
            Required delivery date (optional), reference images (optional).
            When complete, publish; after review it appears in Requests so suppliers can offer.
            Follow offers from the Account page and accept or reject.
            Your account can create Requests only — not Booking, Retail, Category, or discounted Offer.
            """);

        Add(chunks, "create-request-supplier", "كيف ينشئ المورد إعلان Request", "ar", ["supplier"],
            """
            يستطيع المورد أيضاً نشر إعلان Request عندما يحتاج بضاعة غير متوفرة لديه.
            افتح إنشاء إعلان واختر نوع Request، أو انشر من الشات عبر create_request_ad.
            الحقول المطلوبة: اسم المنتج، المواصفات، قابل للتفاوض، محلي أو إعادة تصدير (إلزامي).
            اختياري: الكمية والوحدة، السعر المستهدف والعملة (إذا أُدخل سعر مستهدف يُطلب العملة والوحدة)، عنوان التسليم من العناوين المحفوظة، تاريخ التسليم، صور.
            بعد المراجعة يظهر الطلب في قسم Requests ويتقدم الآخرون بعروضهم عليه.
            تابع العروض من صفحة الحساب واقبل الأنسب.
            """);
        Add(chunks, "create-request-supplier", "How a supplier creates a Request ad", "en", ["supplier"],
            """
            A supplier can also publish a Request ad when they need goods they do not stock.
            Open Create Ad and choose Request, or publish in chat via create_request_ad.
            Required fields: product name, specifications, negotiable, Local or Reexport (required).
            Optional: quantity and unit, target price and currency (if target price is provided, also collect currency and unit), delivery address from saved addresses, delivery date, images.
            After review the request appears in Requests and others submit offers.
            Follow offers from the Account page and accept the most suitable one.
            """);

        Add(chunks, "submit-offer", "كيف أقدم عرضاً على إعلان Request", "ar", ["supplier", "company_customer"],
            """
            افتح قسم Requests وتصفح الطلبات المنشورة، أو ابحث عن البضاعة التي توفرها.
            افتح الطلب المناسب واقرأ المواصفات والكمية المطلوبة بدقة.
            قدّم عرضك بالسعر والكمية التي تستطيع توفيرها، وأضف الصور أو المستندات الداعمة إن طُلبت.
            بعد الإرسال ينتقل عرضك إلى حالة قيد الانتظار (Pending) حتى يراجعه صاحب الطلب.
            تابع حالة عرضك من قسم عروضي (My Offers) داخل صفحة الحساب.
            """);
        Add(chunks, "submit-offer", "How to submit an offer on a Request ad", "en", ["supplier", "company_customer"],
            """
            Open the Requests section and browse published requests, or search for goods you can supply.
            Open the relevant request and read the specifications and required quantity carefully.
            Submit your offer with the price and quantity you can provide, attaching supporting images or documents if requested.
            After submission your offer moves to Pending until the request owner reviews it.
            Follow your offer's status in the My Offers section inside the Account page.
            """);

        Add(chunks, "my-offers", "قسم عروضي وحالات العرض", "ar", ["supplier", "company_customer"],
            """
            قسم عروضي (My Offers) داخل صفحة الحساب يتيح لك تتبع كل العروض التي قدمتها على إعلانات Request الخاصة بشركات أخرى.
            حالات العرض ثلاث:
            قيد الانتظار (Pending): أرسلت العرض ولم يتخذ صاحب الطلب قراراً بعد.
            مقبول (Accepted): وافق المعلن على عرضك وتبدأ خطوات التنفيذ.
            مرفوض (Rejected): رفض المعلن العرض، ويمكنك التقدم بعروض على طلبات أخرى.
            تصلك إشعارات عند تغير حالة عرضك.
            """);
        Add(chunks, "my-offers", "The My Offers section and offer statuses", "en", ["supplier", "company_customer"],
            """
            The My Offers section inside the Account page lets you track every offer you submitted on other companies' Request ads.
            There are three offer statuses:
            Pending: you submitted the offer and the request owner has not decided yet.
            Accepted: the advertiser approved your offer and fulfilment steps begin.
            Rejected: the advertiser declined the offer, and you can bid on other requests.
            You receive notifications when your offer's status changes.
            """);

        Add(chunks, "manage-offers-received", "إدارة العروض الواردة على طلبي", "ar", ["supplier", "company_customer"],
            """
            إذا نشرت إعلان Request فستصلك عروض من الموردين.
            افتح صفحة الحساب وادخل على إعلان الطلب لعرض العروض المقدمة عليه.
            قارن بين العروض من حيث السعر والكمية والمواصفات وسمعة المورد.
            اقبل العرض الأنسب أو ارفض العروض غير المناسبة، ويصل إشعار بذلك لمقدم العرض.
            بعد القبول تنتقل الصفقة إلى خطوات التنفيذ بالتنسيق مع فريق الراس الذكي.
            """);
        Add(chunks, "manage-offers-received", "Managing offers received on my request", "en", ["supplier", "company_customer"],
            """
            If you published a Request ad, suppliers will send you offers.
            Open the Account page and enter the request listing to view the offers submitted on it.
            Compare offers by price, quantity, specifications, and supplier standing.
            Accept the most suitable offer or reject unsuitable ones; the bidder is notified either way.
            After acceptance the deal moves to fulfilment steps in coordination with the Al Ras Smart team.
            """);
    }

    // ---------------------------------------------------------------------
    // 14. Shipping company
    // ---------------------------------------------------------------------

    private static void AddShippingCompany(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "shipping-create-ad", "كيف تضيف شركة الشحن إعلان شحن", "ar", ["shipping"],
            """
            من الصفحة الرئيسية اختر إضافة إعلان شحن (Add shipping ad).
            حدد ميناء وبلد المغادرة (من)، وميناء وبلد الوصول (إلى).
            أدخل مدة الرحلة بعدد الأيام.
            أدخل سعر حاوية 20 قدم (20ft) وسعر حاوية 40 قدم (40ft).
            احفظ الإعلان لينشر بعد المراجعة ويظهر ضمن قسم الشحن للمستخدمين.
            شركة الشحن لا تنشئ أنواع إعلانات أخرى مثل Booking أو Retail أو Request.
            """);
        Add(chunks, "shipping-create-ad", "How a shipping company adds a shipping ad", "en", ["shipping"],
            """
            From Home choose Add shipping ad.
            Set the departure port and country (from) and the arrival port and country (to).
            Enter the transit time in days.
            Enter the 20ft container price and the 40ft container price.
            Save the ad so it is published after review and appears in the Shipping section for users.
            A shipping company does not create other ad types such as Booking, Retail, or Request.
            """);

        Add(chunks, "shipping-manage-ads", "إدارة إعلانات الشحن", "ar", ["shipping"],
            """
            من الصفحة الرئيسية اختر إدارة إعلاناتك (Manage your ads) لعرض كل إعلانات الشحن التي نشرتها.
            من هناك يمكنك تعديل بيانات الإعلان مثل الأسعار أو مدة الرحلة، أو إيقافه أو حذفه.
            عدد إعلاناتك يظهر أيضاً داخل الملف الشخصي.
            التعديلات الجوهرية قد تحتاج مراجعة قبل ظهورها للمستخدمين.
            """);
        Add(chunks, "shipping-manage-ads", "Managing shipping ads", "en", ["shipping"],
            """
            From Home choose Manage your ads to see every shipping ad you published.
            From there you can edit the ad's data such as prices or transit time, pause it, or delete it.
            Your ad count is also shown inside Profile.
            Substantive edits may need review before they appear to users.
            """);

        Add(chunks, "shipping-profile", "الملف الشخصي لشركة الشحن", "ar", ["shipping"],
            """
            الملف الشخصي لشركة الشحن يحتوي على الدعم الفني، وتعديل المعلومات الشخصية وبيانات الشركة، واختيار اللغة، وعدد الإعلانات المنشورة.
            محتويات الملف الشخصي لشركة الشحن أبسط من باقي الحسابات، فلا توجد عناوين محفوظة ولا إعلانات محفوظة ولا صفحة طلبات.
            للتواصل مع فريق الدعم استخدم خيار الدعم داخل الملف الشخصي.
            """);
        Add(chunks, "shipping-profile", "The shipping company Profile page", "en", ["shipping"],
            """
            A shipping company's Profile contains support, editing of personal and company information, language selection, and the number of published ads.
            This Profile is simpler than other accounts: there are no saved addresses, no saved listings, and no orders page.
            To reach the support team, use the support option inside Profile.
            """);
    }

    // ---------------------------------------------------------------------
    // 16. Support and the assistant itself
    // ---------------------------------------------------------------------

    private static void AddSupport(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "live-chat", "المحادثة المباشرة مع الدعم Live Chat", "ar", SignedIn,
            """
            Live Chat هي محادثة مباشرة مع أحد موظفي الدعم البشري في الراس الذكي.
            تجدها في صفحة الملف الشخصي أسفل زر تعديل الملف الشخصي.
            بمجرد إرسال أول رسالة تُفتح جلسة بينك وبين أحد موظفي الراس الذكي ويرد عليك.
            استخدم Live Chat للمشكلات التي تحتاج تدخلاً بشرياً: مشكلة في طلب معين، أو طلب استرجاع، أو استفسار عن رفض إعلان أو حساب.
            عند التواصل اذكر رقم الطلب أو اسم الإعلان لتسريع المساعدة.
            في Live Chat / شات الدعم الفني يمكنك إرسال: رسائل نصية، ورسائل صوتية (فويس)، وصور، وفيديوهات، وملفات/مستندات، وموقعك الجغرافي.
            """);
        Add(chunks, "live-chat", "Live Chat with human support", "en", SignedIn,
            """
            Live Chat is a direct conversation with a human Al Ras Smart support agent.
            You find it on the Profile page below the Edit profile button.
            Sending the first message opens a session between you and an Al Ras Smart agent who replies to you.
            Use Live Chat for anything needing human action: a problem with a specific order, a return request, or a question about a rejected listing or account.
            Mention the order number or listing name to speed up the help you get.
            In Live Chat / support chat you can send: text messages, voice messages, images, videos, files/documents, and your location.
            """);

        Add(chunks, "live-chat-media", "هل أقدر أرسل صوت أو صور أو فيديو أو ملفات أو موقع في شات الدعم Live Chat", "ar", All,
            """
            سؤال: هل يمكنني إرسال رسائل صوت أو صور وفيديوهات أو فايلات أو موقع لشات الدعم الفني أو Live Chat؟
            الإجابة: نعم. في شات الدعم الفني (Live Chat) يمكنك إرسال رسائل نصية، ورسائل صوتية (فويس)، وصور، وفيديوهات، وملفات/مستندات، وموقعك الجغرافي.
            أما شات المساعد الذكي (AI Assistant) فهو مختلف: يقبل حالياً الرسائل النصية والفويس فقط، ولا يدعم رفع الصور أو الفيديو أو الملفات أو الموقع الآن، ومن المتوقع إضافة الصور لاحقاً.
            استخدم Live Chat عندما تحتاج إرفاق صورة مشكلة أو فيديو أو ملف أو إرسال موقعك لموظف الدعم البشري.
            """);
        Add(chunks, "live-chat-media", "Can I send voice images videos files or location in Live Chat support", "en", All,
            """
            Question: Can I send voice messages, images, videos, files, or a location to technical support chat or Live Chat?
            Answer: Yes. In Live Chat / support chat you can send text, voice messages, images, videos, files/documents, and your location.
            The AI Assistant chat is different: it currently accepts text and voice only, and does not support images, video, files, or location yet — image support is expected in the future.
            Use Live Chat when you need to attach a problem photo, video, file, or share your location with a human support agent.
            """);

        Add(chunks, "help-support", "صفحة المساعدة والدعم", "ar", SignedIn,
            """
            زر المساعدة والدعم (Help and support) في الملف الشخصي يفتح صفحة تحتوي على معلومات ساعات العمل.
            وتحتوي على زر للاتصال بالشركة مباشرة، وزر لمراسلة الدعم، وزر لإرسال بريد إلكتروني.
            كما تحتوي على قسم الأسئلة الشائعة الذي يجيب عن أكثر الاستفسارات تكراراً.
            إذا لم تجد إجابتك في الأسئلة الشائعة استخدم Live Chat للتواصل المباشر.
            """);
        Add(chunks, "help-support", "The Help and Support page", "en", SignedIn,
            """
            The Help and support button in Profile opens a page with working hours information.
            It includes a button to call the company directly, a button to message support, and a button to send an email.
            It also contains a frequently asked questions section covering the most common enquiries.
            If your answer is not in the FAQ, use Live Chat for direct contact.
            """);

        Add(chunks, "assistant", "سياسة مساعد الذكاء الاصطناعي", "ar", All,
            """
            الراس الذكي (Alras Smart) يجيب عن أسئلة الراس الذكي فقط، وفق نوع حسابك وصلاحياته.
            لا ينفذ عمليات نيابة عنك مثل إلغاء طلب أو الموافقة على استرجاع أو تحويل أموال، لكنه يستطيع عبر أدواته تحديث سعر/كمية إعلاناتك، وإيجاد أرخص منتج، وعرض عدد مبيعاتك.
            هو مختلف عن Live Chat: المساعد يشرح المنصة وسياساتها وينفّذ أدوات محددة، أما Live Chat فهو موظف دعم بشري يتدخل في الحالات الفردية ويمكنه استقبال صوت وصور وفيديو وملفات وموقع.
            شات المساعد يقبل حالياً الرسائل النصية والفويس فقط (والمساعد يصحّح نص الفويس بعد الاستماع)، ولا يدعم الصور أو الفيديو أو الملفات أو الموقع الآن، ومن المتوقع قبول الصور مستقبلاً.
            يرد المساعد بلغة رسالتك، فإذا كتبت بالعربية يرد بالعربية وإذا كتبت بالإنجليزية يرد بالإنجليزية، وإذا كتبت بلغة أخرى يفهمها داخلياً ويرد بلغة مدعومة.
            الأسئلة خارج نطاق المنصة تُرفض بلطف مع اقتراح مواضيع يمكنه المساعدة فيها.
            عند السؤال عن إنشاء إعلان، يطبّق المساعد صلاحيات نوع حسابك الحالي فقط — لا يطبّق قيود أنواع حسابات أخرى.
            المورد يستطيع إنشاء Booking وغيره مباشرة من الشات عبر create_booking_ad وغيرها؛ لا يرفض المورد طلب Booking.
            عميل الشركة يستطيع Request فقط عبر create_request_ad.
            القيود تخص إنشاء الإعلانات فقط، ولا تمنع تتبع الطلبات أو البحث أو الدعم.
            """);
        Add(chunks, "assistant", "AI Assistant policy", "en", All,
            """
            Alras Smart (الراس الذكي) answers questions about Al Ras Smart only, according to your account type and its permissions.
            It does not cancel orders, approve returns, or move money for you, but through its tools it can update your ad price/quantity, find the cheapest product, and report your sales count.
            It is different from Live Chat: the assistant explains the platform and runs specific tools, while Live Chat is a human support agent who handles individual cases and can receive voice, images, video, files, and location.
            The AI chat currently accepts text and voice only (and the AI corrects the voice transcript after listening); images, video, files, and location are not supported yet — image support is expected in the future.
            The assistant replies in the language of your message: Arabic for Arabic, English for English, and for other languages it understands internally then replies in a supported language.
            Out-of-scope questions are declined politely with suggested platform topics.
            When asked to create an ad, the assistant applies ONLY your current account type's permissions — never rules meant for other account types.
            Suppliers can create Booking and other types directly in chat via create_booking_ad and related tools; a supplier's Booking request is never refused.
            Company customers can create Request only via create_request_ad.
            Restrictions cover only creating ads, and never block order tracking, search, or support.
            """);
    }

    // ---------------------------------------------------------------------
    // 17. Frequently asked details
    // ---------------------------------------------------------------------

    private static void AddCommonQuestions(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "incoterms", "معنى FOB وCNF وCIF في إعلانات Booking", "ar", All,
            """
            أنواع السعر في إعلان Booking تحدد ما الذي يشمله السعر المعروض.
            FOB (تسليم ظهر السفينة): السعر يشمل قيمة البضاعة وتكاليف إيصالها وتحميلها على السفينة، ولا يشمل أجرة الشحن البحري ولا التأمين، ويتحملهما المشتري. عند إنشاء إعلان FOB لا تُطلب بلد الوجهة ولا الموانئ.
            CNF أو CFR (التكلفة وأجرة الشحن): السعر يشمل قيمة البضاعة وأجرة الشحن البحري حتى ميناء الوصول، ولا يشمل التأمين.
            CIF (التكلفة والتأمين وأجرة الشحن): السعر يشمل قيمة البضاعة وأجرة الشحن البحري والتأمين حتى ميناء الوصول.
            المورد هو من يختار نوع السعر عند إنشاء إعلان Booking، ويظهر للمشتري في تفاصيل الإعلان.
            راجع نوع السعر جيداً قبل الطلب لأنه يغيّر التكلفة النهائية عليك.
            """);
        Add(chunks, "incoterms", "What FOB, CNF, and CIF mean on Booking ads", "en", All,
            """
            The price type on a Booking ad defines what the quoted price covers.
            FOB (Free On Board): the price covers the goods and the cost of delivering and loading them onto the vessel; sea freight and insurance are not included and are paid by the buyer. When creating a FOB ad, destination country and ports are not collected.
            CNF or CFR (Cost and Freight): the price covers the goods and the sea freight to the arrival port, but not insurance.
            CIF (Cost, Insurance and Freight): the price covers the goods, the sea freight, and the insurance up to the arrival port.
            The supplier chooses the price type when creating the Booking ad, and it is shown to buyers in the listing details.
            Check the price type carefully before ordering because it changes your final cost.
            """);

        Add(chunks, "booking-ports", "الموانئ وبلدان الشحن في إعلان Booking", "ar", All,
            """
            كل إعلان Booking يحدد الدولة المصدرة وبلد الوجهة.
            إذا كان نوع السعر CNF أو CIF يظهر أيضاً ميناء التحميل وميناء الوصول.
            أما إذا كان نوع السعر FOB فلا تُطلب بلد الوجهة ولا الموانئ ولا تظهر في نموذج الإضافة.
            الدولة المصدرة توضح مصدر البضاعة، وهي مهمة لبعض المشترين لأسباب تنظيمية أو تفضيلية.
            ميناء التحميل وميناء الوصول (عند CNF/CIF) يحددان مسار الشحنة ويؤثران على المدة والتكلفة.
            إذا كنت تبحث عن شحن من ميناء إلى ميناء بشكل منفصل عن البضاعة نفسها، فهذه خدمة تعرضها شركات الشحن في قسم Shipping.
            """);
        Add(chunks, "booking-ports", "Ports and countries on a Booking ad", "en", All,
            """
            Every Booking ad specifies the origin/exporting country and the destination country.
            When the price type is CNF or CIF, the loading port and arrival port are also required.
            When the price type is FOB, destination country and ports are not required and are hidden on the create-ad form.
            The origin country identifies where the goods come from, which matters to some buyers for regulatory or preference reasons.
            The loading and arrival ports (for CNF/CIF) define the route and affect both transit time and cost.
            If you are looking for port-to-port freight separately from the goods themselves, that service is published by shipping companies in the Shipping section.
            """);

        Add(chunks, "packaging", "تفاصيل التعبئة في الإعلان", "ar", All,
            """
            التعبئة (Packaging) حقل اختياري في كل أنواع الإعلانات، يوضح فيه المعلن طريقة تغليف المنتج.
            مثال: عدد العبوات داخل الكرتونة، أو وزن الكيس، أو نوع التغليف المستخدم.
            هذه المعلومة مهمة لمشتري الجملة لأنها تؤثر على التخزين والنقل وحساب الكميات.
            إذا لم يذكر المعلن تفاصيل التعبئة ولزمتك المعلومة، تواصل مع الدعم عبر Live Chat للاستفسار.
            المورد مسؤول عن مطابقة التغليف الفعلي لما ذكره في الإعلان.
            """);
        Add(chunks, "packaging", "Packaging details on a listing", "en", All,
            """
            Packaging is an optional field on every ad type where the advertiser describes how the product is packed.
            Examples: how many units are inside a carton, the weight of a bag, or the type of wrapping used.
            This matters to wholesale buyers because it affects storage, transport, and quantity calculations.
            If the advertiser did not provide packaging details and you need them, ask through Live Chat.
            The supplier is responsible for the actual packaging matching what the listing states.
            """);

        Add(chunks, "offer-expiry", "مدة الخصم في إعلانات Offers", "ar", All,
            """
            إعلان Offer يحمل نسبة خصم ومدة محددة بالأيام يحددها المعلن عند الإنشاء.
            خلال هذه المدة يظهر الإعلان في قسم Offers بالسعر بعد الخصم.
            بعد انتهاء مدة الخصم قد يتوقف عرض الإعلان ضمن العروض أو يعود إلى سعره الأساسي حسب ما يحدده المعلن.
            إذا كنت مهتماً بعرض معين فسارع بالطلب قبل انتهاء مدته.
            المورد يستطيع إنشاء إعلانات Offer، أما باقي أنواع الحسابات فلا.
            """);
        Add(chunks, "offer-expiry", "Discount duration on Offer ads", "en", All,
            """
            An Offer ad carries a discount percentage and a duration in days set by the advertiser at creation.
            During that period the listing appears in the Offers section at the discounted price.
            After the discount period ends, the listing may stop appearing among offers or return to its base price depending on what the advertiser sets.
            If you are interested in a particular offer, order before its period ends.
            Suppliers can create Offer ads; other account types cannot.
            """);

        Add(chunks, "retail-vs-wholesale", "الفرق بين الشراء بالتجزئة والشراء بالجملة", "ar", All,
            """
            الشراء بالتجزئة (Retail) يكون بكميات صغيرة داخل دولة الإمارات، بالدرهم AED، ومتاح للعميل الفردي، ويمكن الدفع فيه بالبطاقة إلكترونياً أو عند الاستلام، ويظهر في قسم Retail.
            الشراء بالجملة يكون بكميات كبيرة من منتجات الأصناف أو عبر Booking أو Requests، ويخص الموردين وعملاء الشركات، وتتم معالجته ومتابعته بواسطة فريق الراس الذكي وليس بالدفع الذاتي.
            العميل الفردي يرى منتجات التجزئة فقط في صفحته الرئيسية، بينما يرى عميل الشركة والمورد منتجات الأصناف وأنواع الإعلانات.
            سياسة الاسترجاع خلال 24 ساعة عمل من الاستلام تطبق على الحالات المؤهلة، ورد الأموال خلال يوم عمل بعد موافقة الدعم.
            """);
        Add(chunks, "retail-vs-wholesale", "The difference between retail and wholesale buying", "en", All,
            """
            Retail buying happens in small quantities inside the UAE, priced in AED, is available to personal customers, supports card payment or cash on delivery, and appears in the Retail section.
            Wholesale buying happens in large quantities from category products or through Booking and Requests, concerns suppliers and company customers, and is processed and followed up by the Al Ras Smart team rather than self-service payment.
            A personal customer sees retail products only on home, while company customers and suppliers see category products and ad types.
            The returns policy of 24 business hours from receipt applies to eligible cases, with refunds within one business day of support approval.
            """);

        Add(chunks, "no-direct-contact", "لماذا لا تظهر بيانات تواصل المورد", "ar", All,
            """
            المنصة تمنع نشر أرقام الهاتف أو البريد الإلكتروني أو اسم الشركة أو أي وسيلة تواصل داخل صور الإعلان أو وصفه.
            سبب المنع هو حماية الطرفين: التعامل داخل المنصة يضمن تسجيل الطلب وتتبع حالته وتنظيم التحصيل وإمكانية الاسترجاع والدعم عند وجود مشكلة.
            التعامل خارج المنصة يفقدك هذه الحماية ولا تتحمل المنصة مسؤوليته.
            إذا احتجت توضيحاً عن منتج أو مورد، استخدم Live Chat وسيساعدك فريق الدعم.
            إذا رأيت إعلاناً يحتوي على بيانات تواصل، أبلغ الدعم عنه.
            """);
        Add(chunks, "no-direct-contact", "Why supplier contact details are not shown", "en", All,
            """
            The platform prohibits publishing phone numbers, emails, company names, or any contact channel inside listing images or descriptions.
            The reason is protection for both sides: dealing inside the platform means the order is recorded and tracked, collection is organised, and returns and support remain available if something goes wrong.
            Dealing off-platform removes that protection and the platform takes no responsibility for it.
            If you need clarification about a product or supplier, use Live Chat and the support team will help.
            If you see a listing containing contact details, report it to support.
            """);

        Add(chunks, "report-listing", "كيف أبلغ عن إعلان أو مشكلة", "ar", SignedIn,
            """
            إذا وجدت إعلاناً مخالفاً، مثل منتج محظور أو مقلد، أو صور مضللة، أو بيانات تواصل داخل الصور، أو سعر أو وصف غير صحيح، فأبلغ فريق الدعم.
            استخدم Live Chat من الملف الشخصي واذكر اسم الإعلان أو رابطه ووصف المشكلة، وأرفق صورة للشاشة إن أمكن.
            كذلك إذا واجهت مشكلة مع طلب أو مورد، أبلغ الدعم في أسرع وقت مع رقم الطلب.
            الإبلاغ المبكر يساعد على حل المشكلة والحفاظ على جودة المنصة.
            """);
        Add(chunks, "report-listing", "How to report a listing or a problem", "en", SignedIn,
            """
            If you find a non-compliant listing, such as a prohibited or counterfeit product, misleading images, contact details inside images, or an incorrect price or description, report it to the support team.
            Use Live Chat from Profile, mention the listing name or link, describe the problem, and attach a screenshot if possible.
            Likewise, if you have a problem with an order or a supplier, report it quickly with the order number.
            Early reporting helps resolve the issue and keeps the platform's quality high.
            """);

        Add(chunks, "working-hours", "ساعات العمل وطرق التواصل", "ar", All,
            """
            معلومات ساعات العمل الرسمية موجودة داخل صفحة المساعدة والدعم (Help and support) في الملف الشخصي.
            من نفس الصفحة تجد زر الاتصال المباشر بالشركة، وزر مراسلة الدعم، وزر إرسال بريد إلكتروني.
            Live Chat يوفر محادثة مباشرة مع موظف دعم بشري خلال ساعات العمل.
            بعض الإجراءات مثل مراجعة الإعلانات وطلبات الاسترجاع تُحسب مدتها بأيام أو ساعات العمل وليس الأيام التقويمية.
            """);
        Add(chunks, "working-hours", "Working hours and contact channels", "en", All,
            """
            Official working hours are shown inside the Help and support page in Profile.
            The same page has a button to call the company directly, a button to message support, and a button to send an email.
            Live Chat provides a direct conversation with a human support agent during working hours.
            Some processes such as listing review and return requests are measured in business days or business hours rather than calendar days.
            """);

        Add(chunks, "banners", "البانرات في الصفحة الرئيسية", "ar", ["supplier", "company_customer", "guest", "public"],
            """
            البانرات هي لافتات إعلانية تظهر في أعلى الصفحة الرئيسية أسفل شريط البحث.
            تعرض عروضاً أو أقساماً أو منتجات مميزة، ويمكن الضغط عليها للانتقال إلى المحتوى المرتبط بها.
            تظهر البانرات للمورد وعميل الشركة والزائر.
            الصفحة الرئيسية للعميل الفردي مبسطة وتركز على منتجات التجزئة.
            """);
        Add(chunks, "banners", "Home page banners", "en", ["supplier", "company_customer", "guest", "public"],
            """
            Banners are promotional panels shown at the top of the home page below the search bar.
            They highlight offers, sections, or featured products, and tapping one opens the related content.
            Banners appear for suppliers, company customers, and guests.
            The personal customer home page is simplified and focuses on retail products.
            """);

        Add(chunks, "seller-approval", "موافقة البائع على الطلب", "ar", ["supplier", "company_customer", "public"],
            """
            في الطلبات غير التجزئة قد يمر الطلب بمرحلة بانتظار موافقة البائع (Awaiting seller approval).
            معناها أن الطلب حصل على موافقة مبدئية من إدارة المنصة، ويُنتظر أن يقبله البائع أو يرفضه.
            إذا قبل البائع ينتقل الطلب إلى مراحل التنفيذ والشحن، وإذا رفض يُلغى الطلب ويُبلَّغ المشتري.
            هذه المرحلة لا تنطبق على طلبات Retail.
            يمكنك متابعة هذه الحالة من صفحة طلباتي.
            """);
        Add(chunks, "seller-approval", "Seller approval on an order", "en", ["supplier", "company_customer", "public"],
            """
            Non-retail orders may pass through an Awaiting seller approval stage.
            It means the order received initial approval from platform administration and is waiting for the seller to accept or reject it.
            If the seller accepts, the order moves into fulfilment and shipping; if they reject, the order is cancelled and the buyer is informed.
            This stage does not apply to Retail orders.
            You can follow this status from the My Orders page.
            """);

        Add(chunks, "account-security", "أمان الحساب", "ar", SignedIn,
            """
            استخدم كلمة سر قوية لا تستخدمها في مواقع أخرى، وغيّرها فوراً إذا شككت في تسريبها.
            لا تشارك رمز التحقق OTP مع أي شخص إطلاقاً، حتى لو ادعى أنه من الدعم؛ فريق الراس الذكي لا يطلب منك رمز OTP ولا كلمة السر.
            فعّل الدخول بالبصمة أو بصمة الوجه لحماية إضافية على جهازك.
            سجّل الخروج من الأجهزة التي لا تستخدمها.
            إذا لاحظت نشاطاً غير مألوف على حسابك تواصل مع الدعم فوراً عبر Live Chat.
            """);
        Add(chunks, "account-security", "Account security", "en", SignedIn,
            """
            Use a strong password that you do not reuse elsewhere, and change it immediately if you suspect it was exposed.
            Never share your OTP code with anyone, even someone claiming to be support; the Al Ras Smart team never asks for your OTP or password.
            Enable fingerprint or face unlock for extra protection on your device.
            Sign out from devices you no longer use.
            If you notice unusual activity on your account, contact support immediately via Live Chat.
            """);

        Add(chunks, "account-switch", "تغيير نوع الحساب أو امتلاك أكثر من حساب", "ar", SignedIn,
            """
            نوع الحساب يُحدد عند التسجيل ويحدد ما تراه وما تستطيع فعله في التطبيق.
            لا يمكنك تحويل حسابك من نوع إلى آخر بنفسك من داخل التطبيق.
            إذا كنت مسجلاً كعميل فردي وتريد العمل كمورد، فهذا يتطلب حساب مورد ببيانات الشركة والرخصة التجارية وصور الشركة، ويمر على مراجعة واعتماد.
            للاستفسار عن تغيير نوع حسابك أو ربط حساباتك تواصل مع الدعم عبر Live Chat.
            """);
        Add(chunks, "account-switch", "Changing account type or having more than one account", "en", SignedIn,
            """
            Your account type is set at registration and determines what you see and what you can do in the app.
            You cannot convert your account from one type to another by yourself inside the app.
            If you registered as a personal customer and want to operate as a supplier, that requires a supplier account with company details, a trade license, and company images, and it goes through review and approval.
            To ask about changing your account type or linking your accounts, contact support via Live Chat.
            """);

        Add(chunks, "app-technical", "متطلبات التطبيق والتحديثات", "ar", All,
            """
            حافظ على تحديث تطبيق الراس الذكي لآخر إصدار من متجر التطبيقات، لأن التحديثات تصلح المشكلات وتضيف الميزات.
            بعض الميزات مثل تسجيل الدخول بأبل أو جوجل والبصمة تعتمد على نوع الجهاز ودعمه لها.
            البحث بالصور يحتاج إذن الوصول للكاميرا أو معرض الصور.
            الإشعارات تحتاج السماح بها في إعدادات الجهاز.
            إذا واجهت بطئاً أو خطأً متكرراً، جرّب إغلاق التطبيق وإعادة فتحه والتأكد من الاتصال بالإنترنت، ثم تواصل مع الدعم إن استمرت المشكلة.
            """);
        Add(chunks, "app-technical", "App requirements and updates", "en", All,
            """
            Keep the Al Ras Smart app updated to the latest version from your app store, since updates fix issues and add features.
            Some features such as Apple or Google sign-in and biometric unlock depend on your device supporting them.
            Image search needs permission to access the camera or photo gallery.
            Notifications need to be allowed in your device settings.
            If you experience slowness or repeated errors, close and reopen the app and check your internet connection, then contact support if the problem persists.
            """);

        Add(chunks, "guest-vs-registered", "لماذا أسجل حساباً بدل التصفح كزائر", "ar", ["guest", "public"],
            """
            الزائر يستطيع التصفح والبحث النصي والبحث بالصورة وفتح تفاصيل الإعلانات فقط.
            بتسجيل حساب تحصل على: إتمام الشراء، وصفحة طلباتي لتتبع حالة كل طلب، وحفظ الإعلانات المفضلة، وحفظ العناوين، والإشعارات، والتواصل مع الدعم عبر Live Chat، وإمكانية طلب الاسترجاع للحالات المؤهلة.
            العميل الفردي ينشئ حسابه في ثوانٍ عبر جوجل أو أبل دون أي مستندات.
            حسابات الشركات تحتاج بيانات إضافية ومراجعة قبل التفعيل.
            """);
        Add(chunks, "order-lifecycle", "ماذا يحدث بعد أن أضع الطلب", "ar", Buyers,
            """
            بعد تأكيد الطلب يُسجَّل في النظام وتصبح حالته تم الطلب (Ordered).
            ثم تتم مراجعته والموافقة عليه ليصبح تمت الموافقة (Approved).
            في الطلبات غير التجزئة قد يمر بمرحلة بانتظار موافقة البائع قبل التنفيذ.
            عند استلام قيمة الطلب لدى المنصة تصبح الحالة مدفوع.
            ثم يبدأ التجهيز والشحن فتصبح الحالة قيد الشحن.
            وعند وصول الطلب إليك واستلامه تصبح الحالة تم التسليم.
            بعد التسليم تبدأ مهلة 24 ساعة عمل للإبلاغ عن أي مشكلة تستوجب الاسترجاع.
            تستطيع متابعة كل هذه المراحل لحظة بلحظة من صفحة طلباتي وسجل حالة الطلب.
            """);
        Add(chunks, "order-lifecycle", "What happens after I place an order", "en", Buyers,
            """
            After you confirm an order it is recorded in the system with the status Ordered.
            It is then reviewed and approved, becoming Approved.
            Non-retail orders may pass through Awaiting seller approval before fulfilment.
            When the order value is received by the platform the status becomes Paid.
            Preparation and dispatch then begin and the status becomes Shipping.
            When the order reaches you and is received, the status becomes Delivered.
            After delivery the 24 business hours window starts for reporting any problem that justifies a return.
            You can follow every one of these stages in real time from My Orders and the order's status history.
            """);

        Add(chunks, "orders-vs-account", "الفرق بين صفحة طلباتي وصفحة الحساب", "ar", ["supplier", "company_customer", "public"],
            """
            صفحة طلباتي (My Orders) تخص عمليات الشراء والطلبات الواردة حسب نوع حسابك.
            المورد: تبويب الواردة للطلبات على إعلاناتك، وتبويب المشتريات لما اشتريته أنت.
            عميل الشركة: تبويب طلباتي (Requests) يعرض إعلانات Request المنشورة والعروض الواردة عليها، وتبويب المشتريات (Orders) لمشترياتك كمشتري.
            صفحة الحساب (Account) لعميل الشركة: إعلاناتي فقط (Request ads) — بدون قسم عروضي. المورد فقط لديه إعلاناتي وعروضي في الحساب.
            العميل الفردي لديه صفحة طلباتي فقط (مشتريات بدون تبويبات) لأنه لا ينشر إعلانات.
            إذا كنت تبحث عن حالة شراء Retail أو Booking فافتح تبويب المشتريات في طلباتي (أو طلباتي مباشرة للعميل الفردي).
            إذا كنت تبحث عن حالة إعلان Request أو عرض سعري فافتح الحساب أو تبويب طلباتي (Requests) لعميل الشركة.
            """);
        Add(chunks, "orders-vs-account", "The difference between My Orders and the Account page", "en", ["supplier", "company_customer", "public"],
            """
            My Orders covers purchases and incoming orders depending on your account type.
            Supplier: Incoming tab for orders on your ads, Purchases tab for orders you placed as a buyer.
            Company customer: Requests tab shows published Request ads and incoming offers on them; Orders (Purchases) tab for your buyer purchases.
            The Account page for a company customer is My Ads only (Request ads) — no My Offers section. Only suppliers have both My Ads and My Offers on Account.
            A personal customer has My Orders only (purchases, no tabs) because this account does not publish listings.
            If you need a Retail or Booking purchase status, open the Purchases tab in My Orders (or My Orders directly for personal customers).
            If you need a Request ad or price-offer status, open Account or the Requests tab in My Orders for company customers.
            """);

        Add(chunks, "supplier-incoming-orders", "كيف يتابع المورد الطلبات الواردة على إعلاناته", "ar", ["supplier"],
            """
            عندما يشتري عميل من أحد إعلاناتك يُنشأ طلب ويصلك إشعار به.
            تابع الطلبات الواردة من تبويب الواردة في صفحة طلباتي (My Orders)، وليس من صفحة الحساب.
            في الطلبات غير التجزئة قد يُطلب منك قبول الطلب أو رفضه في مرحلة بانتظار موافقة البائع؛ ستظهر شارة حمراء على أيقونة طلباتي بعدد الطلبات التي بانتظار موافقتك.
            في تطبيق الجوال قد ترى على الطلب الوارد نص "بانتظار موافقتك" بدلاً من النص الكامل للحالة.
            تُحدَّث قائمة الطلبات تلقائياً عند أي تغيير في الحالة.
            حافظ على تحديث الكميات في إعلاناتك حتى لا تصلك طلبات لبضاعة نفدت.
            عند وجود مشكلة في طلب وارد تواصل مع الدعم عبر Live Chat مع رقم الطلب.
            """);
        Add(chunks, "supplier-incoming-orders", "How a supplier follows incoming orders on their listings", "en", ["supplier"],
            """
            When a customer buys from one of your listings an order is created and you receive a notification.
            Follow incoming orders from the Incoming tab in My Orders, not from the Account page.
            For non-retail orders you may be asked to accept or reject the order during Awaiting seller approval; a red badge on the My Orders icon shows how many orders need your approval.
            On the mobile app you may see "Awaiting your approval" on an incoming order instead of the full status text.
            The order list refreshes automatically when any status changes.
            Keep your listing quantities updated so you do not receive orders for goods that are out of stock.
            If there is a problem with an incoming order, contact support via Live Chat with the order number.
            """);

        Add(chunks, "request-lifecycle", "دورة حياة إعلان Request", "ar", ["supplier", "company_customer", "public"],
            """
            بعد نشر إعلان Request واعتماده يظهر في قسم Requests ليراه الموردون.
            يتقدم الموردون بعروضهم، وتتابعها أنت من صفحة الحساب.
            عندما تقبل عرضاً تبدأ خطوات التنفيذ بالتنسيق مع فريق الراس الذكي، وتُرفض بقية العروض أو تبقى دون قبول.
            إذا اكتملت الكمية المطلوبة أو لم تعد بحاجة للبضاعة، لا يعود الطلب معروضاً للعروض الجديدة.
            إعلانات Request التي وصلت كميتها إلى صفر لا تظهر في نتائج التصفح والبحث.
            """);
        Add(chunks, "request-lifecycle", "The lifecycle of a Request ad", "en", ["supplier", "company_customer", "public"],
            """
            After a Request ad is published and approved it appears in the Requests section for suppliers to see.
            Suppliers submit their offers and you follow them from the Account page.
            When you accept an offer, fulfilment begins in coordination with the Al Ras Smart team, and the remaining offers are rejected or left unaccepted.
            Once the required quantity is met or you no longer need the goods, the request stops taking new offers.
            Request ads whose quantity has reached zero do not appear in browsing or search results.
            """);

        Add(chunks, "glossary", "مصطلحات المنصة", "ar", All,
            """
            المورد (Supplier): شركة تعرض وتبيع البضائع.
            العميل الفردي (Personal customer): مشترٍ فرد يشتري بالتجزئة.
            عميل الشركة (Company customer): شركة تشتري بالجملة وتنشر طلبات Request.
            شركة الشحن (Shipping company): تعرض خدمة شحن من ميناء إلى ميناء.
            الصنف (Category): تصنيف المنتجات، والمنتج الذي له CategoryId يظهر داخل صنفه.
            Retail: بيع بالتجزئة داخل الإمارات بالدرهم.
            Booking: شحنة دولية من ميناء إلى ميناء بالدولار.
            Offer: إما إعلان بخصم، أو عرض سعر تقدمه على إعلان Request.
            Request: إعلان طلب بضاعة غير متوفرة لدى صاحبه.
            Live Chat: محادثة مباشرة مع موظف دعم بشري.
            الراس الذكي (Alras Smart): مساعد ذكي يشرح المنصة وسياساتها وينفّذ أدوات محددة.
            """);
        Add(chunks, "glossary", "Platform glossary", "en", All,
            """
            Supplier: a company that lists and sells goods.
            Personal customer: an individual buyer purchasing at retail.
            Company customer: a company buying wholesale and publishing Request ads.
            Shipping company: publishes port-to-port freight services.
            Category: the product classification; a product with a CategoryId appears inside its category.
            Retail: retail selling inside the UAE priced in AED.
            Booking: an international port-to-port shipment priced in USD.
            Offer: either a discounted ad, or a quotation you submit on a Request ad.
            Request: an ad asking for goods the owner does not have.
            Live Chat: a direct conversation with a human support agent.
            Alras Smart (الراس الذكي): an AI agent that explains the platform and its policies and can run specific tools.
            """);

        Add(chunks, "assistant-scope", "ما الذي يستطيع المساعد الإجابة عنه", "ar", All,
            """
            يستطيع المساعد شرح: أنواع الحسابات وصلاحياتها، وكيفية التسجيل وتسجيل الدخول، والتنقل بين صفحات التطبيق، والبحث النصي والبحث بالصور، وأنواع الإعلانات وكيفية إنشائها لمن يملك الصلاحية، والشراء وطرق الدفع، وتتبع الطلبات ومعاني حالاتها، وسياسة الاسترجاع ورد الأموال، وإعلانات الشحن، وسياسات الشروط والخصوصية، وطرق التواصل مع الدعم.
            لا يستطيع المساعد: تنفيذ أي إجراء نيابة عنك، ولا فتح تفاصيل طلب بعينه، ولا الموافقة على استرجاع، ولا تحويل أموال، ولا تعديل حسابك أو إعلانك.
            لا يجيب عن أسئلة عامة خارج الراس الذكي مثل الطقس أو الأخبار أو الوقت.
            للحالات الفردية التي تحتاج تدخلاً بشرياً استخدم Live Chat من الملف الشخصي.
            """);
        Add(chunks, "assistant-scope", "What the assistant can answer", "en", All,
            """
            The assistant can explain: account types and their permissions, registration and sign-in, navigating the app's pages, text and image search, ad types and how to create them for accounts that are allowed, buying and payment methods, order tracking and status meanings, the returns and refunds policy, shipping ads, terms and privacy policies, and how to reach support.
            The assistant cannot: perform any action for you, open a specific order's details, approve a return, transfer money, or edit your account or listing.
            It does not answer general questions outside Al Ras Smart such as weather, news, or the time.
            For individual cases that need human intervention, use Live Chat from Profile.
            """);

        Add(chunks, "guest-vs-registered", "Why register instead of browsing as a guest", "en", ["guest", "public"],
            """
            A guest can only browse, use text and image search, and open listing details.
            Registering gives you: the ability to complete a purchase, a My Orders page to track each order's status, saved favourite listings, saved addresses, notifications, Live Chat with support, and the ability to request returns for eligible cases.
            A personal customer account is created in seconds with Google or Apple and needs no documents.
            Company accounts require additional details and review before activation.
            """);
    }

    // ---------------------------------------------------------------------
    // 18. Troubleshooting
    // ---------------------------------------------------------------------

    private static void AddTroubleshooting(ICollection<AiKnowledgeChunk> chunks)
    {
        Add(chunks, "trouble-missing-page", "لا أجد صفحة أو زراً في التطبيق", "ar", SignedIn,
            """
            الواجهة تختلف حسب نوع الحساب، ولذلك قد لا تظهر لك صفحة موجودة عند غيرك.
            زر إنشاء إعلان يظهر للمورد فقط، وإنشاء طلب (Create Order) لعميل الشركة فقط.
            صفحة الحساب (Account) للمورد وعميل الشركة.
            العميل الفردي لديه ثلاث صفحات فقط: الرئيسية وطلباتي والملف الشخصي.
            شركة الشحن لديها صفحتان فقط: الرئيسية والملف الشخصي.
            إذا كنت تتوقع ظهور صفحة تخص نوع حسابك ولا تراها، تأكد من اكتمال اعتماد حسابك ثم تواصل مع الدعم عبر Live Chat.
            """);
        Add(chunks, "trouble-missing-page", "I cannot find a page or button in the app", "en", SignedIn,
            """
            The interface differs by account type, so a page that exists for someone else may not appear for you.
            The Create Ad button is for suppliers only, and Create Order is for company customers only.
            The Account page is for suppliers and company customers.
            A personal customer has three pages only: Home, My Orders, and Profile.
            A shipping company has two pages only: Home and Profile.
            If you expect a page that belongs to your account type and cannot see it, confirm your account approval is complete and then contact support via Live Chat.
            """);

        Add(chunks, "trouble-cannot-create", "لماذا لا أستطيع إنشاء هذا النوع من الإعلانات", "ar", SignedIn,
            """
            إنشاء الإعلانات مقيد بنوع الحساب.
            إذا كنت عميلاً فردياً فلا يمكنك إنشاء أي إعلان، لأن حسابك للشراء فقط.
            إذا كنت عميل شركة فيمكنك إنشاء Request فقط، ولا يمكنك إنشاء Booking أو Retail أو Category أو Offer بخصم.
            إذا كنت شركة شحن فيمكنك إنشاء إعلان شحن فقط.
            المورد هو الحساب الوحيد الذي يستطيع إنشاء معظم الأنواع.
            إذا كان نوع حسابك يسمح بالنوع المطلوب ومع ذلك لا تستطيع النشر، فقد يكون حسابك ما زال قيد المراجعة؛ تواصل مع الدعم عبر Live Chat.
            هذا القيد لا يمنعك من الشراء أو البحث أو تتبع طلباتك.
            """);
        Add(chunks, "trouble-cannot-create", "Why I cannot create this type of ad", "en", SignedIn,
            """
            Ad creation is restricted by account type.
            A personal customer cannot create any ad, because the account is for buying only.
            A company customer can create Requests only and cannot create Booking, Retail, Category, or discounted Offer ads.
            A shipping company can create shipping ads only.
            Supplier is the only account able to create most types.
            If your account type does allow the type you want but you still cannot publish, your account may still be under review; contact support via Live Chat.
            This restriction does not stop you from buying, searching, or tracking your orders.
            """);

        Add(chunks, "trouble-signin", "مشاكل تسجيل الدخول", "ar", All,
            """
            إذا لم تستطع تسجيل الدخول تحقق أولاً من صحة البريد الإلكتروني وكلمة السر.
            إذا نسيت كلمة السر استخدم خيار نسيت كلمة السر ليصلك رمز OTP على بريدك ثم عيّن كلمة سر جديدة.
            إذا كنت مورداً وتحاول إنشاء حساب جديد بجوجل أو أبل فلن ينجح ذلك، لأن تسجيل المورد يتطلب الرخصة التجارية وصور الشركة عبر نموذج التسجيل الكامل.
            إذا كان حسابك قيد المراجعة فقد لا تتوفر بعض الميزات حتى الاعتماد.
            تأكد أيضاً من اتصال الإنترنت ومن تحديث التطبيق لآخر إصدار.
            إذا استمرت المشكلة تواصل مع الدعم عبر صفحة المساعدة والدعم.
            """);
        Add(chunks, "trouble-signin", "Sign-in problems", "en", All,
            """
            If you cannot sign in, first check that the email and password are correct.
            If you forgot the password, use the Forgot password option to receive an OTP by email and then set a new password.
            If you are a supplier trying to create a brand-new account with Google or Apple, that will not work, because supplier registration requires the trade license and company images through the full registration form.
            If your account is still under review, some features may be unavailable until approval.
            Also check your internet connection and that the app is updated to the latest version.
            If the problem continues, contact support through the Help and Support page.
            """);

        Add(chunks, "trouble-wrong-price", "السعر أو الكمية في الإعلان غير صحيحة", "ar", All,
            """
            المورد مسؤول عن صحة بيانات إعلانه من سعر وكمية ووحدة ومواصفات.
            إذا كنت المعلن يمكنك تصحيح البيانات من قسم إعلاناتي؛ تعديل السعر وحده لا يوقف ظهور الإعلان، بينما التعديلات الجوهرية تعيده للمراجعة.
            إذا كنت مشترياً ولاحظت خطأً واضحاً في بيانات إعلان، أبلغ الدعم عبر Live Chat مع اسم الإعلان.
            إذا استلمت بضاعة لا تطابق وصف الإعلان فهذه حالة مؤهلة للاسترجاع خلال 24 ساعة عمل من الاستلام مع صور.
            """);
        Add(chunks, "trouble-wrong-price", "The price or quantity on a listing is wrong", "en", All,
            """
            The supplier is responsible for the accuracy of their listing's price, quantity, unit, and specifications.
            If you are the advertiser you can correct the data from My Ads; a price-only change keeps the listing visible, while substantive edits send it back to review.
            If you are a buyer and notice a clear error in a listing, report it to support via Live Chat with the listing name.
            If you received goods that do not match the listing description, that is an eligible return case within 24 business hours of receipt with photos.
            """);
    }

    // ---------------------------------------------------------------------

    private static readonly string[] All =
        ["public", "guest", "supplier", "personal", "company_customer", "shipping"];

    /// <summary>Signed-in accounts of any type (excludes anonymous guests).</summary>
    private static readonly string[] SignedIn =
        ["public", "supplier", "personal", "company_customer", "shipping"];

    /// <summary>Accounts that can place orders and therefore have My Orders.</summary>
    private static readonly string[] Buyers =
        ["public", "supplier", "personal", "company_customer"];

    private static void Add(
        ICollection<AiKnowledgeChunk> chunks,
        string source,
        string title,
        string language,
        IReadOnlyList<string> audiences,
        string content)
    {
        var normalized = content.Trim();
        // Stable id so content updates overwrite the same Qdrant point.
        var hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(
            $"{source}|{title}|{language}"))).ToLowerInvariant();
        var id = $"{hash[..8]}-{hash[8..12]}-{hash[12..16]}-{hash[16..20]}-{hash[20..32]}";
        chunks.Add(new AiKnowledgeChunk(id, source, title, language, audiences, normalized));
    }
}
