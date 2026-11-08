import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

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
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppTheme.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لوحة تحكم المدير العام (أ/ وهدان)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                        ),
                        Text(
                          'تخصيص وتوزيع الصلاحيات وتغيير كلمات المرور لجميع الحسابات الـ 5',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                        ),
                      ],
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '@${user.username}',
                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
          subtitle: Text(
            user.roleTitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
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

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('تغيير كلمة مرور @${user.username}', style: const TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الحساب: ${user.displayName} (${user.roleTitle})', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              const SizedBox(height: 14),
              TextField(
                controller: passController,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة *',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (passController.text.trim().isNotEmpty) {
                  await provider.changePassword(user.id, passController.text.trim());
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم تحديث كلمة المرور لحساب @${user.username} بنجاح', style: const TextStyle(fontFamily: 'Cairo')),
                        backgroundColor: AppTheme.accent,
                      ),
                    );
                  }
                }
              },
              child: const Text('حفظ كلمة المرور'),
            ),
          ],
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
