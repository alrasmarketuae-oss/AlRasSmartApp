/** ~100 lines of bilingual explanation for chat end-to-end encryption. */

export const encryptedMessagesAr = [
  {
    title: 'ما معنى التشفير التام بين الطرفين؟',
    paragraphs: [
      'عندما تفتح محادثة الدعم في تطبيق سوق الراس، يتم تفعيل طبقة حماية تُبقي محتوى الرسائل مقروءًا فقط للأشخاص الموجودين داخل هذه المحادثة.',
      'الخادم ينقل الرسالة ويحفظها بصيغة مشفّرة، لكنه لا يحتاج أن يقرأ النص الصريح كي يوصلها. الهدف أن تبقى المحادثة خاصة بينك وبين فريق الدعم المعتمد.',
    ],
  },
  {
    title: 'لكل مستخدم زوج مفاتيح',
    paragraphs: [
      'ينشئ تطبيقك زوج مفاتيح: مفتاح عام (Public Key) يمكن مشاركته، ومفتاح خاص (Private Key) يبقى على جهازك ولا يغادره.',
      'المفتاح العام مثل قفل مفتوح يستطيع أي مرسل استخدامه لإغلاق صندوق الرسالة بحيث لا يفتحه إلا صاحب المفتاح الخاص.',
      'المفتاح الخاص مثل المفتاح المعدني الفعلي للقفل؛ بدون وجوده على جهازك لا يمكن قراءة الرسائل المشفّرة الخاصة بك.',
    ],
  },
  {
    title: 'كيف تُرسل الرسالة؟ (مثال أحمد → محمد)',
    paragraphs: [
      'يحصل أحمد على المفتاح العام لمحمد.',
      'ينشئ أحمد مفتاح جلسة عشوائيًا (Session Key) قويًا وسريعًا، غالبًا باستخدام AES.',
      'يشفر أحمد نص الرسالة أو محتوى الوسائط الوصفي بهذا المفتاح المتماثل.',
      'ثم يشفر مفتاح الجلسة نفسه باستخدام المفتاح العام لمحمد (RSA-OAEP).',
      'يرسل أحمد إلى الخادم: الرسالة المشفرة + مفتاح الجلسة بعد تشفيره، بدون إرسال النص الواضح.',
    ],
  },
  {
    title: 'كيف تُقرأ الرسالة؟',
    paragraphs: [
      'يستلم محمد الحزمة المشفّرة.',
      'يستخدم مفتاحه الخاص لفك تشفير مفتاح الجلسة فقط.',
      'ثم يستخدم مفتاح الجلسة لفك تشفير الرسالة نفسها وعرضها في الشاشة.',
      'أي جهاز أو طرف لا يملك المفتاح الخاص المناسب يرى بيانات غير مفهومة.',
    ],
  },
  {
    title: 'لماذا مفتاح جلسة + مفاتيح عامة/خاصة؟',
    paragraphs: [
      'التشفير غير المتماثل (RSA) ممتاز لحماية مفاتيح صغيرة، لكنه أبطأ للرسائل الطويلة والصوت والصور.',
      'التشفير المتماثل (AES) سريع جدًا للمحتوى الكبير.',
      'لذلك ندمج الاثنين: AES للمحتوى، وRSA لحماية مفتاح AES. هذه هي طريقة “التشفير الهجين” المستخدمة في أنظمة المراسلة الحديثة.',
    ],
  },
  {
    title: 'من يستطيع القراءة أو الاستماع؟',
    paragraphs: [
      'فقط أطراف هذه المحادثة: أنت وفريق الدعم المخوّل في سوق الراس.',
      'موظفو الدعم المعتمدون يفكّون التشفير على أجهزة لوحة التحكم بعد تحقق الهوية، لكي يردّوا عليك.',
      'لا يظهر نص الرسالة الواضح داخل قاعدة البيانات بشكل قابل للقراءة العادية؛ الإشعارات أيضًا لا تفصح عن محتوى الرسالة المشفّرة.',
    ],
  },
  {
    title: 'ماذا عن التسجيلات والصوت والصور؟',
    paragraphs: [
      'يُعامل وصف المحتوى والروابط الداخلية ضمن نفس مغلف التشفير عند الإرسال داخل المحادثة.',
      'يظل الأمان يعتمد على بقاء مفتاحك الخاص على جهازك، وعلى حماية حسابك بكلمة مرور وOTP وعدم مشاركة الجهاز مع غير المصرح لهم.',
    ],
  },
  {
    title: 'حدود مهمة بصراحة',
    paragraphs: [
      'التشفير يحمي محتوى المحادثة أثناء النقل والتخزين من القراءة العرضية.',
      'إذا سمح شخص ما بالوصول إلى جهازه أو شاشة غير مقفلة، يمكن رؤية الرسائل بعد فكها محليًا.',
      'إذا طلب القانون أو سياسة المنصة إجراءً على حساب مخالف، تبقى الإجراءات الإدارية منفصلة عن قراءة نص المحادثات المشفّرة من قاعدة البيانات مباشرة.',
    ],
  },
  {
    title: 'نصيحة أمان سريعة',
    paragraphs: [
      'حدّث التطبيق، ولا تشارك رمز OTP، واحمِ هاتفك بقفل شاشة.',
      'إذا غيّرت الجهاز، قد تحتاج الجلسة إلى تهيئة مفاتيح جديدة على الجهاز الجديد؛ الرسائل القديمة المشفّرة بمحور جهاز سابق قد لا تُفك على الجهاز الجديد.',
      'شكراً لثقتك في سوق الراس — خصوصية محادثات الدعم جزء أساسي من تجربة المنصة.',
    ],
  },
]

