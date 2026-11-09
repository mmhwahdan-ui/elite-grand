import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/app_provider.dart';
import '../models/partner_loan_model.dart';
import '../theme/app_theme.dart';
import '../services/export_service.dart';

class PartnerSettlementScreen extends StatefulWidget {
  const PartnerSettlementScreen({super.key});

  @override
  State<PartnerSettlementScreen> createState() => _PartnerSettlementScreenState();
}

class _PartnerSettlementScreenState extends State<PartnerSettlementScreen> {
  DateTime _selectedSettlementDate = DateTime(DateTime.now().year, DateTime.now().month, 23);
  final TextEditingController _customProfitCtrl = TextEditingController();
  bool _useCustomProfit = false;

  @override
  void initState() {
    super.initState();
    // Default to the 23rd of current month
    final now = DateTime.now();
    _selectedSettlementDate = DateTime(now.year, now.month, 23);
  }

  @override
  void dispose() {
    _customProfitCtrl.dispose();
    super.dispose();
  }

  void _showAddPartnerLoanDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    String selectedPartner = 'wahdan';
    final amountCtrl = TextEditingController();
    final monthsCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    String repaymentType = 'single'; // 'single' or 'installments'
    String paymentChannel = 'cash';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.handshake_rounded, color: Colors.indigo),
                SizedBox(width: 8),
                Text('تسجيل سلفة شريك', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اختر الشريك المستلف:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedPartner,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'wahdan', child: Text('أ/ وهدان (المدير العام - 40%)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'shimaa', child: Text('أ/ شيماء (المتابعة والتشغيل - 40%)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'zezo', child: Text('أ/ زيزو (الحسابات والمالية - 20%)', style: TextStyle(fontFamily: 'Cairo'))),
                    ],
                    onChanged: (v) => setDialogState(() => selectedPartner = v ?? 'wahdan'),
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'مبلغ السلفة',
                      suffixText: 'ج.م',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Repayment Type
                  const Text('نظام سداد واسترداد السلفة من الأرباح:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('دفعة واحدة من التصفية', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                          selected: repaymentType == 'single',
                          selectedColor: Colors.indigo.shade100,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                repaymentType = 'single';
                                monthsCtrl.text = '1';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('مقسمة على عدة أشهر', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                          selected: repaymentType == 'installments',
                          selectedColor: Colors.teal.shade100,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                repaymentType = 'installments';
                                monthsCtrl.text = '3';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (repaymentType == 'installments') ...[
                    TextField(
                      controller: monthsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'عدد أشهر التقسيط',
                        suffixText: 'أشهر',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Payment channel
                  const Text('مصدر الصرف من الخزينة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: paymentChannel,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('💵 خزينة نقدية (كاش المقر)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'wallet', child: Text('📱 محفظة إلكترونية (فودافون كاش / إنستاباي)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'bank', child: Text('🏦 حساب بنكي (تحويل)', style: TextStyle(fontFamily: 'Cairo'))),
                    ],
                    onChanged: (v) => setDialogState(() => paymentChannel = v ?? 'cash'),
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات وبيان السلفة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  final months = int.tryParse(monthsCtrl.text.trim()) ?? 1;

                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال مبلغ سلفة صحيح', style: TextStyle(fontFamily: 'Cairo'))),
                    );
                    return;
                  }

                  String pName = 'أ/ وهدان';
                  if (selectedPartner == 'shimaa') pName = 'أ/ شيماء';
                  if (selectedPartner == 'zezo') pName = 'أ/ زيزو';

                  await provider.recordPartnerLoan(
                    partnerUsername: selectedPartner,
                    partnerName: pName,
                    totalAmount: amount,
                    date: selectedDate,
                    repaymentType: repaymentType,
                    installmentMonths: months > 0 ? months : 1,
                    paymentChannel: paymentChannel,
                    notes: notesCtrl.text.trim(),
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تسجيل سلفة الشريك بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.accent),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: const Text('حفظ السلفة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisburseConfirmDialog(BuildContext context, Map<String, dynamic> calc) {
    final provider = context.read<AppProvider>();
    final notesCtrl = TextEditingController();
    String paymentChannel = 'cash';

    final totalDisbursed = calc['totalDisbursed'] as double;
    final treasuryBefore = calc['treasuryBefore'] as double;
    final remainingTreasury = calc['remainingTreasury'] as double;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green),
                SizedBox(width: 8),
                Text('تأكيد صرف أرباح الشركاء وتحديث الخزينة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سيتم تنفيذ تصفية أرباح هذه الدورة واستقطاع أقساط السلف المستحقة وصرف الصافي لكل شريك من الخزينة:',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 16),

                  // Treasury summary card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        _buildCashRow('💰 السيولة المتاحة بالخزائن حالياً (قبل الصرف):', '${treasuryBefore.toStringAsFixed(0)} ج.م', Colors.blue.shade900),
                        const Divider(height: 12),
                        _buildCashRow('💸 إجمالي الأرباح المنصرفة للشركاء:', '- ${totalDisbursed.toStringAsFixed(0)} ج.م', Colors.red.shade700),
                        const Divider(height: 12),
                        _buildCashRow(
                          '💵 باقي النقدية والسيولة بالخزينة (بعد الصرف):',
                          '${remainingTreasury.toStringAsFixed(0)} ج.م',
                          remainingTreasury >= 0 ? Colors.green.shade800 : Colors.red.shade900,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Partner Breakdown
                  _buildPartnerMiniPayout('أ/ وهدان (المدير العام)', calc['wahdanNet'] as double, calc['wahdanLoan'] as double),
                  _buildPartnerMiniPayout('أ/ شيماء (المتابعة والتشغيل)', calc['shimaaNet'] as double, calc['shimaaLoan'] as double),
                  _buildPartnerMiniPayout('أ/ زيزو (الحسابات والمالية)', calc['zezoNet'] as double, calc['zezoLoan'] as double),
                  const SizedBox(height: 14),

                  // Payment Channel
                  const Text('قناة صرف الأرباح من الخزينة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: paymentChannel,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('💵 الخزينة النقدية (كاش المقر)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'wallet', child: Text('📱 المحفظة الإلكترونية (فودافون كاش / إنستاباي)', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'bank', child: Text('🏦 الحساب البنكي (تحويل)', style: TextStyle(fontFamily: 'Cairo'))),
                    ],
                    onChanged: (v) => setDialogState(() => paymentChannel = v ?? 'cash'),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات إضافية على التصفية',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
              ElevatedButton(
                onPressed: () async {
                  await provider.executePartnerSettlement(
                    settlementDate: _selectedSettlementDate,
                    customNetProfit: calc['profit'] as double,
                    paymentChannel: paymentChannel,
                    notes: notesCtrl.text.trim(),
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تأكيد صرف الأرباح وتحديث الخزينة وسداد أقساط السلف بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                        backgroundColor: AppTheme.accent,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                child: const Text('تأكيد الصرف وتثبيت التصفية', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashRow(String label, String val, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontFamily: 'Cairo')),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo')),
      ],
    );
  }

  Widget _buildPartnerMiniPayout(String name, double net, double loanDeduction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
          Row(
            children: [
              if (loanDeduction > 0)
                Text('(خصم سلفة: -${loanDeduction.toStringAsFixed(0)})  ', style: const TextStyle(fontSize: 11, color: Colors.amber, fontFamily: 'Cairo')),
              Text('${net.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal, fontFamily: 'Cairo')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');

    double? customProfit;
    if (_useCustomProfit) {
      customProfit = double.tryParse(_customProfitCtrl.text.trim());
    }

    final calc = provider.calculateCycle23Settlement(
      settlementDate: _selectedSettlementDate,
      customNetProfit: customProfit,
    );

    final totalProfit = calc['profit'] as double;
    final totalDisbursed = calc['totalDisbursed'] as double;
    final treasuryBefore = calc['treasuryBefore'] as double;
    final remainingTreasury = calc['remainingTreasury'] as double;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تصفية أرباح الشركاء - دورة 23 ${_getMonthName(_selectedSettlementDate.month)}',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'تصدير تصفية الشركاء لإكسيل',
              onPressed: () {
                ExportService.exportPartnerSettlementToExcel(provider, calc, _selectedSettlementDate);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cycle selector & Date header
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.calendar_month, color: Colors.indigo, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'دورة تصفية أرباح يوم 23 من الشهر (${_getMonthName(_selectedSettlementDate.month)} ${_selectedSettlementDate.year})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                            ),
                            Text(
                              'الفترة المحاسبية: من ${dateFormat.format(calc['startDate'] as DateTime)} إلى ${dateFormat.format(calc['endDate'] as DateTime)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedSettlementDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedSettlementDate = DateTime(picked.year, picked.month, 23);
                            });
                          }
                        },
                        icon: const Icon(Icons.edit_calendar, size: 16),
                        label: const Text('تغيير الشهر', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Company Net Profit & Treasury Impact Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي أرباح الشركة القابلة للتوزيع:', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Cairo')),
                        Row(
                          children: [
                            Text(
                              '${totalProfit.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(_useCustomProfit ? Icons.check_circle : Icons.tune, color: Colors.white70, size: 20),
                              tooltip: 'تعديل أو تحديد صافي أرباح يدوي',
                              onPressed: () {
                                setState(() {
                                  _useCustomProfit = !_useCustomProfit;
                                  if (_useCustomProfit && _customProfitCtrl.text.isEmpty) {
                                    _customProfitCtrl.text = totalProfit.toStringAsFixed(0);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_useCustomProfit) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customProfitCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                        decoration: InputDecoration(
                          labelText: 'تحديد صافي أرباح مخصص لهذه التصفية',
                          labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12),
                          suffixText: 'ج.م',
                          suffixStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const Divider(color: Colors.white24, height: 24),

                    // Treasury Impact row
                    Row(
                      children: [
                        _buildDarkStat('السيولة المتاحة حالياً بالخزائن', '${treasuryBefore.toStringAsFixed(0)} ج.م', Colors.amberAccent),
                        const SizedBox(width: 12),
                        _buildDarkStat('إجمالي المنصرف للشركاء', '- ${totalDisbursed.toStringAsFixed(0)} ج.م', Colors.redAccent),
                        const SizedBox(width: 12),
                        _buildDarkStat('باقي النقدية بالخزينة بعد الصرف', '${remainingTreasury.toStringAsFixed(0)} ج.م', Colors.greenAccent, isHighlight: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Partners Profit Distribution Cards (Wahdan, Shimaa, Zezo)
              const Text(
                'توزيع أرباح الشركاء والأنصبة الرسمية:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Wahdan Card (40%)
                  Expanded(
                    child: _buildPartnerCard(
                      name: 'أ/ وهدان',
                      roleTitle: 'المدير العام',
                      percentage: '40%',
                      baseProfit: calc['wahdanBase'] as double,
                      adminDeduction: calc['wahdanAdminDeduction'] as double,
                      adminDeductionLabel: 'خصم مساهمة ضمان شيماء (40/60)',
                      loanDeduction: calc['wahdanLoan'] as double,
                      netPayout: calc['wahdanNet'] as double,
                      themeColor: const Color(0xFF1E3A8A), // Deep Blue
                      icon: Icons.admin_panel_settings,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 2. Shimaa Card (40% with minimum guarantee)
                  Expanded(
                    child: _buildPartnerCard(
                      name: 'أ/ شيماء',
                      roleTitle: 'المتابعة والتشغيل',
                      percentage: '40% (ضمان 6000)',
                      baseProfit: calc['shimaaBase'] as double,
                      subsidyAmount: calc['shimaaSubsidy'] as double,
                      subsidyLabel: 'دعم ضمان الحد الأدنى (6000 ج.م)',
                      loanDeduction: calc['shimaaLoan'] as double,
                      netPayout: calc['shimaaNet'] as double,
                      themeColor: const Color(0xFF7C3AED), // Purple
                      icon: Icons.support_agent,
                      isGuaranteedMinimum: true,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 3. Zezo Card (20%)
                  Expanded(
                    child: _buildPartnerCard(
                      name: 'أ/ زيزو',
                      roleTitle: 'الحسابات والمالية',
                      percentage: '20%',
                      baseProfit: calc['zezoBase'] as double,
                      adminDeduction: calc['zezoAdminDeduction'] as double,
                      adminDeductionLabel: 'خصم مساهمة ضمان شيماء (20/60)',
                      loanDeduction: calc['zezoLoan'] as double,
                      netPayout: calc['zezoNet'] as double,
                      themeColor: const Color(0xFF0D9488), // Teal
                      icon: Icons.account_balance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Disburse Button
              Center(
                child: SizedBox(
                  width: 400,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDisburseConfirmDialog(context, calc),
                    icon: const Icon(Icons.check_circle, color: Colors.white, size: 22),
                    label: const Text(
                      'صرف الأرباح وتحديث الخزينة وسداد السلف',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Partner Loans Section (سلف الشركاء)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'سجل سلف الشركاء وطرق السداد من الأرباح:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => ExportService.exportPartnerLoansToExcel(provider),
                        icon: const Icon(Icons.download, size: 16, color: Colors.green),
                        label: const Text('تصدير السلف لإكسيل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.green)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAddPartnerLoanDialog(context),
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text('تسجيل سلفة لشريك', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                elevation: 0.5,
                child: provider.partnerLoans.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'لا توجد سلف مسجلة للشركاء حالياً',
                            style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.partnerLoans.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final loan = provider.partnerLoans[idx];
                          final isPaid = loan.isFullyPaid;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPaid ? Colors.green.shade50 : Colors.indigo.shade50,
                              child: Icon(
                                isPaid ? Icons.check : Icons.handshake,
                                color: isPaid ? Colors.green : Colors.indigo,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(loan.partnerName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green.shade100 : Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isPaid ? 'مسددة بالكامل' : 'جاري السداد',
                                    style: TextStyle(color: isPaid ? Colors.green.shade900 : Colors.amber.shade900, fontSize: 10, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'التاريخ: ${dateFormat.format(loan.date)} • ${loan.repaymentTypeArabic} (${loan.channelArabic}) ${loan.notes.isNotEmpty ? " • " + loan.notes : ""}',
                              style: const TextStyle(fontSize: 11, fontFamily: 'Cairo'),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('إجمالي السلفة: ${loan.totalAmount.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
                                    Text(
                                      'المتبقي: ${loan.remainingAmount.toStringAsFixed(0)} ج.م',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isPaid ? Colors.green : Colors.redAccent,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: AlertDialog(
                                          title: const Text('تأكيد حذف السلفة', style: TextStyle(fontFamily: 'Cairo')),
                                          content: const Text('هل أنت متأكد من حذف سلفة هذا الشريك نهائياً؟', style: TextStyle(fontFamily: 'Cairo')),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: Colors.red, fontFamily: 'Cairo'))),
                                          ],
                                        ),
                                      ),
                                    );
                                    if (ok == true) {
                                      await provider.deletePartnerLoan(loan.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkStat(String title, String val, Color valColor, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isHighlight ? valColor.withOpacity(0.15) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: valColor.withOpacity(isHighlight ? 0.6 : 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: isHighlight ? valColor : Colors.white70, fontSize: 10, fontFamily: 'Cairo')),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(color: valColor, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard({
    required String name,
    required String roleTitle,
    required String percentage,
    required double baseProfit,
    double adminDeduction = 0.0,
    String? adminDeductionLabel,
    double subsidyAmount = 0.0,
    String? subsidyLabel,
    required double loanDeduction,
    required double netPayout,
    required Color themeColor,
    required IconData icon,
    bool isGuaranteedMinimum = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: themeColor.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                      Text(roleTitle, style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Cairo')),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text(percentage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardRow('حصة الأرباح الأساسية:', '${baseProfit.toStringAsFixed(0)} ج.م', Colors.black87),

                // Shimaa Subsidy (if applied)
                if (subsidyAmount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('دعم ضمان الحد الأدنى:', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        Text('+ ${subsidyAmount.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('تم رفع النصيب إلى 6000 ج.م كحد أدنى مضمون', style: TextStyle(fontSize: 9, color: Colors.purple, fontFamily: 'Cairo')),
                ],

                // Admin deduction from other partners to support Shimaa
                if (adminDeduction > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('خصم مصاريف ضمان شيماء:', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        Text('- ${adminDeduction.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                ],

                // Loan deduction
                if (loanDeduction > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('استقطاع سلفة الشريك:', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        Text('- ${loanDeduction.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  const Text('لا توجد سلف مستقطعة هذا الشهر', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
                ],

                const Divider(height: 16),

                // Net Payout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('صافي المبلغ المستحق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                    Text(
                      '${netPayout.toStringAsFixed(0)} ج.م',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo')),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
