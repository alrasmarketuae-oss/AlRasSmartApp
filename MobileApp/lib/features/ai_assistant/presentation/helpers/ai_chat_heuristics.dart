import 'package:flutter/material.dart';

TextDirection detectAiTextDirection(String text) {
  var arabic = 0;
  var latin = 0;
  for (final codeUnit in text.codeUnits) {
    if (codeUnit >= 0x0600 && codeUnit <= 0x06FF) {
      arabic++;
    } else if ((codeUnit >= 0x0041 && codeUnit <= 0x005A) ||
        (codeUnit >= 0x0061 && codeUnit <= 0x007A)) {
      latin++;
    }
  }
  if (arabic == 0 && latin == 0) return TextDirection.ltr;
  return arabic >= latin ? TextDirection.rtl : TextDirection.ltr;
}

bool looksLikeSupportCallbackIntent(String? message) {
  final q = (message ?? '').trim().toLowerCase();
  if (q.isEmpty) return false;
  const markers = <String>[
    'دعم فني',
    'الدعم الفني',
    'دعم بشري',
    'الدعم البشري',
    'الدعم',
    'كلم الدعم',
    'محتاج اكلم',
    'محتاج أكلم',
    'محتاج اتكلم',
    'محتاج أتكلم',
    'عايز اكلم',
    'عايز أكلم',
    'عايز اتكلم',
    'عايز أتكلم',
    'عاوز اكلم',
    'عاوز اتكلم',
    'محتاج الدعم',
    'خدمة العملاء',
    'كلمني',
    'اتصل بيا',
    'اتصلوا بيا',
    'technical support',
    'tech support',
    'human support',
    'human technical',
    'talk to support',
    'talk to technical',
    'talk with support',
    'speak to support',
    'speak with support',
    'contact support',
    'contact technical',
    'call support',
    'call me',
    'customer service',
    'customer care',
    'customer support',
    'support agent',
    'help desk',
    'live agent',
    'need support',
    'need technical',
    'need to talk',
    'need to speak',
    'want to talk',
    'want to speak',
    'talk to a human',
    'speak to a human',
    'real person',
    'real human',
    'phone support',
    'support please',
    'human help',
    'connect me to support',
    'transfer to support',
  ];
  return markers.any(q.contains);
}

bool looksLikeSupportCallbackCue(String answer) {
  final text = answer.trim().toLowerCase();
  if (text.isEmpty) return false;
  const markers = <String>[
    'خمس دقايق',
    'خلال خمس',
    'خلال 5',
    'النموذج تحت',
    'رقم تليفونك',
    'اكتب اسمك ورقم',
    'هيتواصل معاك',
    'هيتم الاتصال',
    'بيانات التواصل مع الدعم',
    'سيب اسمك ورقم',
    'five minutes',
    'form below',
    'leave your name',
    'phone number, and email',
    'technical support will call',
    'we’ll call you',
    "we'll call you",
    'called within five',
    'enter your name, phone',
  ];
  return markers.any(text.contains);
}

/// True when the assistant reply indicates a generic temporary outage message.
bool looksLikeTemporaryAssistantFailure(String answer) {
  final q = answer.toLowerCase();
  return q.contains('المساعد مش متاح') ||
      q.contains('تعذر الوصول للمساعد') ||
      q.contains('temporarily unavailable') ||
      q.contains('unavailable right now') ||
      q.contains('high demand') ||
      q.contains('ضغط عالي');
}

/// True when the assistant reply indicates the ad was created successfully.
bool looksLikeAdCreateSuccess(String answer) {
  final q = answer.toLowerCase();
  const markers = [
    'تم إنشاء',
    'تم نشر',
    'اتنشر',
    'نُشر',
    'نشرت',
    'إرساله للمراجعة',
    'created successfully',
    'published successfully',
    'ad created',
    'listing created',
    'submitted for review',
    'submitted for admin review',
    'productcode',
    'product code',
    'رمز المنتج',
  ];
  return markers.any(q.contains);
}
