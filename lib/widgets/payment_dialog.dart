import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class PaymentDialog extends StatefulWidget {
  final ClientModel? preSelectedClient;

  const PaymentDialog({super.key, this.preSelectedClient});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  ClientModel? _selectedClient;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _paymentDate;
  String _paymentChannel = 'wallet'; // 'wallet', 'bank', 'cash'

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.preSelectedClient;
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _paymentDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');

    final availableClients = provider.clients;
    if (_selectedClient == null && availableClients.isNotEmpty) {
      _selectedClient = availableClients.first;
    }

    double currentBalance = 0;
    if (_selectedClient != null) {
      currentBalance = provider.getClientBalance(_selectedClient!);
    }

    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;

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
                          color: AppTheme.accent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.payments_outlined, color: AppTheme.accent, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تسجيل دفعة نقدية / تحصيل',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              'تحديد مكان التحصيل (محفظة إلكترونية أم بنك أم كاش)',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Client Selector (if not preselected)
                  if (widget.preSelectedClient == null) ...[
                    DropdownButtonFormField<ClientModel>(
                      value: _selectedClient,
                      decoration: const InputDecoration(
                        labelText: 'اختيار العميل / الحالة *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: availableClients.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${c.name} (${c.phone})',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClient = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'الحالة: ${widget.preSelectedClient!.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Current Client Balance Banner
                  if (_selectedClient != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: currentBalance < 0
                            ? const Color(0xFFFEF2F2)
                            : (currentBalance > 0 ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: currentBalance < 0
                              ? const Color(0xFFFCA5A5)
                              : (currentBalance > 0 ? const Color(0xFF6EE7B7) : Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentBalance < 0
                                ? '⚠️ مديونية مستحقة على العميل:'
                                : (currentBalance > 0 ? '✅ رصيد دائن متبقي للعميل:' : 'حساب العميل:'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: currentBalance < 0 ? AppTheme.redDebt : (currentBalance > 0 ? AppTheme.greenCredit : Colors.grey),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            '${currentBalance.abs().toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: currentBalance < 0 ? AppTheme.redDebt : (currentBalance > 0 ? AppTheme.greenCredit : Colors.blueGrey),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Amount Input
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ المحصل (بالجنيه المصري) *',
                      suffixText: 'ج.م',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'يرجى إدخال المبلغ';
                      final a = double.tryParse(v);
                      if (a == null || a <= 0) return 'يرجى إدخال مبلغ صحيح أكبر من صفر';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Collection Channel Question: محفظة إلكترونية أم بنك أم كاش؟
                  const Text(
                    'مكان تحصيل وإيداع المبلغ: *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // 1. Electronic Wallet
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _paymentChannel = 'wallet'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                            decoration: BoxDecoration(
                              color: _paymentChannel == 'wallet' ? Colors.deepPurple.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _paymentChannel == 'wallet' ? Colors.deepPurple : Colors.grey.shade300,
                                width: _paymentChannel == 'wallet' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.phone_android, color: _paymentChannel == 'wallet' ? Colors.deepPurple : Colors.grey, size: 22),
                                const SizedBox(height: 4),
                                const Text('محفظة إلكترونية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
                                const Text('فودافون كاش / إنستاباي', style: TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'Cairo')),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 2. Bank Account
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _paymentChannel = 'bank'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                            decoration: BoxDecoration(
                              color: _paymentChannel == 'bank' ? Colors.blue.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _paymentChannel == 'bank' ? Colors.blue.shade800 : Colors.grey.shade300,
                                width: _paymentChannel == 'bank' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.account_balance, color: _paymentChannel == 'bank' ? Colors.blue.shade800 : Colors.grey, size: 22),
                                const SizedBox(height: 4),
                                const Text('الحساب البنكي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
                                const Text('تحويل / إيداع بنكي', style: TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'Cairo')),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3. Cash
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _paymentChannel = 'cash'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                            decoration: BoxDecoration(
                              color: _paymentChannel == 'cash' ? Colors.green.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _paymentChannel == 'cash' ? Colors.green.shade800 : Colors.grey.shade300,
                                width: _paymentChannel == 'cash' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.money, color: _paymentChannel == 'cash' ? Colors.green.shade800 : Colors.grey, size: 22),
                                const SizedBox(height: 4),
                                const Text('خزينة نقدية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
                                const Text('كاش مع المندوب', style: TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'Cairo')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Real-time balance preview of selected channel
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _paymentChannel == 'wallet'
                              ? 'رصيد المحفظة الحالي: ${provider.currentWalletBalance.toStringAsFixed(0)} ج.م'
                              : (_paymentChannel == 'bank'
                                  ? 'رصيد البنك الحالي: ${provider.currentBankBalance.toStringAsFixed(0)} ج.م'
                                  : 'رصيد الخزينة الحالي: ${provider.currentCashBalance.toStringAsFixed(0)} ج.م'),
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800, fontFamily: 'Cairo'),
                        ),
                        if (enteredAmount > 0)
                          Text(
                            '← سيصبح: ${((_paymentChannel == 'wallet' ? provider.currentWalletBalance : (_paymentChannel == 'bank' ? provider.currentBankBalance : provider.currentCashBalance)) + enteredAmount).toStringAsFixed(0)} ج.م',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green, fontFamily: 'Cairo'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _paymentDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setState(() {
                          _paymentDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'تاريخ الدفعة: ${dateFormat.format(_paymentDate)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo', fontSize: 13),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات الدفعة (رقم التحويل أو كود العملية)',
                      hintText: 'مثال: تحويل إنستاباي رقم #4492 أو إيصال استلام',
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
                            if (_formKey.currentState!.validate() && _selectedClient != null) {
                              final amount = double.parse(_amountController.text.trim());
                              await provider.recordPayment(
                                clientId: _selectedClient!.id,
                                amount: amount,
                                paymentDate: _paymentDate,
                                paymentChannel: _paymentChannel,
                                notes: _notesController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تم تسجيل تحصيل $amount ج.م وإيداعها في ${_paymentChannel == 'wallet' ? 'المحفظة الإلكترونية' : (_paymentChannel == 'bank' ? 'حساب البنك' : 'الخزينة النقدية')}',
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
                          child: const Text('تأكيد التحصيل والإيداع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
