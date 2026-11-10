import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/caregiver_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'add_edit_caregiver_dialog.dart';

class CaregiverDetailDialog extends StatelessWidget {
  final CaregiverModel caregiver;

  const CaregiverDetailDialog({super.key, required this.caregiver});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final canEdit = provider.canManageCaregivers;
    final isZezo = provider.currentUser?.username == 'zezo';
    final currentCase = provider.getCaregiverCurrentCase(caregiver.name);
    final pastClients = provider.getCaregiverPastClients(caregiver.name);
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 680,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Row(
              children: [
                // Avatar with Rating
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: caregiver.isBlocked
                          ? Colors.red.shade100
                          : (currentCase != null || caregiver.isCurrentlyWorking
                              ? Colors.green.shade100
                              : AppTheme.primary.withOpacity(0.12)),
                      child: Icon(
                        caregiver.isBlocked ? Icons.person_off : Icons.medical_services_rounded,
                        color: caregiver.isBlocked
                            ? Colors.red
                            : (currentCase != null || caregiver.isCurrentlyWorking ? Colors.green : AppTheme.primary),
                        size: 32,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 10, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            caregiver.rating.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            caregiver.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                          const SizedBox(width: 8),
                          // Code Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: Text(
                              caregiver.code,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.indigo),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caregiver.qualification.isNotEmpty ? caregiver.qualification : 'مقدم خدمة ورعاية صحية',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 24),

            // Read-only indicator for Zezo
            if (isZezo) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'وضع الاطلاع فقط: مصرح لحساب أ/ زيزو الاطلاع والمراجعة الكاملة بدون تعديل.',
                      style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF78350F), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],

            // Status Banner: Currently working OR Blocked OR Available
            if (caregiver.isBlocked) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مقدم الخدمة محظور حالياً (Blacklisted)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontFamily: 'Cairo', fontSize: 13),
                          ),
                          Text(
                            'سبب الحظر: ${caregiver.blockReason ?? "مشاكل في العمل"}',
                            style: TextStyle(color: Colors.red.shade900, fontFamily: 'Cairo', fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (currentCase != null || caregiver.isCurrentlyWorking) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'شغال معانا الآن وفي حالة قائمة:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontFamily: 'Cairo', fontSize: 13),
                          ),
                          Text(
                            'اسم الحالة: ${currentCase ?? caregiver.currentClientName ?? "حالة نشطة"}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF14532D), fontFamily: 'Cairo', fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.event_available, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'متاح للتشغيل واستلام حالات جديدة',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'Cairo', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            // Scrollable Details
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grid / Cards for Key Properties
                    Row(
                      children: [
                        // Shift preference
                        Expanded(
                          child: _buildInfoCard(
                            title: 'نظام العمل',
                            value: caregiver.shiftPreferenceArabic,
                            icon: Icons.timelapse,
                            iconColor: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Daily rate
                        Expanded(
                          child: _buildInfoCard(
                            title: 'السعر الافتراضي لليوم',
                            value: '${caregiver.dailyPrice.toStringAsFixed(0)} ج.م',
                            icon: Icons.payments,
                            iconColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        // Physical Specs
                        Expanded(
                          child: _buildInfoCard(
                            title: 'الوزن والطول',
                            value: (caregiver.weight != null || caregiver.height != null)
                                ? '${caregiver.weight != null ? "${caregiver.weight!.toStringAsFixed(0)} كجم" : ""} - ${caregiver.height != null ? "${caregiver.height!.toStringAsFixed(0)} سم" : ""}'
                                : 'غير مسجل',
                            icon: Icons.accessibility_new,
                            iconColor: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Residence Area
                        Expanded(
                          child: _buildInfoCard(
                            title: 'مكان السكن',
                            value: caregiver.residenceArea.isNotEmpty ? caregiver.residenceArea : 'غير محدد',
                            icon: Icons.location_city,
                            iconColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Phone & National ID
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // Phone
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 18, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text('رقم التليفون:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                              const SizedBox(width: 8),
                              Text(
                                caregiver.phone.isNotEmpty ? caregiver.phone : 'غير مسجل',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14),
                              ),
                              const Spacer(),
                              if (caregiver.phone.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                                  tooltip: 'نسخ رقم الهاتف',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: caregiver.phone));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم نسخ رقم الهاتف', style: TextStyle(fontFamily: 'Cairo'))),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const Divider(height: 16),
                          // National ID
                          Row(
                            children: [
                              const Icon(Icons.credit_card, size: 18, color: Colors.teal),
                              const SizedBox(width: 8),
                              const Text('الرقم القومي:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                              const SizedBox(width: 8),
                              Text(
                                caregiver.nationalId.isNotEmpty ? caregiver.nationalId : 'غير مسجل',
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              ),
                            ],
                          ),
                          if (caregiver.address.isNotEmpty) ...[
                            const Divider(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.home_outlined, size: 18, color: Colors.purple),
                                const SizedBox(width: 8),
                                const Text('العنوان:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    caregiver.address,
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Clients Worked with (أسماء العملاء الذين اشتغل معهم)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_edu, size: 18, color: Colors.indigo),
                              const SizedBox(width: 8),
                              const Text(
                                'العملاء والحالات التي اشتغل معها في الشركة:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13, color: Colors.indigo),
                              ),
                              const Spacer(),
                              Text(
                                '${pastClients.length} عميل',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.indigo),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (pastClients.isNotEmpty) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: pastClients.map((client) {
                                return Chip(
                                  avatar: const Icon(Icons.person, size: 14, color: Colors.indigo),
                                  label: Text(client, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.indigo.shade200),
                                );
                              }).toList(),
                            ),
                          ] else ...[
                            const Text(
                              'لم يتم تسجيل عملاء سابقين له حتى الآن',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Additional Notes
                    if (caregiver.notes != null && caregiver.notes!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ملاحظات إضافية:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(caregiver.notes!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Meta: Created date & by
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تاريخ التسجيل: ${dateFormat.format(caregiver.createdAt)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                        ),
                        Text(
                          'بواسطة: ${caregiver.createdBy}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),

            // Dialog Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (canEdit && !isZezo) ...[
                  // Block / Unblock Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      if (caregiver.isBlocked) {
                        await provider.toggleCaregiverBlock(caregiver.id, isBlocked: false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم إلغاء حظر مقدم الخدمة: ${caregiver.name}', style: const TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        _showBlockConfirmDialog(context, provider, caregiver);
                      }
                    },
                    icon: Icon(caregiver.isBlocked ? Icons.check_circle : Icons.block, size: 16),
                    label: Text(
                      caregiver.isBlocked ? 'إلغاء الحظر' : 'حظر لمشاكل',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: caregiver.isBlocked ? Colors.green : Colors.red,
                      side: BorderSide(color: caregiver.isBlocked ? Colors.green : Colors.red),
                    ),
                  ),
                ] else ...[
                  const SizedBox.shrink(),
                ],

                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                    if (canEdit && !isZezo) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) => AddEditCaregiverDialog(caregiver: caregiver),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('تعديل البيانات', style: TextStyle(fontFamily: 'Cairo')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmDialog(BuildContext context, AppProvider provider, CaregiverModel caregiver) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد حظر مقدم الخدمة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حظر: ${caregiver.name}؟', style: const TextStyle(fontFamily: 'Cairo')),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'نوع المشكلة وسبب الحظر *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              await provider.toggleCaregiverBlock(caregiver.id, isBlocked: true, reason: reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('تأكيد الحظر', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
