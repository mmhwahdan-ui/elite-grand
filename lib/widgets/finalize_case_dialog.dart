import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../services/sms_launcher_stub.dart'
    if (dart.library.js_interop) '../services/sms_launcher_web.dart';
import '../models/case_offer_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class FinalizeCaseDialog extends StatefulWidget {
  final CaseOfferModel offer;

  const FinalizeCaseDialog({super.key, required this.offer});

  @override
  State<FinalizeCaseDialog> createState() => _FinalizeCaseDialogState();
}

class _FinalizeCaseDialogState extends State<FinalizeCaseDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCaregiverId;
  late TextEditingController _clientPriceCtrl;
  late TextEditingController _nursePriceCtrl;
  late TextEditingController _notesCtrl;
  DateTime _startDate = DateTime.now();
  bool _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _clientPriceCtrl = TextEditingController(
      text: o.clientDailyPrice > 0 ? o.clientDailyPrice.toStringAsFixed(0) : '700',
    );
    _nursePriceCtrl = TextEditingController(
      text: o.nurseDailyPrice > 0 ? o.nurseDailyPrice.toStringAsFixed(0) : '450',
    );
    _notesCtrl = TextEditingController();

    if (o.applicants.isNotEmpty) {
      _selectedCaregiverId = o.applicants.first.caregiverId;
    }
  }

  @override
  void dispose() {
    _clientPriceCtrl.dispose();
    _nursePriceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _makePhoneCall(String phone) {
    launchPhoneCallUri(phone);
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCaregiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الممرض / مقدم الخدمة المتفق معه', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    setState(() => _isFinalizing = true);

    try {
      final clientPrice = double.tryParse(_clientPriceCtrl.text.trim()) ?? 0.0;
      final nursePrice = double.tryParse(_nursePriceCtrl.text.trim()) ?? 0.0;

      await provider.finalizeCaseWithZezo(
        caseOfferId: widget.offer.id,
        selectedCaregiverId: _selectedCaregiverId!,
        clientDailyPrice: clientPrice,
        nurseDailyPrice: nursePrice,
        startDate: _startDate,
        agreementNotes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 تم إتمام الحالة تليفونياً بنجاح وتسكين الممرض وتحويلها لعميل نشط في النظام!',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isFinalizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    final provider = context.watch<AppProvider>();
    final allCaregivers = provider.caregivers;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 720),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إتمام الحالة وتسكين الممرض (أ/ زيزو) 📞',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            'للحالة: ${o.title} (${o.code})',
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Step 1: Call Client Phone Section
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.phone, color: Colors.green, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'العميل: ${o.clientName.isNotEmpty ? o.clientName : "عميل جديد"}',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'رقم الهاتف: ${o.clientPhone.isNotEmpty ? o.clientPhone : "لم يسجل"}',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (o.clientPhone.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () => _makePhoneCall(o.clientPhone),
                                  icon: const Icon(Icons.call, size: 16),
                                  label: const Text('اتصال فوري 📞', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Step 2: Choose Caregiver from Applicants or all registered
                        const Text(
                          'اختيار مقدم الخدمة / الممرض المعتمد للحالة:',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),

                        if (o.applicants.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.people_alt_outlined, color: Colors.teal, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'المتقدمين الراغبين في تنفيذ الحالة (${o.applicants.length}):',
                                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal.shade900),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...o.applicants.map((a) {
                                  final isSelected = _selectedCaregiverId == a.caregiverId;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.teal.shade100 : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300),
                                    ),
                                    child: RadioListTile<String>(
                                      value: a.caregiverId,
                                      groupValue: _selectedCaregiverId,
                                      title: Row(
                                        children: [
                                          Text(a.caregiverName, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                                          if (a.caregiverCode.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                              child: Text(a.caregiverCode, style: const TextStyle(fontSize: 10, fontFamily: 'Cairo')),
                                            ),
                                          ],
                                        ],
                                      ),
                                      subtitle: a.notes.isNotEmpty
                                          ? Text('رسالة الممرض: ${a.notes}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.teal))
                                          : null,
                                      onChanged: (val) => setState(() => _selectedCaregiverId = val),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Option to choose any caregiver from database
                        DropdownButtonFormField<String>(
                          value: _selectedCaregiverId,
                          decoration: const InputDecoration(
                            labelText: 'أو اختر ممرضاً آخر من قاعدة الكوادر',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_search),
                          ),
                          items: allCaregivers.map((cg) {
                            return DropdownMenuItem(
                              value: cg.id,
                              child: Text(
                                '${cg.name} (${cg.code}) - ${cg.shiftPreferenceArabic} - ${cg.dailyPrice.toStringAsFixed(0)} ج',
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCaregiverId = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Step 3: Agreed Financials
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _clientPriceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'سعر العميل النهائي (ج.م) *',
                                  helperText: 'المتفق عليه هاتفياً مع العميل',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.monetization_on_outlined, color: Colors.amber),
                                  suffixText: 'ج.م',
                                ),
                                validator: (v) => v?.trim().isEmpty == true ? 'مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _nursePriceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'يومية الممرض المعتمدة (ج.م) *',
                                  helperText: 'مستحقات مقدم الخدمة لليوم',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.payments_outlined, color: Colors.teal),
                                  suffixText: 'ج.م',
                                ),
                                validator: (v) => v?.trim().isEmpty == true ? 'مطلوب' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Start Date Picker
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
                          title: const Text('تاريخ بدء واستلام الخدمة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          subtitle: Text(
                            DateFormat('yyyy/MM/dd').format(_startDate),
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          trailing: const Text('تغيير', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary)),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 7)),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setState(() => _startDate = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // Agreement Notes
                        TextFormField(
                          controller: _notesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات الاتفاق والتسكين (اختياري)',
                            hintText: 'تفاصيل مكالمة العميل أو أي اشتراطات تم الاتفاق عليها...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isFinalizing ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isFinalizing ? null : _handleConfirm,
                      icon: _isFinalizing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text(
                        'تأكيد الاتفاق وتسكين الممرض ✅',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
