import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/management_instruction_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ManagementInstructionsDialog extends StatelessWidget {
  final bool isCaregiverView;

  const ManagementInstructionsDialog({
    super.key,
    this.isCaregiverView = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isAdmin = provider.isAdmin || provider.canManageCaregivers;
    final instructions = isCaregiverView
        ? provider.activeManagementInstructions
        : provider.managementInstructions;

    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 720,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.all(22),
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
                      color: const Color(0xFF312E81).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.gavel_rounded, color: Color(0xFF312E81), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'لوحة تعليمات وتوجيهات الإدارة 📋',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        Text(
                          isCaregiverView
                              ? 'اللوائح والتعليمات الرسمية الملزمة لجميع مقدمي الخدمة والتمريض'
                              : 'إدارة ونشر لوائح وتوجيهات الإدارة التي تظهر لجميع أطقم التمريض',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin && !isCaregiverView) ...[
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditInstructionDialog(context, provider),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة لائحة جديدة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Instructions List
              Expanded(
                child: instructions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد لوائح أو تعليمات منشورة حالياً',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: instructions.length,
                        itemBuilder: (ctx, idx) {
                          final item = instructions[idx];
                          final isUrgent = item.priority == 'urgent';
                          final isImportant = item.priority == 'important';

                          final cardColor = isUrgent
                              ? const Color(0xFFFEF2F2)
                              : (isImportant ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC));
                          final borderColor = isUrgent
                              ? const Color(0xFFFCA5A5)
                              : (isImportant ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0));
                          final tagColor = isUrgent
                              ? Colors.red.shade800
                              : (isImportant ? Colors.amber.shade900 : Colors.indigo.shade800);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: borderColor, width: isUrgent ? 1.5 : 1.0),
                            ),
                            color: cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row: Priority Badge + Title + Actions
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: tagColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          item.priorityArabic,
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: tagColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (isAdmin && !isCaregiverView) ...[
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                          tooltip: 'تعديل',
                                          onPressed: () => _showAddEditInstructionDialog(context, provider, item),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            item.isActive ? Icons.visibility : Icons.visibility_off,
                                            size: 18,
                                            color: item.isActive ? Colors.green : Colors.grey,
                                          ),
                                          tooltip: item.isActive ? 'مفعلة (ظاهرة للتمريض)' : 'معطلة (مخفية)',
                                          onPressed: () => provider.toggleManagementInstructionActive(item.id, !item.isActive),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          tooltip: 'حذف',
                                          onPressed: () => _showDeleteConfirmDialog(context, provider, item),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Content Body
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Text(
                                      item.content,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12.5,
                                        height: 1.5,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Signature / Footer
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.verified, size: 14, color: Color(0xFF4338CA)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'صادر عن: ${item.authorName} (${item.authorRole})',
                                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'تاريخ الإصدار: ${dateFormat.format(item.createdAt)}',
                                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),

              // Bottom Confirmation or Close Button
              if (isCaregiverView) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم تأكيد قراءة وفهم تعليمات إدارة إيليت جراند بنجاح ✅',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: Color(0xFF047857),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text(
                    'قرأت جميع التعليمات وأتعهد بالالتزام بها كاملاً ✅',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق اللوحة', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditInstructionDialog(BuildContext context, AppProvider provider, [ManagementInstructionModel? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    String priority = existing?.priority ?? 'important';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(existing == null ? Icons.post_add : Icons.edit_note, color: AppTheme.accent),
                const SizedBox(width: 8),
                Text(
                  existing == null ? 'إضافة لائحة تعليمات جديدة' : 'تعديل لائحة التعليمات',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('عنوان اللائحة / التوجيه:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'مثال: تعليمات الالتزام بالمواعيد والزي الرسمي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('درجة الأهمية والإلزام:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'urgent', child: Text('🚨 عاجل وملزم فوراً', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red))),
                      DropdownMenuItem(value: 'important', child: Text('⭐ هام وضروري', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.amber))),
                      DropdownMenuItem(value: 'normal', child: Text('📋 تعليمات عامة', style: TextStyle(fontFamily: 'Cairo'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => priority = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('نص التعليمات والتوجيهات (نقاط تفصيلية):', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'اكتب بنود اللائحة والتوجيهات هنا بالتفصيل...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final content = contentCtrl.text.trim();
                  if (title.isEmpty || content.isEmpty) return;

                  Navigator.pop(ctx);
                  if (existing == null) {
                    await provider.addManagementInstruction(
                      title: title,
                      content: content,
                      priority: priority,
                    );
                  } else {
                    await provider.updateManagementInstruction(
                      existing.copyWith(
                        title: title,
                        content: content,
                        priority: priority,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
                child: Text(existing == null ? 'نشر اللائحة' : 'حفظ التعديلات', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, AppProvider provider, ManagementInstructionModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('هل أنت متأكد من حذف لائحة: "${item.title}" نهائياً؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteManagementInstruction(item.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
