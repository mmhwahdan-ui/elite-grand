import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';

class ManualAdjustClientBalanceDialog extends StatefulWidget {
  final ClientModel client;

  const ManualAdjustClientBalanceDialog({super.key, required this.client});

  @override
  State<ManualAdjustClientBalanceDialog> createState() => _ManualAdjustClientBalanceDialogState();
}

class _ManualAdjustClientBalanceDialogState extends State<ManualAdjustClientBalanceDialog> {
  // Mode: 'opening' (ضبط الرصيد الافتتاحي / السابق) | 'target' (تحديد صافي الرصيد الحالي النهائي مباشرة)
  String _mode = 'opening';

  // For 'opening' mode
  String _balanceType = 'debt'; // 'debt' (مديونية -) | 'credit' (رصيد دائن +) | 'zero' (خالص 0)
  late TextEditingController _openingAmountCtrl;

  // For 'target' mode
  String _targetType = 'debt'; // 'debt' (مديونية -) | 'credit' (رصيد دائن +) | 'zero' (خالص 0)
  late TextEditingController _targetAmountCtrl;

  late TextEditingController _notesCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final op = widget.client.openingBalance;
    if (op < 0) {
      _balanceType = 'debt';
      _openingAmountCtrl = TextEditingController(text: op.abs().toStringAsFixed(0));
    } else if (op > 0) {
      _balanceType = 'credit';
      _openingAmountCtrl = TextEditingController(text: op.toStringAsFixed(0));
    } else {
      _balanceType = 'zero';
      _openingAmountCtrl = TextEditingController(text: '0');
    }

    _targetAmountCtrl = TextEditingController();
    _notesCtrl = TextEditingController(text: 'ضبط وتسوية حساب العميل يدوياً');
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
    final client = provider.clients.firstWhere((c) => c.id == widget.client.id, orElse: () => widget.client);

    final totalPaid = provider.getClientTotalPaid(client.id);
    final accruedCost = provider.getClientAccruedCost(client);
    final currentBalance = provider.getClientBalance(client);
        final elapsedBalance = provider.getClientElapsedBalance(client);

