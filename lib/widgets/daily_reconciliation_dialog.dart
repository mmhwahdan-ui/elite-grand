import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class DailyReconciliationDialog extends StatefulWidget {
  const DailyReconciliationDialog({super.key});

  @override
  State<DailyReconciliationDialog> createState() => _DailyReconciliationDialogState();
}

class _DailyReconciliationDialogState extends State<DailyReconciliationDialog> {
  final TextEditingController _actualCashCtrl = TextEditingController();
  final TextEditingController _actualBankCtrl = TextEditingController();
  final TextEditingController _actualWalletCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  double _actualCash = 0.0;
  double _actualBank = 0.0;
  double _actualWallet = 0.0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    // Pre-fill with current expected book balances for convenience
    _actualCash = provider.currentCashBalance;
    _actualBank = provider.currentBankBalance;
    _actualWallet = provider.currentWalletBalance;

    _actualCashCtrl.text = _actualCash.toStringAsFixed(0);
    _actualBankCtrl.text = _actualBank.toStringAsFixed(0);
    _actualWalletCtrl.text = _actualWallet.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _actualCashCtrl.dispose();
    _actualBankCtrl.dispose();
    _actualWalletCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy/MM/dd').format(now);

    // Book balances
    final expectedCash = provider.currentCashBalance;
    final expectedBank = provider.currentBankBalance;
    final expectedWallet = provider.currentWalletBalance;
    final expectedTotal = expectedCash + expectedBank + expectedWallet;

    // Actual total
    final actualTotal = _actualCash + _actualBank + _actualWallet;

    // Variances
    final cashDiff = _actualCash - expectedCash;
    final bankDiff = _actualBank - expectedBank;
    final walletDiff = _actualWallet - expectedWallet;
    final totalDiff = actualTotal - expectedTotal;

    // Today's movements
    final todayPayments = provider.payments.where((p) {
      final pl = p.paymentDate.toLocal();
      return pl.year == now.year && pl.month == now.month && pl.day == now.day;
    }).fold(0.0, (s, p) => s + p.amount);

    final todayExpenses = provider.expenses.where((e) {
      final el = e.expenseDate.toLocal();
      return el.year == now.year && el.month == now.month && el.day == now.day;
    }).fold(0.0, (s, e) => s + e.amount);

    final todayNurseAdvances = provider.nurseTransactions.where((t) {
      final tl = t.date.toLocal();
      return tl.year == now.year && tl.month == now.month && tl.day == now.day && t.type == 'advance';
    }).fold(0.0, (s, t) => s + t.amount);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2540).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0A2540), size: 20),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'مطابقة وتقفيل الخزينة اليومية',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                todayFormatted,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Today's summary pill
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('مقبوضات اليوم', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFF64748B))),
                            Text('+${todayPayments.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('مصروفات وسلف اليوم', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFF64748B))),
                            Text('-${(todayExpenses + todayNurseAdvances).toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('صافي حركة اليوم', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFF64748B))),
                            Text('${(todayPayments - todayExpenses - todayNurseAdvances).toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'قارن النقدية الموجودة فعلياً بالدرج والبنوك مع رصيد السيستم:',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),

                // Cash in drawer
                _buildChannelRow(
                  title: 'الخزينة النقدية (الكاش بالدرج)',
                  icon: Icons.payments_outlined,
                  expected: expectedCash,
                  controller: _actualCashCtrl,
                  diff: cashDiff,
                  onChanged: (val) {
                    setState(() {
                      _actualCash = double.tryParse(val) ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Bank
                _buildChannelRow(
                  title: 'الحساب البنكي (المعاملات البنكية)',
                  icon: Icons.account_balance_outlined,
                  expected: expectedBank,
                  controller: _actualBankCtrl,
                  diff: bankDiff,
                  onChanged: (val) {
                    setState(() {
                      _actualBank = double.tryParse(val) ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Wallets
                _buildChannelRow(
                  title: 'فودافون كاش والمحافظ',
                  icon: Icons.phone_android_outlined,
                  expected: expectedWallet,
                  controller: _actualWalletCtrl,
                  diff: walletDiff,
                  onChanged: (val) {
                    setState(() {
                      _actualWallet = double.tryParse(val) ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Total Reconciliation Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: totalDiff == 0
                        ? const Color(0xFFECFDF5)
                        : totalDiff < 0
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: totalDiff == 0
                          ? const Color(0xFF10B981)
                          : totalDiff < 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        totalDiff == 0
                            ? Icons.check_circle_rounded
                            : totalDiff < 0
                                ? Icons.warning_amber_rounded
                                : Icons.info_outline_rounded,
                        color: totalDiff == 0
                            ? const Color(0xFF059669)
                            : totalDiff < 0
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD97706),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              totalDiff == 0
                                  ? 'الحسابات مطابقة تماماً (الدرج والبنوك تطابق السيستم 100%)'
                                  : totalDiff < 0
                                      ? 'يوجد عجز نقدي بقيمة ${(-totalDiff).toStringAsFixed(0)} ج.م (الفعلي أقل من السيستم)'
                                      : 'توجد زيادة نقدية بقيمة ${totalDiff.toStringAsFixed(0)} ج.م (الفعلي أكبر من السيستم)',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: totalDiff == 0
                                    ? const Color(0xFF065F46)
                                    : totalDiff < 0
                                        ? const Color(0xFF991B1B)
                                        : const Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              'الإجمالي الدفتري: ${expectedTotal.toStringAsFixed(0)} ج  |  الإجمالي الفعلي: ${actualTotal.toStringAsFixed(0)} ج',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Closing Notes
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات تقفيل اليومية (اختياري)',
                    hintText: 'مثال: تم سداد سلفة متبقية نقداً، أو سبب العجز/الزيادة إن وجد...',
                    prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final user = provider.currentUser?.displayName ?? 'المشرف';
              final statusText = totalDiff == 0
                  ? 'مطابقة تامة'
                  : totalDiff < 0
                      ? 'عجز ${(-totalDiff).toStringAsFixed(0)} ج'
                      : 'زيادة ${totalDiff.toStringAsFixed(0)} ج';

              await provider.logSystemAction(
                title: 'تقفيل ومطابقة الخزينة اليومية 🔒',
                description: 'أ/ $user قام بمطابقة الخزينة اليومية ($statusText) - الفعلي: ${actualTotal.toStringAsFixed(0)} ج.م | الدفتري: ${expectedTotal.toStringAsFixed(0)} ج.م ${_notesCtrl.text.isNotEmpty ? "• ملاحظات: ${_notesCtrl.text}" : ""}',
                actionType: 'financial_closing',
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم اعتماد وتسجيل تقفيل الخزينة اليومي بنجاح ✓', style: TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: Color(0xFF0F766E),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2540),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.lock_clock_rounded, size: 16),
            label: const Text('اعتماد وحفظ تقفيل اليومية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelRow({
    required String title,
    required IconData icon,
    required double expected,
    required TextEditingController controller,
    required double diff,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                Text('السيستم: ${expected.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onChanged: onChanged,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                border: OutlineInputBorder(),
                hintText: '0',
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              diff == 0
                  ? 'مطابق ✓'
                  : diff < 0
                      ? '${diff.toStringAsFixed(0)} ج'
                      : '+${diff.toStringAsFixed(0)} ج',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: diff == 0
                    ? const Color(0xFF16A34A)
                    : diff < 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
