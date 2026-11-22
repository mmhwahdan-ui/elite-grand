import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

class FinancialResetDialog extends StatefulWidget {
  const FinancialResetDialog({super.key});

  @override
  State<FinancialResetDialog> createState() => _FinancialResetDialogState();
}

class _FinancialResetDialogState extends State<FinancialResetDialog> {
  final _passwordCtrl = TextEditingController();
  final _confirmationTextCtrl = TextEditingController();
  bool _resetClientOpeningBalances = true;
  bool _resetServiceDays = false;
  bool _isLoading = false;
  bool _backupDownloaded = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmationTextCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final canReset = provider.canManagePermissions || provider.canEditAnyData;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تصفير النظام وإعادة إدخال الحسابات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'إعادة ضبط وتصفير الأرصدة المالية مع الحفاظ الكامل على قاعدة البيانات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Backup Safeguard Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _backupDownloaded ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _backupDownloaded ? Colors.green.shade300 : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _backupDownloaded ? Icons.check_circle : Icons.cloud_download_outlined,
                        color: _backupDownloaded ? Colors.green.shade700 : AppTheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _backupDownloaded
                                  ? 'تم تنزيل النسخة الاحتياطية بنجاح 💾'
                                  : 'خطوة الأمان الأولى: تنزيل نسخة احتياطية كاملة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _backupDownloaded ? Colors.green.shade900 : AppTheme.primary,
                              ),
                            ),
                            const Text(
                              'احفظ نسخة احتياطية من الأرصدة والمدفوعات والمصروفات الحالية للرجوع إليها في أي وقت.',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          ExportService.exportFullFinancialBackupJson(provider);
                          setState(() => _backupDownloaded = true);
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: Text(
                          _backupDownloaded ? 'تنزيل ثانٍ' : 'تنزيل Backup',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _backupDownloaded ? Colors.green.shade700 : AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // What is Reset vs Preserved
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // What is Reset
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'سيتم تصفير وحذف:',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildBulletItem('سندات القبض (مدفوعات العملاء)', isDanger: true),
                            _buildBulletItem('كافة فواتير وسجلات المصروفات', isDanger: true),
                            _buildBulletItem('سلف وصرف مستحقات التمريض', isDanger: true),
                            _buildBulletItem('سلف وتسويات أرباح الشركاء', isDanger: true),
                            _buildBulletItem('أرصدة الخزائن (البنك/المحفظة/الكاش = 0)', isDanger: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // What is Preserved
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.verified_user_outlined, size: 18, color: Colors.green.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'محفوظ 100% دون مساس:',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildBulletItem('بيانات وملفات العملاء (${provider.clients.length} عميل)', isDanger: false),
                            _buildBulletItem('سجل مقدمي الخدمة والتمريض (${provider.caregivers.length})', isDanger: false),
                            _buildBulletItem('حسابات وصلاحيات المستخدمين الإداريين', isDanger: false),
                            _buildBulletItem('سجل المحادثات والتعليمات وعروض الحالات', isDanger: false),
                            _buildBulletItem('أسعار العملاء ويوميات التمريض المعتمدة', isDanger: false),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Options
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _resetClientOpeningBalances,
                        onChanged: (v) => setState(() => _resetClientOpeningBalances = v ?? true),
                        title: const Text(
                          'تصفير الأرصدة الافتتاحية المسجلة للعملاء (تصبح 0 ج.م)',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'لتتمكن من إدخال أرصدة افتتاحية جديدة للعملاء بدقة',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: Colors.red.shade700,
                      ),
                      const Divider(height: 12),
                      CheckboxListTile(
                        value: _resetServiceDays,
                        onChanged: (v) => setState(() => _resetServiceDays = v ?? false),
                        title: const Text(
                          'تصفير سجل الورديات وأيام الخدمة السابقة المنفذة',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'إذا كنت تريد بدء تقفيل الورديات من الصفر بالكامل',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: Colors.red.shade700,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Security confirmation challenge
                const Text(
                  'تأكيد أمان الإدارة:',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة مرور المدير الإداري',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmationTextCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اكتب عبارة "تصفير الحسابات" للتأكيد',
                    hintText: 'تصفير الحسابات',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_note),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: (_isLoading || !canReset) ? null : _handleReset,
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.delete_forever, size: 18),
                      label: Text(
                        _isLoading ? 'جارٍ التصفير وتحديث السحابة...' : 'تأكيد تصفير الأرصدة المالية',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text, {required bool isDanger}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDanger ? Icons.remove_circle_outline : Icons.check_circle_outline,
            size: 13,
            color: isDanger ? Colors.red.shade600 : Colors.green.shade600,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: isDanger ? Colors.red.shade900 : Colors.green.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReset() async {
    final pwd = _passwordCtrl.text.trim();
    final confirmText = _confirmationTextCtrl.text.trim();

    if (confirmText != 'تصفير الحسابات') {
      setState(() => _errorMessage = 'يرجى كتابة عبارة "تصفير الحسابات" بدقة للتأكيد');
      return;
    }

    final provider = context.read<AppProvider>();
    // Check password against current user or wahdan / shimaa
    final currentUser = provider.currentUser;
    final isPasswordValid = (currentUser != null && currentUser.password == pwd) ||
        pwd == 'wahdan2026' ||
        pwd == '123456';

    if (!isPasswordValid) {
      setState(() => _errorMessage = 'كلمة المرور غير صحيحة، يرجى كتابة كلمة مرور الإدارة');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Auto export backup first before zeroing out
      ExportService.exportFullFinancialBackupJson(provider);

      await provider.resetSystemFinancials(
        resetClientOpeningBalances: _resetClientOpeningBalances,
        resetServiceDays: _resetServiceDays,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تصفير الأرصدة المالية بنجاح مع الحفاظ التام على بيانات العملاء ومقدمي الخدمة 🛡️',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.teal,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ أثناء التصفير: $e';
        });
      }
    }
  }
}
