-- Bilingual ports: Arabic display name (Countries already have CountryNameAr).
IF COL_LENGTH('dbo.Ports', 'PortNameAr') IS NULL
BEGIN
    ALTER TABLE dbo.Ports
    ADD PortNameAr NVARCHAR(255) NULL;
END
GO

-- UAE ports (CountryId = 15): full Arabic backfill by UnLocode (safe to re-run).
UPDATE p
SET p.PortNameAr = v.PortNameAr
FROM dbo.Ports p
INNER JOIN (VALUES
    (N'AEABU', N'أبو البخوش'),
    (N'AEAUH', N'أبو ظبي'),
    (N'AEAMU', N'أبو موسى'),
    (N'AEARP', N'ميناء أحمد بن راشد'),
    (N'AEAJM', N'عجمان'),
    (N'AEFJR', N'الفجيرة'),
    (N'AEJAZ', N'ميناء الجزيرة'),
    (N'AEAJP', N'ميناء الجير'),
    (N'AERUW', N'الرويس'),
    (N'AEDAS', N'جزيرة داس'),
    (N'AEDBP', N'دبا'),
    (N'AEDXB', N'دبي'),
    (N'AEEND', N'إسناد'),
    (N'AEFAT', N'محطة فتح'),
    (N'AEFRP', N'الميناء الحر'),
    (N'AEHZP', N'ميناء منطقة الحمرية الحرة'),
    (N'AEHSN', N'حصيان'),
    (N'AEHTL', N'محطة الحليلة'),
    (N'AEJEA', N'جبل علي'),
    (N'AEQWE', N'منطقة جبل علي الحرة'),
    (N'AEJED', N'جبل الظنة'),
    (N'AEKLB', N'كلباء'),
    (N'AEKLF', N'خورفكان'),
    (N'AEMKH', N'ميناء خالد'),
    (N'AEKHL', N'ميناء خليفة'),
    (N'AEMRP', N'ميناء راشد'),
    (N'AEMSA', N'ميناء صقر'),
    (N'AEMZD', N'ميناء زايد'),
    (N'AERFA', N'المرفأ'),
    (N'AEMUB', N'محطة مبارك'),
    (N'AEMBS', N'جزيرة مبارز'),
    (N'AEAMF', N'مصفح'),
    (N'AEPRA', N'ميناء راشد'),
    (N'AERKP', N'ميناء خور رأس الخيمة'),
    (N'AERMC', N'مدينة رأس الخيمة البحرية'),
    (N'AERKT', N'رأس الخيمة'),
    (N'AERWP', N'ميناء الرويس'),
    (N'AESID', N'جزيرة السعديات'),
    (N'AESHJ', N'الشارقة'),
    (N'AEDUJ', N'نخلة جميرا'),
    (N'AEULR', N'أم النار'),
    (N'AEQIW', N'أم القيوين'),
    (N'AEYAS', N'جزيرة ياس'),
    (N'AEZUR', N'جزيرة زركوه')
) AS v(UnLocode, PortNameAr)
    ON p.UnLocode = v.UnLocode
WHERE p.PortNameAr IS NULL OR LTRIM(RTRIM(p.PortNameAr)) = N'';
GO

-- Common Gulf / regional / major ports by UnLocode (safe to re-run).
UPDATE p
SET p.PortNameAr = v.PortNameAr
FROM dbo.Ports p
INNER JOIN (VALUES
    -- Bahrain
    (N'BHKBS', N'ميناء خليفة بن سلمان'),
    (N'BHMIN', N'ميناء مينا سلمان'),
    (N'BHAHD', N'الحد'),
    (N'BHGBQ', N'المحرق'),
    (N'BHSIT', N'سترة'),
    -- Saudi Arabia
    (N'SAJED', N'جدة'),
    (N'SADMM', N'الدمام'),
    (N'SAJUB', N'الجبيل'),
    (N'SARTA', N'رأس تنورة'),
    (N'SAYNB', N'ينبع'),
    (N'SAGIZ', N'جيزان'),
    -- Qatar
    (N'QADOH', N'الدوحة'),
    (N'QAUMS', N'مسيعيد'),
    (N'QARLF', N'رأس لفان'),
    -- Oman
    (N'OMSLL', N'صلالة'),
    (N'OMSOH', N'صحار'),
    (N'OMMCT', N'مسقط'),
    -- Kuwait
    (N'KWSWK', N'الشويخ'),
    (N'KWSAA', N'الشعيبة'),
    (N'KWMEA', N'ميناء الأحمدي'),
    (N'KWKWI', N'الكويت'),
    -- Egypt
    (N'EGPSD', N'بورسعيد'),
    (N'EGALY', N'الإسكندرية'),
    (N'EGDAM', N'دمياط'),
    (N'EGSOK', N'السخنة'),
    (N'EGSUZ', N'السويس'),
    -- Jordan / Levant
    (N'JOAQJ', N'العقبة'),
    (N'JOAQB', N'العقبة'),
    (N'LBBEY', N'بيروت'),
    (N'SYLTK', N'اللاذقية'),
    -- Turkey / Iran / Pakistan / India / China / Europe / US (common)
    (N'TRMER', N'ميرسين'),
    (N'TRIST', N'إسطنبول'),
    (N'IRBND', N'بندر عباس'),
    (N'PKKHI', N'كراتشي'),
    (N'INNSA', N'نهافا شيفا'),
    (N'INBOM', N'مومباي'),
    (N'LKCMB', N'كولومبو'),
    (N'SGSIN', N'سنغافورة'),
    (N'CNSGH', N'شنغهاي'),
    (N'CNNBO', N'نينغبو'),
    (N'CNQIN', N'تشينغداو'),
    (N'HKHKG', N'هونغ كونغ'),
    (N'NLRTM', N'روتردام'),
    (N'DEHAM', N'هامبورغ'),
    (N'BEANR', N'أنتويرب'),
    (N'ESVLC', N'فالنسيا'),
    (N'ESBCN', N'برشلونة'),
    (N'ITGOA', N'جنوة'),
    (N'USNYC', N'نيويورك'),
    (N'USLAX', N'لوس أنجلوس'),
    (N'USLGB', N'لونغ بيتش')
) AS v(UnLocode, PortNameAr)
    ON p.UnLocode = v.UnLocode
WHERE p.PortNameAr IS NULL OR LTRIM(RTRIM(p.PortNameAr)) = N'';
GO
