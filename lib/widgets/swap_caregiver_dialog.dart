import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';

class SwapCaregiverDialog extends StatefulWidget {
  final ClientModel client;
  final String? oldNurseName;

  const SwapCaregiverDialog({
    super.key,
    required this.client,
    this.oldNurseName,
  });

  @override
  State<SwapCaregiverDialog> createState() => _SwapCaregiverDialogState();
}

class _SwapCaregiverDialogState extends State<SwapCaregiverDialog> {
  late DateTime _effectiveDate;
  late TextEditingController _newNurseNameCtrl;
  late TextEditingController _newNursePriceCtrl;
  late TextEditingController _reasonCtrl;
  bool _isLoading = false;

  String get effectiveOldNurseName => (widget.oldNurseName != null && widget.oldNurseName!.isNotEmpty)
      ? widget.oldNurseName!
      : (widget.client.nurseAssigned ?? '');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _effectiveDate = DateTime(now.year, now.month, now.day);
    _newNurseNameCtrl = TextEditingController();
    _newNursePriceCtrl = TextEditingController(
      text: widget.client.nurseDailyPrice > 0 ? widget.client.nurseDailyPrice.toStringAsFixed(0) : '',
    );
    _reasonCtrl = TextEditingController(text: 'تبديل مقدم الخدمة بناءً على طلب الحالة / ظروف عمل');
  }

  @override
  void dispose() {
    _newNurseNameCtrl.dispose();
    _newNursePriceCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final nurseList = provider.allNurseNames.where((n) => !provider.isNurseNameMatch(n, effectiveOldNurseName)).toList();
    final dateFormat = DateFormat('yyyy/MM/dd');

    // Calculations for the current / outgoing nurse
    final oldNurse = effectiveOldNurseName.trim();
    final allShifts = provider.getClientServiceDays(widget.client.id).where((s) => provider.isNurseNameMatch(s.nurseName, oldNurse)).toList();
    final elapsedShifts = allShifts.where((s) {
      final dNorm = DateTime(s.date.year, s.date.month, s.date.day);
      return !dNorm.isAfter(_effectiveDate.subtract(const Duration(days: 1)));
    }).toList();

    // Future shifts to be transferred
    final futureShifts = allShifts.where((s) {
      final dNorm = DateTime(s.date.year, s.date.month, s.date.day);
      return !dNorm.isBefore(DateTime(_effectiveDate.year, _effectiveDate.month, _effectiveDate.day));
    }).toList();

    final oldNurseElapsedEarned = elapsedShifts.fold(0.0, (sum, s) => sum + s.nursePrice);
    final oldNurseTotalReceived = provider.getNurseTotalReceived(oldNurse);
    final oldCg = provider.findCaregiverByName(oldNurse);
    final oldOpening = (oldCg != null && oldCg.openingBalance > 0) ? oldCg.openingBalance : 0.0;
    final netDueOldNurseAtSwap = (oldNurseElapsedEarned + oldOpening) - oldNurseTotalReceived;

    final clientElapsedCost = elapsedShifts.fold(0.0, (sum, s) => sum + s.clientPrice);
    final clientPaid = provider.getClientTotalPaid(widget.client.id);
    final clientOpening = widget.client.openingBalance;
    final clientElapsedBalance = clientOpening + clientPaid - clientElapsedCost;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 760),
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
                        color: Colors.amber.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.swap_horiz, color: Colors.amber.shade900, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تبديل مقدم الخدمة في وسط الأسبوع 🔄',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'الحالة: ${widget.client.name} • الممرض الحالي: $oldNurse',
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

                // Effective Swap Date Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تاريخ سريان التبديل: ${dateFormat.format(_effectiveDate)}',
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_calendar, size: 16),
                        label: const Text('تغيير التاريخ', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _effectiveDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _effectiveDate = DateTime(picked.year, picked.month, picked.day);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Settlement Card for Outgoing Caregiver
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, size: 18, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تسوية مستحقات الممرض الحالي ($oldNurse) عن الأيام المنقضية:',
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              '${elapsedShifts.length} يوم منقضي',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('أجر الأيام المنقضية: ${oldNurseElapsedEarned.toStringAsFixed(0)} ج.م', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.blueGrey)),
                          Text('المنصرف له (سلف ودفعات): ${oldNurseTotalReceived.toStringAsFixed(0)} ج.م', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.amber.shade900)),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('صافي المستحق للممرض عند تسليمه الآن:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            netDueOldNurseAtSwap >= 0
                                ? 'مستحق له طرفنا: ${netDueOldNurseAtSwap.toStringAsFixed(0)} ج.م'
                                : 'عليه سلفة للشركة: ${netDueOldNurseAtSwap.abs().toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: netDueOldNurseAtSwap >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'موقف العميل حتى تاريخ التبديل: ${clientElapsedBalance < 0 ? "مديونية مطلوبة منه: " + clientElapsedBalance.abs().toStringAsFixed(0) + " ج.م" : "رصيد دائن مغطي: " + clientElapsedBalance.toStringAsFixed(0) + " ج.م"}',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: clientElapsedBalance < 0 ? Colors.red.shade900 : Colors.teal.shade900, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // New Caregiver Selection
                const Text(
                  'بيانات مقدم الخدمة الجديد البديل:',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (nurseList.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'اختر الممرض البديل من القائمة',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('اختر مقدم الخدمة الجديد', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    items: nurseList.map((name) {
                      final cg = provider.findCaregiverByName(name);
                      return DropdownMenuItem(
                        value: name,
                        child: Text(
                          '$name ${cg != null ? "(" + cg.code + ")" : ""}',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _newNurseNameCtrl.text = val;
                          final cg = provider.findCaregiverByName(val);
                          if (cg != null && cg.dailyPrice > 0) {
                            _newNursePriceCtrl.text = cg.dailyPrice.toStringAsFixed(0);
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _newNurseNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الممرض البديل (أو إدخال يدوي)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_add_alt_1),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newNursePriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'يومية الممرض الجديد المتفق عليها',
                    suffixText: 'ج.م',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Swap Summary Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⚡ سيتم تحويل عدد (${futureShifts.length} ورديات متبقية) من تاريخ ${dateFormat.format(_effectiveDate)} فصاعداً إلى الممرض الجديد تلقائياً مع تثبيت الوردياات السابقة للممرض القديم.',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                // Reason / Notes
                TextField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'سبب التبديل / ملاحظات',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      onPressed: _isLoading ? null : _handleSwap,
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.swap_horiz, size: 18),
                      label: Text(
                        _isLoading ? 'جارٍ التبديل والتسوية...' : 'تأكيد تبديل مقدم الخدمة 🔄',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade900,
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

  Future<void> _handleSwap() async {
    final newNurse = _newNurseNameCtrl.text.trim();
    if (newNurse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار أو إدخال اسم مقدم الخدمة الجديد البديل', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    final newPrice = double.tryParse(_newNursePriceCtrl.text.trim());

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();
      final transferredCount = await provider.swapCaregiverMidWeek(
        clientId: widget.client.id,
        oldNurseName: effectiveOldNurseName,
        newNurseName: newNurse,
        effectiveDate: _effectiveDate,
        newNurseDailyPrice: newPrice,
        reason: _reasonCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تبديل مقدم الخدمة بنجاح إلى $newNurse وتحويل $transferredCount ورديات متبقية 🔄',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.amber.shade900,
            duration: const Duration(seconds: 4),
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
