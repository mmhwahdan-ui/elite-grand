import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../services/export_service.dart';
import 'nurse_accounts_screen.dart';
import 'partner_settlement_screen.dart';

class FinancialReportsScreen extends StatelessWidget {
  const FinancialReportsScreen({super.key});

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

    final totalRevenues = provider.totalAccruedRevenues;
    final totalNurseCosts = provider.totalNurseAccruedCosts;
    final totalCompanyGrossProfit = provider.totalCompanyGrossProfit;
    final totalCollections = provider.totalPaymentsCollected;
    final totalExpenses = provider.totalExpenses;
    final netProfit = provider.netAccruedProfit;
    final companyDebts = provider.totalClientDebtsOwedToCompany;
    final clientAdvances = provider.totalClientAdvancesHeldByCompany;

    // Expenses breakdown
    final Map<String, double> expensesByCategory = {};
    for (var exp in provider.expenses) {
      expensesByCategory[exp.categoryArabic] = (expensesByCategory[exp.categoryArabic] ?? 0) + exp.amount;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header title with opening balance settings button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التقرير المالي وحساب الأرباح والخزينة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                      Text(
                        'متابعة حية لأرصدة البنك والمحفظة، فروق أسعار التمريض، وصافي الأرباح',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                  if (provider.canManagePermissions || provider.canEditAnyData || provider.canSetPrice)
                    ElevatedButton.icon(
                      onPressed: () => _showOpeningBalancesDialog(context, provider),
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('أرصدة أول المدة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Actions: Nurse Accounts & Partner Settlements (Day 23)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NurseAccountsScreen()),
                        );
                      },
                      icon: const Icon(Icons.badge_outlined, color: Colors.white, size: 20),
                      label: const Text(
                        'حسابات وسلف التمريض',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488), // Teal
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PartnerSettlementScreen()),
                        );
                      },
                      icon: const Icon(Icons.pie_chart_outline, color: Colors.white, size: 20),
                      label: const Text(
                        'تصفية أرباح الشركاء (يوم 23)',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A), // Indigo / Blue
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Treasury & Account Balances (البنك والمحفظة والكاش)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1E293B), Colors.blueGrey.shade900],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance, color: Colors.amber, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'أرصدة الحسابات ومصادر السيولة المتاحة',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.withOpacity(0.5)),
                          ),
                          child: Text(
                            'إجمالي السيولة: ${provider.totalTreasuryBalance.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // 3 Account Cards Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 500;
                        return Row(
                          children: [
                            // E-Wallet
                            Expanded(
                              child: _buildAccountBox(
                                title: '📱 المحفظة الإلكترونية',
                                subtitle: 'فودافون كاش / إنستاباي',
                                opening: provider.walletOpeningBalance,
                                inFlow: provider.walletCollections,
                                outFlow: provider.walletExpenses,
                                current: provider.currentWalletBalance,
                                color: Colors.deepPurple.shade300,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Bank
                            Expanded(
                              child: _buildAccountBox(
                                title: '🏦 الحساب البنكي',
                                subtitle: 'تحويلات وإيداعات',
                                opening: provider.bankOpeningBalance,
                                inFlow: provider.bankCollections,
                                outFlow: provider.bankExpenses,
                                current: provider.currentBankBalance,
                                color: Colors.lightBlue.shade300,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Cash
                            Expanded(
                              child: _buildAccountBox(
                                title: '💵 الخزينة النقدية',
                                subtitle: 'كاش المقر والمندوبين',
                                opening: provider.cashOpeningBalance,
                                inFlow: provider.cashCollections,
                                outFlow: provider.cashExpenses,
                                current: provider.currentCashBalance,
                                color: const Color(0xFF6EE7B7),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Case Profitability & Nurse Price Differences Banner (مكسب الشركة من فرق السعر)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.workspace_premium, color: Color(0xFF047857), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'تصفية أرباح الحالات وفروق الأسعار (العميل vs التمريض)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF047857), fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                        Text(
                          '${totalCompanyGrossProfit.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF047857), fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricMini(
                            'إجمالي تعاقدات العملاء',
                            '${totalRevenues.toStringAsFixed(0)} ج.م',
                            Icons.trending_up,
                            Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricMini(
                            'مستحقات التمريض للحالات',
                            '${totalNurseCosts.toStringAsFixed(0)} ج.م',
                            Icons.medical_services_outlined,
                            Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricMini(
                            '💎 صافي ربح الشركة من الفروق',
                            '${totalCompanyGrossProfit.toStringAsFixed(0)} ج.م',
                            Icons.monetization_on,
                            const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Excel Export Section Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF107C41).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.table_view_rounded, color: Color(0xFF107C41), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'تصدير وتنزيل التقارير بصيغة Excel:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: Color(0xFF107C41),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            ExportService.exportClientsToExcel(provider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تنزيل كشف الحالات والعملاء وفروق الأسعار بصيغة Excel', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: Color(0xFF107C41),
                              ),
                            );
                          },
                          icon: const Icon(Icons.people_outline, size: 16),
                          label: const Text('كشف العملاء والتمريض (Excel)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF107C41),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            ExportService.exportPaymentsToExcel(provider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تنزيل سجل المقبوضات والتحصيلات بصيغة Excel', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: AppTheme.accent,
                              ),
                            );
                          },
                          icon: const Icon(Icons.payments_outlined, size: 16),
                          label: const Text('سجل المقبوضات ومكان الإيداع (Excel)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            ExportService.exportExpensesToExcel(provider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تنزيل سجل المصروفات بصيغة Excel', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: Colors.deepOrange,
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt_long, size: 16),
                          label: const Text('سجل المصروفات (Excel)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            ExportService.exportFinancialReportToExcel(provider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تنزيل التقرير المالي الشامل وأرصدة البنوك بصيغة Excel', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          },
                          icon: const Icon(Icons.analytics, size: 16),
                          label: const Text('التقرير المالي والأرصدة (Excel)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            ExportService.exportServiceDaysToExcel(provider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تنزيل سجل الورديات وأيام الخدمة بصيغة Excel', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: Colors.teal,
                              ),
                            );
                          },
                          icon: const Icon(Icons.event_note, size: 16),
                          label: const Text('سجل أيام الخدمة والشفتات (Excel)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            ExportService.exportNursesReportToExcel(provider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تنزيل كشف أيام ومستحقات التمريض بصيغة Excel', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: Color(0xFF0F766E),
                              ),
                            );
                          },
                          icon: const Icon(Icons.badge, size: 16),
                          label: const Text('كشف حساب ومستحقات التمريض (Excel)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Overall Financial KPI Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: isWide ? 1.4 : 1.15,
                    children: [
                      StatCard(
                        title: 'إيرادات الخدمة المحققة',
                        value: '${totalRevenues.toStringAsFixed(0)} ج.م',
                        subtitle: 'بناءً على أيام الخدمة وأسعار العملاء',
                        icon: Icons.trending_up,
                        color: AppTheme.primaryLight,
                      ),
                      StatCard(
                        title: 'إجمالي المقبوضات المحصلة',
                        value: '${totalCollections.toStringAsFixed(0)} ج.م',
                        subtitle: 'محفظة + بنك + كاش',
                        icon: Icons.account_balance_wallet,
                        color: AppTheme.accent,
                      ),
                      StatCard(
                        title: 'إجمالي المصروفات',
                        value: '${totalExpenses.toStringAsFixed(0)} ج.م',
                        subtitle: 'رواتب وانتقالات وإداريات',
                        icon: Icons.money_off,
                        color: Colors.deepOrange,
                      ),
                      StatCard(
                        title: 'صافي الأرباح التشغيلية',
                        value: '${netProfit.toStringAsFixed(0)} ج.م',
                        subtitle: netProfit >= 0 ? 'أرباح محققة' : 'عجز تشغيلي',
                        icon: Icons.monetization_on,
                        color: netProfit >= 0 ? AppTheme.greenCredit : AppTheme.redDebt,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // 5. Outstanding Dues & Advances Row
              Row(
                children: [
                  // Dues from defaulted / delayed clients
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppTheme.redDebt, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'مستحقات الشركة طرف العملاء (مديونيات)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.redDebt, fontFamily: 'Cairo'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${companyDebts.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.redDebt, fontFamily: 'Cairo'),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'تشمل مديونيات سابقة وحسابات خدمة مستحقة',
                            style: TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Client advance balances
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: AppTheme.greenCredit, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'مستحقات العملاء مقدماً (أرصدة دائنة)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.greenCredit, fontFamily: 'Cairo'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${clientAdvances.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.greenCredit, fontFamily: 'Cairo'),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'تشمل أرصدة افتتاحية ودفعات مقدمة',
                            style: TextStyle(fontSize: 11, color: Color(0xFF166534), fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. Nurse Accounts & Days Statistics Card (كشف حساب وإحصائيات أطقم التمريض)
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.badge, color: Colors.teal),
                              SizedBox(width: 8),
                              Text(
                                'كشف أيام ومستحقات أطقم التمريض',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NurseAccountsScreen()),
                              );
                            },
                            icon: const Icon(Icons.manage_accounts, size: 16),
                            label: const Text('كشف الحسابات والسلف', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (provider.allNursesDaysCount.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: Text(
                              'لم يتم تسجيل ورديات مخصصة للتمريض بعد.\nعند تسجيل أيام الخدمة من بطاقة العميل سيتم تجميع أيام كل ممرض ومستحقاته تلقائياً هنا.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.blueGrey, fontFamily: 'Cairo', fontSize: 12, height: 1.5),
                            ),
                          ),
                        )
                      else ...[
                        ...provider.allNursesDaysCount.entries.map((entry) {
                          final nurseName = entry.key;
                          final days = entry.value;
                          final dues = provider.allNursesAccruedDues[nurseName] ?? 0.0;
                          final shifts = provider.allNursesServiceDays[nurseName] ?? [];
                          final clientNames = shifts.map((s) => s.clientName).toSet().join('، ');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCCFBF1)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.teal.shade100,
                                  child: const Icon(Icons.badge_outlined, color: Colors.teal, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nurseName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                                      ),
                                      if (clientNames.isNotEmpty)
                                        Text(
                                          'الحالات: $clientNames',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade700,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$days يوم عمل',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'المستحق: ${dues.toStringAsFixed(0)} ج.م',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal, fontFamily: 'Cairo'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 7. Expenses by Category Breakdown
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تفصيل المصروفات حسب البند',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 12),
                      if (expensesByCategory.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text('لا توجد مصروفات مسجلة حتى الآن', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
                          ),
                        )
                      else
                        ...expensesByCategory.entries.map((entry) {
                          final percentage = totalExpenses > 0 ? (entry.value / totalExpenses) * 100 : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo', fontSize: 13)),
                                    Text(
                                      '${entry.value.toStringAsFixed(0)} ج.م (${percentage.toStringAsFixed(1)}%)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalExpenses > 0 ? (entry.value / totalExpenses) : 0,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontFamily: 'Cairo')),
          const Divider(height: 12, color: Colors.white12),
          Text('أول المدة: ${opening.toStringAsFixed(0)} ج.م', style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'Cairo')),
          Text('وارد: +${inFlow.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontFamily: 'Cairo')),
          Text('منصرف: -${outFlow.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontFamily: 'Cairo')),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'الرصيد: ${current.toStringAsFixed(0)} ج.م',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricMini(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade800, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }
}
