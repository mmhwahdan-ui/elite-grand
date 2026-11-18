import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_offer_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class AddEditCaseOfferDialog extends StatefulWidget {
  final CaseOfferModel? offer;

  const AddEditCaseOfferDialog({super.key, this.offer});

  @override
  State<AddEditCaseOfferDialog> createState() => _AddEditCaseOfferDialogState();
}

class _AddEditCaseOfferDialogState extends State<AddEditCaseOfferDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _nursePriceCtrl;
  late TextEditingController _requirementsCtrl;
  late TextEditingController _clientNameCtrl;
  late TextEditingController _clientPhoneCtrl;
  late TextEditingController _clientPriceCtrl;
  late TextEditingController _notesCtrl;

  String _shiftType = 'hours12';
  String _genderPreference = 'any';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _titleCtrl = TextEditingController(text: o?.title ?? '');
    _descriptionCtrl = TextEditingController(text: o?.patientDescription ?? '');
    _cityCtrl = TextEditingController(text: o?.city.isNotEmpty == true ? o!.city : 'القاهرة');
    _areaCtrl = TextEditingController(text: o?.area ?? '');
    _nursePriceCtrl = TextEditingController(text: o != null && o.nurseDailyPrice > 0 ? o.nurseDailyPrice.toStringAsFixed(0) : '450');
    _requirementsCtrl = TextEditingController(text: o?.requirements ?? '');
    _clientNameCtrl = TextEditingController(text: o?.clientName ?? '');
    _clientPhoneCtrl = TextEditingController(text: o?.clientPhone ?? '');
    _clientPriceCtrl = TextEditingController(text: o != null && o.clientDailyPrice > 0 ? o.clientDailyPrice.toStringAsFixed(0) : '700');
    _notesCtrl = TextEditingController(text: o?.notes ?? '');
    _shiftType = o?.shiftType ?? 'hours12';
    _genderPreference = o?.genderPreference ?? 'any';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _nursePriceCtrl.dispose();
    _requirementsCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _clientPriceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();
    setState(() => _isSaving = true);

    try {
      final nursePrice = double.tryParse(_nursePriceCtrl.text.trim()) ?? 0.0;
      final clientPrice = double.tryParse(_clientPriceCtrl.text.trim()) ?? 0.0;

      if (widget.offer == null) {
        // Add new
        await provider.addCaseOffer(
          title: _titleCtrl.text.trim(),
          patientDescription: _descriptionCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          area: _areaCtrl.text.trim(),
          shiftType: _shiftType,
          nurseDailyPrice: nursePrice,
          genderPreference: _genderPreference,
          requirements: _requirementsCtrl.text.trim(),
          clientName: _clientNameCtrl.text.trim(),
          clientPhone: _clientPhoneCtrl.text.trim(),
          clientDailyPrice: clientPrice,
          notes: _notesCtrl.text.trim(),
        );
      } else {
        // Edit existing
        final updated = widget.offer!.copyWith(
          title: _titleCtrl.text.trim(),
          patientDescription: _descriptionCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          area: _areaCtrl.text.trim(),
          shiftType: _shiftType,
          nurseDailyPrice: nursePrice,
          genderPreference: _genderPreference,
          requirements: _requirementsCtrl.text.trim(),
          clientName: _clientNameCtrl.text.trim(),
          clientPhone: _clientPhoneCtrl.text.trim(),
          clientDailyPrice: clientPrice,
          notes: _notesCtrl.text.trim(),
        );
        await provider.updateCaseOffer(updated);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.offer == null
                  ? 'تم نشر الحالة بنجاح في جروب مقدمي الخدمة وإرسال إشعار فوري 📢'
                  : 'تم تحديث بيانات الحالة المعروضة بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
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
    final isEdit = widget.offer != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppTheme.accentBright, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'تعديل الحالة المعروضة' : 'نشر حالة جديدة في جروب التمريض 📢',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const Text(
                            'تظهر الحالة فوراً لجميع مقدمي الخدمة المسجلين مع سعر التمريض فقط',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Cairo'),
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

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section 1: Public details for nurses
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.public, color: Colors.teal, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'البيانات المعروضة للتمريض في الجروب',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.teal.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Title
                              TextFormField(
                                controller: _titleCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'عنوان الحالة / الطلب *',
                                  hintText: 'مثال: رعاية مسن - المعادي / مريض زهايمر',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.label_outline),
                                ),
                                validator: (v) => v?.trim().isEmpty == true ? 'يرجى إدخال عنوان الحالة' : null,
                              ),
                              const SizedBox(height: 12),

                              // City & Area
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cityCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'المدينة / المحافظة *',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.location_city),
                                      ),
                                      validator: (v) => v?.trim().isEmpty == true ? 'مطلوب' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _areaCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'المنطقة / الحي *',
                                        hintText: 'مثال: المعادي دجلة',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.place_outlined),
                                      ),
                                      validator: (v) => v?.trim().isEmpty == true ? 'مطلوب' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Shift Type & Gender
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _shiftType,
                                      decoration: const InputDecoration(
                                        labelText: 'نوع الوردية *',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'hours12', child: Text('وردية 12 ساعة', style: TextStyle(fontFamily: 'Cairo'))),
                                        DropdownMenuItem(value: 'hours24', child: Text('إقامة 24 ساعة', style: TextStyle(fontFamily: 'Cairo'))),
                                        DropdownMenuItem(value: 'hours8', child: Text('وردية 8 ساعات', style: TextStyle(fontFamily: 'Cairo'))),
                                        DropdownMenuItem(value: 'hours10', child: Text('وردية 10 ساعات', style: TextStyle(fontFamily: 'Cairo'))),
                                        DropdownMenuItem(value: 'custom', child: Text('ساعات مخصصة', style: TextStyle(fontFamily: 'Cairo'))),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setState(() => _shiftType = val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _genderPreference,
                                      decoration: const InputDecoration(
                                        labelText: 'تفضيل التمريض',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'any', child: Text('أي منهما (متاح للكل)', style: TextStyle(fontFamily: 'Cairo'))),
                                        DropdownMenuItem(value: 'male', child: Text('ممرض (ذكر)', style: TextStyle(fontFamily: 'Cairo'))),
                                        DropdownMenuItem(value: 'female', child: Text('ممرضة (أنثى)', style: TextStyle(fontFamily: 'Cairo'))),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setState(() => _genderPreference = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Nurse Price
                              TextFormField(
                                controller: _nursePriceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'سعر التمريض / اليومية المحددة (ج.م) *',
                                  hintText: '450',
                                  helperText: 'هذا السعر يظهر في الجروب ليوافق عليه مقدم الخدمة',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.payments_outlined, color: Colors.teal),
                                  suffixText: 'ج.م / يوم',
                                ),
                                validator: (v) {
                                  if (v?.trim().isEmpty == true) return 'مطلوب تحديد يومية التمريض';
                                  final num = double.tryParse(v!.trim());
                                  if (num == null || num <= 0) return 'يرجى إدخال مبلغ صحيح';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Patient Description
                              TextFormField(
                                controller: _descriptionCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'تفاصيل ووصف الحالة المرضية *',
                                  hintText: 'مثال: مسن 78 سنة، قرح فراش، أنبوبة تغذية رايل، قياس سكر وضغط، متابعة دورية...',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v?.trim().isEmpty == true ? 'يرجى كتابة وصف تفاصيل الحالة' : null,
                              ),
                              const SizedBox(height: 12),

                              // Requirements
                              TextFormField(
                                controller: _requirementsCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'متطلبات واشتراطات خاصة (اختياري)',
                                  hintText: 'مثال: خبرة رعاية مركزة، قسطرة بولية، غير مدخن...',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.verified_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Management & Client Confidential Details (Only for Wahdan, Shimaa, Zezo)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings, color: Colors.amber, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'بيانات الإدارة والتواصل والربحية (سرية - للإدارة فقط)',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.brown.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '🔒 لن يظهر رقم هاتف العميل أو سعر الشركة لأي ممرض في الجروب، فقط يظهر لـ أ/ زيزو وأ/ وهدان وأ/ شيماء لإتمام الحالة.',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.brown.shade600),
                              ),
                              const SizedBox(height: 12),

                              // Client Name
                              TextFormField(
                                controller: _clientNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'اسم العميل / المتصل (خاص بالإدارة)',
                                  hintText: 'اسم الشخص الذي اتصل بـ أ/ شيماء',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Client Phone & Client Price
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _clientPhoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        labelText: 'رقم هاتف العميل *',
                                        hintText: '01xxxxxxxxx',
                                        helperText: 'لإجراء مكالمة أ/ زيزو لإتمام الحالة 📞',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.phone_in_talk, color: Colors.green),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _clientPriceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'سعر العميل اليومي للشركة (ج.م)',
                                        hintText: '700',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.attach_money, color: Colors.amber),
                                        suffixText: 'ج.م',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Internal Notes
                              TextFormField(
                                controller: _notesCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'ملاحظات إدارية وتنسيقية (اختياري)',
                                  hintText: 'أي ملاحظات بين شيماء وزيزو بخصوص الاتفاق...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Actions Footer
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
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.campaign, size: 20),
                      label: Text(
                        isEdit ? 'حفظ التعديلات' : 'نشر في جروب التمريض 📢',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
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
