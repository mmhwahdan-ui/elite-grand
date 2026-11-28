import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;

class WhatsAppService {
  /// تنظيف وتنسيق رقم الهاتف المصري إلى الصيغة الدولية لواتساب (201xxxxxxxxx)
  static String formatPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('+')) {
      clean = clean.substring(1);
    }
    if (clean.startsWith('00')) {
      clean = clean.substring(2);
    }
    // إذا كان يبدأ بـ 01 (أرقام مصرية)
    if (clean.startsWith('01') && clean.length == 11) {
      clean = '2$clean';
    } else if (clean.startsWith('1') && clean.length == 10) {
      clean = '20$clean';
    }
    return clean;
  }

  /// فتح محادثة الواتساب مباشرة مع نص الرسالة
  static void openChat({required BuildContext context, required String phone, required String message}) {
    final cleanPhone = formatPhoneNumber(phone);
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رقم الهاتف غير صالح للإرسال عبر واتساب', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final encodedMsg = Uri.encodeComponent(message);
    final waUrl = 'https://wa.me/$cleanPhone?text=$encodedMsg';

    try {
      if (kIsWeb) {
        web.window.open(waUrl, '_blank');
      } else {
        // Fallback for non-web platforms if applicable
        web.window.open(waUrl, '_blank');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر فتح تطبيق واتساب: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// 1. إيصال استلام نقدية رسمي للعميل
  static void sharePaymentReceipt({
    required BuildContext context,
    required String phone,
    required String clientName,
    required double amount,
    required String channel,
    required double remainingBalance,
    DateTime? date,
    String? receiverName,
  }) {
    final paymentDate = DateFormat('yyyy/MM/dd - hh:mm a').format(date ?? DateTime.now());
    final channelName = channel == 'bank'
        ? 'تحويل بنكي'
        : channel == 'wallet'
            ? 'فودافون كاش / محفظة'
            : 'نقداً (كاش)';

    final balanceText = remainingBalance < 0
        ? 'المتبقي مستحق على العميل: ${(-remainingBalance).toStringAsFixed(0)} ج.م'
        : remainingBalance > 0
            ? 'رصيد مقدم دائن للعميل: ${remainingBalance.toStringAsFixed(0)} ج.م'
            : 'الحساب خالص بالكامل (0 ج.م)';

    final message = '''
*شركة إيليت جراند للتمريض المنزلي والرعاية الصحية 🏥*
━━━━━━━━━━━━━━━━━━━
*إيصال استلام نقدية رسمي 🧾*

• *العميل:* $clientName
• *المبلغ المستلم:* ${amount.toStringAsFixed(0)} ج.م
• *طريقة السداد:* $channelName
• *التاريخ والوقت:* $paymentDate
• *مستلم النقدية:* ${receiverName ?? 'إدارة الحسابات'}
• *الموقف المالي:* $balanceText
━━━━━━━━━━━━━━━━━━━
شكراً لثقتكم بشركة إيليت جراند، ونتمنى لكم ولمريضكم دوام الصحة والعافية 🌸
_خدمة عملاء إيليت جراند - تم التوليد آلياً من النظام_
''';

    openChat(context: context, phone: phone, message: message.trim());
  }

  /// 2. كشف حساب ومطالبة مالية مختصرة للعميل
  static void shareAccountStatement({
    required BuildContext context,
    required String phone,
    required String clientName,
    required String serviceType,
    required double dailyPrice,
    required int daysCount,
    required double totalDue,
    required double totalPaid,
    required double remainingBalance,
    String? patientName,
  }) {
    final serviceTypeName = serviceType == 'hours24'
        ? 'إقامة كاملة (24 ساعة)'
        : serviceType == 'hours12'
            ? 'وردية نهارية/ليلية (12 ساعة)'
            : 'زيارة وتمريض منزلي';

    final balanceText = remainingBalance < 0
        ? 'المتبقي المطلوب تحصيله: ${(-remainingBalance).toStringAsFixed(0)} ج.م'
        : remainingBalance > 0
            ? 'رصيد دائن مسبق للعميل: ${remainingBalance.toStringAsFixed(0)} ج.م'
            : 'الحساب خالص بالكامل (0 ج.م)';

    final message = '''
*شركة إيليت جراند للتمريض المنزلي والرعاية الصحية 🏥*
━━━━━━━━━━━━━━━━━━━
*كشف حساب وموقف خدمة مالي 📋*

• *العميل:* $clientName ${patientName != null && patientName.isNotEmpty ? '($patientName)' : ''}
• *نوع الخدمة:* $serviceTypeName
• *سعر اليومية:* ${dailyPrice.toStringAsFixed(0)} ج.م
• *إجمالي أيام العمل:* $daysCount يوم
• *إجمالي قيمة الخدمة:* ${totalDue.toStringAsFixed(0)} ج.م
• *إجمالي المسدد:* ${totalPaid.toStringAsFixed(0)} ج.م
• *الموقف المالي:* $balanceText
━━━━━━━━━━━━━━━━━━━
برجاء التكرم بمراجعة الحساب وتأكيد السداد في الموعد المحدد.
شاكرين حسن تعاونكم معنا، إدارة إيليت جراند 🌸
''';

    openChat(context: context, phone: phone, message: message.trim());
  }

  /// 3. إرسال تكليف وردية وتفاصيل الحالة للممرض
  static void shareShiftAssignment({
    required BuildContext context,
    required String phone,
    required String nurseName,
    required String clientName,
    required String address,
    required String serviceType,
    required double nursePrice,
    required DateTime startDate,
    String? healthCondition,
    String? notes,
  }) {
    final startFormatted = DateFormat('yyyy/MM/dd').format(startDate);
    final shiftType = serviceType == 'hours24'
        ? 'إقامة كاملة (24 ساعة)'
        : serviceType == 'hours12'
            ? 'وردية (12 ساعة)'
            : 'خدمة تمريض';

    final message = '''
*شركة إيليت جراند للتمريض المنزلي والرعاية الصحية 🏥*
━━━━━━━━━━━━━━━━━━━
*تكليف وردية عمل جديدة 📋*

الزميل/ة العزيز/ة: *$nurseName*
تحية طيبة، تم إسناد الحالة التالية لحضرتك:

• *اسم الحالة / العميل:* $clientName
• *العنوان بالتفصيل:* $address
• *نظام الوردية:* $shiftType
• *تاريخ بدء العمل:* $startFormatted
• *يومية التمريض المعتمدة:* ${nursePrice.toStringAsFixed(0)} ج.م
${healthCondition != null && healthCondition.isNotEmpty ? '• *التشخيص والحالة الصحية:* $healthCondition\n' : ''}${notes != null && notes.isNotEmpty ? '• *تعليمات وملاحظات:* $notes\n' : ''}━━━━━━━━━━━━━━━━━━━
*تنبيه هام:*
1. برجاء تسجيل الحضور من التطبيق فور الوصول لمقر الحالة.
2. الالتزام بالزي الطبي والتعليمات السريرية للشركة.

مع تمنياتنا بالتوفيق والتميز دائماً ✨
_إدارة التشغيل والمتابعة - إيليت جراند_
''';

    openChat(context: context, phone: phone, message: message.trim());
  }

  /// 4. إرسال كشف حساب مالي للممرض (المستحقات والسلف)
  static void shareCaregiverStatement({
    required BuildContext context,
    required String phone,
    required String nurseName,
    required int daysCount,
    required double totalEarned,
    required double totalAdvances,
    required double netDue,
  }) {
    final message = '''
*شركة إيليت جراند للتمريض المنزلي 🏥*
━━━━━━━━━━━━━━━━━━━
*كشف حساب مستحقات مقدم الخدمة 💰*

الزميل/ة: *$nurseName*
• *عدد الأيام المنفذة:* $daysCount يوم
• *إجمالي أجر العمل المستحق:* ${totalEarned.toStringAsFixed(0)} ج.م
• *إجمالي السلف والمنصرفات:* ${totalAdvances.toStringAsFixed(0)} ج.م
• *صافي المستحق للصرف:* ${netDue.toStringAsFixed(0)} ج.م
━━━━━━━━━━━━━━━━━━━
_إدارة الحسابات - شركة إيليت جراند_
''';

    openChat(context: context, phone: phone, message: message.trim());
  }
}
