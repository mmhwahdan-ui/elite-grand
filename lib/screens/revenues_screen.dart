import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/payment_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/payment_dialog.dart';
import '../services/export_service.dart';

class RevenuesScreen extends StatefulWidget {
  const RevenuesScreen({super.key});

  @override
  State<RevenuesScreen> createState() => _RevenuesScreenState();
}

class _RevenuesScreenState extends State<RevenuesScreen> {
  String _selectedChannel = 'all';
  String _searchQuery = '';

  void _showOpeningBalancesDialog(BuildContext context, AppProvider provider) {
    final bankCtrl = TextEditingController(text: provider.bankOpeningBalance.toStringAsFixed(0));
    final walletCtrl = TextEditingController(text: provider.walletOpeningBalance.toStringAsFixed(0));
    final cashCtrl = TextEditingController(text: provider.cashOpeningBalance.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.tune, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('ضبط أرصدة أول المدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أدخل الرصيد الافتتاحي (أول المدة) لكل حساب ليتم بناء الأرصدة الفعلية عليه تلقائياً مع كل تحصيل أو صرف:',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: walletCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '📱 رصيد أول المدة - المحفظة الإلكترونية (فودافون كاش / إنستاباي)',
                    suffixText: 'ج.م',
                    prefixIcon: Icon(Icons.phone_android, color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bankCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '🏦 رصيد أول المدة - الحساب البنكي',
                    suffixText: 'ج.م',
                    prefixIcon: Icon(Icons.account_balance, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cashCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '💵 رصيد أول المدة - الخزينة النقدية (الكاش)',
                    suffixText: 'ج.م',
                    prefixIcon: Icon(Icons.money, color: Colors.green),
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
                final b = double.tryParse(bankCtrl.text.trim()) ?? 0.0;
                final w = double.tryParse(walletCtrl.text.trim()) ?? 0.0;
                final c = double.tryParse(cashCtrl.text.trim()) ?? 0.0;
                await provider.updateOpeningBalances(bank: b, wallet: w, cash: c);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث أرصدة أول المدة ومزامنتها بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: AppTheme.accent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('حفظ وتثبيت الأرصدة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');

    // Filter by channel
    List<PaymentModel> filtered = provider.payments;
    if (_selectedChannel != 'all') {
      filtered = filtered.where((p) => p.paymentChannel == _selectedChannel).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((p) {
        return p.clientName.toLowerCase().contains(q) ||
            p.notes.toLowerCase().contains(q) ||
            p.receivedBy.toLowerCase().contains(q) ||
            p.amount.toString().contains(q);
      }).toList();
    }

    final totalFilteredAmount = filtered.fold(0.0, (s, p) => s + p.amount);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            // Top Section: Header & Treasury Accounts Dashboard
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title & Top Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سجل الإيرادات وحسابات الخزينة',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                          Text(
                            'متابعة رصيد أول المدة والمحفظة والبنك والخزينة ومتحصلات العملاء',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (provider.canManagePermissions || provider.canEditAnyData || provider.canSetPrice)
                            IconButton(
                              onPressed: () => _showOpeningBalancesDialog(context, provider),
                              tooltip: 'ضبط أرصدة أول المدة',
                              icon: const Icon(Icons.tune, color: AppTheme.primary),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primary.withOpacity(0.08),
                              ),
                            ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () {
                              ExportService.exportPaymentsToExcel(provider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم تنزيل كشف الإيرادات والتحصيلات بصيغة Excel بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                                  backgroundColor: AppTheme.accent,
                                ),
                              );
                            },
                            tooltip: 'تنزيل كشف الإيرادات (Excel)',
                            icon: const Icon(Icons.file_download, color: Color(0xFF107C41)),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF107C41).withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Accounts Card (محفظة، بنك، خزينة)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF0F172A), Colors.blueGrey.shade900],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_balance, color: Colors.amber, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'أرصدة الحسابات ومصادر الإيرادات',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.withOpacity(0.4)),
                              ),
                              child: Text(
                                'السيولة: ${provider.totalTreasuryBalance.toStringAsFixed(0)} ج.م',
                                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // 1. Electronic Wallet
                            Expanded(
                              child: _buildAccountBox(
                                title: '📱 المحفظة',
                                subtitle: 'فودافون كاش / إنستاباي',
                                opening: provider.walletOpeningBalance,
                                inFlow: provider.walletCollections,
                                outFlow: provider.walletExpenses,
                                current: provider.currentWalletBalance,
                                color: Colors.deepPurple.shade300,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // 2. Bank
                            Expanded(
                              child: _buildAccountBox(
                                title: '🏦 البنك',
                                subtitle: 'تحويلات وإيداع',
                                opening: provider.bankOpeningBalance,
                                inFlow: provider.bankCollections,
                                outFlow: provider.bankExpenses,
                                current: provider.currentBankBalance,
                                color: Colors.lightBlue.shade300,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // 3. Cash
                            Expanded(
                              child: _buildAccountBox(
                                title: '💵 الخزينة',
                                subtitle: 'كاش المقر والمندوبين',
                                opening: provider.cashOpeningBalance,
                                inFlow: provider.cashCollections,
                                outFlow: provider.cashExpenses,
                                current: provider.currentCashBalance,
                                color: const Color(0xFF6EE7B7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Field
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'بحث باسم العميل، المبلغ، أو الملاحظات...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Channel Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'جميع الإيرادات (${provider.payments.length}) - ${provider.totalPaymentsCollected.toStringAsFixed(0)} ج.م'),
                        _buildFilterChip('wallet', '📱 المحفظة (${provider.payments.where((p) => p.paymentChannel == 'wallet').length}) - ${provider.walletCollections.toStringAsFixed(0)} ج.م', color: Colors.deepPurple),
                        _buildFilterChip('bank', '🏦 البنك (${provider.payments.where((p) => p.paymentChannel == 'bank').length}) - ${provider.bankCollections.toStringAsFixed(0)} ج.م', color: Colors.blue.shade800),
                        _buildFilterChip('cash', '💵 الخزينة (${provider.payments.where((p) => p.paymentChannel == 'cash').length}) - ${provider.cashCollections.toStringAsFixed(0)} ج.م', color: Colors.green.shade800),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Revenues List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payments_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد إيرادات مسجلة مطابقة للبحث',
                            style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, index) {
                        final payment = filtered[index];
                        return _buildPaymentCard(context, provider, payment, dateFormat);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: provider.canRecordPayment
            ? FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PaymentDialog(),
                  );
                },
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('تسجيل إيراد / تحصيل جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? color}) {
    final isSelected = _selectedChannel == key;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Cairo',
          color: isSelected ? Colors.white : Colors.grey.shade800,
        ),
        backgroundColor: Colors.grey.shade100,
        selectedColor: color ?? AppTheme.primary,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedChannel = key),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }

  Widget _buildAccountBox({
    required String title,
    required String subtitle,
    required double opening,
    required double inFlow,
    required double outFlow,
    required double current,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 8, fontFamily: 'Cairo'), overflow: TextOverflow.ellipsis),
          const Divider(height: 8, color: Colors.white12),
          Text('أول المدة: ${opening.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'Cairo')),
          Text('إيراد: +${inFlow.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontFamily: 'Cairo')),
          Text('صرف: -${outFlow.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontFamily: 'Cairo')),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'الرصيد: ${current.toStringAsFixed(0)} ج.م',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, AppProvider provider, PaymentModel payment, DateFormat dateFormat) {
    Color channelColor;
    switch (payment.paymentChannel) {
      case 'wallet':
        channelColor = Colors.deepPurple;
        break;
      case 'bank':
        channelColor = Colors.blue.shade800;
        break;
      case 'cash':
      default:
        channelColor = Colors.green.shade800;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: channelColor.withOpacity(0.12),
              child: Icon(
                payment.paymentChannel == 'wallet'
                    ? Icons.phone_android
                    : (payment.paymentChannel == 'bank' ? Icons.account_balance : Icons.money),
                color: channelColor,
                size: 22,
              ),
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
                          payment.clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                        ),
                      ),
                      Text(
                        '+${payment.amount.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF047857),
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
                          color: channelColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: channelColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          payment.channelShortArabic,
                          style: TextStyle(fontSize: 10, color: channelColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'التاريخ: ${dateFormat.format(payment.paymentDate)}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '| المستلم: ${payment.receivedBy}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                  if (payment.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ملاحظات: ${payment.notes}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                    ),
                  ],
                ],
              ),
            ),
            if (provider.canEditAnyData)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                tooltip: 'حذف الدفعة',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تأكيد حذف الإيراد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      content: Text(
                        'هل أنت متأكد من حذف هذه الدفعة بقيمة ${payment.amount.toStringAsFixed(0)} ج.م الخاصة بـ "${payment.clientName}"؟',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await provider.deletePayment(payment.id);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
