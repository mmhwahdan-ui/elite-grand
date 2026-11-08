import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class StopServiceDialog extends StatefulWidget {
  final ClientModel client;

  const StopServiceDialog({super.key, required this.client});

  @override
  State<StopServiceDialog> createState() => _StopServiceDialogState();
}

class _StopServiceDialogState extends State<StopServiceDialog> {
  late DateTime _endDate;
  String _selectedReason = 'تعثر العميل في سداد المستحقات';
  late TextEditingController _customReasonController;
  bool _isDefaulting = true;

  final List<String> _commonReasons = [
    'تعثر العميل في سداد المستحقات',
    'تأخر الدفعات بالرغم من التنبيه المتكرر',
    'طلب العميل إيقاف الخدمة مؤقتاً',
    'اكتمال فترة العلاج والشفاء بحمد الله',
    'انتقال المريض للمستشفى',
    'أسباب أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _customReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');
    final balance = provider.getClientBalance(widget.client);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.redDebt.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stop_circle_outlined, color: AppTheme.redDebt, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إنهاء الخدمة يدوياً',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: AppTheme.redDebt,
                            ),
                          ),
                          Text(
                            'بقرار مدير الحسابات (زيزو) أو المدير العام',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Client Summary & Dues Warning
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'العميل: ${widget.client.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'إجمالي مدة الخدمة: ${widget.client.servedDays} يوم | تكلفة الخدمة: ${widget.client.totalServiceCost.toStringAsFixed(0)} ج.م',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 6),
                      if (balance < 0)
                        Text(
                          '⚠️ مستحقات للشركة متأخرة عند العميل: ${balance.abs().toStringAsFixed(0)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.redDebt, fontFamily: 'Cairo'),
                        )
                      else if (balance > 0)
                        Text(
                          'مستحقات للعميل رصيد متبقي: ${balance.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.greenCredit, fontFamily: 'Cairo'),
                        )
                      else
                        const Text(
                          'الحساب خالص تماماً',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Cairo'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // End Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: widget.client.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_busy, color: AppTheme.redDebt),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'تاريخ انتهاء الخدمة: ${dateFormat.format(_endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'سبب إنهاء الخدمة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: _commonReasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedReason = val;
                        _isDefaulting = val.contains('تعثر') || val.contains('تأخر');
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customReasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات وتفاصيل إضافية عن الإنهاء',
                    hintText: 'مثال: تم الاتصال بأهل المريض لإبلاغهم بوقف الخدمة لحين السداد',
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
                          final fullReason = _customReasonController.text.trim().isNotEmpty
                              ? '$_selectedReason - ${_customReasonController.text.trim()}'
                              : _selectedReason;

                          await provider.endClientService(
                            clientId: widget.client.id,
                            reason: fullReason,
                            isDueToPaymentDefault: _isDefaulting,
                            endDate: _endDate,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم إنهاء الخدمة وتجميد المستحقات', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: AppTheme.redDebt,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.redDebt,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('تأكيد إنهاء الخدمة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
}
