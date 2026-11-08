import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_dialog.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');

    List<ExpenseModel> filtered = provider.expenses;
    if (_selectedCategory != 'all') {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            // Top Summary Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إجمالي مصروفات الشركة',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Cairo'),
                            ),
                            Text(
                              'مدخلات مدير الحسابات (زيزو)',
                              style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                        Text(
                          '${provider.totalExpenses.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('all', 'الكل (${provider.expenses.length})'),
                        _buildCategoryChip('nurse_salary', 'رواتب تمريض'),
                        _buildCategoryChip('transportation', 'انتقالات'),
                        _buildCategoryChip('medical_supplies', 'مستلزمات طبية'),
                        _buildCategoryChip('advances', 'سلف وعُهد'),
                        _buildCategoryChip('admin', 'إداريات ومقر'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Expense List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد مصروفات مسجلة في هذا البند',
                            style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, index) {
                        final expense = filtered[index];
                        return _buildExpenseCard(context, provider, expense, dateFormat);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: provider.canRecordExpense
            ? FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ExpenseDialog(),
                  );
                },
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('تسجيل مصروف جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Cairo',
          color: isSelected ? Colors.white : Colors.grey.shade800,
        ),
        backgroundColor: Colors.grey.shade100,
        selectedColor: Colors.deepOrange,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedCategory = key),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, AppProvider provider, ExpenseModel expense, DateFormat dateFormat) {
    String? clientName;
    if (expense.relatedClientId != null) {
      final matches = provider.clients.where((c) => c.id == expense.relatedClientId);
      if (matches.isNotEmpty) {
        clientName = matches.first.name;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.deepOrange.withOpacity(0.12),
              child: const Icon(Icons.money_off, color: Colors.deepOrange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          expense.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                        ),
                      ),
                      Text(
                        '${expense.amount.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepOrange,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          expense.categoryArabic,
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700, fontFamily: 'Cairo'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          expense.channelShortArabic,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade800, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (clientName != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'خاص بحالة: $clientName',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontFamily: 'Cairo'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (expense.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      expense.notes,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'التاريخ: ${dateFormat.format(expense.expenseDate)} | سُجل بواسطة: ${expense.recordedBy}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
            if (provider.canEditAnyData)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => provider.deleteExpense(expense.id),
              ),
          ],
        ),
      ),
    );
  }
}
