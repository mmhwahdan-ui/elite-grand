import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/caregiver_model.dart';
import '../providers/app_provider.dart';

class ManualAdjustCaregiverBalanceDialog extends StatefulWidget {
  final String nurseName;
  final CaregiverModel? caregiver;

  const ManualAdjustCaregiverBalanceDialog({
    super.key,
    required this.nurseName,
    this.caregiver,
  });

  @override
  State<ManualAdjustCaregiverBalanceDialog> createState() => _ManualAdjustCaregiverBalanceDialogState();
}

class _ManualAdjustCaregiverBalanceDialogState extends State<ManualAdjustCaregiverBalanceDialog> {
  // Mode: 'opening' (ضبط الرصيد الافتتاحي / مستحقات خدمة قديمة) | 'target' (تحديد صافي الرصيد النهائي مباشرة)
  String _mode = 'opening';

  // For 'opening' mode
  String _balanceType = 'due'; // 'due' (مستحق له +) | 'debt' (مديونية عليه -) | 'zero' (خالص 0)
  late TextEditingController _openingAmountCtrl;

  // For 'target' mode
  String _targetType = 'due'; // 'due' (مستحق له +) | 'debt' (مديونية عليه -) | 'zero' (خالص 0)
  late TextEditingController _targetAmountCtrl;

  late TextEditingController _notesCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final op = widget.caregiver?.openingBalance ?? 0.0;
    if (op > 0) {
      _balanceType = 'due';
      _openingAmountCtrl = TextEditingController(text: op.toStringAsFixed(0));
    } else if (op < 0) {
      _balanceType = 'debt';
      _openingAmountCtrl = TextEditingController(text: op.abs().toStringAsFixed(0));
    } else {
      _balanceType = 'zero';
      _openingAmountCtrl = TextEditingController(text: '0');
    }

