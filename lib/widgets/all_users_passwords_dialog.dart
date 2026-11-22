import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class AllUsersPasswordsDialog extends StatefulWidget {
  const AllUsersPasswordsDialog({super.key});

  @override
  State<AllUsersPasswordsDialog> createState() => _AllUsersPasswordsDialogState();
}

class _AllUsersPasswordsDialogState extends State<AllUsersPasswordsDialog> {
  String _searchQuery = '';
  final Set<String> _visiblePasswordUserIds = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final users = provider.users;

    final filteredUsers = users.where((u) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return u.displayName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.roleTitle.toLowerCase().contains(q) ||
          u.password.toLowerCase().contains(q);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 620,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(22),
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
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.vpn_key_rounded, color: Colors.amber, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كشف كلمات مرور المستخدمين 🔑',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'خاص بالمدير العام (أ/ وهدان) - استعراض ونسخ وتعديل كلمات المرور لجميع الحسابات',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar & Copy All Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'بحث باسم المستخدم أو الحساب أو الدور...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final buffer = StringBuffer();
                      buffer.writeln('=== كشف بيانات الدخول وكلمات المرور - إيليت جراند ===');
                      for (final u in users) {
                        buffer.writeln('${u.displayName} (@${u.username}) [${u.roleTitle}] -> كلمة المرور: ${u.password}');
                      }
                      Clipboard.setData(ClipboardData(text: buffer.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ بيانات الدخول لكافة المستخدمين إلى الحافظة بنجاح 📋', style: TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_all, size: 16),
                    label: const Text('نسخ الكل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Users List
              Expanded(
                child: filteredUsers.isEmpty
                    ? const Center(
                        child: Text('لا يوجد مستخدمين مطابقين للبحث', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                      )
                    : ListView.separated(
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isWahdan = user.username == 'wahdan';
                          final isPasswordVisible = _visiblePasswordUserIds.contains(user.id) || true; // Always visible for Wahdan

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isWahdan ? Colors.amber.shade50.withOpacity(0.4) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isWahdan ? Colors.amber.shade300 : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isWahdan ? AppTheme.primary : AppTheme.primaryLight.withOpacity(0.15),
                                  foregroundColor: isWahdan ? Colors.white : AppTheme.primaryLight,
                                  child: Icon(
                                    isWahdan
                                        ? Icons.star
                                        : user.isNurse
                                            ? Icons.medical_services_outlined
                                            : Icons.person_outline,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user.displayName,
                                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '@${user.username}',
                                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.blueGrey),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        user.roleTitle,
                                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Password Badge with Copy & Edit
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade400, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.key, size: 14, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      SelectableText(
                                        user.password,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 15, color: Colors.blueGrey),
                                        tooltip: 'نسخ كلمة المرور',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: user.password));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('تم نسخ كلمة مرور @${user.username} بنجاح (${user.password})', style: const TextStyle(fontFamily: 'Cairo')),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Edit Password Button
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                                  tooltip: 'تغيير كلمة المرور',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showChangePasswordDialog(context, provider, user),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),

              // Footer Note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.primary, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ملاحظة أمان: هذا الكشف مخصص للمدير العام فقط لتزويد الموظفين ببيانات الدخول عند نسيانها.',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                      setState(() {});
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
}
