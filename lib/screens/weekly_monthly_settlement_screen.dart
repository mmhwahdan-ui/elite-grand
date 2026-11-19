import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/settlement_report_model.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import '../services/export_service.dart';
import '../widgets/payment_dialog.dart';

class WeeklyMonthlySettlementScreen extends StatefulWidget {
  final String initialTab; // 'weekly' or 'monthly'

  const WeeklyMonthlySettlementScreen({super.key, this.initialTab = 'weekly'});

  @override
  State<WeeklyMonthlySettlementScreen> createState() => _WeeklyMonthlySettlementScreenState();
}

class _WeeklyMonthlySettlementScreenState extends State<WeeklyMonthlySettlementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

  // Dates for Weekly Settlement (Ending on Thursday)
  late DateTime _weeklyStartDate;
  late DateTime _weeklyEndDate;
  int _weeklyOffset = 0; // 0 = current week, -1 = previous week, etc.

  // Dates for Monthly Settlement
  late int _monthlyYear;
  late int _monthlyMonth;

  // Search filter
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Caregiver vs Client toggle inside the view ('all', 'caregivers', 'clients')
  String _viewFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab == 'monthly' ? 1 : 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });

    final now = DateTime.now();
    _initWeeklyDates(now, 0);

    _monthlyYear = now.year;
    _monthlyMonth = now.month;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initWeeklyDates(DateTime ref, int offsetWeeks) {
    // Find Thursday of target week
    final currentWeekday = ref.weekday; // 1=Mon, 4=Thu, 7=Sun
    final diffToThursday = DateTime.thursday - currentWeekday;
    final thursday = ref.add(Duration(days: diffToThursday + (offsetWeeks * 7)));

    final endThursday = DateTime(thursday.year, thursday.month, thursday.day, 23, 59, 59);
    // Egyptian work week usually Saturday to Thursday (6 days) or 7 days
    final startSaturday = DateTime(thursday.year, thursday.month, thursday.day).subtract(const Duration(days: 6));

    setState(() {
      _weeklyOffset = offsetWeeks;
      _weeklyStartDate = startSaturday;
      _weeklyEndDate = endThursday;
    });
  }

  void _showAddNurseTransactionDialog({
    required BuildContext context,
    required String nurseName,
    required double defaultAmount,
    required String defaultType, // 'payout' or 'advance'
  }) {
    final provider = context.read<AppProvider>();
    final amountCtrl = TextEditingController(text: defaultAmount > 0 ? defaultAmount.toStringAsFixed(0) : '');
    final notesCtrl = TextEditingController();
    String transType = defaultType;
    String paymentChannel = 'cash';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  transType == 'payout' ? Icons.payments_outlined : Icons.handshake_outlined,
                  color: transType == 'payout' ? Colors.teal : Colors.amber.shade800,
                ),
                const SizedBox(width: 8),
                Text(
                  transType == 'payout' ? 'صرف مستحقات أسبوعية للممرض' : 'تسجيل سلفة ممرض',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'الممرض: $nurseName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Type Selector
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('صرف أجر / مستحقات', style: TextStyle(fontFamily: 'Cairo')),
                          selected: transType == 'payout',
                          selectedColor: Colors.teal.shade200,
                          onSelected: (val) {
                            if (val) setDlgState(() => transType = 'payout');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('سلفة تمريض', style: TextStyle(fontFamily: 'Cairo')),
                          selected: transType == 'advance',
                          selectedColor: Colors.amber.shade200,
                          onSelected: (val) {
                            if (val) setDlgState(() => transType = 'advance');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ المستحق للدفع (جنيه)',
                      suffixText: 'ج.م',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment Channel
                  DropdownButtonFormField<String>(
                    value: paymentChannel,
                    decoration: const InputDecoration(
                      labelText: 'طريقة ومكان الصرف',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('الخزينة كاش 💵', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'wallet', child: Text('محفظة فودافون كاش / إنستاباي 📱', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'bank', child: Text('الحساب البنكي 🏦', style: TextStyle(fontFamily: 'Cairo'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => paymentChannel = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات الصرف',
                      hintText: transType == 'payout' ? 'تقفيل حساب أسبوعي' : 'سلفة على حساب الوردية',
                      border: const OutlineInputBorder(),
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
                  final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  if (amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال مبلغ صحيح', style: TextStyle(fontFamily: 'Cairo'))),
                    );
                    return;
                  }

                  await provider.recordNurseTransaction(
                    nurseName: nurseName,
                    amount: amt,
                    date: selectedDate,
                    type: transType,
                    paymentChannel: paymentChannel,
                    notes: notesCtrl.text.trim().isNotEmpty
                        ? notesCtrl.text.trim()
                        : (transType == 'payout' ? 'تقفيل الحساب الأسبوعي (دورة الخميس)' : 'سلفة تمريض'),
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          transType == 'payout'
                              ? 'تم تسجيل صرف مبلغ ${amt.toStringAsFixed(0)} ج.م للممرض $nurseName بنجاح'
                              : 'تم تسجيل سلفة $nurseName بنجاح',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: AppTheme.accent,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                child: const Text('تأكيد الصرف والتسجيل', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isWeekly = _tabController.index == 0;

    // Build Current Period Report
    final DateTime start;
    final DateTime end;
    final String pType;

    if (isWeekly) {
      start = _weeklyStartDate;
      end = _weeklyEndDate;
      pType = 'weekly';
    } else {
      start = DateTime(_monthlyYear, _monthlyMonth, 1);
      final lastDay = DateTime(_monthlyYear, _monthlyMonth + 1, 0).day;
      end = DateTime(_monthlyYear, _monthlyMonth, lastDay, 23, 59, 59);
      pType = 'monthly';
    }

    final report = provider.getSettlementReportData(
      startDate: start,
      endDate: end,
      periodType: pType,
    );

    // Apply search filter
    final filteredCaregivers = report.caregivers.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.nurseName.toLowerCase().contains(q) ||
          (c.nursePhone != null && c.nursePhone!.contains(q)) ||
          c.clientNames.any((cn) => cn.toLowerCase().contains(q));
    }).toList();

    final filteredClients = report.clients.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.client.name.toLowerCase().contains(q) ||
          c.client.phone.contains(q) ||
          (c.client.nurseAssigned != null && c.client.nurseAssigned!.toLowerCase().contains(q));
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isWeekly ? 'تقفيل الحساب الأسبوعي (دورة الخميس) 🔔' : 'تقفيل الحسابات الشهرية 🗓️',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          actions: [
            // Sound Test Button
            IconButton(
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: 'تشغيل نغمة تنبيه تقفيل الخميس بصوت عالي 🔊',
              onPressed: () {
                SoundService.playWeeklySettlementSound();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إطلاق إشعار صوتي عالي لتقفيل الخميس 🔔', style: TextStyle(fontFamily: 'Cairo')),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            // Export to Excel Button
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'تصدير كشف التقفيل لإكسيل 📊',
              onPressed: () {
                ExportService.exportSettlementReportToExcel(report);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.calendar_view_week),
                text: 'التقفيل الأسبوعي (دورة الخميس)',
              ),
              Tab(
                icon: Icon(Icons.calendar_month),
                text: 'التقفيل الشهري (نهاية الشهر)',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Period Selector & Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  if (isWeekly) ...[
                    // Weekly Navigator
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'الأسبوع السابق',
                      onPressed: () => _initWeeklyDates(DateTime.now(), _weeklyOffset - 1),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: DateTimeRange(start: _weeklyStartDate, end: _weeklyEndDate),
                          );
                          if (picked != null) {
                            setState(() {
                              _weeklyStartDate = picked.start;
                              _weeklyEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.date_range, color: AppTheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${_dateFormat.format(_weeklyStartDate)}  ←  ${_dateFormat.format(_weeklyEndDate)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _weeklyOffset == 0 ? Colors.green : Colors.grey,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _weeklyOffset == 0 ? 'الأسبوع الحالي (الخميس)' : (_weeklyOffset == -1 ? 'الأسبوع الماضي' : 'أسبوع مخصص'),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'الأسبوع التالي',
                      onPressed: _weeklyOffset < 0 ? () => _initWeeklyDates(DateTime.now(), _weeklyOffset + 1) : null,
                    ),
                  ] else ...[
                    // Monthly Navigator
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'الشهر السابق',
                      onPressed: () {
                        setState(() {
                          if (_monthlyMonth == 1) {
                            _monthlyMonth = 12;
                            _monthlyYear--;
                          } else {
                            _monthlyMonth--;
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Text(
                            'شهر $_monthlyMonth / $_monthlyYear (${_dateFormat.format(start)} - ${_dateFormat.format(end)})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14, color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'الشهر التالي',
                      onPressed: () {
                        setState(() {
                          if (_monthlyMonth == 12) {
                            _monthlyMonth = 1;
                            _monthlyYear++;
                          } else {
                            _monthlyMonth++;
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Top Summary KPI Cards (7 Metrics)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.primary,
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildSummaryKpi('مستحقات التمريض', '${report.totalCaregiverEarned.toStringAsFixed(0)} ج.م', Icons.badge_outlined),
                      _buildSummaryKpi('سلف التمريض', '${report.totalCaregiverAdvances.toStringAsFixed(0)} ج.م', Icons.handshake),
                      _buildSummaryKpi('المتبقي صرفه للتمريض 💵', '${report.totalCaregiverNetPayable.toStringAsFixed(0)} ج.م', Icons.account_balance_wallet, isHighlight: true),
                      _buildSummaryKpi('مطالبات العملاء', '${report.totalClientAccruedCost.toStringAsFixed(0)} ج.م', Icons.receipt_long),
                      _buildSummaryKpi('تحصيلات العملاء', '${report.totalClientCollected.toStringAsFixed(0)} ج.م', Icons.payments),
                      _buildSummaryKpi('المتبقي على العملاء', '${report.totalClientRemaining.toStringAsFixed(0)} ج.م', Icons.price_check, isWarning: true),
                      _buildSummaryKpi('صافي ربح الشركة', '${report.netCompanyProfit.toStringAsFixed(0)} ج.م', Icons.trending_up, isProfit: true),
                    ],
                  ),
                ],
              ),
            ),

            // Filter Tabs & Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // View Switcher Chips
                  ChoiceChip(
                    label: Text('الكل (${filteredCaregivers.length + filteredClients.length})', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    selected: _viewFilter == 'all',
                    selectedColor: AppTheme.primary.withOpacity(0.15),
                    onSelected: (val) {
                      if (val) setState(() => _viewFilter = 'all');
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.healing, size: 14),
                    label: Text('مقدمو الخدمة (${filteredCaregivers.length})', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    selected: _viewFilter == 'caregivers',
                    selectedColor: Colors.teal.shade100,
                    onSelected: (val) {
                      if (val) setState(() => _viewFilter = 'caregivers');
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.person, size: 14),
                    label: Text('العملاء والحالات (${filteredClients.length})', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    selected: _viewFilter == 'clients',
                    selectedColor: Colors.blue.shade100,
                    onSelected: (val) {
                      if (val) setState(() => _viewFilter = 'clients');
                    },
                  ),
                  const SizedBox(width: 12),
                  // Search
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'بحث باسم الممرض، العميل، أو الحالة...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  // Caregivers Section
                  if (_viewFilter == 'all' || _viewFilter == 'caregivers') ...[
                    _buildSectionHeader(
                      'كشف تقفيل مقدمي الخدمة (التمريض)',
                      'عدد الكوادر النشطة: ${filteredCaregivers.length} • إجمالي الورديات: ${report.totalShiftsCount} • صافي المتبقي صرفه: ${report.totalCaregiverNetPayable.toStringAsFixed(0)} ج.م',
                      Icons.healing,
                      Colors.teal,
                    ),
                    if (filteredCaregivers.isEmpty)
                      _buildEmptyState('لا توجد ورديات أو مستحقات تمريض مسجلة خلال هذه الفترة')
                    else
                      ...filteredCaregivers.map((cg) => _buildCaregiverCard(context, cg)),
                    const SizedBox(height: 16),
                  ],

                  // Clients Section
                  if (_viewFilter == 'all' || _viewFilter == 'clients') ...[
                    _buildSectionHeader(
                      'كشف تقفيل الحالات والعملاء',
                      'عدد الحالات: ${filteredClients.length} • إجمالي المطالبات: ${report.totalClientAccruedCost.toStringAsFixed(0)} ج.م • المحصل: ${report.totalClientCollected.toStringAsFixed(0)} ج.م',
                      Icons.medical_services,
                      AppTheme.primary,
                    ),
                    if (filteredClients.isEmpty)
                      _buildEmptyState('لا توجد مطالبات أو عملاء نشطين خلال هذه الفترة')
                    else
                      ...filteredClients.map((cl) => _buildClientCard(context, cl)),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryKpi(String label, String value, IconData icon, {bool isHighlight = false, bool isWarning = false, bool isProfit = false}) {
    Color bg = Colors.white.withOpacity(0.12);
    Color txtColor = Colors.white;

    if (isHighlight) {
      bg = Colors.amber.shade400;
      txtColor = Colors.black87;
    } else if (isWarning) {
      bg = Colors.orange.shade300;
      txtColor = Colors.black87;
    } else if (isProfit) {
      bg = Colors.greenAccent.shade400;
      txtColor = Colors.black87;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: txtColor),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontFamily: 'Cairo', color: txtColor), textAlign: TextAlign.center, maxLines: 1),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: txtColor),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                Text(subtitle, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
      ),
    );
  }

  Widget _buildCaregiverCard(BuildContext context, CaregiverSettlementItem cg) {
    final hasPayable = cg.periodNetDue > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.teal.shade50,
                  child: const Icon(Icons.person, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(cg.nurseName, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
                          if (cg.nurseCode != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(cg.nurseCode!, style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.blue.shade900)),
                            ),
                          ],
                        ],
                      ),
                      if (cg.clientNames.isNotEmpty)
                        Text(
                          'الحالات المنفذة: ${cg.clientNames.join("، ")}',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ),

                // Quick Action Buttons
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddNurseTransactionDialog(
                      context: context,
                      nurseName: cg.nurseName,
                      defaultAmount: cg.periodNetDue > 0 ? cg.periodNetDue : 0,
                      defaultType: 'payout',
                    );
                  },
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('صرف المستحق 💵', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: () {
                    _showAddNurseTransactionDialog(
                      context: context,
                      nurseName: cg.nurseName,
                      defaultAmount: 0,
                      defaultType: 'advance',
                    );
                  },
                  icon: const Icon(Icons.handshake_outlined, size: 16),
                  label: const Text('سلفة 🤝', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Financial Breakdown Row
            Row(
              children: [
                _buildDataCell('عدد الورديات', '${cg.shiftsCount} وردية'),
                _buildDataCell('اليومية المعتمدة', '${cg.dailyRate.toStringAsFixed(0)} ج.م'),
                _buildDataCell('إجمالي المستحق', '${cg.totalEarned.toStringAsFixed(0)} ج.م', isBold: true),
                _buildDataCell('السلف المنصرفة', '${cg.advances.toStringAsFixed(0)} ج.م', color: Colors.orange.shade800),
                _buildDataCell('المسدد في الفترة', '${cg.payouts.toStringAsFixed(0)} ج.م'),
                _buildDataCell(
                  'صافي المتبقي للصرف 💵',
                  '${cg.periodNetDue.toStringAsFixed(0)} ج.م',
                  isBold: true,
                  color: hasPayable ? Colors.green.shade800 : Colors.grey,
                  isHighlighted: hasPayable,
                ),
                _buildDataCell('الرصيد التراكمي', '${cg.allTimeRemaining.toStringAsFixed(0)} ج.م'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, ClientSettlementItem cl) {
    final c = cl.client;
    final hasDebt = cl.periodRemaining > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withOpacity(0.08),
                  child: const Icon(Icons.person, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(c.name, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Text(
                              c.scheduleDescriptionArabic,
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Text(
                              c.settlementFrequencyArabic,
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'الممرض المسند: ${c.nurseAssigned ?? "غير محدد"} • التليفون: ${c.phone}',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),

                // Quick Collect Payment Button
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => PaymentDialog(preSelectedClient: c),
                    );
                  },
                  icon: const Icon(Icons.credit_card, size: 16),
                  label: const Text('تحصيل دفعة 💳', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Financial Breakdown Row
            Row(
              children: [
                _buildDataCell('أيام الخدمة بالفترة', '${cl.daysServedInPeriod} يوم'),
                _buildDataCell('سعر اليومية', '${cl.dailyPrice.toStringAsFixed(0)} ج.م'),
                _buildDataCell('قيمة الخدمة للفترة', '${cl.periodAccruedCost.toStringAsFixed(0)} ج.م', isBold: true),
                _buildDataCell('التحصيلات المسددة', '${cl.periodCollected.toStringAsFixed(0)} ج.م', color: Colors.green.shade800),
                _buildDataCell(
                  'باقي الحساب للفترة',
                  '${cl.periodRemaining.toStringAsFixed(0)} ج.م',
                  isBold: true,
                  color: hasDebt ? Colors.red.shade800 : Colors.teal,
                  isHighlighted: hasDebt,
                ),
                _buildDataCell('الرصيد التراكمي الشامل', '${cl.allTimeBalance.toStringAsFixed(0)} ج.م'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String label, String value, {bool isBold = false, Color? color, bool isHighlighted = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: isHighlighted
            ? BoxDecoration(
                color: (color ?? AppTheme.primary).withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.grey.shade600), textAlign: TextAlign.center, maxLines: 1),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontFamily: 'Cairo',
                color: color ?? Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
