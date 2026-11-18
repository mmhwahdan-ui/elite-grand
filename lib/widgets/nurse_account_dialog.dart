import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/caregiver_model.dart';
import '../providers/app_provider.dart';
import '../services/sms_service.dart';
import '../theme/app_theme.dart';

class NurseAccountDialog extends StatefulWidget {
  final CaregiverModel caregiver;

  const NurseAccountDialog({super.key, required this.caregiver});

  @override
  State<NurseAccountDialog> createState() => _NurseAccountDialogState();
}

class _NurseAccountDialogState extends State<NurseAccountDialog> {
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  bool _obscurePassword = false;
  bool _sendSmsNow = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default username: phone without non-digits, or caregiver code
    final defaultUsername = widget.caregiver.loginUsername?.isNotEmpty == true
        ? widget.caregiver.loginUsername!
        : (widget.caregiver.phone.trim().isNotEmpty
            ? widget.caregiver.phone.replaceAll(RegExp(r'[^0-9]'), '')
            : widget.caregiver.code.toLowerCase().replaceAll('-', ''));

    final defaultPassword = widget.caregiver.loginPassword?.isNotEmpty == true
        ? widget.caregiver.loginPassword!
        : _generateRandomPassword();

    _usernameCtrl = TextEditingController(text: defaultUsername);
    _passwordCtrl = TextEditingController(text: defaultPassword);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _generateRandomPassword() {
    final rng = Random();
    return (100000 + rng.nextInt(900000)).toString(); // 6 digits
  }

  Future<void> _handleSaveAndSend() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة اسم المستخدم للدخول', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة كلمة المرور', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<AppProvider>();

    try {
      final success = await provider.createOrUpdateNurseAccount(
        caregiver: widget.caregiver,
        username: username,
        password: password,
        sendSms: _sendSmsNow,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _sendSmsNow
                    ? 'تم حفظ الحساب وإرسال رسالة SMS للممرض بنجاح'
                    : 'تم تفعيل وتحديث حساب الممرض بنجاح',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleResendSms() async {
    setState(() => _isLoading = true);
    final provider = context.read<AppProvider>();

    try {
      final result = await provider.resendNurseCredentialsSms(widget.caregiver);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.openedNativeSms
                  ? 'تم تجهيز رسالة SMS وفتح تطبيق الرسائل بنجاح'
                  : 'تم إرسال بيانات الدخول عبر SMS',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSendWhatsApp() {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    SmsService.sendViaWhatsApp(
      phone: widget.caregiver.phone,
      nurseName: widget.caregiver.name,
      username: username,
      password: password,
    );
  }

  void _handleCopyCredentials() {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final text = SmsService.formatCredentialsMessage(
      nurseName: widget.caregiver.name,
      username: username,
      password: password,
    );
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ بيانات الدخول ورابط النظام إلى الحافظة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAccount = widget.caregiver.hasLoginAccount;
    final lastSms = widget.caregiver.lastSmsSentAt;

    final smsPreviewText = SmsService.formatCredentialsMessage(
      nurseName: widget.caregiver.name,
      username: _usernameCtrl.text.trim().isNotEmpty ? _usernameCtrl.text.trim() : '...',
      password: _passwordCtrl.text.trim().isNotEmpty ? _passwordCtrl.text.trim() : '••••••',
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 580,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: const Icon(Icons.sms_outlined, color: Colors.teal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAccount ? 'إدارة حساب الممرض والرسائل القصيرة' : 'إنشاء حساب دخول للممرض وإرسال SMS',
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'الممرض: ${widget.caregiver.name} (كود: ${widget.caregiver.code})',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (hasAccount)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.teal),
                          SizedBox(width: 4),
                          Text('حساب مفعل', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              const Divider(height: 24),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Target Phone Indicator
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.caregiver.phone.trim().isNotEmpty ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.caregiver.phone.trim().isNotEmpty ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.caregiver.phone.trim().isNotEmpty ? Icons.phone_android : Icons.warning_amber_rounded,
                              color: widget.caregiver.phone.trim().isNotEmpty ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.caregiver.phone.trim().isNotEmpty
                                        ? 'سيتم إرسال الـ SMS إلى رقم الهاتف: ${widget.caregiver.phone}'
                                        : 'تنبيه: لم يتم تسجيل رقم هاتف لهذا الممرض في الملف الشخصي!',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: widget.caregiver.phone.trim().isNotEmpty ? Colors.green.shade900 : Colors.red.shade900,
                                    ),
                                  ),
                                  if (lastSms != null)
                                    Text(
                                      'آخر رسالة تم إرسالها: ${DateFormat('yyyy/MM/dd - hh:mm a').format(lastSms)}',
                                      style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Username Input
                      TextField(
                        controller: _usernameCtrl,
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم للدخول (Username)',
                          hintText: 'مثال: رقم التليفون أو الكود',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          helperText: 'يمكن للممرض تسجيل الدخول بهذا الاسم أو برقم هاتفه',
                          helperStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),

                      // Password Input with Generator
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور (Password)',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _passwordCtrl.text = _generateRandomPassword();
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('توليد تلقائي', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Send SMS Checkbox
                      CheckboxListTile(
                        value: _sendSmsNow,
                        onChanged: (val) => setState(() => _sendSmsNow = val ?? true),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'إرسال رسالة نصية SMS للممرض فور الحفظ تلقائياً',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: const Text(
                          'يقوم النظام بتجهيز الرسالة وإرسالها للهاتف مع رابط الدخول وبيانات الحساب',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 12),

                      // SMS Preview Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 16, color: Colors.blueGrey),
                                    SizedBox(width: 6),
                                    Text('معاينة نص رسالة الـ SMS:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: _handleCopyCredentials,
                                  icon: const Icon(Icons.copy, size: 14),
                                  label: const Text('نسخ النص', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                smsPreviewText,
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, height: 1.5, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Channel Actions (WhatsApp & Copy)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.caregiver.phone.trim().isNotEmpty ? _handleSendWhatsApp : null,
                              icon: const Icon(Icons.send_rounded, size: 16, color: Colors.green),
                              label: const Text('إرسال عبر واتساب', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.green)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _handleCopyCredentials,
                              icon: const Icon(Icons.content_copy, size: 16, color: AppTheme.primary),
                              label: const Text('نسخ بيانات الدخول', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.primary)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primary),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                  ),
                  Row(
                    children: [
                      if (hasAccount) ...[
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleResendSms,
                          icon: const Icon(Icons.sms, size: 16),
                          label: const Text('إعادة إرسال SMS', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: const BorderSide(color: Colors.teal),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSaveAndSend,
                        icon: _isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(hasAccount ? Icons.save : Icons.person_add_alt_1, size: 18),
                        label: Text(
                          hasAccount
                              ? (_sendSmsNow ? 'حفظ وتحديث وإرسال SMS' : 'حفظ التعديلات')
                              : (_sendSmsNow ? 'إنشاء الحساب وإرسال SMS' : 'إنشاء الحساب فقط'),
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
