import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/cloud_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cloud_settings_dialog.dart';
import '../widgets/notifications_dialog.dart';
import 'clients_list_screen.dart';
import 'revenues_screen.dart';
import 'expenses_screen.dart';
import 'financial_reports_screen.dart';
import 'users_permissions_screen.dart';
import 'login_screen.dart';
import 'nurse_accounts_screen.dart';
import 'partner_settlement_screen.dart';
import 'caregivers_screen.dart';
import 'team_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentUser = provider.currentUser;

    // Determine available navigation tabs based on user permissions
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Determine available navigation tabs based on user permissions
    final List<NavigationDestination> destinations = [
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'الحالات',
      ),
      NavigationDestination(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chat_bubble_outline),
            if (provider.unreadChatCount > 0)
              Positioned(
                top: -3,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    provider.unreadChatCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        selectedIcon: const Icon(Icons.chat_bubble),
        label: 'شات الشركة',
      ),
      const NavigationDestination(
        icon: Icon(Icons.badge_outlined),
        selectedIcon: Icon(Icons.badge),
        label: 'سجل الكوادر',
      ),
    ];

    final List<Widget> screens = [
      const ClientsListScreen(),
      const TeamChatScreen(),
      const CaregiversScreen(),
    ];

    // Revenues tab (الإيرادات ومتابعة الحسابات)
    if (provider.canRecordPayment || provider.canViewFinancialReports || provider.isManager) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'الإيرادات',
        ),
      );
      screens.add(const RevenuesScreen());
    }

    // Expenses tab (for Accountant or Manager or if has permission)
    if (provider.canRecordExpense || provider.isManager) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'المصروفات',
        ),
      );
      screens.add(const ExpensesScreen());
    }

    // Financial Reports tab (for Accountant or Manager or if has permission)
    if (provider.canViewFinancialReports || provider.isManager) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'التقارير والأرباح',
        ),
      );
      screens.add(const FinancialReportsScreen());
    }

    // Permissions & User Management (Exclusively for Wahdan / Manager)
    if (provider.canManagePermissions || provider.isManager) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'إدارة الصلاحيات',
        ),
      );
      screens.add(const UsersPermissionsScreen());
    }

    // Ensure _currentIndex is within bounds
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_hospital_rounded, color: AppTheme.accentBright, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'إيليت جراند',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  if (!isMobile)
                    const Text(
                      'تمريض منزلي ورعاية صحية',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                    ),
                ],
              ),
            ],
          ),
          actions: [
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
                  border: Border.all(color: _getSyncBorderColor(provider.syncStatus), width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getSyncIcon(provider.syncStatus),
                      size: 16,
                      color: _getSyncBorderColor(provider.syncStatus),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 6),
                      Text(
                        _getSyncTitle(provider.syncStatus),
                        style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

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
            const SizedBox(width: 4),

            // Team Chat Button with Unread Badge
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  tooltip: 'شات وتواصل أفراد الشركة',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamChatScreen()));
                  },
                ),
                if (provider.unreadChatCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        provider.unreadChatCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),

            // Caregivers Database button
            IconButton(
              icon: const Icon(Icons.badge_outlined, color: Colors.white),
              tooltip: 'قاعدة بيانات وسجل مقدمي الخدمة',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiversScreen()));
              },
            ),
            const SizedBox(width: 4),

            // Financial Reports & Periodic Net Profit button
            IconButton(
              icon: const Icon(Icons.analytics_outlined, color: Colors.white),
              tooltip: 'التقارير والأرباح (صافي الربح الدوري)',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialReportsScreen()));
              },
            ),
            const SizedBox(width: 4),

            // User Profile / Switch Account
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'switch') { await provider.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                } else if (val == 'cloud') {
                  showDialog(
                    context: context,
                    builder: (_) => const CloudSettingsDialog(),
                  );
                } else if (val == 'nurses') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseAccountsScreen()));
                } else if (val == 'notifications') {
                  provider.markNotificationsAsRead();
                  showDialog(
                    context: context,
                    builder: (_) => const NotificationsDialog(),
                  );
                } else if (val == 'chat') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamChatScreen()));
                } else if (val == 'caregivers') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiversScreen()));
                } else if (val == 'settlement') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerSettlementScreen()));
                } else if (val == 'reports') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialReportsScreen()));
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: const Color(0xFF1E293B)),
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
                  value: 'switch',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text('تبديل الحساب / تسجيل خروج', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
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
                  value: 'nurses',
                  child: Row(
                    children: [
                      Icon(Icons.badge_outlined, color: Colors.teal, size: 20),
                      SizedBox(width: 8),
                      Text('حسابات وسلف أطقم التمريض', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'caregivers',
                  child: Row(
                    children: [
                      Icon(Icons.badge, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text('قاعدة بيانات وسجل مقدمي الخدمة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settlement',
                  child: Row(
                    children: [
                      Icon(Icons.pie_chart_outline, color: Colors.indigo, size: 20),
                      SizedBox(width: 8),
                      Text('تصفية أرباح الشركاء (يوم 23)', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reports',
                  child: Row(
                    children: [
                      Icon(Icons.analytics_rounded, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('التقارير والأرباح (صافي الربح الدوري)', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: destinations.length > 1
            ? NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (idx) {
                  setState(() => _currentIndex = idx);
                },
                backgroundColor: Colors.white,
                elevation: 4,
                indicatorColor: AppTheme.primary.withOpacity(0.12),
                destinations: destinations,
              )
            : null,
      ),
    );
  }

  Color _getSyncBorderColor(SyncStatus status) {
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

  IconData _getSyncIcon(SyncStatus status) {
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

  String _getSyncTitle(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return 'سحابي متصل';
      case SyncStatus.syncing:
        return 'مزامنة...';
      case SyncStatus.error:
        return 'خطأ اتصال';
      case SyncStatus.offline:
        return 'محلي';
      case SyncStatus.idle:
      default:
        return 'السحابة';
    }
  }
}
