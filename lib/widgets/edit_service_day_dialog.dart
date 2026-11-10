import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../models/service_day_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class EditServiceDayDialog extends StatefulWidget {
  final ServiceDayModel serviceDay;
  final ClientModel client;

  const EditServiceDayDialog({
    super.key,
    required this.serviceDay,
    required this.client,
  });

  @override
  State<EditServiceDayDialog> createState() => _EditServiceDayDialogState();
}

class _EditServiceDayDialogState extends State<EditServiceDayDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  late TextEditingController _nurseNameController;
  late TextEditingController _clientPriceController;
  late TextEditingController _nursePriceController;
  late TextEditingController _notesController;
  late String _shiftType;

  String? _startTime;
  String? _endTime;
  double? _hoursCount;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _date = widget.serviceDay.date;
    _nurseNameController = TextEditingController(text: widget.serviceDay.nurseName);
    _clientPriceController = TextEditingController(
      text: widget.serviceDay.clientPrice > 0 ? widget.serviceDay.clientPrice.toStringAsFixed(0) : '',
    );
    _nursePriceController = TextEditingController(
      text: widget.serviceDay.nursePrice > 0 ? widget.serviceDay.nursePrice.toStringAsFixed(0) : '',
    );
    _notesController = TextEditingController(text: widget.serviceDay.notes);
    _shiftType = widget.serviceDay.shiftType.isNotEmpty ? widget.serviceDay.shiftType : 'hours12';
    _startTime = widget.serviceDay.startTime;
    _endTime = widget.serviceDay.endTime;
    _hoursCount = widget.serviceDay.hoursCount;
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
  double get _currentProfit => _currentClientPrice - _currentNursePrice;

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final allNurses = provider.allNurseNames;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
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
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_calendar_rounded,
                        color: AppTheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تعديل الوردية أو تبديل الممرض',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            'العميل: ${widget.client.name} | يوم: ${dateFormat.format(_date)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: Colors.grey.shade600,
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

                // Scrollable Form Fields
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Date selector
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2023),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                              locale: const Locale('ar'),
                            );
                            if (picked != null) {
                              setState(() => _date = picked);
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
                                const Icon(Icons.calendar_month, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 10),
                                const Text('تاريخ الوردية:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text(
                                  dateFormat.format(_date),
                                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nurse Name Field
                        TextFormField(
                          controller: _nurseNameController,
                          decoration: InputDecoration(
                            labelText: 'اسم الممرض / مقدم الخدمة القائم بالوردية *',
                            prefixIcon: const Icon(Icons.medical_services_outlined, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            helperText: 'يمكنك كتابة ممرض بديل أو اختيار من القائمة أدناه',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى كتابة أو اختيار اسم الممرض';
                            }
                            return null;
                          },
                        ),

                        // Quick nurse picker chips
                        if (allNurses.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.swap_horiz, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'تبديل سريع للممرض:',
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
                              return ActionChip(
                                label: Text(name, style: TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                backgroundColor: isSelected ? Colors.teal.shade100 : Colors.grey.shade100,
                                side: BorderSide(color: isSelected ? Colors.teal : Colors.grey.shade300),
                                onPressed: () {
                                  setState(() {
                                    _nurseNameController.text = name;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Shift Type Dropdown
                        DropdownButtonFormField<String>(
                          value: _shiftType,
                          decoration: InputDecoration(
                            labelText: 'نوع الوردية وساعات العمل',
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
                        const SizedBox(height: 16),

                        // Shift Timing (Check-in & Check-out Handover)
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
                                  const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primary),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'وقت استلام الخدمة ووقت إنهائها (التسليم):',
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
                                  // Start Time Picker
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
                                                Text('وقت الاستلام (حضور)', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _startTime ?? 'انقر للتحديد',
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: _startTime != null ? AppTheme.primary : Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // End Time Picker
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
                                                Text('وقت الإنهاء (تسليم)', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _endTime ?? 'انقر للتحديد',
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: _endTime != null ? AppTheme.primary : Colors.grey.shade500,
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
                        const SizedBox(height: 16),

                        // Rates: Client Price & Nurse Daily Rate
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
                                  prefixIcon: const Icon(Icons.medical_services, color: Colors.teal),
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
                        const SizedBox(height: 10),

                        // Profit difference preview badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentProfit >= 0 ? const Color(0xFFE6FBF5) : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _currentProfit >= 0 ? const Color(0xFF00D09C) : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ربح الشركة من هذه الوردية:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  color: _currentProfit >= 0 ? const Color(0xFF047857) : Colors.red,
                                ),
                              ),
                              Text(
                                '${_currentProfit.toStringAsFixed(0)} ج.م',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  color: _currentProfit >= 0 ? const Color(0xFF047857) : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Notes Field
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'ملاحظات الوردية (اختياري)',
                            prefixIcon: const Icon(Icons.note_alt_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            hintText: 'مثال: تم التبديل مع ممرض بديل لظرف طارئ',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSubmitting ? 'جاري الحفظ...' : 'حفظ التعديلات وتحديث الحسابات',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _isSubmitting = true);

                                final updated = widget.serviceDay.copyWith(
                                  date: _date,
                                  nurseName: _nurseNameController.text.trim(),
                                  shiftType: _shiftType,
                                  clientPrice: _currentClientPrice,
                                  nursePrice: _currentNursePrice,
                                  notes: _notesController.text.trim(),
                                  startTime: _startTime,
                                  endTime: _endTime,
                                  hoursCount: _hoursCount,
                                );

                                await provider.updateServiceDay(updated);

                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'تم تحديث وردية الممرض "${updated.nurseName}" وحسابات الخدمة بنجاح',
                                        style: const TextStyle(fontFamily: 'Cairo'),
                                      ),
                                      backgroundColor: AppTheme.accent,
                                      duration: const Duration(seconds: 2),
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
