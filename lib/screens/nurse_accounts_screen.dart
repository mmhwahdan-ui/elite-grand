import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../services/export_service.dart';

class NurseAccountsScreen extends StatefulWidget {
  const NurseAccountsScreen({super.key});

  @override
  State<NurseAccountsScreen> createState() => _NurseAccountsScreenState();
}

class _NurseAccountsScreenState extends State<NurseAccountsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddTransactionDialog(BuildContext context, {String? defaultNurseName, String defaultType = 'advance'}) {
    final provider = context.read<AppProvider>();
    final nurseNames = provider.allNurseNames;

    String selectedNurse = defaultNurseName ?? (nurseNames.isNotEmpty ? nurseNames.first : '');
    final customNurseCtrl = TextEditingController(text: selectedNurse);
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String transType = defaultType; // 'advance' or 'payout'
    String paymentChannel = 'cash';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  transType == 'advance' ? Icons.handshake_outlined : Icons.payments_outlined,
                  color: transType == 'advance' ? Colors.amber.shade800 : AppTheme.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  transType == 'advance' ? 'تسجيل سلفة ممرض' : 'صرف مستحقات وأجر ممرض',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Selector
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('سلفة تمريض', style: TextStyle(fontFamily: 'Cairo')),
                          selected: transType == 'advance',
                          selectedColor: Colors.amber.shade200,
                          onSelected: (val) {
                            if (val) setDialogState(() => transType = 'advance');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('صرف أجر / مستحقات', style: TextStyle(fontFamily: 'Cairo')),
                          selected: transType == 'payout',
                          selectedColor: Colors.teal.shade200,
                          onSelected: (val) {
                            if (val) setDialogState(() => transType = 'payout');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nurse selection
                  const Text('اسم الممرض / الممرضة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                  const SizedBox(height: 6),
                  if (nurseNames.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: nurseNames.contains(selectedNurse) ? selectedNurse : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      hint: const Text('اختر من قائمة التمريض', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                      items: nurseNames.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name, style: const TextStyle(fontFamily: 'Cairo')),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedNurse = val;
                            customNurseCtrl.text = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: customNurseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'أو اكتب اسم الممرض يدوياً',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (v) => selectedNurse = v.trim(),
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (جنيه مصري)',
                      suffixText: 'ج.م',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment Channel
                  const Text('طريقة الصرف من الخزينة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: paymentChannel,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('💵 خزينة نقدية (كاش المقر / عهدة)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'wallet', child: Text('📱 محفظة إلكترونية (فودافون كاش / إنستاباي)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'bank', child: Text('🏦 حساب بنكي (تحويل)', style: TextStyle(fontFamily: 'Cairo'))),
                    ],
                    onChanged: (v) => setDialogState(() => paymentChannel = v ?? 'cash'),
                  ),
                  const SizedBox(height: 12),

                  // Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
                    title: Text(
                      'التاريخ: ${DateFormat('yyyy/MM/dd').format(selectedDate)}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                    trailing: TextButton(
                      child: const Text('تغيير', style: TextStyle(fontFamily: 'Cairo')),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات وتفاصيل السلفة أو الأجر',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nurse = customNurseCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;

                  if (nurse.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى تحديد أو كتابة اسم الممرض', style: TextStyle(fontFamily: 'Cairo'))),
                    );
                    return;
                  }
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى كتابة مبلغ صحيح أكبر من الصفر', style: TextStyle(fontFamily: 'Cairo'))),
                    );
                    return;
                  }

                  await provider.recordNurseTransaction(
                    nurseName: nurse,
                    amount: amount,
                    date: selectedDate,
                    type: transType,
                    paymentChannel: paymentChannel,
                    notes: notesCtrl.text.trim(),
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          transType == 'advance' ? 'تم تسجيل سلفة الممرض بنجاح' : 'تم تسجيل صرف الأجر والمستحقات بنجاح',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: AppTheme.accent,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('حفظ وتسجيل', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNurseDetailsDialog(BuildContext context, String nurseName) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer<AppProvider>(
        builder: (context, provider, _) {
          final days = provider.getNurseDaysCount(nurseName);
          final earned = provider.getNurseTotalEarned(nurseName);
          final advances = provider.getNurseTotalAdvances(nurseName);
          final payouts = provider.getNurseTotalPayouts(nurseName);
          final totalReceived = provider.getNurseTotalReceived(nurseName);
          final remaining = provider.getNurseRemainingBalance(nurseName);

          final shifts = provider.getNurseShifts(nurseName);
          final transactions = provider.getNurseTransactions(nurseName);

          final dateFormat = DateFormat('yyyy/MM/dd');

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: 700,
                constraints: const BoxConstraints(maxHeight: 700),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              radius: 22,
                              child: const Icon(Icons.person, color: AppTheme.primary, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nurseName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                ),
                                const Text(
                                  'كشف حساب تفصيلي - ورديات وسلف ومستحقات',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Financial summary cards
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          _buildSummaryBox('أيام العمل', '$days يوم', Icons.event, Colors.blue),
                          const SizedBox(width: 8),
                          _buildSummaryBox('إجمالي الأجر', '${earned.toStringAsFixed(0)} ج.م', Icons.attach_money, Colors.teal),
                          const SizedBox(width: 8),
                          _buildSummaryBox('السلف المأخوذة', '${advances.toStringAsFixed(0)} ج.م', Icons.handshake, Colors.amber.shade900),
                          const SizedBox(width: 8),
                          _buildSummaryBox('الدفعات المنصرفة', '${payouts.toStringAsFixed(0)} ج.م', Icons.done_all, Colors.purple),
                          const SizedBox(width: 8),
                          _buildSummaryBox(
                            'باقي له طرفنا',
                            '${remaining.toStringAsFixed(0)} ج.م',
                            remaining >= 0 ? Icons.account_balance_wallet : Icons.warning_amber,
                            remaining >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                            isHighlighted: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions bar
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddTransactionDialog(context, defaultNurseName: nurseName, defaultType: 'advance');
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('تسجيل سلفة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddTransactionDialog(context, defaultNurseName: nurseName, defaultType: 'payout');
                          },
                          icon: const Icon(Icons.payments, size: 16),
                          label: const Text('صرف دفعة مستحقات', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () {
                            ExportService.exportSingleNurseStatementToExcel(provider, nurseName);
                          },
                          icon: const Icon(Icons.download, size: 16, color: Colors.green),
                          label: const Text('تصدير إكسيل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.green)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tabs: Shifts vs Transactions
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              labelColor: AppTheme.primary,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: AppTheme.primary,
                              tabs: [
                                Tab(child: Text('سجل أيام الخدمة والورديات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                                Tab(child: Text('سجل السلف والمدفوعات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // Tab 1: Shifts
                                  shifts.isEmpty
                                      ? const Center(child: Text('لا توجد ورديات مسجلة لهذا الممرض', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')))
                                      : ListView.builder(
                                          itemCount: shifts.length,
                                          itemBuilder: (ctx, idx) {
                                            final s = shifts[idx];
                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              elevation: 0.5,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                                              child: ListTile(
                                                dense: true,
                                                leading: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                                                  child: const Icon(Icons.calendar_month, color: Colors.teal, size: 20),
                                                ),
                                                title: Text('${s.clientName} (${s.shiftTypeArabic})', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                                                subtitle: Text('التاريخ: ${dateFormat.format(s.date)} ${s.notes.isNotEmpty ? " • " + s.notes : ""}', style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                                                trailing: Text('${s.nursePrice.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal, fontFamily: 'Cairo')),
                                              ),
                                            );
                                          },
                                        ),

                                  // Tab 2: Transactions (Advances & Payouts)
                                  transactions.isEmpty
                                      ? const Center(child: Text('لا توجد سلف أو مدفوعات مسجلة لهذا الممرض', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')))
                                      : ListView.builder(
                                          itemCount: transactions.length,
                                          itemBuilder: (ctx, idx) {
                                            final t = transactions[idx];
                                            final isAdv = t.type == 'advance';
                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              elevation: 0.5,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                                              child: ListTile(
                                                dense: true,
                                                leading: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: isAdv ? Colors.amber.shade50 : Colors.purple.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    isAdv ? Icons.handshake : Icons.payments,
                                                    color: isAdv ? Colors.amber.shade800 : Colors.purple,
                                                    size: 20,
                                                  ),
                                                ),
                                                title: Row(
                                                  children: [
                                                    Text(t.typeArabic, style: TextStyle(fontWeight: FontWeight.bold, color: isAdv ? Colors.amber.shade900 : Colors.purple, fontFamily: 'Cairo', fontSize: 13)),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                                      child: Text(t.channelArabic, style: const TextStyle(fontSize: 10, fontFamily: 'Cairo')),
                                                    ),
                                                  ],
                                                ),
                                                subtitle: Text('التاريخ: ${dateFormat.format(t.date)} ${t.notes.isNotEmpty ? " • " + t.notes : ""}', style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${t.amount.toStringAsFixed(0)} ج.م',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isAdv ? Colors.amber.shade900 : Colors.purple, fontFamily: 'Cairo'),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                                      onPressed: () async {
                                                        final ok = await showDialog<bool>(
                                                          context: context,
                                                          builder: (c) => Directionality(
                                                            textDirection: TextDirection.rtl,
                                                            child: AlertDialog(
                                                              title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
                                                              content: const Text('هل أنت متأكد من حذف هذه المعاملة؟', style: TextStyle(fontFamily: 'Cairo')),
                                                              actions: [
                                                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                                                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: Colors.red, fontFamily: 'Cairo'))),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                        if (ok == true) {
                                                          await provider.deleteNurseTransaction(t.id);
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBox(String title, String val, IconData icon, Color color, {bool isHighlighted = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isHighlighted ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(isHighlighted ? 0.6 : 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontFamily: 'Cairo'), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allNurses = provider.allNurseNames;

    final filteredNurses = allNurses.where((name) {
      if (_searchQuery.isEmpty) return true;
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Summary calculations
    int totalDays = 0;
    double totalEarned = 0;
    double totalAdvances = 0;
    double totalRemaining = 0;

    for (var n in allNurses) {
      totalDays += provider.getNurseDaysCount(n);
      totalEarned += provider.getNurseTotalEarned(n);
      totalAdvances += provider.getNurseTotalAdvances(n);
      totalRemaining += provider.getNurseRemainingBalance(n);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حسابات وأطقم التمريض والسلف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'تصدير كشف التمريض لإكسيل',
              onPressed: () {
                ExportService.exportNursesReportToExcel(provider);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Top Overview Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primary,
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildHeaderStat('عدد أطقم التمريض', '${allNurses.length}', Icons.badge_outlined),
                      _buildHeaderStat('إجمالي الأيام المنفذة', '$totalDays يوم', Icons.calendar_month),
                      _buildHeaderStat('إجمالي المستحقات', '${totalEarned.toStringAsFixed(0)} ج.م', Icons.attach_money),
                      _buildHeaderStat('إجمالي السلف المنصرفة', '${totalAdvances.toStringAsFixed(0)} ج.م', Icons.handshake),
                      _buildHeaderStat('صافي باقي المستحق', '${totalRemaining.toStringAsFixed(0)} ج.م', Icons.account_balance_wallet, isSpecial: true),
                    ],
                  ),
                ],
              ),
            ),

            // Search & Actions bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'بحث باسم الممرض أو الممرضة...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddTransactionDialog(context),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text('تسجيل سلفة / دفعة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // Nurse Cards List
            Expanded(
              child: filteredNurses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا يوجد ممرضين مسجلين مطابقين للبحث', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 14)),
                          const SizedBox(height: 8),
                          const Text('يتم إدراج الممرضين تلقائياً بمجرد تسجيل ورديات عمل لهم أو تسجيل سلف', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: filteredNurses.length,
                      itemBuilder: (ctx, idx) {
                        final nurse = filteredNurses[idx];
                        final days = provider.getNurseDaysCount(nurse);
                        final earned = provider.getNurseTotalEarned(nurse);
                        final advances = provider.getNurseTotalAdvances(nurse);
                        final remaining = provider.getNurseRemainingBalance(nurse);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                          elevation: 1,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showNurseDetailsDialog(context, nurse),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                                    radius: 24,
                                    child: const Icon(Icons.person, color: AppTheme.primary, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(nurse, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo')),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                              child: Text('$days يوم عمل', style: TextStyle(color: Colors.blue.shade900, fontSize: 11, fontFamily: 'Cairo')),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                                              child: Text('المستحق: ${earned.toStringAsFixed(0)} ج.م', style: TextStyle(color: Colors.teal.shade900, fontSize: 11, fontFamily: 'Cairo')),
                                            ),
                                            const SizedBox(width: 6),
                                            if (advances > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4)),
                                                child: Text('سلف: ${advances.toStringAsFixed(0)} ج.م', style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontFamily: 'Cairo')),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('باقي المستحق له', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
                                      Text(
                                        '${remaining.toStringAsFixed(0)} ج.م',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: 'Cairo',
                                          color: remaining >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String title, String val, IconData icon, {bool isSpecial = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSpecial ? AppTheme.accentBright.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSpecial ? AppTheme.accentBright.withOpacity(0.5) : Colors.white24),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSpecial ? AppTheme.accentBright : Colors.white70, size: 16),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: isSpecial ? AppTheme.accentBright : Colors.white70, fontSize: 10, fontFamily: 'Cairo'), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
