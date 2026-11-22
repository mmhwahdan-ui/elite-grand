import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/caregiver_model.dart';
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

  // رصيد أو مديونية العميل السابقة
  late TextEditingController _clientBalanceCtrl;
  String _clientBalanceType = 'zero'; // 'debt' (مديونية على العميل -) | 'credit' (رصيد دائن للعميل +) | 'zero' (خالص 0)

  // رصيد أو مستحقات مقدم الخدمة السابقة
  late TextEditingController _nurseBalanceCtrl;
  String _nurseBalanceType = 'zero'; // 'due' (مستحقات سابقة للممرض +) | 'debt' (مديونية سابقة على الممرض -) | 'zero' (خالص 0)
  bool _hasInitializedNurseBalance = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate.add(const Duration(days: 7));
    _nurseController = TextEditingController(text: widget.client.nurseAssigned ?? '');

    // إعداد الرصيد الافتتاحي للعميل
    if (widget.client.openingBalance < 0) {
      _clientBalanceType = 'debt';
      _clientBalanceCtrl = TextEditingController(text: widget.client.openingBalance.abs().toStringAsFixed(0));
    } else if (widget.client.openingBalance > 0) {
      _clientBalanceType = 'credit';
      _clientBalanceCtrl = TextEditingController(text: widget.client.openingBalance.toStringAsFixed(0));
    } else {
      _clientBalanceType = 'zero';
      _clientBalanceCtrl = TextEditingController(text: '0');
    }

    _nurseBalanceCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _nurseController.dispose();
    _clientBalanceCtrl.dispose();
    _nurseBalanceCtrl.dispose();
    super.dispose();
  }

  int get _selectedDaysCount {
    if (_endDate.isBefore(_startDate)) return 1;
    if (widget.client.serviceScheduleType == 'custom_days') {
      if (widget.client.activeWeekdays.isNotEmpty) {
        int count = 0;
        DateTime cur = _startDate;
        while (!cur.isAfter(_endDate)) {
          if (widget.client.activeWeekdays.contains(cur.weekday)) {
            count++;
          }
          cur = cur.add(const Duration(days: 1));
        }
        return count > 0 ? count : 1;
      } else if (widget.client.daysPerWeek > 0 && widget.client.daysPerWeek < 7) {
        final totalDays = _endDate.difference(_startDate).inDays + 1;
        final weeks = totalDays ~/ 7;
        final rem = totalDays % 7;
        final extra = rem > widget.client.daysPerWeek ? widget.client.daysPerWeek : rem;
        final res = (weeks * widget.client.daysPerWeek) + extra;
        return res > 0 ? res : 1;
      }
    }
    return _endDate.difference(_startDate).inDays + 1;
  }

  double get _computedClientOpeningBalance {
    if (_clientBalanceType == 'zero') return 0.0;
    final val = double.tryParse(_clientBalanceCtrl.text.trim()) ?? 0.0;
    if (val == 0.0) return 0.0;
    return _clientBalanceType == 'debt' ? -val.abs() : val.abs();
  }

  double get _computedNurseOpeningBalance {
    if (_nurseBalanceType == 'zero') return 0.0;
    final val = double.tryParse(_nurseBalanceCtrl.text.trim()) ?? 0.0;
    if (val == 0.0) return 0.0;
    return _nurseBalanceType == 'due' ? val.abs() : -val.abs();
  }

  // اقتراح مستحقات الممرض المقابلة لمديونية العميل إذا كانت ناتجة عن خدمة قديمة
  void _suggestNurseDuesFromClientDebt() {
    final clientDebt = double.tryParse(_clientBalanceCtrl.text.trim()) ?? 0.0;
    if (clientDebt > 0 && widget.client.dailyPrice > 0 && widget.client.nurseDailyPrice > 0) {
      final days = clientDebt / widget.client.dailyPrice;
      final suggestedNurseDue = days * widget.client.nurseDailyPrice;
      setState(() {
        _nurseBalanceType = 'due';
        _nurseBalanceCtrl.text = suggestedNurseDue.toStringAsFixed(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');

    final daysCount = _selectedDaysCount;
    final totalClientCost = daysCount * widget.client.dailyPrice;
    final totalNurseCost = daysCount * widget.client.nurseDailyPrice;
    final totalProfit = totalClientCost - totalNurseCost;

    // مقدم الخدمة المحدد
    final selectedNurseName = _nurseController.text.trim();
    CaregiverModel? matchedCaregiver;
    if (selectedNurseName.isNotEmpty) {
      final list = provider.caregivers.where((c) => provider.isNurseNameMatch(c.name, selectedNurseName)).toList();
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

    final nurseRemaining = selectedNurseName.isNotEmpty ? provider.getNurseRemainingBalance(selectedNurseName) : 0.0;
    final nurseEarned = selectedNurseName.isNotEmpty ? provider.getNurseTotalEarned(selectedNurseName) : 0.0;
    final nurseAdvances = selectedNurseName.isNotEmpty ? provider.getNurseTotalAdvances(selectedNurseName) : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 780),
          padding: const EdgeInsets.all(22),
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
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_circle_fill, color: AppTheme.accent, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تأكيد بدء الخدمة وضبط حسابات الحالة والتمريض',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            'تاريخ البدء + مديونية العميل السابقة + مستحقات مقدم الخدمة السابقة',
                            style: TextStyle(fontSize: 11.5, color: Colors.blueGrey, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // 1. Client Info Summary Card
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
                            Row(
                              children: [
                                Text(
                                  widget.client.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: widget.client.isExistingClient ? Colors.blue.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: widget.client.isExistingClient ? Colors.blue.shade200 : Colors.green.shade200),
                                  ),
                                  child: Text(
                                    widget.client.isExistingClient ? 'عميل حالي' : 'عميل جديد',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      color: widget.client.isExistingClient ? Colors.blue.shade900 : Colors.green.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${widget.client.serviceTypeArabic} | ${widget.client.scheduleDescriptionArabic} | سعر اليوم: ${widget.client.dailyPrice.toStringAsFixed(0)} ج.م | يومية التمريض: ${widget.client.nurseDailyPrice.toStringAsFixed(0)} ج.م',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Client Previous Debt / Balance Card (مديونية العميل السابقة عن خدمة قديمة لم تُحصل)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _clientBalanceType == 'debt'
                        ? Colors.red.shade50
                        : (_clientBalanceType == 'credit' ? Colors.green.shade50 : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _clientBalanceType == 'debt'
                          ? Colors.red.shade200
                          : (_clientBalanceType == 'credit' ? Colors.green.shade200 : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 18,
                            color: _clientBalanceType == 'debt'
                                ? Colors.red.shade700
                                : (_clientBalanceType == 'credit' ? Colors.green.shade700 : AppTheme.primary),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'مديونية العميل السابقة (عن خدمة قديمة تمت ولم تُحصّل بعد):',
                              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Choice Chips: مديونية (-) أم رصيد دائن (+) أم خالص (0)
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: Text('مديونية على العميل (-)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              selected: _clientBalanceType == 'debt',
                              selectedColor: Colors.red.shade100,
                              onSelected: (val) {
                                if (val) setState(() => _clientBalanceType = 'debt');
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: Text('رصيد دائن للعميل (+)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                              ),
                              selected: _clientBalanceType == 'credit',
                              selectedColor: Colors.green.shade100,
                              onSelected: (val) {
                                if (val) setState(() => _clientBalanceType = 'credit');
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: Text('خالص (0 ج.م)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                              ),
                              selected: _clientBalanceType == 'zero',
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _clientBalanceType = 'zero';
                                    _clientBalanceCtrl.text = '0';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_clientBalanceType != 'zero') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _clientBalanceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: _clientBalanceType == 'debt'
                                ? 'مبلغ المديونية السابقة المستحقة على العميل (عن خدمة سابقة)'
                                : 'مبلغ الرصيد الدائن / الدفعة المقدمة للعميل',
                            prefixIcon: Icon(
                              _clientBalanceType == 'debt' ? Icons.money_off : Icons.add_circle,
                              color: _clientBalanceType == 'debt' ? Colors.red : Colors.green,
                            ),
                            suffixText: 'ج.م',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Caregiver Previous Dues / Debt Card (مستحقات مقدم الخدمة عن خدمة قديمة عند نفس العميل)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _nurseBalanceType == 'due'
                        ? const Color(0xFFF0FDF4)
                        : (_nurseBalanceType == 'debt' ? Colors.red.shade50 : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _nurseBalanceType == 'due'
                          ? Colors.green.shade300
                          : (_nurseBalanceType == 'debt' ? Colors.red.shade200 : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 18, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'مقدم الخدمة (الممرض) ومستحقاته السابقة عن نفس الحالة:',
                              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Caregiver Autocomplete / Search
                      Autocomplete<CaregiverModel>(
                        displayStringForOption: (CaregiverModel cg) => cg.name,
                        initialValue: TextEditingValue(text: _nurseController.text),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return provider.caregivers;
                          }
                          return provider.caregivers.where((CaregiverModel cg) {
                            return cg.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                cg.code.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (CaregiverModel selection) {
                          setState(() {
                            _nurseController.text = selection.name;
                            if (selection.openingBalance > 0) {
                              _nurseBalanceType = 'due';
                              _nurseBalanceCtrl.text = selection.openingBalance.toStringAsFixed(0);
                            } else if (selection.openingBalance < 0) {
                              _nurseBalanceType = 'debt';
                              _nurseBalanceCtrl.text = selection.openingBalance.abs().toStringAsFixed(0);
                            }
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) {
                              setState(() {
                                _nurseController.text = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'اختر أو اكتب اسم مقدم الخدمة القائم بالحالة',
                              prefixIcon: const Icon(Icons.person_search),
                              suffixIcon: _nurseController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        controller.clear();
                                        setState(() {
                                          _nurseController.text = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          );
                        },
                      ),

                      // Live Status of selected caregiver
                      if (selectedNurseName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: nurseRemaining > 0
                                ? const Color(0xFFF0FDF4)
                                : (nurseRemaining < 0 ? Colors.red.shade50 : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(10),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    matchedCaregiver != null ? 'كود: ${matchedCaregiver.code}' : 'ممرض محدد',
                                    style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  ),
                                  Text(
                                    nurseRemaining > 0
                                        ? 'له رصيد مستحق في النظام: ${nurseRemaining.toStringAsFixed(0)} ج.م'
                                        : (nurseRemaining < 0
                                            ? 'عليه سلف / مديونية: ${nurseRemaining.abs().toStringAsFixed(0)} ج.م'
                                            : 'الرصيد في النظام: 0 ج.م (خالص)'),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      color: nurseRemaining > 0
                                          ? Colors.green.shade900
                                          : (nurseRemaining < 0 ? Colors.red.shade900 : Colors.blueGrey),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'إجمالي ما استحقه: ${nurseEarned.toStringAsFixed(0)} ج.م | إجمالي السلف والخصومات: ${nurseAdvances.toStringAsFixed(0)} ج.م',
                                style: TextStyle(fontSize: 10.5, fontFamily: 'Cairo', color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                      // Caregiver Previous Dues / Debt selector
                      const Text(
                        'حساب مستحقات مقدم الخدمة عن الفترة السابقة:',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: Text('مستحق للممرض (+) (خدمة قديمة)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
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
                                child: Text('مديونية على الممرض (-)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
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
                                child: Text('خالص (0 ج.م)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
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
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nurseBalanceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: _nurseBalanceType == 'due'
                                ? 'مبلغ مستحقات الممرض السابقة (خدمة قديمة لم يحصلها عند نفس العميل)'
                                : 'مبلغ المديونية أو السلفة السابقة على الممرض',
                            prefixIcon: Icon(
                              _nurseBalanceType == 'due' ? Icons.account_balance_wallet : Icons.money_off,
                              color: _nurseBalanceType == 'due' ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                            suffixText: 'ج.م',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        // Smart suggestion button from client debt
                        if (_clientBalanceType == 'debt' && (double.tryParse(_clientBalanceCtrl.text) ?? 0) > 0) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _suggestNurseDuesFromClientDebt,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 14, color: Colors.teal),
                                  const SizedBox(width: 6),
                                  Text(
                                    'اقتراح مستحقات الممرض تلقائياً من مديونية العميل (حسب يومية ${widget.client.nurseDailyPrice.toStringAsFixed(0)} ج.م)',
                                    style: const TextStyle(fontSize: 10.5, fontFamily: 'Cairo', color: Colors.teal, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Service Dates & Duration Switcher (تاريخ بدء الخدمة وفترة التعاقد)
                const Text(
                  'تاريخ بدء الخدمة الجديد وفترة التعاقد:',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isOpenEnded = false),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isOpenEnded ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !_isOpenEnded
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.date_range, size: 16, color: !_isOpenEnded ? AppTheme.primary : Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  'مدة محددة (بتاريخ نهاية)',
                                  style: TextStyle(
                                    fontSize: 12,
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
                          onTap: () => setState(() => _isOpenEnded = true),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isOpenEnded ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _isOpenEnded
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.all_inclusive, size: 16, color: _isOpenEnded ? Colors.teal : Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  'مدة مفتوحة (مستمرة)',
                                  style: TextStyle(
                                    fontSize: 12,
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
                const SizedBox(height: 10),

                // Calendars Row
                Row(
                  children: [
                    // Start Date
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 90)),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
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
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 15, color: AppTheme.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'تاريخ بدء الخدمة:',
                                    style: TextStyle(fontSize: 11, color: AppTheme.primary, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(_startDate),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // End Date or Open-ended
                    Expanded(
                      child: _isOpenEnded
                          ? Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.all_inclusive, size: 15, color: Colors.teal),
                                      SizedBox(width: 6),
                                      Text(
                                        'نهاية الخدمة:',
                                        style: TextStyle(fontSize: 11, color: Colors.teal, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'مدة مفتوحة (مستمرة)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, fontFamily: 'Cairo', color: Colors.teal),
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
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.event_available, size: 15, color: Colors.deepOrange),
                                        SizedBox(width: 6),
                                        Text(
                                          'نهاية الخدمة:',
                                          style: TextStyle(fontSize: 11, color: Colors.deepOrange, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateFormat.format(_endDate),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),

                if (!_isOpenEnded) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        label: const Text('+ 7 أيام (أسبوع)', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5)),
                        onPressed: () => setState(() => _endDate = _startDate.add(const Duration(days: 6))),
                      ),
                      ActionChip(
                        label: const Text('+ 14 يوم (أسبوعين)', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5)),
                        onPressed: () => setState(() => _endDate = _startDate.add(const Duration(days: 13))),
                      ),
                      ActionChip(
                        label: const Text('+ 30 يوم (شهر)', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5)),
                        onPressed: () => setState(() => _endDate = _startDate.add(const Duration(days: 29))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Contract preview
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'مدة التعاقد: $daysCount يوم',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo', color: AppTheme.primary),
                            ),
                            Text(
                              'قيمة التعاقد: ${totalClientCost.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo', color: AppTheme.accent),
                            ),
                          ],
                        ),
                        if (widget.client.nurseDailyPrice > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'مستحق التمريض: ${totalNurseCost.toStringAsFixed(0)} ج.م',
                                style: TextStyle(fontSize: 10.5, fontFamily: 'Cairo', color: Colors.grey.shade700),
                              ),
                              Text(
                                'مكسب الشركة المتوقع: ${totalProfit.toStringAsFixed(0)} ج.م',
                                style: const TextStyle(fontSize: 10.5, fontFamily: 'Cairo', color: Colors.teal, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final nurseName = _nurseController.text.trim();
                          final clientOpBalance = _computedClientOpeningBalance;
                          final nurseOpBalance = _computedNurseOpeningBalance;

                          await provider.startClientService(
                            clientId: widget.client.id,
                            startDate: _startDate,
                            endDate: _isOpenEnded ? null : _endDate,
                            isOpenEnded: _isOpenEnded,
                            nurseAssigned: nurseName.isNotEmpty ? nurseName : null,
                            clientOpeningBalance: clientOpBalance,
                            nurseOpeningBalance: nurseOpBalance,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تم بدء الخدمة بنجاح وتحديث تاريخ البدء وحسابات الحالة والتمريض 🛡️',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                                backgroundColor: AppTheme.accent,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'تأكيد بدء الخدمة وحفظ الحسابات',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
                        ),
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
