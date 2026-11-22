import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/all_users_passwords_dialog.dart';

class UsersPermissionsScreen extends StatelessWidget {
  const UsersPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final users = provider.users;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لوحة تحكم المدير العام (أ/ وهدان)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                        ),
                        Text(
                          'تخصيص وتوزيع الصلاحيات واستعراض كلمات المرور لجميع الحسابات',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AllUsersPasswordsDialog(),
                      );
                    },
                    icon: const Icon(Icons.vpn_key_rounded, size: 16),
                    label: const Text('كشف كلمات المرور 🔑', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...users.map((user) => _buildUserPermissionTile(context, provider, user)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPermissionTile(BuildContext context, AppProvider provider, UserModel user) {
    final isManager = user.username == 'wahdan';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: !isManager,
          leading: CircleAvatar(
            backgroundColor: isManager ? AppTheme.primary : AppTheme.primaryLight.withValues(alpha: 0.15),
            foregroundColor: isManager ? Colors.white : AppTheme.primaryLight,
            child: Icon(isManager ? Icons.star : Icons.person_outline),
          ),
          title: Row(
            children: [
              Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: user.isNurse ? Colors.teal.shade50 : Colors.grey.shade100,
                  border: user.isNurse ? Border.all(color: Colors.teal.shade200) : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.isNurse ? 'كود الدخول: ${user.username}' : '@${user.username}',
                  style: TextStyle(
                    fontSize: 11,
                    color: user.isNurse ? Colors.teal.shade800 : Colors.blueGrey,
                    fontWeight: user.isNurse ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.roleTitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 6),
              // Password Display Badge for Wahdan / Manager
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: user.password));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم نسخ كلمة مرور @${user.username} بنجاح (${user.password})', style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: Colors.teal,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.vpn_key_rounded, size: 13, color: Colors.amber.shade900),
                      const SizedBox(width: 4),
                      Text(
                        'كلمة المرور: ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontFamily: 'Cairo'),
                      ),
                      SelectableText(
                        user.password,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy, size: 12, color: Colors.amber.shade900),
                    ],
                  ),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.lock_reset, color: Colors.blueGrey, size: 22),
                tooltip: 'تغيير كلمة المرور',
                onPressed: () => _showChangePasswordDialog(context, provider, user),
              ),
              if (!isManager)
                IconButton(
                  icon: const Icon(Icons.edit_note, color: AppTheme.accent),
                  tooltip: 'تعديل اسم ومسمى الحساب',
                  onPressed: () => _showEditUserDialog(context, provider, user),
                ),
            ],
          ),
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: isManager
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'حساب المدير العام يمتلك كافة صلاحيات النظام افتراضياً ويستطيع الاطلاع والتعديل على أي بيان.',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppTheme.primary),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تحديد الصلاحيات المتاحة لهذا الحساب:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 8),
                        _buildSwitch(
                          title: 'إدخال وتعديل بيانات المرضى والحالات',
                          subtitle: 'اسم المريض، العنوان، الحالة الصحية (المتابعة - شيماء)',
                          value: user.permissions.canAddClient,
                          onChanged: (val) {
                            final updated = user.permissions.copyWith(canAddClient: val, canEditClient: val);
                            provider.updateUserPermissions(user.id, updated);
                          },
                        ),
                        _buildSwitch(
                          title: 'تسعير الخدمة ونوع الشيفت (12 أو 24 ساعة)',
                          subtitle: 'تحديد السعر اليومي وإسناد نوع التمريض (الحسابات - زيزو)',
                          value: user.permissions.canSetPrice,
                          onChanged: (val) {
                            final updated = user.permissions.copyWith(canSetPrice: val);
                            provider.updateUserPermissions(user.id, updated);
                          },
                        ),
                        _buildSwitch(
                          title: 'تسجيل بدء الخدمة',
                          subtitle: 'تفعيل العداد وبدء الخدمة عند نزول التمريض (شيماء)',
                          value: user.permissions.canStartService,
                          onChanged: (val) {
                            final updated = user.permissions.copyWith(canStartService: val);
                            provider.updateUserPermissions(user.id, updated);
                          },
                        ),
                        _buildSwitch(
                          title: 'إنهاء الخدمة يدوياً لتعثر السداد',
                          subtitle: 'إيقاف الخدمة في حالة تعثر العميل عن دفع المستحقات (زيزو)',
                          value: user.permissions.canEndService,
                          onChanged: (val) {
                            final updated = user.permissions.copyWith(canEndService: val);
                            provider.updateUserPermissions(user.id, updated);
                          },
                        ),
                        _buildSwitch(
                          title: 'تسجيل المقبوضات والدفعات النقدية',
                          subtitle: 'استلام مبالغ من العميل نقداً أو تحويل بنكي',
                          value: user.permissions.canRecordPayment,
                          onChanged: (val) {
                            final updated = user.permissions.copyWith(canRecordPayment: val);
                            provider.updateUserPermissions(user.id, updated);
                          },
                        ),
                        _buildSwitch(
                          title: 'تسجيل مصروفات الشركة',
                          subtitle: 'رواتب تمريض، انتقالات، مستلزمات طبية',
                          value: user.permissions.canRecordExpense,
                          onChanged: (val) {
                            final updated = user.permissions.copyWith(canRecordExpense: val);
                            provider.updateUserPermissions(user.id, updated);
                          },
                        ),
                        _buildSwitch(
                          title: 'الاطلاع على التقارير المالية وصافي الأرباح',
                          subtitle: 'مشاهدة إجمالي الإيرادات والمصروفات والأرباح التشغيلية',
                          value: user.permissions.canViewFinancialReports,
                          onChanged: (val) {
                            final updated = user.permissions.copyWith(canViewFinancialReports: val);
                            provider.updateUserPermissions(user.id, updated);
                          },
                        ),
                        _buildSwitch(
                          title: 'تعديل أو حذف أي بيان (صلاحية خاصة)',
                          subtitle: 'تعديل أو تصحيح سجلات سابقة للمستخدمين الآخرين',
                          value: user.permissions.canEditAnyData,
                          onChanged: (val) {
                            final updated = user.permissions.copyWith(canEditAnyData: val);
                            provider.updateUserPermissions(user.id, updated);
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'Cairo'),
        ),
        value: value,
        activeColor: AppTheme.accent,
        onChanged: onChanged,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppProvider provider, UserModel user) {
    final passController = TextEditingController(text: user.password);
    bool obscure = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.lock_reset, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('تغيير كلمة مرور @${user.username}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الحساب: ${user.displayName} (${user.roleTitle})', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.primary)),
                const SizedBox(height: 14),
                TextField(
                  controller: passController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDlgState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
              ElevatedButton.icon(
                onPressed: () async {
                  final newPass = passController.text.trim();
                  if (newPass.isNotEmpty) {
                    await provider.changePassword(user.id, newPass);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تحديث كلمة المرور لحساب @${user.username} بنجاح ومزامنتها سحابياً', style: const TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save, size: 18),
                label: const Text('حفظ كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, AppProvider provider, UserModel user) {
    final nameController = TextEditingController(text: user.displayName);
    final roleController = TextEditingController(text: user.roleTitle);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('تعديل مسمى @${user.username}', style: const TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم المعروض',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'المسمى الوظيفي',
                  hintText: 'مثال: مشرف تمريض ميداني / خدمة عملاء',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty && roleController.text.trim().isNotEmpty) {
                  await provider.updateUserDetails(
                    userId: user.id,
                    displayName: nameController.text.trim(),
                    roleTitle: roleController.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
