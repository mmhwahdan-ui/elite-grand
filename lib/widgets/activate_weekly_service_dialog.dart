import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/caregiver_model.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ActivateWeeklyServiceDialog extends StatefulWidget {
  final ClientModel client;

  const ActivateWeeklyServiceDialog({super.key, required this.client});

  @override
  State<ActivateWeeklyServiceDialog> createState() => _ActivateWeeklyServiceDialogState();
}

class _ActivateWeeklyServiceDialogState extends State<ActivateWeeklyServiceDialog> {
  late DateTime _weekStartDate;
  late TextEditingController _clientPriceCtrl;
  late TextEditingController _nursePriceCtrl;
  late TextEditingController _nurseNameCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _nurseBalanceCtrl;
  String _nurseBalanceType = 'zero'; // 'due', 'debt', 'zero'
  bool _hasInitializedNurseBalance = false;
  final Set<int> _selectedDayIndices = {}; // 0 to 6
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // In Egypt/Arab world, week typically starts Saturday (weekday 6 in ISO)
    // Find most recent Saturday (or today if Saturday)
    int diffToSaturday = (now.weekday == DateTime.saturday)
        ? 0
        : (now.weekday == DateTime.sunday)
            ? 1
            : (now.weekday + 1); // e.g. Mon(1)+1=2 days ago sat
    _weekStartDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: diffToSaturday));

    _clientPriceCtrl = TextEditingController(
      text: widget.client.dailyPrice > 0 ? widget.client.dailyPrice.toStringAsFixed(0) : '',
    );
    _nursePriceCtrl = TextEditingController(
      text: widget.client.nurseDailyPrice > 0 ? widget.client.nurseDailyPrice.toStringAsFixed(0) : '',
    );
    _nurseNameCtrl = TextEditingController(text: widget.client.nurseAssigned ?? '');
    _notesCtrl = TextEditingController();
    _nurseBalanceCtrl = TextEditingController(text: '0');

    // Pre-select days based on client's active weekdays if defined
    if (widget.client.activeWeekdays.isNotEmpty) {
      for (int i = 0; i < 7; i++) {
        final d = _weekStartDate.add(Duration(days: i));
        if (widget.client.activeWeekdays.contains(d.weekday)) {
          _selectedDayIndices.add(i);
        }
      }
    } else {
      // Default select first days_per_week or 4 days
      final count = widget.client.daysPerWeek > 0 ? widget.client.daysPerWeek : 4;
      for (int i = 0; i < count && i < 7; i++) {
        _selectedDayIndices.add(i);
      }
    }
  }

  @override
  void dispose() {
    _clientPriceCtrl.dispose();
    _nursePriceCtrl.dispose();
    _nurseNameCtrl.dispose();
    _notesCtrl.dispose();
    _nurseBalanceCtrl.dispose();
    super.dispose();
  }

  String _getDayArabicName(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final nurseList = provider.allNurseNames;
    final clientPrice = double.tryParse(_clientPriceCtrl.text.trim()) ?? 0.0;
    final nursePrice = double.tryParse(_nursePriceCtrl.text.trim()) ?? 0.0;
    final selectedCount = _selectedDayIndices.length;
    final totalClientCost = selectedCount * clientPrice;
    final totalNurseCost = selectedCount * nursePrice;
    final totalProfit = totalClientCost - totalNurseCost;

    final weekEndDate = _weekStartDate.add(const Duration(days: 6));
    final dateRangeStr = '${DateFormat('MM/dd').format(_weekStartDate)} إلى ${DateFormat('MM/dd').format(weekEndDate)}';

    // مقدم الخدمة المحدد وحسابه المالي
    final selectedNurse = _nurseNameCtrl.text.trim();
    CaregiverModel? matchedCaregiver;
    if (selectedNurse.isNotEmpty) {
      final list = provider.caregivers.where((c) => provider.isNurseNameMatch(c.name, selectedNurse)).toList();
      if (list.isNotEmpty) matchedCaregiver = list.first;
    }

    if (!_hasInitializedNurseBalance && matchedCaregiver != null) {
      _hasInitializedNurseBalance = true;
      if (matchedCaregiver.openingBalance > 0) {
        _nurseBalanceType = 'due';
        _nurseBalanceCtrl.text = matchedCaregiver.openingBalance.toStringAsFixed(0);
      } else if (matchedCaregiver.openingBalance < 0) {
        _nurseBalanceType = 'debt';
        _nurseBalanceCtrl.text = matchedCaregiver.openingBalance.abs().toStringAsFixed(0);
      }
    }

    final nurseEarned = selectedNurse.isNotEmpty ? provider.getNurseTotalEarned(selectedNurse) : 0.0;
    final nurseAdvances = selectedNurse.isNotEmpty ? provider.getNurseTotalAdvances(selectedNurse) : 0.0;
    final nurseRemaining = selectedNurse.isNotEmpty ? provider.getNurseRemainingBalance(selectedNurse) : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 740),
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
                        color: Colors.deepPurple.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flash_on, color: Colors.deepPurple, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفعيل الخدمة الأسبوعي ⚡',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'العميل: ${widget.client.name} (${widget.client.scheduleDescriptionArabic})',
                            style: const TextStyle(
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
                const SizedBox(height: 16),

                // Week Selector Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'أسبوع: $dateRangeStr',
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_calendar, size: 16),
                        label: const Text('تغيير الأسبوع', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _weekStartDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _weekStartDate = DateTime(picked.year, picked.month, picked.day);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Days Selection (7 Days Checkboxes)
                const Text(
                  'اختر أيام الخدمة لهذا الأسبوع:',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (i) {
                    final dayDate = _weekStartDate.add(Duration(days: i));
                    final isSelected = _selectedDayIndices.contains(i);
                    final dayName = _getDayArabicName(dayDate.weekday);
                    final formattedDate = DateFormat('MM/dd').format(dayDate);

                    return FilterChip(
                      selected: isSelected,
                      label: Text(
                        '$dayName ($formattedDate)',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.deepPurple.shade900 : Colors.black87,
                        ),
                      ),
                      selectedColor: Colors.deepPurple.shade100,
                      checkmarkColor: Colors.deepPurple,
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedDayIndices.add(i);
                          } else {
                            _selectedDayIndices.remove(i);
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Pricing & Caregiver Confirmation
                const Text(
                  'تأكيد أسعار ومقدم الخدمة:',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _clientPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'سعر العميل اليومي',
                          suffixText: 'ج.م',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _nursePriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'يومية التمريض',
                          suffixText: 'ج.م',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Assigned Nurse Selection / Input
                if (nurseList.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: nurseList.contains(_nurseNameCtrl.text.trim()) ? _nurseNameCtrl.text.trim() : null,
                    decoration: const InputDecoration(
                      labelText: 'مقدم الخدمة / الممرض المكلف',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('اختر من قائمة التمريض', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    items: nurseList.map((name) {
                      return DropdownMenuItem(
                        value: name,
                        child: Text(name, style: const TextStyle(fontFamily: 'Cairo')),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _nurseNameCtrl.text = val;
                          final list = provider.caregivers.where((c) => provider.isNurseNameMatch(c.name, val)).toList();
                          if (list.isNotEmpty) {
                            final cg = list.first;
                            if (cg.openingBalance > 0) {
                              _nurseBalanceType = 'due';
                              _nurseBalanceCtrl.text = cg.openingBalance.toStringAsFixed(0);
                            } else if (cg.openingBalance < 0) {
                              _nurseBalanceType = 'debt';
                              _nurseBalanceCtrl.text = cg.openingBalance.abs().toStringAsFixed(0);
                            } else {
                              _nurseBalanceType = 'zero';
                              _nurseBalanceCtrl.text = '0';
                            }
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _nurseNameCtrl,
                  onChanged: (val) {
                    setState(() {
                      final list = provider.caregivers.where((c) => provider.isNurseNameMatch(c.name, val.trim())).toList();
                      if (list.isNotEmpty) {
                        final cg = list.first;
                        if (cg.openingBalance > 0) {
                          _nurseBalanceType = 'due';
                          _nurseBalanceCtrl.text = cg.openingBalance.toStringAsFixed(0);
                        } else if (cg.openingBalance < 0) {
                          _nurseBalanceType = 'debt';
                          _nurseBalanceCtrl.text = cg.openingBalance.abs().toStringAsFixed(0);
                        }
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'اسم الممرض (أو تعديل يدوي)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Caregiver Live Financial Status & Previous Dues Card
                if (selectedNurse.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: nurseRemaining > 0
                          ? const Color(0xFFF0FDF4)
                          : (nurseRemaining < 0 ? Colors.red.shade50 : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: nurseRemaining > 0
                            ? Colors.green.shade300
                            : (nurseRemaining < 0 ? Colors.red.shade200 : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 18,
                              color: nurseRemaining >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'حساب ومستحقات مقدم الخدمة ($selectedNurse):',
                                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            if (matchedCaregiver != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'كود: ${matchedCaregiver.code}',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                nurseRemaining > 0
                                    ? 'له مستحق حالي في النظام: ${nurseRemaining.toStringAsFixed(0)} ج.م'
                                    : (nurseRemaining < 0
                                        ? 'عليه سلف / مديونية: ${nurseRemaining.abs().toStringAsFixed(0)} ج.م'
                                        : 'الرصيد في النظام: خالص (0 ج.م)'),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: nurseRemaining > 0
                                      ? Colors.green.shade800
                                      : (nurseRemaining < 0 ? Colors.red.shade800 : Colors.blueGrey),
                                ),
                              ),
                              Text(
                                'مكتسب: ${nurseEarned.toStringAsFixed(0)} | سلف: ${nurseAdvances.toStringAsFixed(0)}',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Option to adjust / set previous dues from older services
                        const Text(
                          'مستحقات أو مديونية الممرض السابقة عن خدمة قديمة:',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text('مستحق له (+)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                selected: _nurseBalanceType == 'due',
                                selectedColor: Colors.green.shade100,
                                onSelected: (val) {
                                  if (val) setState(() => _nurseBalanceType = 'due');
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text('مديونية عليه (-)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                                ),
                                selected: _nurseBalanceType == 'debt',
                                selectedColor: Colors.red.shade100,
                                onSelected: (val) {
                                  if (val) setState(() => _nurseBalanceType = 'debt');
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text('خالص (0)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                                ),
                                selected: _nurseBalanceType == 'zero',
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _nurseBalanceType = 'zero';
                                      _nurseBalanceCtrl.text = '0';
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_nurseBalanceType != 'zero') ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nurseBalanceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: _nurseBalanceType == 'due'
                                  ? 'قيمة مستحقات الممرض السابقة (خدمة قديمة لم يحصلها)'
                                  : 'قيمة المديونية / السلفة السابقة على الممرض',
                              suffixText: 'ج.م',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Live Summary Calculation Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('عدد الأيام المحددة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          Text(
                            '$selectedCount يوم',
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('إجمالي تكلفة العميل للأسبوع:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          Text(
                            '${totalClientCost.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('إجمالي مستحقات التمريض للأسبوع:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          Text(
                            '${totalNurseCost.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('صافي ربح الشركة المتوقع:', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            '${totalProfit.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات إضافية (اختياري)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
                const SizedBox(height: 18),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: (_isLoading || selectedCount == 0) ? null : _handleActivate,
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.flash_on, size: 18),
                      label: Text(
                        _isLoading ? 'جارٍ تفعيل الورديات...' : 'تأكيد وتفعيل ورديات الأسبوع ($selectedCount) ⚡',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Future<void> _handleActivate() async {
    final clientPrice = double.tryParse(_clientPriceCtrl.text.trim()) ?? 0.0;
    final nursePrice = double.tryParse(_nursePriceCtrl.text.trim()) ?? 0.0;
    final nurseName = _nurseNameCtrl.text.trim();

    if (_selectedDayIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد يوم واحد على الأقل لتفعيل الخدمة', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    if (clientPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال سعر العميل اليومي بشكل صحيح', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    final selectedDates = _selectedDayIndices
        .map((i) => _weekStartDate.add(Duration(days: i)))
        .toList()
      ..sort();

    try {
      final provider = context.read<AppProvider>();
      double? nurseOpeningBalance;
      if (_nurseBalanceType != 'zero') {
        final val = double.tryParse(_nurseBalanceCtrl.text.trim()) ?? 0.0;
        if (val > 0) {
          nurseOpeningBalance = _nurseBalanceType == 'due' ? val.abs() : -val.abs();
        }
      }

      final activatedCount = await provider.activateWeeklyClientService(
        clientId: widget.client.id,
        selectedDates: selectedDates,
        clientPrice: clientPrice,
        nursePrice: nursePrice,
        nurseName: nurseName,
        notes: _notesCtrl.text.trim(),
        nurseOpeningBalance: nurseOpeningBalance,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تفعيل $activatedCount ورديات أسبوعية بنجاح للعميل ${widget.client.name} ⚡',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.deepPurple,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo'))),
        );
      }
    }
  }
}
