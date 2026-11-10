import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class AddServiceDayDialog extends StatefulWidget {
  final ClientModel client;

  const AddServiceDayDialog({
    super.key,
    required this.client,
  });

  @override
  State<AddServiceDayDialog> createState() => _AddServiceDayDialogState();
}

class _AddServiceDayDialogState extends State<AddServiceDayDialog> {
  final _formKey = GlobalKey<FormState>();

  // Mode: 0 = Single Day, 1 = Batch Days (Variable Weekly)
  int _selectedMode = 0;

  // Single Day Fields
  DateTime _singleDate = DateTime.now();
  late TextEditingController _nurseNameController;
  late TextEditingController _clientPriceController;
  late TextEditingController _nursePriceController;
  final TextEditingController _notesController = TextEditingController();
  String _shiftType = 'hours12';
  String? _startTime;
  String? _endTime;
  double? _hoursCount;

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  void _autoSuggestEndTime(TimeOfDay start) {
    int addHours = 12;
    if (_shiftType == 'hours24') addHours = 24;
    if (_shiftType == 'hours8') addHours = 8;
    if (_shiftType == 'hours10') addHours = 10;

    final newHour = (start.hour + addHours) % 24;
    final end = TimeOfDay(hour: newHour, minute: start.minute);
    setState(() {
      _endTime = _formatTimeOfDay(end);
    });
  }

  // Batch Days Fields
  DateTime _batchStartDate = DateTime.now();
  int _batchDaysCount = 4; // Default 4 days weekly
  final List<DateTime> _customDates = [];
  bool _useExplicitDates = false;

  bool _isSubmitting = false;

    @override
  void initState() {
    super.initState();
    _nurseNameController = TextEditingController(text: widget.client.nurseAssigned ?? '');
    _clientPriceController = TextEditingController(
      text: widget.client.dailyPrice > 0 ? widget.client.dailyPrice.toStringAsFixed(0) : '',
    );
    _nursePriceController = TextEditingController(
      text: widget.client.nurseDailyPrice > 0 ? widget.client.nurseDailyPrice.toStringAsFixed(0) : '',
    );
    _shiftType = widget.client.serviceType.isNotEmpty ? widget.client.serviceType : 'hours12';

    if (widget.client.startDate != null) {
      _batchStartDate = widget.client.startDate!;
      if (widget.client.endDate != null) {
        _batchDaysCount = widget.client.servedDays;
        _selectedMode = 1;
      }
    }

    _generateDefaultBatchDates();
  }

  void _generateDefaultBatchDates() {
    _customDates.clear();
    for (int i = 0; i < _batchDaysCount; i++) {
      _customDates.add(_batchStartDate.add(Duration(days: i)));
    }
  }

