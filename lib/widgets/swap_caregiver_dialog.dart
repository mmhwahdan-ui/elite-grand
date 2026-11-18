import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../models/caregiver_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class SwapCaregiverDialog extends StatefulWidget {
  final ClientModel client;

  const SwapCaregiverDialog({
    super.key,
    required this.client,
  });

  @override
  State<SwapCaregiverDialog> createState() => _SwapCaregiverDialogState();
}

class _SwapCaregiverDialogState extends State<SwapCaregiverDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _newNurseController;
  late TextEditingController _newDailyPriceController;
  late TextEditingController _reasonController;

  CaregiverModel? _selectedCaregiver;
  DateTime _effectiveDate = DateTime.now();
  bool _updateUpcomingShifts = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _newNurseController = TextEditingController();
    _newDailyPriceController = TextEditingController(
      text: widget.client.nurseDailyPrice > 0
          ? widget.client.nurseDailyPrice.toStringAsFixed(0)
          : '',
    );
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _newNurseController.dispose();
    _newDailyPriceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double get _currentNewPrice =>
      double.tryParse(_newDailyPriceController.text.trim()) ?? 0.0;
  double get _companyProfit => widget.client.dailyPrice - _currentNewPrice;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final registeredCaregivers = provider.caregivers;
    final currentNurse = widget.client.nurseAssigned?.trim();
    final hasCurrentNurse = currentNurse != null && currentNurse.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 750),
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
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
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.swap_horiz, color: Colors.teal, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تبديل مقدم الخدمة / الممرض للحالة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'العميل: ${widget.client.name}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Current Caregiver Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_pin, size: 18, color: Colors.blueGrey),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'مقدم الخدمة الحالي المسند:',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hasCurrentNurse ? Colors.blue.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      hasCurrentNurse ? currentNurse : 'لم يُحدد بعد',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: hasCurrentNurse ? Colors.blue.shade800 : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (hasCurrentNurse) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'يومية التمريض الحالية: ${widget.client.nurseDailyPrice.toStringAsFixed(0)} ج.م • سعر العميل: ${widget.client.dailyPrice.toStringAsFixed(0)} ج.م',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Select from registered caregivers
                        const Text(
                          'اختيار مقدم الخدمة الجديد من قاعدة البيانات:',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        if (registeredCaregivers.isNotEmpty) ...[
                          DropdownButtonFormField<CaregiverModel>(
                            initialValue: _selectedCaregiver,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              hintText: 'اختر ممرض مسجل (الاسم / الكود / اليومية)...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: registeredCaregivers.map((cg) {
                              final statusTxt = cg.isCurrentlyWorking ? ' (على رأس عمل)' : ' (متفرغ)';
                              final priceTxt = cg.dailyPrice > 0 ? ' - ${cg.dailyPrice.toStringAsFixed(0)} ج' : '';
                              return DropdownMenuItem<CaregiverModel>(
                                value: cg,
                                child: Text(
                                  '${cg.name} [${cg.code}]$priceTxt$statusTxt',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (CaregiverModel? cg) {
                              if (cg != null) {
                                setState(() {
                                  _selectedCaregiver = cg;
                                  _newNurseController.text = cg.name;
                                  if (cg.dailyPrice > 0) {
                                    _newDailyPriceController.text = cg.dailyPrice.toStringAsFixed(0);
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Custom nurse name
                        TextFormField(
                          controller: _newNurseController,
                          decoration: const InputDecoration(
                            labelText: 'اسم مقدم الخدمة الجديد *',
                            hintText: 'اكتب اسم الممرض أو عدله',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_add_alt_1),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'يرجى إدخال أو اختيار اسم مقدم الخدمة الجديد';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Effective date
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          leading: const Icon(Icons.calendar_month, color: AppTheme.primary),
                          title: const Text('تاريخ سريان التبديل:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          subtitle: Text(
                            DateFormat('yyyy/MM/dd').format(_effectiveDate),
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.edit_calendar, size: 16),
                            label: const Text('تغيير', style: TextStyle(fontFamily: 'Cairo')),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _effectiveDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _effectiveDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // New daily price
                        TextFormField(
                          controller: _newDailyPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'يومية مقدم الخدمة الجديد *',
                            suffixText: 'ج.م',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'يرجى تحديد يومية مقدم الخدمة الجديد';
                            }
                            final val = double.tryParse(v.trim());
                            if (val == null || val <= 0) {
                              return 'يرجى إدخال مبلغ صحيح أكبر من الصفر';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Profit preview
                        if (widget.client.dailyPrice > 0 && _currentNewPrice > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _companyProfit >= 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _companyProfit >= 0 ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _companyProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                                  size: 18,
                                  color: _companyProfit >= 0 ? const Color(0xFF16A34A) : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'صافي ربح الشركة اليومي الجديد: ${_companyProfit.toStringAsFixed(0)} ج.م (سعر العميل: ${widget.client.dailyPrice.toStringAsFixed(0)} - يومية الممرض: ${_currentNewPrice.toStringAsFixed(0)})',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _companyProfit >= 0 ? const Color(0xFF15803D) : Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Checkbox for updating upcoming shifts
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'تحديث الورديات المستقبلية تلقائياً للممرض الجديد',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'الورديات السابقة لتاريخ التبديل تظل مسجلة ومحسوبة للممرض القديم، والورديات ابتداءً من تاريخ التبديل تُنقل للممرض الجديد بيوميته الجديدة.',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                          ),
                          value: _updateUpcomingShifts,
                          activeColor: Colors.teal,
                          onChanged: (v) => setState(() => _updateUpcomingShifts = v ?? true),
                        ),
                        const SizedBox(height: 10),

                        // Reason / notes
                        TextFormField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: 'سبب التبديل / ملاحظات إدارية',
                            hintText: 'مثال: طلب العميل تغيير الممرضة، ظروف طارئة، انتهاء المدة...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isSubmitting ? 'جاري التبديل...' : 'تأكيد التبديل وتحديث الحسابات 🔄',
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _isSubmitting = true);

                                final newNurse = _newNurseController.text.trim();
                                final newPrice = double.tryParse(_newDailyPriceController.text.trim()) ?? 0.0;
                                final reason = _reasonController.text.trim();

                                await provider.swapClientCaregiver(
                                  clientId: widget.client.id,
                                  newNurseName: newNurse,
                                  newNurseDailyPrice: newPrice,
                                  effectiveDate: _effectiveDate,
                                  updateUpcomingShifts: _updateUpcomingShifts,
                                  reason: reason.isNotEmpty ? reason : null,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'تم تبديل مقدم الخدمة للعميل "${widget.client.name}" إلى "$newNurse" وتحديث الحسابات بنجاح',
                                        style: const TextStyle(fontFamily: 'Cairo'),
                                      ),
                                      backgroundColor: Colors.teal,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
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
