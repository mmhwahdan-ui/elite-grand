import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../services/cloud_sync_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cloud_settings_dialog.dart';
import '../widgets/notifications_dialog.dart';
import 'dashboard_screen.dart';
import 'clients_list_screen.dart';
import 'revenues_screen.dart';
import 'expenses_screen.dart';
import 'financial_reports_screen.dart';
import 'users_permissions_screen.dart';
import 'weekly_monthly_settlement_screen.dart';
import 'login_screen.dart';
import 'nurse_accounts_screen.dart';
import 'partner_settlement_screen.dart';
import 'caregivers_screen.dart';
import 'team_chat_screen.dart';
import 'nurse_portal_screen.dart';
import 'case_offers_screen.dart';
import '../widgets/management_instructions_dialog.dart';
import '../widgets/all_users_passwords_dialog.dart';
import '../widgets/daily_reconciliation_dialog.dart';
import '../widgets/edit_company_dialog.dart';
import '../services/pwa_install_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (provider.isNurse) {
      return const NursePortalScreen();
    }
    final currentUser = provider.currentUser;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    // Ordered list of screens:
    // 0: لوحة القيادة والتحكم (Dashboard)
    // 1: الحالات والعملاء (Clients)
    // 2: سجل الكوادر والتمريض (Caregivers)
    // 3: جروب الفرص (Case Offers)
    // 4: شات الشركة (Team Chat)
    // 5: الإيرادات والتحصيلات (Revenues)
    // 6: المصروفات والسلفيات (Expenses)
    // 7: التقارير والأرباح (Financial Reports)
    // 8: إدارة الصلاحيات (Users Permissions)
    final List<Widget> screens = [
      DashboardScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const ClientsListScreen(),
      const CaregiversScreen(),
      const CaseOffersScreen(),
      const TeamChatScreen(),
      _buildAuthorizedScreen(
        isAuthorized: provider.canRecordPayment || provider.canViewFinancialReports || provider.isManager,
        screen: const RevenuesScreen(),
        title: 'الإيرادات والتحصيلات',
      ),
      _buildAuthorizedScreen(
        isAuthorized: provider.canRecordExpense || provider.isManager,
        screen: const ExpensesScreen(),
        title: 'المصروفات والسلفيات',
      ),
      _buildAuthorizedScreen(
        isAuthorized: provider.canViewFinancialReports || provider.isManager,
        screen: const FinancialReportsScreen(),
        title: 'التقارير والأرباح',
      ),
      _buildAuthorizedScreen(
        isAuthorized: provider.canManagePermissions || provider.isManager,
        screen: const UsersPermissionsScreen(),
        title: 'إدارة الصلاحيات',
      ),
    ];

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: isMobile ? Drawer(backgroundColor: const Color(0xFF0F1E36), child: _buildSidebarContent(context, provider, isDrawer: true)) : null,
        appBar: AppBar(
          titleSpacing: isMobile ? 8 : 16,
          leading: isMobile
              ? IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                  tooltip: 'القائمة الرئيسية',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                )
              : null,
          title: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const EditCompanyDialog(),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC59B6D), width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: provider.companyLogoUrl != null && provider.companyLogoUrl!.isNotEmpty
                        ? Image.network(
                            provider.companyLogoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                          )
                        : Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.companyName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, size: 12, color: Color(0xFFC59B6D)),
                        ],
                      ),
                      if (!isMobile)
                        Text(
                          provider.companySubtitle,
                          style: const TextStyle(fontSize: 10, color: Color(0xFFC59B6D), fontFamily: 'Cairo'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // Install App Button
            InkWell(
              onTap: () => PwaInstallService.handleInstallClick(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentBright.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentBright, width: 1.3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.install_mobile_rounded,
                      size: 16,
                      color: AppTheme.accentBright,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isMobile ? 'تثبيت' : 'تثبيت البرنامج',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Cloud Sync Button & Indicator
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const CloudSettingsDialog(),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getSyncBorderColor(provider.syncStatus, hasPending: provider.hasPendingOfflineSync),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getSyncIcon(provider.syncStatus, hasPending: provider.hasPendingOfflineSync),
                      size: 16,
                      color: _getSyncBorderColor(provider.syncStatus, hasPending: provider.hasPendingOfflineSync),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 6),
                      Text(
                        _getSyncTitle(provider.syncStatus, hasPending: provider.hasPendingOfflineSync),
                        style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            if (!isMobile) ...[
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'تحديث فوري للبيانات من السحابة',
                onPressed: () async {
                  await provider.syncWithCloud();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث البيانات من السحابة فوراً', style: TextStyle(fontFamily: 'Cairo')),
                        duration: Duration(seconds: 1),
                        backgroundColor: AppTheme.accent,
                      ),
                    );
                  }
                },
              ),
            ],

            // User Profile / Settings Menu
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'company') {
                  showDialog(
                    context: context,
                    builder: (_) => const EditCompanyDialog(),
                  );
                } else if (val == 'password') {
                  _showChangePasswordDialog(context, provider, currentUser);
                } else if (val == 'switch') {
                  await provider.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                } else if (val == 'all_passwords') {
                  showDialog(
                    context: context,
                    builder: (_) => const AllUsersPasswordsDialog(),
                  );
                } else if (val == 'cloud') {
                  showDialog(
                    context: context,
                    builder: (_) => const CloudSettingsDialog(),
                  );
                } else if (val == 'reconciliation') {
                  showDialog(
                    context: context,
                    builder: (_) => const DailyReconciliationDialog(),
                  );
                } else if (val == 'weekly_settlement') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyMonthlySettlementScreen(initialTab: 'weekly')));
                }
              },
              tooltip: 'الحساب والإعدادات',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle, color: AppTheme.accentBright, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      currentUser?.displayName ?? 'المستخدم',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
                    ),
                  ],
                ),
              ),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.displayName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1E293B)),
                      ),
                      Text(
                        currentUser?.roleTitle ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'company',
                  child: Row(
                    children: [
                      Icon(Icons.business_rounded, color: Color(0xFF9A7444), size: 20),
                      SizedBox(width: 8),
                      Text('تخصيص اللوجو واسم الشركة ✏️', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF9A7444))),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reconciliation',
                  child: Row(
                    children: [
                      Icon(Icons.balance_rounded, color: Color(0xFF0F766E), size: 20),
                      SizedBox(width: 8),
                      Text('مطابقة وتقفيل الخزينة اليومي 🔒', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'weekly_settlement',
                  child: Row(
                    children: [
                      Icon(Icons.event_available_rounded, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text('تقفيل الحساب الأسبوعي (دورة الخميس)', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    ],
                  ),
                ),
                if (provider.isManager || provider.canManagePermissions)
                  PopupMenuItem(
                    value: 'all_passwords',
                    child: Row(
                      children: [
                        Icon(Icons.vpn_key_rounded, color: Colors.amber.shade800, size: 20),
                        SizedBox(width: 8),
                        Text('كشف كلمات مرور المستخدمين 🔑', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'cloud',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_sync, color: AppTheme.accent, size: 20),
                      SizedBox(width: 8),
                      Text('إعدادات السحابة والمزامنة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'switch',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text('تسجيل خروج / تبديل الحساب', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Row(
          children: [
            // 1. Right Sidebar on Desktop (appears on the RIGHT in RTL)
            if (!isMobile)
              Container(
                width: 250,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F1E36),
                  border: Border(left: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
                ),
                child: _buildSidebarContent(context, provider, isDrawer: false),
              ),

            // 2. Main Active Screen
            Expanded(
              child: Column(
                children: [
                  if (provider.showThursdayBanner)
                    _buildThursdaySettlementBanner(context, provider),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: screens,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Clean Mobile Bottom Navigation (only 4 primary comfortable targets)
        bottomNavigationBar: isMobile ? _buildMobileBottomBar(context, provider) : null,
      ),
    );
  }

  // Sidebar content (shared by Desktop permanent Sidebar and Mobile slide-out Drawer)
  Widget _buildSidebarContent(BuildContext context, AppProvider provider, {required bool isDrawer}) {
    final currentUser = provider.currentUser;

    return Column(
      children: [
        // Top Brand Header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: const BoxDecoration(
            color: Color(0xFF0B192C),
            border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC59B6D), width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: provider.companyLogoUrl != null && provider.companyLogoUrl!.isNotEmpty
                        ? Image.network(
                            provider.companyLogoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                          )
                        : Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.companyName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          provider.companySubtitle,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            color: Color(0xFFC59B6D),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFC59B6D)),
                    tooltip: 'تعديل اسم وشعار الشركة',
                    onPressed: () {
                      if (isDrawer) Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const EditCompanyDialog(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // User Info Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF0D9488),
                      child: Text(
                        (currentUser?.displayName.isNotEmpty ?? false) ? currentUser!.displayName.substring(0, 1) : 'م',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.displayName ?? 'المستخدم',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            currentUser?.roleTitle ?? '',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 9, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: Color(0xFF00D09C), shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrollable Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            children: [
              // Group 1: الرئيسية والتشغيل
              _buildCategoryHeader('الرئيسية والتشغيل'),
              _buildNavTile(
                index: 0,
                icon: Icons.dashboard_rounded,
                title: 'لوحة القيادة والتحكم',
                badgeText: 'الرئيسية',
                badgeColor: const Color(0xFF0D9488),
                isDrawer: isDrawer,
              ),
              _buildNavTile(
                index: 1,
                icon: Icons.people_alt_rounded,
                title: 'الحالات والعملاء',
                badgeText: '${provider.clients.where((c) => c.status == "active").length} نشطة',
                badgeColor: const Color(0xFF2563EB),
                isDrawer: isDrawer,
              ),
              _buildNavTile(
                index: 2,
                icon: Icons.badge_rounded,
                title: 'سجل الكوادر والتمريض',
                badgeText: '${provider.caregivers.length} كادر',
                badgeColor: const Color(0xFF7C3AED),
                isDrawer: isDrawer,
              ),
              _buildNavTile(
                index: 3,
                icon: Icons.campaign_rounded,
                title: 'جروب الفرص الجديدة',
                badgeText: provider.openCaseOffersCount > 0 ? '${provider.openCaseOffersCount}' : null,
                badgeColor: const Color(0xFFF59E0B),
                isDrawer: isDrawer,
              ),

              const SizedBox(height: 8),

              // Group 2: القطاع المالي والحسابات
              _buildCategoryHeader('القطاع المالي والحسابات'),
              if (provider.canRecordPayment || provider.canViewFinancialReports || provider.isManager)
                _buildNavTile(
                  index: 5,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'الإيرادات والتحصيلات',
                  isDrawer: isDrawer,
                ),
              if (provider.canRecordExpense || provider.isManager)
                _buildNavTile(
                  index: 6,
                  icon: Icons.receipt_long_rounded,
                  title: 'المصروفات والسلفيات',
                  isDrawer: isDrawer,
                ),
              _buildActionTile(
                icon: Icons.lock_clock_rounded,
                title: 'تقفيل الخزينة والدرج 🔒',
                color: const Color(0xFF0F766E),
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  showDialog(context: context, builder: (_) => const DailyReconciliationDialog());
                },
              ),
              _buildActionTile(
                icon: Icons.event_available_rounded,
                title: 'دورة الخميس (الشركاء) 🔔',
                color: const Color(0xFFC59B6D),
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyMonthlySettlementScreen(initialTab: 'weekly')));
                },
              ),
              if (provider.canViewFinancialReports || provider.isManager)
                _buildNavTile(
                  index: 7,
                  icon: Icons.analytics_rounded,
                  title: 'التقارير وصافي الأرباح',
                  isDrawer: isDrawer,
                ),

              const SizedBox(height: 8),

              // Group 3: التواصل والإدارة
              _buildCategoryHeader('التواصل والإدارة'),
              _buildNavTile(
                index: 4,
                icon: Icons.chat_bubble_rounded,
                title: 'شات أفراد الشركة',
                badgeText: provider.unreadChatCount > 0 ? '${provider.unreadChatCount}' : null,
                badgeColor: Colors.redAccent,
                isDrawer: isDrawer,
              ),
              _buildActionTile(
                icon: Icons.assignment_outlined,
                title: 'لوحة توجيهات الإدارة 📋',
                color: const Color(0xFF38BDF8),
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  showDialog(context: context, builder: (_) => const ManagementInstructionsDialog(isCaregiverView: false));
                },
              ),
              if (provider.canManagePermissions || provider.isManager) ...[
                _buildNavTile(
                  index: 8,
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'إدارة الصلاحيات',
                  isDrawer: isDrawer,
                ),
                _buildActionTile(
                  icon: Icons.vpn_key_rounded,
                  title: 'كشف كلمات المرور 🔑',
                  color: Colors.amber.shade700,
                  onTap: () {
                    if (isDrawer) Navigator.pop(context);
                    showDialog(context: context, builder: (_) => const AllUsersPasswordsDialog());
                  },
                ),
              ],
            ],
          ),
        ),

        // Bottom Footer
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFF0B192C),
            border: Border(top: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  showDialog(context: context, builder: (_) => const CloudSettingsDialog());
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getSyncIcon(provider.syncStatus, hasPending: provider.hasPendingOfflineSync),
                            size: 14,
                            color: _getSyncBorderColor(provider.syncStatus, hasPending: provider.hasPendingOfflineSync),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getSyncTitle(provider.syncStatus, hasPending: provider.hasPendingOfflineSync),
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white70),
                          ),
                        ],
                      ),
                      const Text('v8.2', style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: Colors.white38)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => PwaInstallService.handleInstallClick(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBright.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentBright.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.install_mobile_rounded, size: 13, color: AppTheme.accentBright),
                      SizedBox(width: 6),
                      Text('مثبت كبرنامج مستقل', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required int index,
    required IconData icon,
    required String title,
    String? badgeText,
    Color? badgeColor,
    required bool isDrawer,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: InkWell(
        onTap: () {
          setState(() => _currentIndex = index);
          if (isDrawer) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? const Color(0xFF0D9488)).withOpacity(isSelected ? 0.35 : 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : (badgeColor ?? const Color(0xFF0D9488)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.95),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Clean Mobile Bottom Navigation (only 4 buttons)
  Widget _buildMobileBottomBar(BuildContext context, AppProvider provider) {
    // Map current index to 0, 1, 2 or highlight none
    int selectedBarIndex = _currentIndex == 0 ? 0 : (_currentIndex == 1 ? 1 : (_currentIndex == 2 ? 2 : 0));

    return NavigationBar(
      selectedIndex: selectedBarIndex,
      onDestinationSelected: (idx) {
        if (idx == 0) {
          setState(() => _currentIndex = 0);
        } else if (idx == 1) {
          setState(() => _currentIndex = 1);
        } else if (idx == 2) {
          setState(() => _currentIndex = 2);
        } else if (idx == 3) {
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      backgroundColor: Colors.white,
      elevation: 6,
      indicatorColor: const Color(0xFF0D9488).withOpacity(0.15),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF0D9488)),
          label: 'لوحة التحكم',
        ),
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people_rounded, color: Color(0xFF0D9488)),
          label: 'الحالات',
        ),
        const NavigationDestination(
          icon: Icon(Icons.badge_outlined),
          selectedIcon: Icon(Icons.badge_rounded, color: Color(0xFF0D9488)),
          label: 'الكوادر',
        ),
        NavigationDestination(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.menu_rounded),
              if (provider.unreadChatCount > 0 || provider.openCaseOffersCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          selectedIcon: const Icon(Icons.menu_open_rounded),
          label: 'المزيد ☰',
        ),
      ],
    );
  }

  Widget _buildAuthorizedScreen({
    required bool isAuthorized,
    required Widget screen,
    required String title,
  }) {
    if (isAuthorized) return screen;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('قسم $title', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'عفواً، لا تملك الصلاحية الكافية للوصول إلى هذا القسم.\nيرجى مراجعة إدارة النظام لتعديل صلاحياتك.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThursdaySettlementBanner(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        border: Border(
          bottom: BorderSide(color: Colors.amber.shade400, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active, color: Color(0xFFB45309), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔔 تنبيه تقفيل الحساب الأسبوعي (اليوم الخميس)',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                ),
                Text(
                  'موعد انتهاء الخدمة الأسبوعية وتقفيل حسابات الورديات ومستحقات مقدمي الخدمة والعملاء.',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF78350F)),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WeeklyMonthlySettlementScreen(initialTab: 'weekly'),
                ),
              );
            },
            icon: const Icon(Icons.table_chart_outlined, size: 16),
            label: const Text('فتح كشف التقفيل 📊', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB45309),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.volume_up, color: Color(0xFF92400E), size: 20),
            tooltip: 'تشغيل نغمة التنبيه 🔊',
            onPressed: () => SoundService.playWeeklySettlementSound(),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF92400E), size: 18),
            tooltip: 'إخفاء التنبيه',
            onPressed: () => provider.dismissThursdayBanner(),
          ),
        ],
      ),
    );
  }

  Color _getSyncBorderColor(SyncStatus status, {bool hasPending = false}) {
    if (hasPending) return Colors.amber;
    switch (status) {
      case SyncStatus.success:
        return AppTheme.accentBright;
      case SyncStatus.syncing:
        return Colors.lightBlueAccent;
      case SyncStatus.error:
        return Colors.redAccent;
      case SyncStatus.offline:
        return Colors.orangeAccent;
      case SyncStatus.idle:
      default:
        return Colors.white54;
    }
  }

  IconData _getSyncIcon(SyncStatus status, {bool hasPending = false}) {
    if (hasPending) return Icons.cloud_upload_outlined;
    switch (status) {
      case SyncStatus.success:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.error:
        return Icons.cloud_off;
      case SyncStatus.offline:
        return Icons.signal_wifi_off;
      case SyncStatus.idle:
      default:
        return Icons.cloud_queue;
    }
  }

  String _getSyncTitle(SyncStatus status, {bool hasPending = false}) {
    if (hasPending) return 'معلق للمزامنة';
    switch (status) {
      case SyncStatus.success:
        return 'سحابي متصل';
      case SyncStatus.syncing:
        return 'جاري المزامنة...';
      case SyncStatus.error:
        return 'خطأ اتصال';
      case SyncStatus.offline:
        return 'غير متصل (أوفلاين)';
      case SyncStatus.idle:
      default:
        return 'سحابي متصل';
    }
  }

  void _showChangePasswordDialog(BuildContext context, AppProvider provider, UserModel? user) {
    if (user == null) return;
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تغيير كلمة المرور',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        user.displayName,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPassCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الحالية',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDlgState(() => obscureCurrent = !obscureCurrent),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: const Icon(Icons.key, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDlgState(() => obscureNew = !obscureNew),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور الجديدة',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: const Icon(Icons.key_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDlgState(() => obscureConfirm = !obscureConfirm),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سيتم تطبيق كلمة المرور ومزامنتها سحابياً فوراً مع باقي الأجهزة.',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
              ),
              ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        final currentInput = currentPassCtrl.text.trim();
                        final newPass = newPassCtrl.text.trim();
                        final confirmPass = confirmPassCtrl.text.trim();

                        if (newPass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى إدخال كلمة المرور الجديدة', style: TextStyle(fontFamily: 'Cairo'))),
                          );
                          return;
                        }

                        final isCurrentValid = currentInput == user.password ||
                            (user.password == '123' && (currentInput == '123' || currentInput == '123456'));
                        if (!isCurrentValid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('كلمة المرور الحالية غير صحيحة!', style: TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('كلمتا المرور غير متطابقتين!', style: TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        setDlgState(() => isSaving = true);
                        await provider.changePassword(user.id, newPass);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تغيير كلمة المرور بنجاح وحفظها سحابياً', style: TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: const Text('حفظ كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
