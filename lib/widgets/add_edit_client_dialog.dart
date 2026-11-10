import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class AddEditClientDialog extends StatefulWidget {
  final ClientModel? client;

  const AddEditClientDialog({super.key, this.client});

  @override
  State<AddEditClientDialog> createState() => _AddEditClientDialogState();
}

class _AddEditClientDialogState extends State<AddEditClientDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _healthConditionController;
  late TextEditingController _nurseController;
  late TextEditingController _notesController;

  // New vs Existing Client
  late bool _isExistingClient;
  // If existing: true = credit for client (+), false = debt on client (-)
  late bool _isCreditForClient;
  late TextEditingController _openingAmountController;

  // Optional direct pricing if user has permission
  late TextEditingController _dailyPriceController;
  late TextEditingController _nurseDailyPriceController;
  late String _serviceType;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _healthConditionController = TextEditingController(text: c?.healthCondition ?? '');
    _nurseController = TextEditingController(text: c?.nurseAssigned ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');

    _isExistingClient = c?.isExistingClient ?? false;
    final opBal = c?.openingBalance ?? 0.0;
    _isCreditForClient = opBal >= 0;
    _openingAmountController = TextEditingController(
      text: opBal != 0 ? opBal.abs().toStringAsFixed(0) : '',
    );

    _dailyPriceController = TextEditingController(
      text: (c != null && c.dailyPrice > 0) ? c.dailyPrice.toStringAsFixed(0) : '',
    );
    _nurseDailyPriceController = TextEditingController(
      text: (c != null && c.nurseDailyPrice > 0) ? c.nurseDailyPrice.toStringAsFixed(0) : '',
    );
    _serviceType = c?.serviceType ?? 'hours12';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _healthConditionController.dispose();
    _nurseController.dispose();
    _notesController.dispose();
    _openingAmountController.dispose();
    _dailyPriceController.dispose();
    _nurseDailyPriceController.dispose();
    super.dispose();
  }

  double _calculateComputedOpeningBalance() {
    if (!_isExistingClient) return 0.0;
    final amt = double.tryParse(_openingAmountController.text.trim()) ?? 0.0;
    return _isCreditForClient ? amt.abs() : -amt.abs();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isEditing = widget.client != null;

    final clientPrice = double.tryParse(_dailyPriceController.text.trim()) ?? 0.0;
    final nursePrice = double.tryParse(_nurseDailyPriceController.text.trim()) ?? 0.0;
    final dailyProfit = clientPrice - nursePrice;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 540,
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_alt_1, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'تعديل بيانات الحالة' : 'تسجيل حالة / عميل جديد',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const Text(
                              'إدخال بيانات المريض، نوع العميل، وتفاصيل الخدمة والحسابات',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 1. Client Type Question (جديد أم حالي)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تصنيف الحالة: هل العميل جديد أم حالي؟ *',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _isExistingClient = false),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isExistingClient ? AppTheme.accent.withOpacity(0.12) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !_isExistingClient ? AppTheme.accent : Colors.grey.shade300,
                                      width: !_isExistingClient ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        !_isExistingClient ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: !_isExistingClient ? AppTheme.accent : Colors.grey,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'عميل جديد (أول مرة)',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: !_isExistingClient ? FontWeight.bold : FontWeight.normal,
                                          color: !_isExistingClient ? AppTheme.accent : Colors.grey.shade800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _isExistingClient = true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isExistingClient ? AppTheme.primary.withOpacity(0.12) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _isExistingClient ? AppTheme.primary : Colors.grey.shade300,
                                      width: _isExistingClient ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isExistingClient ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: _isExistingClient ? AppTheme.primary : Colors.grey,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'عميل حالي (رصيد سابق)',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: _isExistingClient ? FontWeight.bold : FontWeight.normal,
                                          color: _isExistingClient ? AppTheme.primary : Colors.grey.shade800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // If Existing Client -> Ask for Opening Balance (+ or -)
                        if (_isExistingClient) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.shade400, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.amber),
                                    SizedBox(width: 6),
                                    Text(
                                      'المبالغ المدفوعة مسبقاً / الرصيد السابق للعميل:',
                                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _isCreditForClient = true),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: _isCreditForClient ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _isCreditForClient ? Colors.green : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _isCreditForClient ? Icons.add_circle : Icons.circle_outlined,
                                                color: _isCreditForClient ? Colors.green : Colors.grey,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'بالموجب (+) مستحق للعميل',
                                                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _isCreditForClient = false),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: !_isCreditForClient ? Colors.red.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: !_isCreditForClient ? Colors.red : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                !_isCreditForClient ? Icons.remove_circle : Icons.circle_outlined,
                                                color: !_isCreditForClient ? Colors.red : Colors.grey,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'بالسالب (-) مستحق على العميل',
                                                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _openingAmountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: _isCreditForClient
                                        ? 'مبلغ الدفعة المقدمة المستحقة للعميل (ج.م) *'
                                        : 'مبلغ المديونية المستحقة على العميل للشركة (ج.م) *',
                                    prefixIcon: Icon(
                                      _isCreditForClient ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: _isCreditForClient ? Colors.green : Colors.red,
                                    ),
                                    suffixText: 'ج.م',
                                    filled: true,
                                    fillColor: _isCreditForClient ? Colors.green.shade50.withOpacity(0.3) : Colors.red.shade50.withOpacity(0.3),
                                  ),
                                  validator: (v) {
                                    if (_isExistingClient && (v == null || v.trim().isEmpty)) {
                                      return 'يرجى إدخال مبلغ الرصيد الافتتاحي';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isCreditForClient
                                      ? '💡 المبلغ بالموجب: يعتبر رصيداً لصالح العميل يغطي أيام الخدمة القادمة.'
                                      : '⚠️ المبلغ بالسالب: يعتبر مديونية سابقة على العميل تلزمه بالسداد.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _isCreditForClient ? Colors.green.shade800 : Colors.red.shade800,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المريض / العميل *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم العميل' : null,
                  ),
                  const SizedBox(height: 14),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف للتواصل *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                  ),
                  const SizedBox(height: 14),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'العنوان بالتفصيل (المنطقة، الشارع، رقم العمارة، الدور) *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال العنوان بالتفصيل' : null,
                  ),
                  const SizedBox(height: 14),

                  // Health Condition
                  TextFormField(
                    controller: _healthConditionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'الحالة الصحية والتشخيص الطبي بالتفصيل *',
                      hintText: 'مثال: مريض سكر، جلطة سابقة، يحتاج قسطرة، رعاية ما بعد جراحة...',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال الحالة الصحية والتشخيص' : null,
                  ),
                  const SizedBox(height: 14),

                  // Pricing & Nurse Rate Section (for authorized users or managers)
                  if (provider.canSetPrice || provider.canEditAnyData) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.monetization_on_outlined, size: 18, color: AppTheme.primary),
                              SizedBox(width: 6),
                              Text(
                                'التسعير ويومية الممرض (مكسب الشركة من فرق السعر):',
                                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dailyPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'سعر العميل (ج.م/يوم)',
                                    prefixIcon: Icon(Icons.attach_money),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _nurseDailyPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'يومية الممرض (ج.م/يوم)',
                                    prefixIcon: Icon(Icons.medical_information_outlined),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Live difference preview
                          if (clientPrice > 0 || nursePrice > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: dailyProfit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'مكسب الشركة اليومي من الحالة: ${dailyProfit.toStringAsFixed(0)} ج.م/يوم',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: dailyProfit >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                  ),
                                  Text(
                                    '($clientPrice - $nursePrice)',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Shift Type
                          DropdownButtonFormField<String>(
                            value: _serviceType,
                            decoration: const InputDecoration(
                              labelText: 'نوع الشيفت المتفق عليه',
                              prefixIcon: Icon(Icons.schedule),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'hours8', child: Text('وردية 8 ساعات', style: TextStyle(fontFamily: 'Cairo'))),
                              DropdownMenuItem(value: 'hours10', child: Text('وردية 10 ساعات', style: TextStyle(fontFamily: 'Cairo'))),
                              DropdownMenuItem(value: 'hours12', child: Text('وردية يومية (12 ساعة)', style: TextStyle(fontFamily: 'Cairo'))),
                              DropdownMenuItem(value: 'hours24', child: Text('إقامة كاملة (24 ساعة)', style: TextStyle(fontFamily: 'Cairo'))),
                              DropdownMenuItem(value: 'custom', child: Text('ساعات عمل مخصصة', style: TextStyle(fontFamily: 'Cairo'))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _serviceType = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Nurse Assigned
                  TextFormField(
                    controller: _nurseController,
                    decoration: const InputDecoration(
                      labelText: 'الممرض / الممرضة المسند له الحالة (اختياري)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات إضافية وتوصيات خاصة',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Action Buttons
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
                            if (_formKey.currentState!.validate()) {
                              final openingBal = _calculateComputedOpeningBalance();
                              final cPrice = double.tryParse(_dailyPriceController.text.trim()) ?? (widget.client?.dailyPrice ?? 0.0);
                              final nPrice = double.tryParse(_nurseDailyPriceController.text.trim()) ?? (widget.client?.nurseDailyPrice ?? 0.0);

                              if (isEditing) {
                                final updated = widget.client!.copyWith(
                                  name: _nameController.text.trim(),
                                  phone: _phoneController.text.trim(),
                                  address: _addressController.text.trim(),
                                  healthCondition: _healthConditionController.text.trim(),
                                  nurseAssigned: _nurseController.text.trim(),
                                  notes: _notesController.text.trim(),
                                  isExistingClient: _isExistingClient,
                                  openingBalance: openingBal,
                                  dailyPrice: cPrice,
                                  nurseDailyPrice: nPrice,
                                  serviceType: _serviceType,
                                );
                                await provider.editClient(updated);
                              } else {
                                await provider.addClient(
                                  name: _nameController.text.trim(),
                                  phone: _phoneController.text.trim(),
                                  address: _addressController.text.trim(),
                                  healthCondition: _healthConditionController.text.trim(),
                                  nurseAssigned: _nurseController.text.trim(),
                                  notes: _notesController.text.trim(),
                                  isExistingClient: _isExistingClient,
                                  openingBalance: openingBal,
                                  dailyPrice: cPrice,
                                  nurseDailyPrice: nPrice,
                                  serviceType: _serviceType,
                                );
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing ? 'تم تحديث بيانات الحالة بنجاح' : 'تم إضافة الحالة بنجاح وتسجيل الرصيد الافتتاحي',
                                      style: const TextStyle(fontFamily: 'Cairo'),
                                    ),
                                    backgroundColor: AppTheme.accent,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isEditing ? 'حفظ التعديلات' : 'تسجيل الحالة',
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