    _targetAmountCtrl = TextEditingController();
    _notesCtrl = TextEditingController(text: 'ضبط وتسوية حساب مقدم الخدمة يدوياً');
  }

  @override
  void dispose() {
    _openingAmountCtrl.dispose();
    _targetAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final nurseName = widget.nurseName.trim();
    final cg = provider.findCaregiverByName(nurseName) ?? widget.caregiver;

                final totalReceived = provider.getNurseTotalReceived(nurseName);
    final remaining = provider.getNurseRemainingBalance(nurseName);

    // Shifts-only earned (excluding opening balance)
    final shiftsOnlyEarned = provider.getNurseShifts(nurseName).fold(0.0, (sum, s) => sum + s.nursePrice);

    // Calculate resulting opening balance if target mode
    double calculatedOpeningFromTarget = 0.0;
    if (_mode == 'target') {
      final targetAmt = double.tryParse(_targetAmountCtrl.text.trim()) ?? 0.0;
      double targetNet = 0.0;
      if (_targetType == 'due') targetNet = targetAmt.abs();
      if (_targetType == 'debt') targetNet = -targetAmt.abs();
      // targetNet = remaining = earned - totalReceived
      // earned = shiftsOnlyEarned + openingBalance
      // targetNet = shiftsOnlyEarned + openingBalance - totalReceived
      // => openingBalance = targetNet + totalReceived - shiftsOnlyEarned
      calculatedOpeningFromTarget = targetNet + totalReceived - shiftsOnlyEarned;
    }

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
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tune, color: Colors.teal, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ضبط وتسوية حساب مقدم الخدمة يدوياً ⚖️',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'مقدم الخدمة: $nurseName ${cg != null ? "(${cg.code})" : ""}',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.blueGrey),
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
                const SizedBox(height: 16),

                // Current Financial Breakdown Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الرصيد الافتتاحي القديم المسجل:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          Text(
                            (cg != null && cg.openingBalance > 0)
                                ? 'مستحق سابق: ${cg.openingBalance.toStringAsFixed(0)} ج.م'
                                : ((cg != null && cg.openingBalance < 0)
                                    ? 'مديونية سابقة: ${cg.openingBalance.abs().toStringAsFixed(0)} ج.م'
                                    : '0 ج.م (خالص)'),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: (cg != null && cg.openingBalance > 0) ? Colors.green.shade800 : ((cg != null && cg.openingBalance < 0) ? Colors.red.shade800 : Colors.blueGrey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('أجر الورديات: ${shiftsOnlyEarned.toStringAsFixed(0)} ج.م', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.blueGrey)),
                          Text('المنصرف (سلف + دفعات): ${totalReceived.toStringAsFixed(0)} ج.م', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.amber.shade900)),
                        ],
                      ),
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('صافي رصيد مقدم الخدمة الحالي في النظام:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            remaining > 0
                                ? 'له باقي: ${remaining.toStringAsFixed(0)} ج.م'
                                : (remaining < 0
                                    ? 'عليه سلف / مديونية: ${remaining.abs().toStringAsFixed(0)} ج.م'
                                    : 'خالص (0 ج.م)'),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: remaining > 0 ? Colors.green.shade800 : (remaining < 0 ? Colors.red.shade800 : Colors.blueGrey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Mode Selector
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(
                          child: Text('تعديل المستحقات السابقة (خدمة قديمة) 📝', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        selected: _mode == 'opening',
                        selectedColor: Colors.teal.shade100,
                        onSelected: (val) {
                          if (val) setState(() => _mode = 'opening');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(
                          child: Text('تحديد الصافي النهائي المطلوب 🎯', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        selected: _mode == 'target',
                        selectedColor: Colors.blue.shade100,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _mode = 'target';
                              if (remaining > 0) {
                                _targetType = 'due';
                                _targetAmountCtrl.text = remaining.toStringAsFixed(0);
                              } else if (remaining < 0) {
                                _targetType = 'debt';
                                _targetAmountCtrl.text = remaining.abs().toStringAsFixed(0);
                              } else {
                                _targetType = 'zero';
                                _targetAmountCtrl.text = '0';
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // MODE 1: Opening balance / previous service dues
                if (_mode == 'opening') ...[
                  const Text(
                    'تحديد مستحقات أو مديونية الممرض عن خدمة سابقة:',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text('مستحق للممرض (+) (خدمة قديمة)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          selected: _balanceType == 'due',
                          selectedColor: Colors.green.shade100,
                          onSelected: (val) {
                            if (val) setState(() => _balanceType = 'due');
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text('مديونية سابقة على الممرض (-)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                          ),
                          selected: _balanceType == 'debt',
                          selectedColor: Colors.red.shade100,
                          onSelected: (val) {
                            if (val) setState(() => _balanceType = 'debt');
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text('خالص (0 ج.م)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                          ),
                          selected: _balanceType == 'zero',
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _balanceType = 'zero';
                                _openingAmountCtrl.text = '0';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_balanceType != 'zero') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _openingAmountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: _balanceType == 'due'
                            ? 'قيمة مستحقات الممرض السابقة (خدمة قديمة لم يحصلها)'
                            : 'قيمة المديونية / السلفة السابقة على الممرض',
                        suffixText: 'ج.م',
                        prefixIcon: Icon(_balanceType == 'due' ? Icons.add_circle : Icons.remove_circle, color: _balanceType == 'due' ? Colors.green : Colors.red),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ],

                // MODE 2: Target Final Balance
                if (_mode == 'target') ...[
                  const Text(
                    'حدد صافي الرصيد النهائي المطلوب أن يتبقى لمقدم الخدمة:',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text('صافي مستحق للممرض (+)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          selected: _targetType == 'due',
                          selectedColor: Colors.green.shade100,
                          onSelected: (val) {
                            if (val) setState(() => _targetType = 'due');
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text('صافي مديونية على الممرض (-)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                          ),
                          selected: _targetType == 'debt',
                          selectedColor: Colors.red.shade100,
                          onSelected: (val) {
                            if (val) setState(() => _targetType = 'debt');
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text('تصفير الحساب (خالص 0)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                          ),
                          selected: _targetType == 'zero',
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _targetType = 'zero';
                                _targetAmountCtrl.text = '0';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_targetType != 'zero') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _targetAmountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: _targetType == 'due'
                            ? 'إجمالي المبلغ المستحق النهائي للممرض طرف الشركة'
                            : 'إجمالي المديونية النهائية على الممرض',
                        suffixText: 'ج.م',
                        prefixIcon: const Icon(Icons.track_changes, color: Colors.teal),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💡 سيتم ضبط الرصيد الافتتاحي تلقائياً إلى (${calculatedOpeningFromTarget.toStringAsFixed(0)} ج.م) ليصبح الصافي الكلي بالضبط كما حددت.',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.teal.shade900),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Notes / Reason
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'سبب الضبط اليدوي / ملاحظات التسوية',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 20),

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
                      onPressed: _isLoading ? null : _handleSave,
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        _isLoading ? 'جارٍ الحفظ والتسوية...' : 'حفظ وتثبيت الحساب ⚖️',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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

  Future<void> _handleSave() async {
    final provider = context.read<AppProvider>();
    final nurseName = widget.nurseName.trim();
    final totalReceived = provider.getNurseTotalReceived(nurseName);
    final shiftsOnlyEarned = provider.getNurseShifts(nurseName).fold(0.0, (sum, s) => sum + s.nursePrice);

    double newOpeningBalance = 0.0;
    if (_mode == 'opening') {
      if (_balanceType != 'zero') {
        final val = double.tryParse(_openingAmountCtrl.text.trim()) ?? 0.0;
        newOpeningBalance = _balanceType == 'due' ? val.abs() : -val.abs();
      }
    } else {
      double targetNet = 0.0;
      if (_targetType != 'zero') {
        final val = double.tryParse(_targetAmountCtrl.text.trim()) ?? 0.0;
        targetNet = _targetType == 'due' ? val.abs() : -val.abs();
      }
      newOpeningBalance = targetNet + totalReceived - shiftsOnlyEarned;
    }

    setState(() => _isLoading = true);

    try {
      await provider.manuallyAdjustCaregiverBalance(
        nurseName: nurseName,
        newOpeningBalance: newOpeningBalance,
        reason: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : 'تسوية يدوية للرصيد',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم ضبط وتسوية حساب مقدم الخدمة $nurseName بنجاح ⚖️',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.teal.shade800,
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
