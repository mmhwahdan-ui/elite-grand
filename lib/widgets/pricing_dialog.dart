import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class PricingDialog extends StatefulWidget {
  final ClientModel client;

  const PricingDialog({super.key, required this.client});

  @override
  State<PricingDialog> createState() => _PricingDialogState();
}

class _PricingDialogState extends State<PricingDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  late TextEditingController _nursePriceController;
  late String _selectedServiceType;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.client.dailyPrice > 0 ? widget.client.dailyPrice.toStringAsFixed(0) : '',
    );
    _nursePriceController = TextEditingController(
      text: widget.client.nurseDailyPrice > 0 ? widget.client.nurseDailyPrice.toStringAsFixed(0) : '',
    );
    _selectedServiceType = widget.client.serviceType.isNotEmpty ? widget.client.serviceType : 'hours12';
  }

  @override
  void dispose() {
    _priceController.dispose();
    _nursePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    final clientPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final nursePrice = double.tryParse(_nursePriceController.text.trim()) ?? 0.0;
    final dailyProfit = clientPrice - nursePrice;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.request_quote_outlined, color: AppTheme.primaryLight, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تسعير الخدمة وتحديد يومية الممرض',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              'حساب فرق السعر ومكسب الشركة من الحالة',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Client Info Card preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'المريض: ${widget.client.name}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
                              ),
                            ),
                            if (widget.client.isExistingClient)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  widget.client.openingBalance >= 0
                                      ? 'رصيد دائن سابق: +${widget.client.openingBalance.toStringAsFixed(0)} ج.م'
                                      : 'مديونية سابقة: ${widget.client.openingBalance.toStringAsFixed(0)} ج.م',
                                  style: TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الحالة الصحية: ${widget.client.healthCondition}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontFamily: 'Cairo'),
                        ),
                        if (widget.client.nurseAssigned != null && widget.client.nurseAssigned!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'الممرض المسند: ${widget.client.nurseAssigned}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Shift selection
                  const Text(
                    'نوع الشيفت والوردية:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedServiceType = 'hours12'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: _selectedServiceType == 'hours12' ? AppTheme.primary.withOpacity(0.08) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedServiceType == 'hours12' ? AppTheme.primary : Colors.grey.shade300,
                                width: _selectedServiceType == 'hours12' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.wb_sunny_outlined, color: _selectedServiceType == 'hours12' ? AppTheme.primary : Colors.grey),
                                const SizedBox(height: 4),
                                const Text('وردية 12 ساعة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                                const Text('صباحي أو مسائي', style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedServiceType = 'hours24'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: _selectedServiceType == 'hours24' ? AppTheme.accent.withOpacity(0.08) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedServiceType == 'hours24' ? AppTheme.accent : Colors.grey.shade300,
                                width: _selectedServiceType == 'hours24' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.nightlight_outlined, color: _selectedServiceType == 'hours24' ? AppTheme.accent : Colors.grey),
                                const SizedBox(height: 4),
                                const Text('إقامة 24 ساعة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                                const Text('ممرض مقيم على مدار اليوم', style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Pricing inputs row
                  Row(
                    children: [
                      // Client Daily Price
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'سعر العميل اليومي *',
                            suffixText: 'ج.م',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'يرجى إدخال السعر';
                            final price = double.tryParse(v);
                            if (price == null || price <= 0) return 'سعر غير صحيح';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nurse Daily Price
                      Expanded(
                        child: TextFormField(
                          controller: _nursePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'يومية الممرض *',
                            suffixText: 'ج.م',
                            prefixIcon: Icon(Icons.medical_services_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'يرجى إدخال يومية الممرض';
                            final price = double.tryParse(v);
                            if (price == null || price < 0) return 'مبلغ غير صحيح';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Profit difference live preview box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: dailyProfit >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: dailyProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'صافي مكسب الشركة اليومي من الحالة:',
                              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${dailyProfit.toStringAsFixed(0)} ج.م / يوم',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: dailyProfit >= 0 ? const Color(0xFF047857) : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الحسبة: ($clientPrice ج.م سعر العميل) - ($nursePrice ج.م يومية الممرض) = $dailyProfit ج.م صافي ربح الشركة يومياً.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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
                              final price = double.parse(_priceController.text.trim());
                              final nursePrice = double.parse(_nursePriceController.text.trim());
                              await provider.setClientPricing(
                                clientId: widget.client.id,
                                dailyPrice: price,
                                nurseDailyPrice: nursePrice,
                                serviceType: _selectedServiceType,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم اعتماد التسعير ويومية الممرض وحساب فرق السعر بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                                    backgroundColor: AppTheme.accent,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('اعتماد التسعير والأرباح', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
