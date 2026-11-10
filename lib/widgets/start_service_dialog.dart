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
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isOpenEnded = false;
  late TextEditingController _nurseController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate.add(const Duration(days: 7));
    _nurseController = TextEditingController(text: widget.client.nurseAssigned ?? '');
  }

  @override
  void dispose() {
    _nurseController.dispose();
    super.dispose();
  }

  int get _selectedDaysCount {
    if (_endDate.isBefore(_startDate)) return 1;
    return _endDate.difference(_startDate).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');

    final daysCount = _selectedDaysCount;
    final totalClientCost = daysCount * widget.client.dailyPrice;
    final totalNurseCost = daysCount * widget.client.nurseDailyPrice;
    final totalProfit = totalClientCost - totalNurseCost;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 520,
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
                            'تأكيد بدء الخدمة وتحديد فترة التعاقد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            'تسجيل مديرة المتابعة (شيماء) / الإدارة',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Client Info Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.client.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
                            ),
                            Text(
                              '${widget.client.serviceTypeArabic} | سعر اليوم: ${widget.client.dailyPrice.toStringAsFixed(0)} ج.م | يومية التمريض: ${widget.client.nurseDailyPrice.toStringAsFixed(0)} ج.م',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Duration Mode Switcher (محددة vs مفتوحة)
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
                              _isOpenEnded = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isOpenEnded ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !_isOpenEnded
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
                                  Icons.date_range,
                                  size: 18,
                                  color: !_isOpenEnded ? AppTheme.primary : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'مدة محددة (بتاريخ نهاية)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Cairo',
                                    fontWeight: !_isOpenEnded ? FontWeight.bold : FontWeight.normal,
                                    color: !_isOpenEnded ? AppTheme.primary : Colors.grey.shade700,
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
                              _isOpenEnded = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isOpenEnded ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _isOpenEnded
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
                                  color: _isOpenEnded ? Colors.teal : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'مدة مفتوحة (مستمرة)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Cairo',
                                    fontWeight: _isOpenEnded ? FontWeight.bold : FontWeight.normal,
                                    color: _isOpenEnded ? Colors.teal : Colors.grey.shade700,
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

                // Calendars Section
                Row(
                  children: [
                    // Calendar 1: Start Date
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 60)),
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = DateTime(picked.year, picked.month, picked.day);
                              if (_endDate.isBefore(_startDate)) {
                                _endDate = _startDate.add(const Duration(days: 7));
                              }
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    '1. بداية الخدمة:',
                                    style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dateFormat.format(_startDate),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Calendar 2: End Date (or Open Ended Badge)
                    Expanded(
                      child: _isOpenEnded
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.all_inclusive, size: 16, color: Colors.teal),
                                      SizedBox(width: 6),
                                      Text(
                                        '2. نهاية الخدمة:',
                                        style: TextStyle(fontSize: 11, color: Colors.teal, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'مدة مفتوحة (مستمرة)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: Colors.teal),
                                  ),
                                ],
                              ),
                            )
                          : InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: _startDate.add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _endDate = DateTime(picked.year, picked.month, picked.day);
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.event_available, size: 16, color: Colors.deepOrange),
                                        SizedBox(width: 6),
                                        Text(
                                          '2. نهاية الخدمة:',
                                          style: TextStyle(fontSize: 11, color: Colors.deepOrange, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      dateFormat.format(_endDate),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),

                // Quick Duration Shortcuts (if not open ended)
                if (!_isOpenEnded) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('+ 7 أيام (أسبوع)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            _endDate = _startDate.add(const Duration(days: 6));
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('+ 14 يوم (أسبوعين)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            _endDate = _startDate.add(const Duration(days: 13));
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('+ 30 يوم (شهر)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            _endDate = _startDate.add(const Duration(days: 29));
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Contract Calculation Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'مدة التعاقد المحددة: $daysCount يوم',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: AppTheme.primary),
                            ),
                            Text(
                              'إجمالي قيمة التعاقد: ${totalClientCost.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: AppTheme.accent),
                            ),
                          ],
                        ),
                        if (widget.client.nurseDailyPrice > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'مستحق التمريض: ${totalNurseCost.toStringAsFixed(0)} ج.م',
                                style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.grey.shade700),
                              ),
                              Text(
                                'مكسب الشركة المتوقع: ${totalProfit.toStringAsFixed(0)} ج.م',
                                style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.teal, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.teal, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تم اختيار مدة مفتوحة: سيبدأ العداد الآلي بحساب الأيام والمستحقات يومياً بشكل مستمر، ويسمح بمد أو إنهاء الخدمة في أي وقت لاحقاً.',
                            style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF134E4A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                TextField(
                  controller: _nurseController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الممرض / الممرضة القائم بالخدمة',
                    prefixIcon: Icon(Icons.badge_outlined),
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
                          final nurseName = _nurseController.text.trim();
                          if (nurseName.isNotEmpty) {
                            widget.client.nurseAssigned = nurseName;
                          }
                          await provider.startClientService(
                            clientId: widget.client.id,
                            startDate: _startDate,
                            endDate: _isOpenEnded ? null : _endDate,
                            isOpenEnded: _isOpenEnded,
                            nurseAssigned: nurseName.isNotEmpty ? nurseName : null,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isOpenEnded
                                      ? 'تم بدء الخدمة بمدة مفتوحة ومستمرة'
                                      : 'تم بدء الخدمة بنجاح لمدة $daysCount يوم (حتى ${dateFormat.format(_endDate)})',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
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
      ),
    );
  }
}