    // Calculate resulting opening balance if target mode
    double calculatedOpeningFromTarget = 0.0;
    if (_mode == 'target') {
      final targetAmt = double.tryParse(_targetAmountCtrl.text.trim()) ?? 0.0;
      double targetNet = 0.0;
      if (_targetType == 'debt') targetNet = -targetAmt.abs();
      if (_targetType == 'credit') targetNet = targetAmt.abs();
      // targetNet = openingBalance + totalPaid - accruedCost
      // => openingBalance = targetNet - totalPaid + accruedCost
      calculatedOpeningFromTarget = targetNet - totalPaid + accruedCost;
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
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.scale, color: Colors.blue, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ضبط وتسوية حساب العميل يدوياً ⚖️',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'العميل: ${client.name} (${client.phone.isNotEmpty ? client.phone : "بدون هاتف"})',
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

                // Current Financial Snapshot Card
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
                          const Text('الرصيد الافتتاحي المسجل حالياً:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          Text(
                            client.openingBalance < 0
                                ? 'مديونية سابقة: ${client.openingBalance.abs().toStringAsFixed(0)} ج.م'
                                : (client.openingBalance > 0
                                    ? 'رصيد دائن: ${client.openingBalance.toStringAsFixed(0)} ج.م'
                                    : '0 ج.م (خالص)'),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: client.openingBalance < 0 ? Colors.red.shade800 : (client.openingBalance > 0 ? Colors.green.shade800 : Colors.blueGrey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('إجمالي تكلفة الخدمات: ${accruedCost.toStringAsFixed(0)} ج.م', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.blueGrey)),
                          Text('إجمالي المسدد من العميل: ${totalPaid.toStringAsFixed(0)} ج.م', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.teal)),
                        ],
                      ),
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('صافي المديونية عن الأيام المنقضية حتى اليوم:', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.blueGrey)),
                              Text(
                                elapsedBalance < 0
                                    ? 'مطلوب من العميل الآن: ${elapsedBalance.abs().toStringAsFixed(0)} ج.م'
                                    : 'رصيد دائن للعميل: ${elapsedBalance.toStringAsFixed(0)} ج.م',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: elapsedBalance < 0 ? Colors.amber.shade900 : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('إجمالي رصيد العميل الكلي:', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.blueGrey)),
                              Text(
                                currentBalance < 0
                                    ? 'مديونية كلية: ${currentBalance.abs().toStringAsFixed(0)} ج.م'
                                    : 'دائن كلي: ${currentBalance.toStringAsFixed(0)} ج.م',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: currentBalance < 0 ? Colors.red.shade800 : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Adjustment Mode Selector
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(
                          child: Text('تعديل الرصيد السابق / الافتتاحي 📝', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                        selected: _mode == 'opening',
                        selectedColor: Colors.blue.shade100,
                        onSelected: (val) {
                          if (val) setState(() => _mode = 'opening');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(
                          child: Text('تحديد الصافي النهائي المطلوب 🎯', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                        selected: _mode == 'target',
                        selectedColor: Colors.teal.shade100,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _mode = 'target';
                              if (currentBalance < 0) {
                                _targetType = 'debt';
                                _targetAmountCtrl.text = currentBalance.abs().toStringAsFixed(0);
                              } else if (currentBalance > 0) {
                                _targetType = 'credit';
                                _targetAmountCtrl.text = currentBalance.toStringAsFixed(0);
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

                // MODE 1: Opening Balance Adjustment
                if (_mode == 'opening') ...[
                  const Text(
                    'تحديد الرصيد الافتتاحي أو المديونية السابقة عن خدمة قديمة:',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text('مديونية سابقة على العميل (-)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
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
                            child: Text('رصيد دائن / دفعة مقدمة (+)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                          ),
                          selected: _balanceType == 'credit',
                          selectedColor: Colors.green.shade100,
                          onSelected: (val) {
                            if (val) setState(() => _balanceType = 'credit');
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
                        labelText: _balanceType == 'debt'
                            ? 'قيمة مديونية العميل السابقة (خدمة قديمة لم تُحصل)'
                            : 'قيمة الرصيد الدائن السابق للعميل',
                        suffixText: 'ج.م',
                        prefixIcon: Icon(_balanceType == 'debt' ? Icons.arrow_downward : Icons.arrow_upward, color: _balanceType == 'debt' ? Colors.red : Colors.green),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ],

                // MODE 2: Target Net Balance Calibration
                if (_mode == 'target') ...[
                  const Text(
                    'حدد صافي المديونية أو الرصيد المطلوب أن يظهر للعميل في النظام:',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text('مديونية نهائية على العميل (-)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
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
                            child: Text('رصيد دائن نهائي للعميل (+)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                          ),
                          selected: _targetType == 'credit',
                          selectedColor: Colors.green.shade100,
                          onSelected: (val) {
                            if (val) setState(() => _targetType = 'credit');
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
                        labelText: _targetType == 'debt'
                            ? 'إجمالي المديونية النهائية المطلوبة على العميل'
                            : 'إجمالي الرصيد الدائن النهائي المطلوب للعميل',
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💡 سيتم ضبط الرصيد الافتتاحي تلقائياً إلى (${calculatedOpeningFromTarget.toStringAsFixed(0)} ج.م) ليصبح الصافي الكلي بالضبط كما حددت.',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.blue.shade900),
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
                        backgroundColor: Colors.blue.shade800,
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
    final client = provider.clients.firstWhere((c) => c.id == widget.client.id, orElse: () => widget.client);
    final accruedCost = provider.getClientAccruedCost(client);
    final totalPaid = provider.getClientTotalPaid(client.id);

    double newOpeningBalance = 0.0;
    if (_mode == 'opening') {
      if (_balanceType != 'zero') {
        final val = double.tryParse(_openingAmountCtrl.text.trim()) ?? 0.0;
        newOpeningBalance = _balanceType == 'debt' ? -val.abs() : val.abs();
      }
    } else {
      double targetNet = 0.0;
      if (_targetType != 'zero') {
        final val = double.tryParse(_targetAmountCtrl.text.trim()) ?? 0.0;
        targetNet = _targetType == 'debt' ? -val.abs() : val.abs();
      }
      newOpeningBalance = targetNet - totalPaid + accruedCost;
    }

    setState(() => _isLoading = true);

    try {
      await provider.manuallyAdjustClientBalance(
        clientId: client.id,
        newOpeningBalance: newOpeningBalance,
        reason: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : 'تسوية يدوية للرصيد',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم ضبط وتسوية حساب العميل ${client.name} بنجاح ⚖️',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.blue.shade800,
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
