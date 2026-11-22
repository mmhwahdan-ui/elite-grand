import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'add_edit_caregiver_dialog.dart';

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

  // مستحقات أو مديونية مقدم الخدمة السابقة
  late TextEditingController _nurseOpeningBalanceController;
  String _nurseBalanceType = 'zero'; // 'due', 'debt', 'zero'
  bool _hasInitializedNurseBalance = false;

  // Optional direct pricing if user has permission
  late TextEditingController _dailyPriceController;
  late TextEditingController _nurseDailyPriceController;
  late String _serviceType;

  // Weekly Service Schedule & Settlement
  late String _serviceScheduleType; // 'all_week', 'custom_days'
  late int _daysPerWeek; // 4, 5, 6, 7
  late List<int> _activeWeekdays;
  late String _settlementFrequency; // 'weekly', 'monthly'

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
    _nurseOpeningBalanceController = TextEditingController(text: '0');

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
    _serviceScheduleType = c?.serviceScheduleType ?? 'all_week';
    _daysPerWeek = c?.daysPerWeek ?? 7;
    _activeWeekdays = List<int>.from(c?.activeWeekdays ?? [1, 2, 3, 4, 5, 6, 7]);
    _settlementFrequency = c?.settlementFrequency ?? 'weekly';
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
    _nurseOpeningBalanceController.dispose();
    _dailyPriceController.dispose();
    _nurseDailyPriceController.dispose();
    super.dispose();
  }

  double _calculateComputedOpeningBalance() {
    if (!_isExistingClient) return 0.0;
    final amt = double.tryParse(_openingAmountController.text.trim()) ?? 0.0;
    return _isCreditForClient ? amt.abs() : -amt.abs();
  }

  Widget _buildDaysCountChip(int count, String label, List<int> defaultDays) {
    final isSel = _daysPerWeek == count;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _daysPerWeek = count;
            _activeWeekdays = List<int>.from(defaultDays);
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? Colors.teal.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSel ? Colors.teal : Colors.grey.shade300, width: isSel ? 1.5 : 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? Colors.teal.shade900 : Colors.grey.shade800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayToggleChip(int weekday, String label) {
    final isChecked = _activeWeekdays.contains(weekday);
    return FilterChip(
      label: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: isChecked ? FontWeight.bold : FontWeight.normal)),
      selected: isChecked,
      selectedColor: Colors.teal.shade100,
      checkmarkColor: Colors.teal,
      onSelected: (val) {
        setState(() {
          if (val) {
            if (!_activeWeekdays.contains(weekday)) _activeWeekdays.add(weekday);
          } else {
            if (_activeWeekdays.length > 1) {
              _activeWeekdays.remove(weekday);
            }
          }
          _daysPerWeek = _activeWeekdays.length;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isEditing = widget.client != null;

    final clientPrice = double.tryParse(_dailyPriceController.text.trim()) ?? 0.0;
    final nursePrice = double.tryParse(_nurseDailyPriceController.text.trim()) ?? 0.0;
    final dailyProfit = clientPrice - nursePrice;
    final allNurses = provider.allNurseNames;
    final matchedCaregiver = provider.findCaregiverByName(_nurseController.text.trim());

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

                  // 3. Weekly Service Schedule & Days (نظام وتكرار الخدمة الأسبوعي)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month, color: Colors.teal, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'نظام وتكرار الخدمة الأسبوعي: *',
                              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _serviceScheduleType = 'all_week';
                                    _daysPerWeek = 7;
                                    _activeWeekdays = [1, 2, 3, 4, 5, 6, 7];
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _serviceScheduleType == 'all_week' ? Colors.teal : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _serviceScheduleType == 'all_week' ? Colors.teal : Colors.grey.shade300),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'طوال الأسبوع (7 أيام مستمرة)',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        fontWeight: _serviceScheduleType == 'all_week' ? FontWeight.bold : FontWeight.normal,
                                        color: _serviceScheduleType == 'all_week' ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _serviceScheduleType = 'custom_days';
                                    if (_daysPerWeek == 7) {
                                      _daysPerWeek = 5;
                                      _activeWeekdays = [6, 7, 1, 2, 3]; // السبت للأربعاء
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _serviceScheduleType == 'custom_days' ? Colors.teal : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _serviceScheduleType == 'custom_days' ? Colors.teal : Colors.grey.shade300),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'أيام محددة (4 أو 5 أيام أسبوعياً)',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        fontWeight: _serviceScheduleType == 'custom_days' ? FontWeight.bold : FontWeight.normal,
                                        color: _serviceScheduleType == 'custom_days' ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_serviceScheduleType == 'custom_days') ...[
                          const SizedBox(height: 10),
                          const Text(
                            'اختر عدد الأيام في الأسبوع:',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildDaysCountChip(4, '4 أيام أسبوعياً', [6, 7, 1, 2]),
                              const SizedBox(width: 6),
                              _buildDaysCountChip(5, '5 أيام أسبوعياً', [6, 7, 1, 2, 3]),
                              const SizedBox(width: 6),
                              _buildDaysCountChip(6, '6 أيام أسبوعياً', [6, 7, 1, 2, 3, 4]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'حدد أيام الخدمة الفعلية بالأسبوع:',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildWeekdayToggleChip(6, 'السبت'),
                              _buildWeekdayToggleChip(7, 'الأحد'),
                              _buildWeekdayToggleChip(1, 'الإثنين'),
                              _buildWeekdayToggleChip(2, 'الثلاثاء'),
                              _buildWeekdayToggleChip(3, 'الأربعاء'),
                              _buildWeekdayToggleChip(4, 'الخميس'),
                              _buildWeekdayToggleChip(5, 'الجمعة'),
                            ],
                          ),
                        ],

                        const SizedBox(height: 10),
                        // Settlement Frequency
                        Row(
                          children: [
                            const Text(
                              'دورة التقفيل المالي:',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            ChoiceChip(
                              label: const Text('تقفيل أسبوعي (كل خميس) 🔔', style: TextStyle(fontFamily: 'Cairo', fontSize: 10)),
                              selected: _settlementFrequency == 'weekly',
                              selectedColor: Colors.amber.shade200,
                              onSelected: (val) {
                                if (val) setState(() => _settlementFrequency = 'weekly');
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('تقفيل شهري 🗓️', style: TextStyle(fontFamily: 'Cairo', fontSize: 10)),
                              selected: _settlementFrequency == 'monthly',
                              selectedColor: Colors.blue.shade200,
                              onSelected: (val) {
                                if (val) setState(() => _settlementFrequency = 'monthly');
                              },
                            ),
                          ],
                        ),

                        if (clientPrice > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'المستحق أسبوعياً: ${(_daysPerWeek * clientPrice).toStringAsFixed(0)} ج.م ($_daysPerWeek أيام)',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                                if (nursePrice > 0)
                                  Text(
                                    'مستحق التمريض: ${(_daysPerWeek * nursePrice).toStringAsFixed(0)} ج.م',
                                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade700),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Nurse Assigned
                  TextFormField(
                    controller: _nurseController,
                    decoration: const InputDecoration(
                      labelText: 'الممرض / الممرضة المسند له الحالة (اختياري)',
                      prefixIcon: Icon(Icons.badge_outlined),
                      helperText: 'يمكن كتابة الاسم أو الاختيار من الكوادر المسجلة أدناه',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (allNurses.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: allNurses.map((name) {
                        final isSelected = _nurseController.text.trim() == name;
                        final cg = provider.findCaregiverByName(name);
                        return ActionChip(
                          avatar: cg != null && cg.isBlocked
                              ? const Icon(Icons.block, size: 14, color: Colors.red)
                              : (isSelected ? const Icon(Icons.check, size: 14, color: Colors.teal) : null),
                          label: Text(
                            name,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Cairo',
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: cg != null && cg.isBlocked ? Colors.red : null,
                            ),
                          ),
                          backgroundColor: isSelected ? Colors.teal.shade100 : Colors.grey.shade100,
                          onPressed: () {
                            setState(() {
                              _nurseController.text = name;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  if (_nurseController.text.trim().isNotEmpty &&
                      _nurseController.text.trim() != 'غير محدد' &&
                      _nurseController.text.trim() != 'متغير' &&
                      (matchedCaregiver == null || matchedCaregiver.code.trim().isEmpty)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'مقدم الخدمة (' + _nurseController.text.trim() + ') غير مكود بقاعدة البيانات.',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AddEditCaregiverDialog(
                                  initialName: _nurseController.text.trim(),
                                  initialClientName: _nameController.text.trim(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.badge_outlined, size: 14),
                            label: const Text('تكويد الآن ✍️', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (matchedCaregiver != null) ...[
                    const SizedBox(height: 8),
                    if (matchedCaregiver.isBlocked) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          'تحذير: هذا الممرض محظور بسبب مشاكل: ${matchedCaregiver.blockReason ?? "غير محدد"}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo'),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مقدم الخدمة مسجل بقاعدة البيانات (سعره المعتمد: ${matchedCaregiver.dailyPrice.toStringAsFixed(0)} ج/يوم)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.teal, fontFamily: 'Cairo'),
                            ),
                            const SizedBox(height: 4),
                            if (nursePrice != matchedCaregiver.dailyPrice)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _nurseDailyPriceController.text = matchedCaregiver.dailyPrice.toStringAsFixed(0);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'اضغط هنا لاعتماد نفس حسابه (${matchedCaregiver.dailyPrice.toStringAsFixed(0)} ج.م/يوم)',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Caregiver Live Financial Status & Previous Dues Card
                      Builder(builder: (context) {
                        final nurseEarned = provider.getNurseTotalEarned(matchedCaregiver.name);
                        final nurseAdvances = provider.getNurseTotalAdvances(matchedCaregiver.name);
                        final nurseRemaining = provider.getNurseRemainingBalance(matchedCaregiver.name);

                        if (!_hasInitializedNurseBalance) {
                          _hasInitializedNurseBalance = true;
                          if (matchedCaregiver.openingBalance > 0) {
                            _nurseBalanceType = 'due';
                            _nurseOpeningBalanceController.text = matchedCaregiver.openingBalance.toStringAsFixed(0);
                          } else if (matchedCaregiver.openingBalance < 0) {
                            _nurseBalanceType = 'debt';
                            _nurseOpeningBalanceController.text = matchedCaregiver.openingBalance.abs().toStringAsFixed(0);
                          }
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
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
                                    'رصيد ومستحقات الممرض (${matchedCaregiver.name}):',
                                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    nurseRemaining > 0
                                        ? 'له مستحق: ${nurseRemaining.toStringAsFixed(0)} ج.م'
                                        : (nurseRemaining < 0
                                            ? 'عليه سلف/مديونية: ${nurseRemaining.abs().toStringAsFixed(0)} ج.م'
                                            : 'خالص (0 ج.م)'),
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: nurseRemaining > 0
                                          ? Colors.green.shade800
                                          : (nurseRemaining < 0 ? Colors.red.shade800 : Colors.blueGrey),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'إجمالي ما استحقه: ${nurseEarned.toStringAsFixed(0)} ج.م | إجمالي السلف والخصومات: ${nurseAdvances.toStringAsFixed(0)} ج.م',
                                style: TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.grey.shade700),
                              ),
                              const Divider(height: 12),
                              const Text(
                                'تعديل رصيد أو مستحقات الممرض السابقة عن خدمة قديمة:',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(
                                        child: Text('مستحق له (+)', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, fontWeight: FontWeight.bold)),
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
                                        child: Text('مديونية عليه (-)', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5)),
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
                                        child: Text('خالص (0)', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5)),
                                      ),
                                      selected: _nurseBalanceType == 'zero',
                                      onSelected: (val) {
                                        if (val) {
                                          setState(() {
                                            _nurseBalanceType = 'zero';
                                            _nurseOpeningBalanceController.text = '0';
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (_nurseBalanceType != 'zero') ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nurseOpeningBalanceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: _nurseBalanceType == 'due'
                                        ? 'مستحقات سابقة للممرض (خدمة قديمة لم يحصلها)'
                                        : 'مديونية / سلفة سابقة على الممرض',
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
                        );
                      }),
                    ],
                  ],
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
                              final effectiveIsExisting = _isExistingClient || openingBal != 0.0;
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
                                  isExistingClient: effectiveIsExisting,
                                  openingBalance: openingBal,
                                  dailyPrice: cPrice,
                                  nurseDailyPrice: nPrice,
                                  serviceType: _serviceType,
                                  serviceScheduleType: _serviceScheduleType,
                                  daysPerWeek: _daysPerWeek,
                                  activeWeekdays: _activeWeekdays,
                                  settlementFrequency: _settlementFrequency,
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
                                  isExistingClient: effectiveIsExisting,
                                  openingBalance: openingBal,
                                  dailyPrice: cPrice,
                                  nurseDailyPrice: nPrice,
                                  serviceType: _serviceType,
                                  serviceScheduleType: _serviceScheduleType,
                                  daysPerWeek: _daysPerWeek,
                                  activeWeekdays: _activeWeekdays,
                                  settlementFrequency: _settlementFrequency,
                                );
                              }

                              // Update caregiver opening balance if adjusted
                              if (matchedCaregiver != null && _nurseBalanceType != 'zero') {
                                final val = double.tryParse(_nurseOpeningBalanceController.text.trim()) ?? 0.0;
                                if (val > 0) {
                                  final op = _nurseBalanceType == 'due' ? val.abs() : -val.abs();
                                  await provider.updateCaregiver(matchedCaregiver.copyWith(openingBalance: op));
                                }
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
