import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class StartServiceDialog extends StatefulWidget {
  final ClientModel client;

  const StartServiceDialog({super.key, required this.client});

  @override
  State<StartServiceDialog> createState() => _StartServiceDialogState();
}

class _StartServiceDialogState extends State<StartServiceDialog> {
  late DateTime _selectedDate;
  late TextEditingController _nurseController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _nurseController = TextEditingController(text: widget.client.nurseAssigned ?? '');
  }

  @override
  void dispose() {
    _nurseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_circle_fill, color: AppTheme.accent, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تأكيد بدء الخدمة والتمريض',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          'تسجيل مديرة المتابعة (شيماء)',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'العميل: ${widget.client.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 4),
              Text(
                'الخدمة: ${widget.client.serviceTypeArabic} | السعر: ${widget.client.dailyPrice} ج.م / يوم',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 16),
              // Date picker tile
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 7)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تاريخ بدء الخدمة الفعلي:',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                            ),
                            Text(
                              dateFormat.format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nurseController,
                decoration: const InputDecoration(
                  labelText: 'اسم الممرض / الممرضة القائم بالخدمة',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'عند تأكيد البدء، سيبدأ العداد الآلي لحساب المستحقات اليومية للشركة على العميل تلقائياً.',
                        style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF78350F)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_nurseController.text.trim().isNotEmpty) {
                          widget.client.nurseAssigned = _nurseController.text.trim();
                        }
                        await provider.startClientService(
                          clientId: widget.client.id,
                          startDate: _selectedDate,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم بدء الخدمة وبدء احتساب الأيام والمستحقات', style: TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: AppTheme.accent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('تأكيد بدء الخدمة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    ),
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
