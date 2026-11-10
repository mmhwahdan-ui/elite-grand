import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/caregiver_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class AddEditCaregiverDialog extends StatefulWidget {
  final CaregiverModel? caregiver;

  const AddEditCaregiverDialog({super.key, this.caregiver});

  @override
  State<AddEditCaregiverDialog> createState() => _AddEditCaregiverDialogState();
}

class _AddEditCaregiverDialogState extends State<AddEditCaregiverDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _nationalIdController;
  late TextEditingController _phoneController;
  late TextEditingController _qualificationController;
  late TextEditingController _addressController;
  late TextEditingController _residenceAreaController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _priceController;
  late TextEditingController _blockReasonController;
  late TextEditingController _currentClientController;
  late TextEditingController _newPastClientController;
  late TextEditingController _notesController;

  String _shiftPreference = 'both'; // 'hours12', 'hours24', 'both'
  double _rating = 5.0;
  bool _isBlocked = false;
  bool _hasWorkedWithUs = false;
  bool _isCurrentlyWorking = false;
  List<String> _pastClients = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.caregiver;
    final provider = Provider.of<AppProvider>(context, listen: false);

    _codeController = TextEditingController(
      text: c != null ? c.code : provider.generateNextCaregiverCode(),
    );
    _nameController = TextEditingController(text: c?.name ?? '');
    _nationalIdController = TextEditingController(text: c?.nationalId ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _qualificationController = TextEditingController(text: c?.qualification ?? 'بكالوريوس تمريض');
    _addressController = TextEditingController(text: c?.address ?? '');
    _residenceAreaController = TextEditingController(text: c?.residenceArea ?? '');
    _weightController = TextEditingController(text: c?.weight != null ? c!.weight!.toStringAsFixed(0) : '');
    _heightController = TextEditingController(text: c?.height != null ? c!.height!.toStringAsFixed(0) : '');
    _priceController = TextEditingController(
      text: (c != null && c.dailyPrice > 0) ? c.dailyPrice.toStringAsFixed(0) : '400',
    );
    _blockReasonController = TextEditingController(text: c?.blockReason ?? '');
    _currentClientController = TextEditingController(
      text: c?.currentClientName ?? (c != null ? (provider.getCaregiverCurrentCase(c.name) ?? '') : ''),
    );
    _newPastClientController = TextEditingController();
    _notesController = TextEditingController(text: c?.notes ?? '');

    if (c != null) {
      _shiftPreference = c.shiftPreference;
      _rating = c.rating;
      _isBlocked = c.isBlocked;
      _hasWorkedWithUs = c.hasWorkedWithUs || provider.getCaregiverPastClients(c.name).isNotEmpty;
      _isCurrentlyWorking = c.isCurrentlyWorking || provider.getCaregiverCurrentCase(c.name) != null;
      _pastClients = List<String>.from(provider.getCaregiverPastClients(c.name));
      if (_pastClients.isEmpty) {
        _pastClients = List<String>.from(c.pastClients);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _addressController.dispose();
    _residenceAreaController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _priceController.dispose();
    _blockReasonController.dispose();
    _currentClientController.dispose();
    _newPastClientController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addPastClient() {
    final name = _newPastClientController.text.trim();
    if (name.isNotEmpty && !_pastClients.contains(name)) {
      setState(() {
        _pastClients.add(name);
        _hasWorkedWithUs = true;
        _newPastClientController.clear();
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isBlocked && _blockReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى توضيح نوع المشكلة وسبب الحظر', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();

    try {
      final code = _codeController.text.trim();
      final name = _nameController.text.trim();
      final nationalId = _nationalIdController.text.trim();
      final phone = _phoneController.text.trim();
      final qualification = _qualificationController.text.trim();
      final address = _addressController.text.trim();
      final residenceArea = _residenceAreaController.text.trim();
      final weight = double.tryParse(_weightController.text.trim());
      final height = double.tryParse(_heightController.text.trim());
      final dailyPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final blockReason = _isBlocked ? _blockReasonController.text.trim() : null;
      final currentClientName = _isCurrentlyWorking ? _currentClientController.text.trim() : null;
      final notes = _notesController.text.trim();

      if (widget.caregiver == null) {
        // Add new
        final newCaregiver = CaregiverModel(
          id: 'cg_${DateTime.now().millisecondsSinceEpoch}',
          code: code,
          name: name,
          nationalId: nationalId,
          phone: phone,
          qualification: qualification,
          address: address,
          residenceArea: residenceArea,
          weight: weight,
          height: height,
          shiftPreference: _shiftPreference,
          dailyPrice: dailyPrice,
          rating: _rating,
          isBlocked: _isBlocked,
          blockReason: blockReason,
          hasWorkedWithUs: _hasWorkedWithUs || _pastClients.isNotEmpty,
          pastClients: _pastClients,
          isCurrentlyWorking: _isCurrentlyWorking,
          currentClientName: currentClientName,
          notes: notes.isNotEmpty ? notes : null,
          createdBy: provider.currentUser?.username ?? 'shimaa',
        );
        await provider.addCaregiver(newCaregiver);
      } else {
        // Update existing
        final updated = widget.caregiver!.copyWith(
          code: code,
          name: name,
          nationalId: nationalId,
          phone: phone,
          qualification: qualification,
          address: address,
          residenceArea: residenceArea,
          weight: weight,
          height: height,
          shiftPreference: _shiftPreference,
          dailyPrice: dailyPrice,
          rating: _rating,
          isBlocked: _isBlocked,
          blockReason: blockReason,
          hasWorkedWithUs: _hasWorkedWithUs || _pastClients.isNotEmpty,
          pastClients: _pastClients,
          isCurrentlyWorking: _isCurrentlyWorking,
          currentClientName: currentClientName,
          notes: notes.isNotEmpty ? notes : null,
        );
        await provider.updateCaregiver(updated);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.caregiver == null
                  ? 'تمت إضافة مقدم الخدمة بنجاح إلى قاعدة البيانات'
                  : 'تم تحديث بيانات مقدم الخدمة بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e', style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.caregiver != null;
    final provider = context.watch<AppProvider>();
    final activeClientList = provider.activeClients;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 720,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
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
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.badge_rounded,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'تعديل بيانات مقدم الخدمة' : 'إضافة مقدم خدمة جديد لقاعدة البيانات',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          isEdit
                              ? 'تعديل السجل الكامل للكوادر التمريضية والطبية'
                              : 'تسجيل بيانات التمريض والمواصفات ونظام العمل والأسعار',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Form Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Code & Name Row
                      Row(
                        children: [
                          // Code (تكويد مقدم الخدمة)
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                labelText: 'كود مقدم الخدمة *',
                                prefixIcon: const Icon(Icons.qr_code_2, color: Colors.indigo),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'الكود مطلوب' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name (الاسم)
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'الاسم الكامل لمقدم الخدمة *',
                                prefixIcon: const Icon(Icons.person, color: AppTheme.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة الاسم' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. National ID & Phone
                      Row(
                        children: [
                          // National ID (الرقم القومي)
                          Expanded(
                            child: TextFormField(
                              controller: _nationalIdController,
                              keyboardType: TextInputType.number,
                              maxLength: 14,
                              decoration: InputDecoration(
                                labelText: 'الرقم القومي (14 رقم)',
                                prefixIcon: const Icon(Icons.credit_card, color: Colors.teal),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Phone (رقم التليفون)
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'رقم التليفون للتواصل *',
                                prefixIcon: const Icon(Icons.phone, color: Colors.green),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'رقم التليفون مطلوب' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 3. Qualification & Residence Area
                      Row(
                        children: [
                          // Qualification (المؤهل)
                          Expanded(
                            child: TextFormField(
                              controller: _qualificationController,
                              decoration: InputDecoration(
                                labelText: 'المؤهل العلمي / التخصص',
                                prefixIcon: const Icon(Icons.school, color: Colors.blueAccent),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                helperText: 'مثال: بكالوريوس تمريض / معهد تمريض / رعاية مسنين',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Residence Area (مكان السكن)
                          Expanded(
                            child: TextFormField(
                              controller: _residenceAreaController,
                              decoration: InputDecoration(
                                labelText: 'مكان السكن / المنطقة والمحافظة',
                                prefixIcon: const Icon(Icons.location_city, color: Colors.orange),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                helperText: 'مثال: مدينة نصر، فيصل، إمبابة، شبرا...',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 4. Detailed Address
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'العنوان بالتفصيل',
                          prefixIcon: const Icon(Icons.home_outlined, color: Colors.purple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5. Physical Specs: Weight & Height
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.accessibility_new, color: Colors.blueGrey, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'المواصفات البدنية والجسدية (الوزن والطول):',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _weightController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'الوزن (كجم)',
                                      suffixText: 'كجم',
                                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _heightController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'الطول (سم)',
                                      suffixText: 'سم',
                                      prefixIcon: const Icon(Icons.height_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 6. Shift Preference & Daily Price
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.teal, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'نظام العمل واليومية المعتمدة:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13, color: Colors.teal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Shift Preference
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: _shiftPreference,
                                    decoration: InputDecoration(
                                      labelText: 'بيشتغل 12 ساعة ولا 24 ساعة؟',
                                      prefixIcon: const Icon(Icons.timelapse, color: Colors.teal),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'hours12', child: Text('12 ساعة فقط')),
                                      DropdownMenuItem(value: 'hours24', child: Text('24 ساعة (إقامة)')),
                                      DropdownMenuItem(value: 'both', child: Text('متاح للاثنين (12 و 24 ساعة)')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _shiftPreference = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Daily Price
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'سعره اليومي الافتراضي *',
                                      suffixText: 'ج.م',
                                      prefixIcon: const Icon(Icons.payments_outlined, color: Colors.teal),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'السعر مطلوب' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 7. Rating (التقييم من 1 إلى 5 نجوم)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 24),
                            const SizedBox(width: 10),
                            const Text(
                              'تقييم مقدم الخدمة:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                final starValue = index + 1.0;
                                return IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: Icon(
                                    _rating >= starValue ? Icons.star : Icons.star_border,
                                    color: Colors.amber.shade700,
                                    size: 26,
                                  ),
                                  onPressed: () {
                                    setState(() => _rating = starValue);
                                  },
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_rating.toStringAsFixed(0)} / 5)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.amber),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 8. Currently Working Status (ولما يكون شغال معانا الآن تظهر بجوار اسمه اسم الحالة)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isCurrentlyWorking ? Colors.green.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isCurrentlyWorking ? Colors.green.shade400 : Colors.grey.shade300,
                            width: _isCurrentlyWorking ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isCurrentlyWorking ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: _isCurrentlyWorking ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'هل يعمل معنا الآن بحالة قائمة؟',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                                      ),
                                      Text(
                                        'تظهر شارة خضراء واسم الحالة بجوار اسمه في كل القوائم',
                                        style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isCurrentlyWorking,
                                  activeColor: Colors.green,
                                  onChanged: (val) {
                                    setState(() {
                                      _isCurrentlyWorking = val;
                                      if (!val) {
                                        _currentClientController.clear();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_isCurrentlyWorking) ...[
                              const SizedBox(height: 12),
                              // Fast pick from active clients or custom
                              if (activeClientList.isNotEmpty) ...[
                                const Text(
                                  'اختر الحالة النشطة التي يعمل بها حالياً:',
                                  style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: activeClientList.map((cl) {
                                    final isSelected = _currentClientController.text.trim() == cl.name.trim();
                                    return ChoiceChip(
                                      label: Text(cl.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                                      selected: isSelected,
                                      selectedColor: Colors.green.shade100,
                                      onSelected: (selected) {
                                        setState(() {
                                          _currentClientController.text = selected ? cl.name : '';
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],
                              TextFormField(
                                controller: _currentClientController,
                                decoration: InputDecoration(
                                  labelText: 'اسم الحالة التي يعمل فيها الآن *',
                                  prefixIcon: const Icon(Icons.person_pin, color: Colors.green),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 9. Worked with us before & Past Clients list
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'هل اشتغل مع شركتنا من قبل؟',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                                  ),
                                ),
                                Switch(
                                  value: _hasWorkedWithUs || _pastClients.isNotEmpty,
                                  activeColor: Colors.blue,
                                  onChanged: (val) {
                                    setState(() => _hasWorkedWithUs = val);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'أسماء العملاء الذين اشتغل معهم سابقاً:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
                            ),
                            const SizedBox(height: 6),
                            if (_pastClients.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _pastClients.map((clientName) {
                                  return Chip(
                                    label: Text(clientName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                                    backgroundColor: Colors.white,
                                    deleteIcon: const Icon(Icons.close, size: 14),
                                    onDeleted: () {
                                      setState(() {
                                        _pastClients.remove(clientName);
                                        if (_pastClients.isEmpty) _hasWorkedWithUs = false;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _newPastClientController,
                                    decoration: InputDecoration(
                                      hintText: 'إضافة اسم عميل اشتغل معه...',
                                      hintStyle: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    onFieldSubmitted: (_) => _addPastClient(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _addPastClient,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 10. Block & Problem Details (حظره بسبب مشاكل ونوع المشكلة)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isBlocked ? Colors.red.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isBlocked ? Colors.red.shade400 : Colors.grey.shade300,
                            width: _isBlocked ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.block,
                                  color: _isBlocked ? Colors.red : Colors.grey,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'حظر مقدم الخدمة بسبب مشاكل (Blacklist)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13, color: Colors.red),
                                      ),
                                      Text(
                                        'يمنع إسناده للحالات ويعطي تحذيراً فورياً عند اختياره',
                                        style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isBlocked,
                                  activeColor: Colors.red,
                                  onChanged: (val) {
                                    setState(() => _isBlocked = val);
                                  },
                                ),
                              ],
                            ),
                            if (_isBlocked) ...[
                              const SizedBox(height: 12),
                              // Fast common problem chips
                              const Text(
                                'أسباب شائعة للمشكلة:',
                                style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  'ترك الوردية فجأة',
                                  'تكرار التأخير والغياب',
                                  'إهمال في الرعاية والتمريض',
                                  'شكوى وسوء معاملة مع الحالة',
                                  'خلاف مالي',
                                  'عدم التزام بمواعيد التسليم',
                                ].map((reason) {
                                  return ActionChip(
                                    label: Text(reason, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                                    backgroundColor: Colors.red.shade100,
                                    onPressed: () {
                                      setState(() {
                                        if (_blockReasonController.text.trim().isEmpty) {
                                          _blockReasonController.text = reason;
                                        } else {
                                          _blockReasonController.text += ' - $reason';
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _blockReasonController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: 'نوع المشكلة وتفاصيل سبب الحظر *',
                                  prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 11. Additional Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'ملاحظات إضافية عن مقدم الخدمة',
                          prefixIcon: const Icon(Icons.note_alt_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(
                      isEdit ? 'حفظ التعديلات' : 'تسجيل وحفظ مقدم الخدمة',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