  @override
  void dispose() {
    _nurseNameController.dispose();
    _clientPriceController.dispose();
    _nursePriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _currentClientPrice => double.tryParse(_clientPriceController.text.trim()) ?? 0.0;
  double get _currentNursePrice => double.tryParse(_nursePriceController.text.trim()) ?? 0.0;
  double get _currentProfitDifference => _currentClientPrice - _currentNursePrice;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final provider = context.watch<AppProvider>();
    final allNurses = provider.allNurseNames;
    final matchedCaregiver = provider.findCaregiverByName(_nurseNameController.text.trim());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 580,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
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
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available,
                      color: AppTheme.primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تسجيل أيام الخدمة والشفتات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'الحالة: ${widget.client.name}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Contract Period & Calculated Accounts Info Card
              if (widget.client.startDate != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, color: Colors.indigo, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.client.endDate != null
                                  ? 'المدة المحددة للتعاقد: من ${dateFormat.format(widget.client.startDate!)} إلى ${dateFormat.format(widget.client.endDate!)} (${widget.client.servedDays} يوم)'
                                  : 'تاريخ بدء الخدمة: ${dateFormat.format(widget.client.startDate!)} (مدة مفتوحة)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.client.isExistingClient ? 'عميل حالي' : 'عميل جديد',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'حساب العميل عن المدة: ${(widget.client.servedDays * widget.client.dailyPrice).toStringAsFixed(0)} ج.م',
                            style: TextStyle(fontSize: 12, color: Colors.indigo.shade900, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'حساب مقدم الخدمة: ${(widget.client.servedDays * widget.client.nurseDailyPrice).toStringAsFixed(0)} ج.م',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (widget.client.endDate != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedMode = 1;
                                _batchStartDate = widget.client.startDate!;
                                _batchDaysCount = widget.client.servedDays;
                                _generateDefaultBatchDates();
                              });
                            },
                            icon: const Icon(Icons.playlist_add_check, size: 18),
                            label: Text(
                              'تطبيق وتسجيل أيام المدة المحددة (${widget.client.servedDays} يوم) في الحسابات',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Mode Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedMode = 0),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedMode == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedMode == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'تسجيل يوم فردي',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedMode == 0 ? FontWeight.bold : FontWeight.normal,
                              color: _selectedMode == 0 ? AppTheme.primaryColor : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedMode = 1),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedMode == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedMode == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'تسجيل باقة / عدة أيام (أسبوعي متغير)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedMode == 1 ? FontWeight.bold : FontWeight.normal,
                              color: _selectedMode == 1 ? AppTheme.primaryColor : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable Form Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_selectedMode == 0) ...[
                        // Single Day Date Picker
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _singleDate,
                              firstDate: DateTime(2023),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                              locale: const Locale('ar'),
                            );
                            if (picked != null) {
                              setState(() => _singleDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: AppTheme.primaryColor, size: 20),
                                const SizedBox(width: 10),
                                const Text('تاريخ اليوم / الوردية:', style: TextStyle(fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text(
                                  dateFormat.format(_singleDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Batch Days Settings
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.tune, color: AppTheme.primaryColor, size: 18),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'تحديد الأيام لهذا الأسبوع أو الفترة:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _batchStartDate,
                                          firstDate: DateTime(2023),
                                          lastDate: DateTime.now().add(const Duration(days: 60)),
                                          locale: const Locale('ar'),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            _batchStartDate = picked;
                                            _generateDefaultBatchDates();
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('تاريخ البداية', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                            Text(
                                              dateFormat.format(_batchStartDate),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Days Count Counter
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 18),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: _batchDaysCount > 1
                                              ? () {
                                                  setState(() {
                                                    _batchDaysCount--;
                                                    _generateDefaultBatchDates();
                                                  });
                                                }
                                              : null,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Column(
                                            children: [
                                              const Text('عدد الأيام', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text(
                                                '$_batchDaysCount أيام',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 18),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: _batchDaysCount < 31
                                              ? () {
                                                  setState(() {
                                                    _batchDaysCount++;
                                                    _generateDefaultBatchDates();
                                                  });
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Quick presets
                              Wrap(
                                spacing: 8,
                                children: [
                                  ActionChip(
                                    label: const Text('3 أيام أسبوعياً', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      setState(() {
                                        _batchDaysCount = 3;
                                        _generateDefaultBatchDates();
                                      });
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text('4 أيام أسبوعياً', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      setState(() {
                                        _batchDaysCount = 4;
                                        _generateDefaultBatchDates();
                                      });
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text('5 أيام أسبوعياً', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      setState(() {
                                        _batchDaysCount = 5;
                                        _generateDefaultBatchDates();
                                      });
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text('أسبوع كامل (7 أيام)', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      setState(() {
                                        _batchDaysCount = 7;
                                        _generateDefaultBatchDates();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Nurse Name with quick list
                      TextFormField(
                        controller: _nurseNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم الممرض / الممرضة القائم بالخدمة *',
                          prefixIcon: const Icon(Icons.medical_services_outlined, color: Colors.teal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          helperText: 'يمكنك كتابة ممرض أو الاختيار السريع من القائمة أدناه',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى كتابة اسم الممرض';
                          }
                          return null;
                        },
                      ),

                      // Quick Nurse Selection Chips
                      if (allNurses.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'اختيار سريع من الكوادر والتمريض:',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: allNurses.map((name) {
                            final isSelected = _nurseNameController.text.trim() == name;
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
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.teal
                                    : (cg != null && cg.isBlocked ? Colors.red.shade300 : Colors.grey.shade300),
                              ),
                              onPressed: () {
                                setState(() {
                                  _nurseNameController.text = name;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      // Smart Nurse Account Inquiry / Alert (تسأل يسجل بنفس الحسابات أم لا)
                      if (matchedCaregiver != null) ...[
                        const SizedBox(height: 10),
                        if (matchedCaregiver.isBlocked) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'تحذير: هذا الممرض محظور بسبب مشاكل: ${matchedCaregiver.blockReason ?? "غير محدد"}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.teal.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified, color: Colors.teal, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      'مقدم الخدمة مسجل بقاعدة البيانات (${matchedCaregiver.code})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal, fontFamily: 'Cairo'),
                                    ),
                                    const Spacer(),
                                    if (matchedCaregiver.isCurrentlyWorking || provider.getCaregiverCurrentCase(matchedCaregiver.name) != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.green),
                                        ),
                                        child: Text(
                                          'يعمل الآن مع: ${provider.getCaregiverCurrentCase(matchedCaregiver.name) ?? matchedCaregiver.currentClientName ?? ""}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF14532D), fontFamily: 'Cairo'),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'السعر المعتمد للممرض: ${matchedCaregiver.dailyPrice.toStringAsFixed(0)} ج.م / يوم (${matchedCaregiver.shiftPreferenceArabic})',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontFamily: 'Cairo'),
                                ),
                                const SizedBox(height: 8),
                                if (_currentNursePrice == matchedCaregiver.dailyPrice) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check, size: 14, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text(
                                          'يتم التسجيل بنفس الحسابات والسعر المعتمد للممرض',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green, fontFamily: 'Cairo'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'هل تريد تسجيل الوردية بنفس الحسابات والأسعار المسجلة له (${matchedCaregiver.dailyPrice.toStringAsFixed(0)} ج)؟',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), fontFamily: 'Cairo'),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _nursePriceController.text = matchedCaregiver.dailyPrice.toStringAsFixed(0);
                                          });
                                        },
                                        icon: const Icon(Icons.check, size: 14),
                                        label: Text(
                                          'نعم، تطبيق حسابه المعتمد (${matchedCaregiver.dailyPrice.toStringAsFixed(0)} ج)',
                                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          elevation: 0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          // Keep custom price
                                        },
                                        child: Text(
                                          'لا، الإبقاء على سعر مخصص (${_currentNursePrice.toStringAsFixed(0)} ج)',
                                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),

                      // Shift Type Selector
                      DropdownButtonFormField<String>(
                        value: _shiftType,
                        decoration: InputDecoration(
                          labelText: 'نوع الوردية / الشفت وساعات العمل',
                          prefixIcon: const Icon(Icons.schedule, color: Colors.indigo),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'hours8', child: Text('وردية 8 ساعات')),
                          DropdownMenuItem(value: 'hours10', child: Text('وردية 10 ساعات')),
                          DropdownMenuItem(value: 'hours12', child: Text('وردية 12 ساعة (يومية)')),
                          DropdownMenuItem(value: 'hours24', child: Text('إقامة كاملة 24 ساعة')),
                          DropdownMenuItem(value: 'custom', child: Text('ساعات عمل مخصصة')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _shiftType = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Shift Handover Timing (استلام وتسليم الخدمة)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 6),
                                const Text(
                                  'وقت استلام الخدمة ووقت إنهائها (اختياري):',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                if (_startTime != null || _endTime != null)
                                  TextButton(
                                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                    onPressed: () {
                                      setState(() {
                                        _startTime = null;
                                        _endTime = null;
                                      });
                                    },
                                    child: const Text('مسح الأوقات', style: TextStyle(fontSize: 11, color: Colors.red)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: const TimeOfDay(hour: 8, minute: 0),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _startTime = _formatTimeOfDay(picked);
                                          _autoSuggestEndTime(picked);
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.login, size: 14, color: Colors.teal),
                                              SizedBox(width: 4),
                                              Text('وقت الاستلام', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _startTime ?? 'انقر للتحديد',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _startTime != null ? AppTheme.primaryColor : Colors.grey.shade500,
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
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: const TimeOfDay(hour: 20, minute: 0),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _endTime = _formatTimeOfDay(picked);
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.logout, size: 14, color: Colors.deepOrange),
                                              SizedBox(width: 4),
                                              Text('وقت الإنهاء', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _endTime ?? 'انقر للتحديد',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _endTime != null ? AppTheme.primaryColor : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Rates: Client Daily Rate & Nurse Daily Rate
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _clientPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'سعر اليوم للعميل (ج)*',
                                prefixIcon: const Icon(Icons.person, color: Colors.blue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'مطلوب';
                                if (double.tryParse(val.trim()) == null) return 'رقم غير صحيح';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nursePriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'يومية الممرض (ج)*',
                                prefixIcon: const Icon(Icons.badge, color: Colors.orange),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'مطلوب';
                                if (double.tryParse(val.trim()) == null) return 'رقم غير صحيح';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Profit & Financial Preview Card
                      Builder(builder: (context) {
                        final daysCount = _selectedMode == 0 ? 1 : _batchDaysCount;
                        final totalClient = _currentClientPrice * daysCount;
                        final totalNurse = _currentNursePrice * daysCount;
                        final totalProfit = totalClient - totalNurse;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: totalProfit >= 0
                                ? const Color(0xFFECFDF5)
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: totalProfit >= 0
                                  ? const Color(0xFF6EE7B7)
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    totalProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                                    color: totalProfit >= 0 ? const Color(0xFF047857) : Colors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedMode == 0
                                        ? 'حسبة الوردية ومكسب الشركة اليومي:'
                                        : 'إجمالي حسبة الباقة ($daysCount أيام):',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: totalProfit >= 0 ? const Color(0xFF047857) : Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'المحسوب على العميل: ${totalClient.toStringAsFixed(0)} ج',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'مستحق للممرض: ${totalNurse.toStringAsFixed(0)} ج',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                                  ),
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'صافي مكسب الشركة (فرق السعر):',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${totalProfit.toStringAsFixed(0)} ج',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: totalProfit >= 0 ? const Color(0xFF047857) : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 14),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'ملاحظات الوردية (اختياري)',
                          hintText: 'مثال: تبديل شفت، أو ظرف طارئ، سلفية تمريض، إلخ.',
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

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
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _selectedMode == 0
                            ? 'تسجيل اليومية'
                            : 'تسجيل الـ ($_batchDaysCount) أيام',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final nurseName = _nurseNameController.text.trim();
      final clientPrice = _currentClientPrice;
      final nursePrice = _currentNursePrice;
      final notes = _notesController.text.trim();

      if (_selectedMode == 0) {
        // Single Day
        await provider.recordServiceDay(
          clientId: widget.client.id,
          date: _singleDate,
          nurseName: nurseName,
          shiftType: _shiftType,
          clientPrice: clientPrice,
          nursePrice: nursePrice,
          notes: notes,
          startTime: _startTime,
          endTime: _endTime,
          hoursCount: _hoursCount,
        );
      } else {
        // Batch Days
        await provider.recordBatchServiceDays(
          clientId: widget.client.id,
          dates: _customDates,
          nurseName: nurseName,
          shiftType: _shiftType,
          clientPrice: clientPrice,
          nursePrice: nursePrice,
          notes: notes,
          startTime: _startTime,
          endTime: _endTime,
          hoursCount: _hoursCount,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedMode == 0
                  ? 'تم تسجيل يومية الخدمة والممرض بنجاح'
                  : 'تم تسجيل ($_batchDaysCount) أيام خدمة للممرض والعميل بنجاح',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التسجيل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
