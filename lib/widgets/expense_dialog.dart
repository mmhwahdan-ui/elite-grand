import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ExpenseDialog extends StatefulWidget {
  final ClientModel? relatedClient;

  const ExpenseDialog({super.key, this.relatedClient});

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _expenseDate;
  String _category = 'nurse_salary';
  String _paymentChannel = 'cash'; // 'cash', 'wallet', 'bank'
  ClientModel? _selectedClient;

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.relatedClient;
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _expenseDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');

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
                          color: Colors.deepOrange.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_outlined, color: Colors.deepOrange, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تسجيل مصروف جديد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              'تحديد بند الصرف وقناة الدفع (محفظة / بنك / كاش)',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'بيان / وصف المصروف *',
                      hintText: 'مثال: يومية ممرض أحمد علي أو شراء مستلزمات',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'يرجى كتابة بيان المصروف' : null,
                  ),
                  const SizedBox(height: 14),

                  // Category
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'بند المصروف *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'nurse_salary', child: Text('رواتب ويوميات تمريض', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'transportation', child: Text('انتقالات ومواصلات', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'medical_supplies', child: Text('مستلزمات وأدوات طبية', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'advances', child: Text('سلف وعُهد تمريض', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'admin', child: Text('مصاريف إدارية ومقر', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'other', child: Text('مصروفات أخرى', style: TextStyle(fontFamily: 'Cairo'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ المدفوع (بالجنيه المصري) *',
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
                  const SizedBox(height: 14),

                  // Payment Channel (من أي حساب تم الصرف؟)
                  const Text(
                    'تم الصرف من: *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _paymentChannel = 'cash'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: _paymentChannel == 'cash' ? Colors.green.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _paymentChannel == 'cash' ? Colors.green : Colors.grey.shade300,
                                width: _paymentChannel == 'cash' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.money, size: 20, color: _paymentChannel == 'cash' ? Colors.green : Colors.grey),
                                const SizedBox(height: 2),
                                const Text('خزينة نقدية (كاش)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _paymentChannel = 'wallet'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: _paymentChannel == 'wallet' ? Colors.deepPurple.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _paymentChannel == 'wallet' ? Colors.deepPurple : Colors.grey.shade300,
                                width: _paymentChannel == 'wallet' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.phone_android, size: 20, color: _paymentChannel == 'wallet' ? Colors.deepPurple : Colors.grey),
                                const SizedBox(height: 2),
                                const Text('محفظة إلكترونية', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _paymentChannel = 'bank'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: _paymentChannel == 'bank' ? Colors.blue.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _paymentChannel == 'bank' ? Colors.blue.shade800 : Colors.grey.shade300,
                                width: _paymentChannel == 'bank' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.account_balance, size: 20, color: _paymentChannel == 'bank' ? Colors.blue.shade800 : Colors.grey),
                                const SizedBox(height: 2),
                                const Text('حساب بنكي', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Related Client Dropdown
                  DropdownButtonFormField<ClientModel?>(
                    value: _selectedClient,
                    decoration: const InputDecoration(
                      labelText: 'ربط المصروف بحالة معينة (اختياري)',
                      prefixIcon: Icon(Icons.person_pin_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('مصروف عام للشركة (غير مرتبط بعميل محدد)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                      ),
                      ...provider.clients.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} (${c.phone})', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedClient = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Expense Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expenseDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setState(() {
                          _expenseDate = picked;
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
                              'تاريخ الصرف: ${dateFormat.format(_expenseDate)}',
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
                      labelText: 'ملاحظات وتفاصيل الفاتورة',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 22),

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
                              final amount = double.parse(_amountController.text.trim());
                              await provider.recordExpense(
                                title: _titleController.text.trim(),
                                category: _category,
                                amount: amount,
                                expenseDate: _expenseDate,
                                paymentChannel: _paymentChannel,
                                notes: _notesController.text.trim(),
                                relatedClientId: _selectedClient?.id,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم تسجيل مصروف بقيمة $amount ج.م وخصمها من ${_paymentChannel == 'cash' ? 'الخزينة النقدية' : (_paymentChannel == 'wallet' ? 'المحفظة' : 'البنك')}', style: const TextStyle(fontFamily: 'Cairo')),
                                    backgroundColor: Colors.deepOrange,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('تسجيل المصروف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
