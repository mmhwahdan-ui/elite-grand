import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/app_provider.dart';
import '../models/period_financial_summary.dart';
import '../theme/app_theme.dart';
import '../screens/partner_settlement_screen.dart';

class PeriodicNetProfitCard extends StatefulWidget {
  const PeriodicNetProfitCard({super.key});

  @override
  State<PeriodicNetProfitCard> createState() => _PeriodicNetProfitCardState();
}

class _PeriodicNetProfitCardState extends State<PeriodicNetProfitCard> {
  // 'daily', 'weekly', 'monthly'
  String _selectedTab = 'monthly';

  // For daily custom date
  DateTime _selectedDailyDate = DateTime.now();

  // For monthly cycle offset (-1, 0, +1)
  int _monthlyCycleOffset = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final dailySummary = provider.getDailyNetProfitSummary(_selectedDailyDate);
    final weeklySummary = provider.getWeeklyNetProfitSummary();
    final monthlySummary = provider.getMonthlyNetProfitSummary(offsetCycles: _monthlyCycleOffset);

    final currentSummary = _selectedTab == 'daily'
        ? dailySummary
        : (_selectedTab == 'weekly' ? weeklySummary : monthlySummary);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مؤشرات وتقارير صافي الأرباح الدورية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'صافي ربح اليوم، الأسبوع، والشهري وفق دورة نهاية الشهر (يوم 23)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 KPI Cards Row (Daily, Weekly, Monthly)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'صافي الربح اليومي',
                        periodSubtitle: DateFormat('yyyy/MM/dd').format(dailySummary.endDate),
                        summary: dailySummary,
                        badgeText: 'اليوم',
                        color: const Color(0xFF059669), // Green
                        icon: Icons.today_rounded,
                        isSelected: _selectedTab == 'daily',
                        onTap: () => setState(() => _selectedTab = 'daily'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'صافي الربح الأسبوعي',
                        periodSubtitle: 'آخر 7 أيام',
                        summary: weeklySummary,
                        badgeText: '7 أيام',
                        color: const Color(0xFF0284C7), // Blue
                        icon: Icons.date_range_rounded,
                        isSelected: _selectedTab == 'weekly',
                        onTap: () => setState(() => _selectedTab = 'weekly'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'صافي الربح الشهري',
                        periodSubtitle: 'دورة 23 من الشهر',
                        summary: monthlySummary,
                        badgeText: monthlySummary.daysRemainingUntil23 != null && monthlySummary.daysRemainingUntil23! > 0
                            ? 'باقي ${monthlySummary.daysRemainingUntil23} يوم'
                            : 'موعد التصفية',
                        color: const Color(0xFF6366F1), // Indigo
                        icon: Icons.calendar_month_rounded,
                        isSelected: _selectedTab == 'monthly',
                        onTap: () => setState(() => _selectedTab = 'monthly'),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildKpiCard(
                      title: 'صافي الربح الشهري (دورة 23)',
                      periodSubtitle: 'دورة الشهر المنتهية في 23',
                      summary: monthlySummary,
                      badgeText: monthlySummary.daysRemainingUntil23 != null && monthlySummary.daysRemainingUntil23! > 0
                          ? 'باقي ${monthlySummary.daysRemainingUntil23} يوم حتى 23'
                          : 'موعد تصفية الشهر',
                      color: const Color(0xFF6366F1),
                      icon: Icons.calendar_month_rounded,
                      isSelected: _selectedTab == 'monthly',
                      onTap: () => setState(() => _selectedTab = 'monthly'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: 'صافي ربح اليوم',
                            periodSubtitle: DateFormat('MM/dd').format(dailySummary.endDate),
                            summary: dailySummary,
                            badgeText: 'اليوم',
                            color: const Color(0xFF059669),
                            icon: Icons.today_rounded,
                            isSelected: _selectedTab == 'daily',
                            onTap: () => setState(() => _selectedTab = 'daily'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'صافي ربح الأسبوع',
                            periodSubtitle: 'آخر 7 أيام',
                            summary: weeklySummary,
                            badgeText: '7 أيام',
                            color: const Color(0xFF0284C7),
                            icon: Icons.date_range_rounded,
                            isSelected: _selectedTab == 'weekly',
                            onTap: () => setState(() => _selectedTab = 'weekly'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Period Mode Selector Tabs & Controls
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabPill(
                    label: 'الشهري (دورة 23)',
                    isSelected: _selectedTab == 'monthly',
                    color: const Color(0xFF6366F1),
                    icon: Icons.calendar_month,
                    onTap: () => setState(() => _selectedTab = 'monthly'),
                  ),
                ),
                Expanded(
                  child: _buildTabPill(
                    label: 'الأسبوعي (7 أيام)',
                    isSelected: _selectedTab == 'weekly',
                    color: const Color(0xFF0284C7),
                    icon: Icons.date_range,
                    onTap: () => setState(() => _selectedTab = 'weekly'),
                  ),
                ),
                Expanded(
                  child: _buildTabPill(
                    label: 'اليومي',
                    isSelected: _selectedTab == 'daily',
                    color: const Color(0xFF059669),
                    icon: Icons.today,
                    onTap: () => setState(() => _selectedTab = 'daily'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Controls & Cycle Switcher Bar
          if (_selectedTab == 'monthly') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF4F46E5)),
                    tooltip: 'الدورة السابقة',
                    onPressed: () => setState(() => _monthlyCycleOffset--),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          monthlySummary.periodTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF312E81),
                          ),
                        ),
                        if (_monthlyCycleOffset == 0)
                          Text(
                            monthlySummary.daysRemainingUntil23 != null && monthlySummary.daysRemainingUntil23! > 0
                                ? '⏳ متبقي ${monthlySummary.daysRemainingUntil23} يوم على تصفية نهاية الشهر (يوم 23)'
                                : '🏁 اليوم هو موعد تصفية دورة يوم 23 من الشهر!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: monthlySummary.daysRemainingUntil23 == 0 ? Colors.green.shade800 : Colors.indigo.shade700,
                            ),
                          )
                        else
                          Text(
                            _monthlyCycleOffset < 0 ? 'دورة منتهية سابقة' : 'دورة قادمة',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF4F46E5)),
                    tooltip: 'الدورة التالية',
                    onPressed: () => setState(() => _monthlyCycleOffset++),
                  ),
                  if (_monthlyCycleOffset != 0)
                    TextButton(
                      onPressed: () => setState(() => _monthlyCycleOffset = 0),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('الدورة الحالية', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else if (_selectedTab == 'daily') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event, size: 18, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Text(
                        'اليوم المحدد: ${DateFormat('yyyy/MM/dd').format(_selectedDailyDate)}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (!DateUtils.isSameDay(_selectedDailyDate, DateTime.now()))
                        TextButton(
                          onPressed: () => setState(() => _selectedDailyDate = DateTime.now()),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: const Text('اليوم الحالي', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDailyDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDailyDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: const Text('تغيير اليوم', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Detailed Breakdown Card
          _buildDetailedBreakdown(currentSummary),

          // If Monthly, show Partner Distributions Card (Wahdan 40%, Shimaa 40% with 6000 min, Zezo 20%)
          if (_selectedTab == 'monthly') ...[
            const SizedBox(height: 14),
            _buildPartnerDistributionCard(context, monthlySummary),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String periodSubtitle,
    required PeriodFinancialSummary summary,
    required String badgeText,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isProfitable = summary.netProfit >= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Big Net Profit Value
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  summary.netProfit >= 0
                      ? '+${summary.netProfit.toStringAsFixed(0)}'
                      : summary.netProfit.toStringAsFixed(0),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: isProfitable ? const Color(0xFF059669) : Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'ج.م',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Subtitle info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'فروق: ${summary.grossProfit.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  'مصروف: ${summary.expenses.toStringAsFixed(0)} ج.م',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill({
    required String label,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? color : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBreakdown(PeriodFinancialSummary summary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'تفاصيل الأرباح والتشغيل: ${summary.periodTitle}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: summary.isProfitable ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: summary.isProfitable ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Text(
                  'هامش الربح: ${summary.profitMargin.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: summary.isProfitable ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4-item KPI grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: _buildMetricTile('📈 إيراد الخدمة (تعاقدات)', '${summary.revenues.toStringAsFixed(0)} ج.م', Colors.blue.shade900)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricTile('🩺 مستحقات التمريض', '${summary.nurseCosts.toStringAsFixed(0)} ج.م', Colors.teal.shade800)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricTile('💎 ربح فروق الأسعار', '${summary.grossProfit.toStringAsFixed(0)} ج.م', const Color(0xFF059669))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricTile('💸 المصروفات التشغيلية', '${summary.expenses.toStringAsFixed(0)} ج.م', Colors.red.shade700)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildMetricTile('📈 إيراد الخدمة', '${summary.revenues.toStringAsFixed(0)} ج.م', Colors.blue.shade900)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMetricTile('🩺 مستحق التمريض', '${summary.nurseCosts.toStringAsFixed(0)} ج.م', Colors.teal.shade800)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildMetricTile('💎 ربح الفروق', '${summary.grossProfit.toStringAsFixed(0)} ج.م', const Color(0xFF059669))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMetricTile('💸 المصروفات', '${summary.expenses.toStringAsFixed(0)} ج.م', Colors.red.shade700)),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 10),

          // Bottom Net Profit Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: summary.isProfitable
                    ? [const Color(0xFF065F46), const Color(0xFF047857)]
                    : [const Color(0xFF991B1B), const Color(0xFFB91C1C)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '🏆 صافي الربح المحقق للفترة:',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${summary.netProfit.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Operational Shift / Client Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'الحالات المخدومة: ${summary.activeClientsCount} حالة',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_filled, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'إجمالي الورديات / الأيام: ${summary.shiftsCount} وردية',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerDistributionCard(BuildContext context, PeriodFinancialSummary summary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF), // Light indigo
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart, size: 18, color: Color(0xFF4338CA)),
                  SizedBox(width: 6),
                  Text(
                    'توزيع أرباح الشركاء لدورة يوم 23 من الشهر:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF312E81),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PartnerSettlementScreen()),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('شاشة التصفية والسلف', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4338CA),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3 Partners
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildPartnerPayoutBadge(
                        partnerName: 'أ/ وهدان (المدير العام)',
                        sharePercentage: '40%',
                        amount: summary.wahdanShare,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPartnerPayoutBadge(
                        partnerName: 'أ/ شيماء (المتابعة والتشغيل)',
                        sharePercentage: '40%',
                        amount: summary.shimaaShare,
                        color: const Color(0xFF047857),
                        extraBadge: summary.netProfit > 0 && (summary.netProfit * 0.40 < 6000)
                            ? 'ضمان أدنى 6,000 ج'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPartnerPayoutBadge(
                        partnerName: 'أ/ زيزو (الحسابات والمالية)',
                        sharePercentage: '20%',
                        amount: summary.zezoShare,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPartnerPayoutBadge(
                      partnerName: 'أ/ وهدان (المدير العام)',
                      sharePercentage: '40%',
                      amount: summary.wahdanShare,
                      color: const Color(0xFF1E3A8A),
                    ),
                    const SizedBox(height: 6),
                    _buildPartnerPayoutBadge(
                      partnerName: 'أ/ شيماء (المتابعة والتشغيل)',
                      sharePercentage: '40%',
                      amount: summary.shimaaShare,
                      color: const Color(0xFF047857),
                      extraBadge: summary.netProfit > 0 && (summary.netProfit * 0.40 < 6000)
                          ? 'ضمان أدنى 6,000 ج'
                          : null,
                    ),
                    const SizedBox(height: 6),
                    _buildPartnerPayoutBadge(
                      partnerName: 'أ/ زيزو (الحسابات والمالية)',
                      sharePercentage: '20%',
                      amount: summary.zezoShare,
                      color: const Color(0xFF7C3AED),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerPayoutBadge({
    required String partnerName,
    required String sharePercentage,
    required double amount,
    required Color color,
    String? extraBadge,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  partnerName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sharePercentage,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${amount.toStringAsFixed(0)} ج.م',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              if (extraBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Text(
                    extraBadge,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
