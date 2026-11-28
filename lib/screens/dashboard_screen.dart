import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/app_provider.dart';
import '../models/client_model.dart';
import '../models/service_day_model.dart';
import '../theme/app_theme.dart';
import '../services/whatsapp_service.dart';
import '../widgets/daily_reconciliation_dialog.dart';
import '../widgets/edit_company_dialog.dart';
import '../widgets/add_edit_client_dialog.dart';
import '../widgets/add_service_day_dialog.dart';
import 'case_offers_screen.dart';
import 'team_chat_screen.dart';
import 'caregivers_screen.dart';
import 'weekly_monthly_settlement_screen.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final now = DateTime.now();
    final todayFormatted = DateFormat('EEEE d MMMM yyyy', 'ar').format(now);

    // Active & all clients
    final allClients = provider.clients;
    final activeClients = allClients.where((c) => c.status == 'active').toList();
    final pendingPricingClients = allClients.where((c) => c.status == 'pending_pricing' || c.status == 'pending').toList();

    // Today's service days
    final todayLoggedDays = provider.serviceDays.where((d) {
      final dl = d.date.toLocal();
      return dl.year == now.year && dl.month == now.month && dl.day == now.day;
    }).toList();

    final loggedClientIds = todayLoggedDays.map((d) => d.clientId).toSet();
    final confirmedCount = todayLoggedDays.length;
    final pendingConfirmClients = activeClients.where((c) => !loggedClientIds.contains(c.id)).toList();

    // Financial summaries
    final drawerCash = provider.openingBalances['cash'] ?? 0.0;
    final bankBalance = provider.openingBalances['bank'] ?? 0.0;
    final walletBalance = provider.openingBalances['wallet'] ?? 0.0;

    double totalDebtsOwed = 0.0;
    for (final c in allClients) {
      final b = provider.getClientBalance(c);
      if (b < 0) totalDebtsOwed += b.abs();
    }

    final dailySummary = provider.getDailyNetProfitSummary();
    final monthlySummary = provider.getMonthlyNetProfitSummary();

    // Caregivers on shift today
    final activeNursesToday = todayLoggedDays.map((d) => d.nurseName).toSet();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Executive Welcome & Branding Hero Card
              _buildBrandingHeroCard(context, provider, todayFormatted, isMobile),
              const SizedBox(height: 16),

              // 2. Windows Grid (شبابيك موقف العمل كاملاً)
              _buildWindowsGrid(
                context,
                provider,
                isDesktop: isDesktop,
                isMobile: isMobile,
                activeCount: activeClients.length,
                pendingPricingCount: pendingPricingClients.length,
                confirmedShifts: confirmedCount,
                totalActiveForShifts: activeClients.length,
                pendingConfirmClients: pendingConfirmClients,
                drawerCash: drawerCash,
                bankBalance: bankBalance,
                walletBalance: walletBalance,
                totalDebtsOwed: totalDebtsOwed,
                todayProfit: dailySummary.netProfit,
                cycleProfit: monthlySummary.netProfit,
                activeNursesCount: activeNursesToday.length,
                totalCaregivers: provider.caregivers.length,
              ),
              const SizedBox(height: 16),

              // 3. Operational Attention & Urgent Shifts Window
              _buildOperationalDailyMonitor(
                context,
                provider,
                activeClients: activeClients,
                todayLoggedDays: todayLoggedDays,
                isMobile: isMobile,
              ),
              const SizedBox(height: 16),

              // 4. Quick Actions Launchpad
              _buildQuickActionsLaunchpad(context, provider, isMobile),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Executive Welcome & Branding Hero Card
  Widget _buildBrandingHeroCard(BuildContext context, AppProvider provider, String todayFormatted, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1E36), Color(0xFF1E3A5F)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1E36).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Company Logo Box (Clickable to edit)
              Tooltip(
                message: 'اضغط لتعديل اللوجو واسم الشركة ✏️',
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const EditCompanyDialog(),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: isMobile ? 54 : 64,
                    height: isMobile ? 54 : 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC59B6D), width: 1.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: provider.companyLogoUrl != null && provider.companyLogoUrl!.isNotEmpty
                              ? Image.network(
                                  provider.companyLogoUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                                )
                              : Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withOpacity(0.55),
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: const Text(
                              'تعديل ✏️',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 8, color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Company Info & Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.companyName,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isMobile ? 17 : 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFC59B6D)),
                          tooltip: 'تعديل اسم وشعار الشركة',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const EditCompanyDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.companySubtitle,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Color(0xFFC59B6D),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                todayFormatted,
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D09C).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF00D09C).withOpacity(0.5), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_done_rounded, size: 11, color: Color(0xFF00D09C)),
                              SizedBox(width: 4),
                              Text(
                                'سحابي متصل',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00D09C)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons on desktop
              if (!isMobile) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddEditClientDialog(),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('تسجيل حالة جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),

          if (isMobile) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddEditClientDialog(),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                    label: const Text('تسجيل حالة جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const DailyReconciliationDialog(),
                    );
                  },
                  icon: const Icon(Icons.lock_clock_rounded, size: 15),
                  label: const Text('تقفيل الخزينة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC59B6D),
                    foregroundColor: const Color(0xFF0F1E36),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 2. Windows Grid (شبابيك موقف العمل كاملاً)
  Widget _buildWindowsGrid(
    BuildContext context,
    AppProvider provider, {
    required bool isDesktop,
    required bool isMobile,
    required int activeCount,
    required int pendingPricingCount,
    required int confirmedShifts,
    required int totalActiveForShifts,
    required List<ClientModel> pendingConfirmClients,
    required double drawerCash,
    required double bankBalance,
    required double walletBalance,
    required double totalDebtsOwed,
    required double todayProfit,
    required double cycleProfit,
    required int activeNursesCount,
    required int totalCaregivers,
  }) {
    final currencyFormat = NumberFormat('#,##0', 'ar');

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 600
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 1.65 : 1.55,
          children: [
            // Window 1: موقف ورديات اليوم (الموقف الصباحي)
            _buildWindowCard(
              title: 'شباك ورديات اليوم والتشغيل ☀️',
              badge: confirmedShifts == totalActiveForShifts && totalActiveForShifts > 0
                  ? 'مكتمل بنسبة 100% ✓'
                  : '$confirmedShifts من $totalActiveForShifts وردية',
              badgeColor: confirmedShifts == totalActiveForShifts && totalActiveForShifts > 0
                  ? const Color(0xFF059669)
                  : const Color(0xFFD97706),
              icon: Icons.wb_sunny_rounded,
              iconColor: const Color(0xFFD97706),
              primaryStat: '$confirmedShifts / $totalActiveForShifts',
              primaryLabel: 'ورديات مؤكدة حضورها اليوم',
              subStats: [
                'المتبقي للتأكيد: ${pendingConfirmClients.length} حالة',
                'الكوادر العاملة: $activeNursesCount كادر',
              ],
              actionLabel: pendingConfirmClients.isNotEmpty ? '⚡ تأكيد ورديات اليوم للكل' : 'استعراض الورديات',
              actionColor: pendingConfirmClients.isNotEmpty ? const Color(0xFF0D9488) : const Color(0xFF64748B),
              onAction: () async {
                if (pendingConfirmClients.isNotEmpty) {
                  _confirmAllTodayShifts(context, provider, pendingConfirmClients);
                } else if (onNavigateTab != null) {
                  onNavigateTab!(1); // Go to clients
                }
              },
            ),

            // Window 2: نبض الخزينة والسيولة النقدية 💵
            _buildWindowCard(
              title: 'شباك الخزينة والسيولة النقدية 💵',
              badge: 'مطابق اليوم ✓',
              badgeColor: const Color(0xFF0F766E),
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF0F766E),
              primaryStat: '${currencyFormat.format(drawerCash)} ج',
              primaryLabel: 'كاش الدرج المتوفر حالياً',
              subStats: [
                'البنك والمحفظة: ${currencyFormat.format(bankBalance + walletBalance)} ج',
                'أرباح اليوم: ${currencyFormat.format(todayProfit)} ج',
              ],
              actionLabel: '🔒 مطابقة وتقفيل الدرج اليومي',
              actionColor: const Color(0xFF0F766E),
              onAction: () {
                showDialog(
                  context: context,
                  builder: (_) => const DailyReconciliationDialog(),
                );
              },
            ),

            // Window 3: المديونيات المعلقة للتحصيل ⚠️
            _buildWindowCard(
              title: 'شباك المديونيات والتحصيل المطلوب ⚠️',
              badge: '${currencyFormat.format(totalDebtsOwed)} ج مستحق',
              badgeColor: totalDebtsOwed > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
              icon: Icons.hourglass_top_rounded,
              iconColor: const Color(0xFFDC2626),
              primaryStat: '${currencyFormat.format(totalDebtsOwed)} ج',
              primaryLabel: 'مستحقات معلقة على العملاء',
              subStats: [
                'حالات بها مديونية نشطة',
                'أرباح دورة الخميس: ${currencyFormat.format(cycleProfit)} ج',
              ],
              actionLabel: '💵 جدول التحصيلات والإيرادات',
              actionColor: const Color(0xFF2563EB),
              onAction: () {
                if (onNavigateTab != null) {
                  onNavigateTab!(5); // Revenues tab
                }
              },
            ),

            // Window 4: حالات المرضى والرعاية 👥
            _buildWindowCard(
              title: 'شباك الحالات والرعاية الطبية 👥',
              badge: '$activeCount حالة نشطة',
              badgeColor: const Color(0xFF2563EB),
              icon: Icons.people_alt_rounded,
              iconColor: const Color(0xFF2563EB),
              primaryStat: '$activeCount حالة',
              primaryLabel: 'إجمالي الحالات الجارية الآن',
              subStats: [
                'بانتظار التسعير/البدء: $pendingPricingCount حالة',
                'إجمالي قاعدة البيانات: ${provider.clients.length} عميل',
              ],
              actionLabel: '👥 فتح ملفات الحالات',
              actionColor: const Color(0xFF2563EB),
              onAction: () {
                if (onNavigateTab != null) {
                  onNavigateTab!(1); // Clients tab
                }
              },
            ),

            // Window 5: أطقم التمريض والكوادر 🩺
            _buildWindowCard(
              title: 'شباك التمريض ومقدمي الخدمة 🩺',
              badge: '$totalCaregivers كادر مسجل',
              badgeColor: const Color(0xFF7C3AED),
              icon: Icons.badge_rounded,
              iconColor: const Color(0xFF7C3AED),
              primaryStat: '$activeNursesCount كادر',
              primaryLabel: 'في خدمة الحالات اليوم',
              subStats: [
                'الكوادر الجاهزة للتكليف: ${totalCaregivers - activeNursesCount}',
                'إجمالي سجل الكوادر: $totalCaregivers ممرض',
              ],
              actionLabel: '🩺 استعراض سجل الكوادر',
              actionColor: const Color(0xFF7C3AED),
              onAction: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiversScreen()));
              },
            ),

            // Window 6: أرباح دورة الخميس والشركاء 📊
            _buildWindowCard(
              title: 'شباك أرباح دورة الخميس (الشركاء) 📊',
              badge: 'دورة 23',
              badgeColor: const Color(0xFFC59B6D),
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF9A7444),
              primaryStat: '${currencyFormat.format(cycleProfit)} ج',
              primaryLabel: 'صافي أرباح الدورة الحالية',
              subStats: [
                'صافي ربح اليوم: ${currencyFormat.format(todayProfit)} ج',
                'موعد التصفية: يوم 23 من الشهر',
              ],
              actionLabel: '📊 كشف تقفيل الأسبوع والشركاء',
              actionColor: const Color(0xFF9A7444),
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeeklyMonthlySettlementScreen(initialTab: 'weekly')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Generic Window Card Widget
  Widget _buildWindowCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required String primaryStat,
    required String primaryLabel,
    required List<String> subStats,
    required String actionLabel,
    required Color actionColor,
    required VoidCallback onAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Primary Stat
          Text(
            primaryStat,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
          Text(
            primaryLabel,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          const Spacer(),

          // Sub stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: subStats.map((s) => Text(s, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFF94A3B8)))).toList(),
          ),
          const SizedBox(height: 8),

          // Action button
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: actionColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    actionLabel,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: actionColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: actionColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Operational Attention & Urgent Shifts Window
  Widget _buildOperationalDailyMonitor(
    BuildContext context,
    AppProvider provider, {
    required List<ClientModel> activeClients,
    required List<ServiceDayModel> todayLoggedDays,
    required bool isMobile,
  }) {
    final loggedClientIds = todayLoggedDays.map((d) => d.clientId).toSet();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flash_on_rounded, color: Color(0xFF0F766E), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شباك المتابعة الفورية لحالات اليوم (إجراءات سريعة)',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'تأكيد ورديات اليوم وتواصل واتساب مباشر ومتابعة المديونيات',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (activeClients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('لا توجد حالات جارية حالياً', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeClients.length > 5 ? 5 : activeClients.length,
              separatorBuilder: (_, __) => const Divider(height: 14, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, idx) {
                final client = activeClients[idx];
                final isConfirmed = loggedClientIds.contains(client.id);
                final balance = provider.getClientBalance(client);
                final isDebt = balance < 0;

                return Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConfirmed ? const Color(0xFF059669) : const Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Client details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                client.name,
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isConfirmed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isConfirmed ? 'مؤكدة ✓' : 'بانتظار التأكيد',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isConfirmed ? const Color(0xFF166534) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'الممرض: ${(client.nurseAssigned?.isNotEmpty == true) ? client.nurseAssigned! : "لم يحدد"} • ${client.dailyPrice.toStringAsFixed(0)} ج/يوم',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),

                    // Financial balance pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isDebt ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDebt ? '${balance.abs().toInt()} ج مستحق' : 'خالص (0 ج)',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDebt ? const Color(0xFFDC2626) : const Color(0xFF475569),
                        ),
                      ),
                    ),

                    // WhatsApp 1-Click Button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_rounded, size: 15, color: Color(0xFF15803D)),
                      ),
                      tooltip: 'إرسال كشف حساب بالواتساب',
                      onPressed: () {
                        WhatsAppService.shareAccountStatement(
                          context: context,
                          phone: client.phone,
                          clientName: client.name,
                          serviceType: client.serviceType,
                          dailyPrice: client.dailyPrice,
                          daysCount: client.servedDays,
                          totalDue: balance < 0 ? (-balance) : 0.0,
                          totalPaid: 0.0,
                          remainingBalance: balance,
                        );
                      },
                    ),
                    const SizedBox(width: 6),

                    // Action: Confirm Shift or Details
                    if (!isConfirmed)
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddServiceDayDialog(client: client),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('تأكيد الوردية', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        onPressed: () {
                          if (onNavigateTab != null) onNavigateTab!(1);
                        },
                      ),
                  ],
                );
              },
            ),

          if (activeClients.length > 5) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  if (onNavigateTab != null) onNavigateTab!(1);
                },
                child: Text('عرض جميع الحالات الجارية (${activeClients.length} حالة) ←', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. Quick Actions Launchpad
  Widget _buildQuickActionsLaunchpad(BuildContext context, AppProvider provider, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'روابط الوصول السريع',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLaunchpadPill(
                icon: Icons.person_add_alt_1_rounded,
                label: 'تسجيل حالة جديدة',
                color: const Color(0xFF0D9488),
                onTap: () => showDialog(context: context, builder: (_) => const AddEditClientDialog()),
              ),
              _buildLaunchpadPill(
                icon: Icons.lock_clock_rounded,
                label: 'تقفيل ومطابقة الخزينة',
                color: const Color(0xFF0F766E),
                onTap: () => showDialog(context: context, builder: (_) => const DailyReconciliationDialog()),
              ),
              _buildLaunchpadPill(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'شات وتنبيهات الشركة',
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamChatScreen())),
              ),
              _buildLaunchpadPill(
                icon: Icons.campaign_outlined,
                label: 'جروب الحالات والفرص',
                color: const Color(0xFFF59E0B),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CaseOffersScreen())),
              ),
              _buildLaunchpadPill(
                icon: Icons.business_rounded,
                label: 'تخصيص اللوجو واسم الشركة',
                color: const Color(0xFF9A7444),
                onTap: () => showDialog(context: context, builder: (_) => const EditCompanyDialog()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchpadPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // 1-Click confirmation of all pending today shifts
  void _confirmAllTodayShifts(BuildContext context, AppProvider provider, List<ClientModel> pendingClients) {
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد جميع ورديات اليوم بضغطة واحدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
            'سيتم تأكيد وتسجيل وردية اليوم (${DateFormat('yyyy/MM/dd').format(now)}) لجميع الحالات الجارية المتبقية وعددهم (${pendingClients.length}) حالة بالأسعار واليوميات المحددة.\nهل أنت متأكد؟',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                int recorded = 0;
                for (final client in pendingClients) {
                  final nurseName = (client.nurseAssigned?.isNotEmpty == true) ? client.nurseAssigned! : 'مقدم خدمة';
                  await provider.recordServiceDay(
                    clientId: client.id,
                    date: DateTime(now.year, now.month, now.day),
                    clientPrice: client.dailyPrice,
                    nursePrice: client.nurseDailyPrice,
                    nurseName: nurseName,
                    notes: 'تسجيل وتأكيد جماعي من لوحة القيادة',
                    shiftType: client.serviceType,
                  );
                  recorded++;
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تأكيد $recorded وردية لليوم بنجاح ✓', style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: const Color(0xFF0F766E),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد الكل الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
