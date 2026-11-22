import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'sms_launcher_stub.dart'
    if (dart.library.js_interop) 'sms_launcher_web.dart' as launcher;

class SmsResult {
  final bool success;
  final String message;
  final String smsText;
  final bool openedNativeSms;

  const SmsResult({
    required this.success,
    required this.message,
    required this.smsText,
    this.openedNativeSms = true,
  });
}

class SmsService {
  static const String defaultSystemUrl = 'https://mmhwahdan-ui.github.io/elite-grand/';

  /// صياغة الرسالة النصية لبيانات دخول الممرض
  static String formatCredentialsMessage({
    required String nurseName,
    required String username,
    required String password,
    String? systemUrl,
  }) {
    final url = systemUrl ?? defaultSystemUrl;
    return 'شركة إيليت جراند للتمريض المنزلي 🏥\n'
        'مرحباً بك د/ $nurseName\n'
        'تم تفعيل حسابك في النظام لمتابعة حالاتك ومستحقاتك:\n'
        '🌐 رابط الدخول: $url\n'
        '🆔 كود مقدم الخدمة (اسم المستخدم): $username\n'
        '🔑 كلمة المرور: $password\n'
        '📌 ملاحظة: تسجيل الدخول في النظام يتم باستخدام الكود أعلاه وليس برقم الهاتف.\n'
        '⚠️ يرجى عدم مشاركة بيانات الدخول مع أي شخص.';
  }

  /// إرسال رسالة SMS تلقائية للممرض
  static Future<SmsResult> sendNurseCredentials({
    required String phone,
    required String nurseName,
    required String username,
    required String password,
    String? customGatewayUrl,
    String? systemUrl,
  }) async {
    final smsText = formatCredentialsMessage(
      nurseName: nurseName,
      username: username,
      password: password,
      systemUrl: systemUrl,
    );

    // 1. نسخ النص تلقائياً إلى الحافظة
    try {
      await Clipboard.setData(ClipboardData(text: smsText));
    } catch (_) {}

    // 2. إذا تم تحديد رابط بوابة SMS من الإدارة، يتم الإرسال عبر السيرفر
    if (customGatewayUrl != null && customGatewayUrl.trim().isNotEmpty) {
      try {
        final uri = Uri.parse(customGatewayUrl.trim());
        await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'to': phone,
            'message': smsText,
            'nurseName': nurseName,
          }),
        ).timeout(const Duration(seconds: 8));
      } catch (_) {}
    }

    // 3. فتح تطبيق الرسائل النصية SMS مع الرقم والنص جاهز للإرسال
    if (phone.trim().isNotEmpty) {
      launcher.launchSmsUri(phone, smsText);
    }

    return SmsResult(
      success: true,
      message: 'تم تجهيز وإرسال رسالة SMS للممرض بنجاح',
      smsText: smsText,
      openedNativeSms: phone.trim().isNotEmpty,
    );
  }

  /// إرسال مباشر عبر واتساب
  static void sendViaWhatsApp({
    required String phone,
    required String nurseName,
    required String username,
    required String password,
    String? systemUrl,
  }) {
    final text = formatCredentialsMessage(
      nurseName: nurseName,
      username: username,
      password: password,
      systemUrl: systemUrl,
    );
    launcher.launchWhatsAppUri(phone, text);
  }
}