export const encryptedMessagesEn = [
  {
    title: 'What does end-to-end encryption mean?',
    paragraphs: [
      'When you open Al Ras Market support chat, a protection layer keeps message content readable only to people in that conversation.',
      'The server can deliver and store ciphertext without needing the clear text. The goal is a private thread between you and authorized support staff.',
    ],
  },
  {
    title: 'Every user has a key pair',
    paragraphs: [
      'Your app creates a public key (shareable) and a private key that stays on your device and never leaves it.',
      'The public key is like an open lock anyone can use to seal a box that only the private-key owner can open.',
      'The private key is the physical key to that lock; without it on your device, your encrypted messages cannot be read.',
    ],
  },
  {
    title: 'How is a message sent? (Ahmed → Mohamed)',
    paragraphs: [
      'Ahmed fetches Mohamed’s public key.',
      'Ahmed generates a random fast session key (AES).',
      'Ahmed encrypts the message with that session key.',
      'Ahmed encrypts the session key with Mohamed’s public key (RSA-OAEP).',
      'Ahmed uploads ciphertext + wrapped session key — never the clear message.',
    ],
  },
  {
    title: 'How is a message read?',
    paragraphs: [
      'Mohamed receives the encrypted package.',
      'He uses his private key to unwrap the session key.',
      'He uses the session key to decrypt and display the message.',
      'Anyone without the matching private key only sees unreadable data.',
    ],
  },
  {
    title: 'Why session keys plus public/private keys?',
    paragraphs: [
      'RSA is great for protecting small secrets, but slow for long media.',
      'AES is fast for large content.',
      'Hybrid encryption uses AES for content and RSA to protect the AES key — the same pattern used by modern messengers.',
    ],
  },
  {
    title: 'Who can read or listen?',
    paragraphs: [
      'Only parties in this conversation: you and authorized Al Ras Market support.',
      'Verified support agents decrypt on dashboard devices after sign-in so they can reply.',
      'Clear text is not stored for casual database reading; push notifications do not reveal encrypted body content.',
    ],
  },
  {
    title: 'Voice, images, and media',
    paragraphs: [
      'Content descriptors and in-chat payloads are wrapped in the same encryption envelope when sent in the thread.',
      'Security still depends on keeping your private key on your device and protecting your account with password, OTP, and a locked phone.',
    ],
  },
  {
    title: 'Honest limits',
    paragraphs: [
      'Encryption protects against casual interception and storage snooping.',
      'If someone already has unlocked access to your device screen, they can see messages after local decryption.',
      'Administrative account actions are separate from reading encrypted chat plaintext directly from the database.',
    ],
  },
  {
    title: 'Quick safety tips',
    paragraphs: [
      'Keep the app updated, never share OTP codes, and lock your phone.',
      'On a new device, keys may need to be set up again; messages sealed with an older device key may not decrypt on the new device.',
      'Thank you for trusting Al Ras Market — private support chats are part of the platform experience.',
    ],
  },
]
