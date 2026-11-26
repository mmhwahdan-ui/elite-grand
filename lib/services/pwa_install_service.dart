import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@JS('isAppStandalone')
external JSBoolean? _isAppStandalone();

@JS('promptPwaInstall')
external JSPromise<JSString>? _promptPwaInstall();

class PwaInstallService {
  static bool isStandalone() {
    if (!kIsWeb) return true;
    try {
      final res = _isAppStandalone();
      return res?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String> promptInstall() async {
    if (!kIsWeb) return 'unsupported';
    try {
      final promise = _promptPwaInstall();
      if (promise != null) {
        final jsVal = await promise.toDart;
        return jsVal.toDart;
      }
      return 'unavailable';
    } catch (_) {
      return 'error';
    }
  }

  static Future<void> handleInstallClick(BuildContext context) async {
    final status = await promptInstall();
    if (status == 'accepted') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جاري تثبيت إيليت جراند بنجاح على جهازك', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Color(0xFF00D09C),
          ),
        );
      }
    } else if (status == 'dismissed') {
      // User cancelled
    } else {
      // Unavailable or manual guide needed
      if (context.mounted) {
        showInstallHelpDialog(context);
      }
    }
  }

  static void showInstallHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.install_mobile_rounded, color: Color(0xFF00D09C)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تثبيت التطبيق على جهازك',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'يمكنك تشغيل إيليت جراند كبرنامج مستقل وسريع بدون الحاجة لفتح المتصفح في كل مرة، مع دعم كامل للعمل بدون إنترنت.',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                _buildInstructionBox(
                  icon: Icons.android_rounded,
                  color: Colors.green.shade700,
                  bgColor: Colors.green.shade50,
                  title: 'على هواتف الأندرويد (Chrome):',
                  step: '1. اضغط على القائمة (⁝) بأعلى الشاشة.\n2. اضغط "تثبيت التطبيق" (Install app) أو "إضافة إلى الشاشة الرئيسية".\n3. سيتم تثبيت أيقونة إيليت جراند كبرنامج مستقل.',
                ),
                const SizedBox(height: 12),
                _buildInstructionBox(
                  icon: Icons.computer_rounded,
                  color: Colors.blue.shade700,
                  bgColor: Colors.blue.shade50,
                  title: 'على الكمبيوتر (Chrome / Edge):',
                  step: '1. اضغط على علامة التثبيت ⊕ بجوار رابط الموقع في شريط العنوان بالأعلى.\n2. أو من قائمة المتصفح (⁝) -> تطبيقات (Apps) -> "تثبيت إيليت جراند".\n3. سيفتح البرنامج فوراً كنافذة كمبيوتر مستقلة.',
                ),
                const SizedBox(height: 12),
                _buildInstructionBox(
                  icon: Icons.phone_iphone_rounded,
                  color: Colors.black87,
                  bgColor: Colors.grey.shade100,
                  title: 'على الآيفون / الآيباد (Safari):',
                  step: '1. اضغط على زر المشاركة (Share ⎋) أسفل المتصفح.\n2. مرر لأسفل واختر "إضافة إلى الشاشة الرئيسية" (Add to Home Screen).',
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2540),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('حسناً', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildInstructionBox({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String step,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            step,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, height: 1.4, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}
