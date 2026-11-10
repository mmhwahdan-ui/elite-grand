import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ExtendServiceDialog extends StatefulWidget {
  final ClientModel client;

  const ExtendServiceDialog({super.key, required this.client});

  @override
  State<ExtendServiceDialog> createState() => _ExtendServiceDialogState();
}

class _ExtendServiceDialogState extends State<ExtendServiceDialog> {
  late DateTime _newEndDate;
  late bool _makeOpenEnded;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _makeOpenEnded = widget.client.isOpenEnded;

    if (widget.client.endDate != null) {
      // If current endDate is in the past, default new endDate to today + 7 days
      final currentEnd = DateTime(
        widget.client.endDate!.year,
        widget.client.endDate!.month,
        widget.client.endDate!.day,
      );
      _newEndDate = currentEnd.isBefore(today)
          ? today.add(const Duration(days: 7))
          : currentEnd.add(const Duration(days: 7));
    } else {
      _newEndDate = today.add(const Duration(days: 7));
    }

    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');

    final startDate = widget.client.startDate ?? DateTime.now();
    final int newTotalDays = _newEndDate.difference(startDate).inDays + 1;
    final int servedSoFar = widget.client.servedDays;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
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
                        color: Colors.indigo.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.update, color: Colors.indigo, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تمديد أو فتح مدة الخدمة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            'بناءً على طلب العميل لمَد فترة الرعاية',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Current State Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'العميل: ${widget.client.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'تاريخ البدء: ${widget.client.startDate != null ? dateFormat.format(widget.client.startDate!) : '-'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                          ),
                          const Spacer(),
                          Text(
                            widget.client.isOpenEnded
                                ? 'الوضع الحالي: مدة مفتوحة'
                                : 'تاريخ النهاية الحالي: ${dateFormat.format(widget.client.endDate!)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الأيام المنقضية حتى الآن: $servedSoFar يوم',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Choice: Extend with new End Date vs Make Open Ended
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _makeOpenEnded = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_makeOpenEnded ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !_makeOpenEnded
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 18,
                                  color: !_makeOpenEnded ? Colors.indigo : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'تمديد لتاريخ محدد',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Cairo',
                                    fontWeight: !_makeOpenEnded ? FontWeight.bold : FontWeight.normal,
                                    color: !_makeOpenEnded ? Colors.indigo : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _makeOpenEnded = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _makeOpenEnded ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _makeOpenEnded
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.all_inclusive,
                                  size: 18,
                                  color: _makeOpenEnded ? Colors.teal : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'فتح المدة (مستمرة)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Cairo',
                                    fontWeight: _makeOpenEnded ? FontWeight.bold : FontWeight.normal,
                                    color: _makeOpenEnded ? Colors.teal : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (!_makeOpenEnded) ...[
                  // Date Picker for New End Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _newEndDate,
                        firstDate: widget.client.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _newEndDate = DateTime(picked.year, picked.month, picked.day);
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.indigo),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تاريخ نهاية الخدمة الجديد بعد التمديد:',
                                  style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontFamily: 'Cairo'),
                                ),
                                Text(
                                  dateFormat.format(_newEndDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo', color: Colors.indigo),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Extension Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('+ 3 أيام', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            final base = widget.client.endDate ?? DateTime.now();
                            _newEndDate = base.add(const Duration(days: 3));
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('+ 7 أيام (أسبوع)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            final base = widget.client.endDate ?? DateTime.now();
                            _newEndDate = base.add(const Duration(days: 7));
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('+ 14 يوم (أسبوعين)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            final base = widget.client.endDate ?? DateTime.now();
                            _newEndDate = base.add(const Duration(days: 14));
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('+ 30 يوم (شهر)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            final base = widget.client.endDate ?? DateTime.now();
                            _newEndDate = base.add(const Duration(days: 30));
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Updated totals calculation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'إجمالي أيام التعاقد الجديد: $newTotalDays يوم',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo', color: Colors.indigo),
                        ),
                        Text(
                          'إجمالي التعاقد: ${(newTotalDays * widget.client.dailyPrice).toStringAsFixed(0)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo', color: Colors.indigo),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Open-ended banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.all_inclusive, color: Colors.teal, size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'سيتم فتح مدة الخدمة لتكون مستمرة بدون تاريخ نهاية محدد. سيواصل النظام احتساب الأيام آلياً يوماً بيوم حتى يطلب العميل إنهاء الخدمة.',
                            style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF134E4A), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات التمديد (اختياري)',
                    hintText: 'مثال: طلب العميل مد الخدمة أسبوعاً إضافياً',
                    prefixIcon: Icon(Icons.note_alt_outlined),
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
                          final note = _notesController.text.trim();
                          await provider.extendOrUpdateServiceDuration(
                            clientId: widget.client.id,
                            newEndDate: _makeOpenEnded ? null : _newEndDate,
                            makeOpenEnded: _makeOpenEnded,
                            note: note.isNotEmpty ? note : 'تم تمديد/تعديل مدة الخدمة',
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _makeOpenEnded
                                      ? 'تم فتح مدة الخدمة لتكون مستمرة بنجاح'
                                      : 'تم تمديد الخدمة بنجاح حتى ${dateFormat.format(_newEndDate)}',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                                backgroundColor: Colors.indigo,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('حفظ التمديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
