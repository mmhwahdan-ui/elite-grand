import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/app_provider.dart';
import '../models/client_model.dart';
import '../models/caregiver_model.dart';
import '../models/service_day_model.dart';
import '../models/nurse_transaction_model.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class NursePortalScreen extends StatefulWidget {
  const NursePortalScreen({super.key});

  @override
  State<NursePortalScreen> createState() => _NursePortalScreenState();
}

class _NursePortalScreenState extends State<NursePortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog(BuildContext context, AppProvider provider) {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDlgState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور الجديدة',
                      border: OutlineInputBorder(),
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
                  final newPass = passCtrl.text.trim();
                  if (newPass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال كلمة المرور الجديدة', style: TextStyle(fontFamily: 'Cairo'))),
                    );
                    return;
                  }
                  if (newPass != confirmCtrl.text.trim()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('كلمتا المرور غير متطابقتين', style: TextStyle(fontFamily: 'Cairo'))),
                    );
                    return;
                  }
                  final currentUserId = provider.currentUser?.id;
                  if (currentUserId != null) {
                    await provider.changePassword(currentUserId, newPass);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تغيير كلمة المرور بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordShiftDialog(BuildContext context, AppProvider provider, ClientModel client, CaregiverModel caregiver) {
    DateTime selectedDate = DateTime.now();
    String shiftType = client.serviceType;
    final startCtrl = TextEditingController(text: '08:00 ص');
    final endCtrl = TextEditingController(text: '08:00 م');
    final hoursCtrl = TextEditingController(text: '12');
    final notesCtrl = TextEditingController();
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
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_outlined, color: Colors.teal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تسجيل حضور واستلام وردية',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'للحالة: ${client.name}',
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date Picker
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
                    title: const Text('تاريخ الوردية:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    subtitle: Text(
                      DateFormat('yyyy/MM/dd').format(selectedDate),
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    trailing: const Text('تغيير', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setDlgState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Shift Type
                  DropdownButtonFormField<String>(
                    value: shiftType,
                    decoration: const InputDecoration(
                      labelText: 'نوع الوردية',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'hours12', child: Text('وردية 12 ساعة', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'hours24', child: Text('إقامة 24 ساعة', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'hours8', child: Text('وردية 8 ساعات', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'hours10', child: Text('وردية 10 ساعات', style: TextStyle(fontFamily: 'Cairo'))),
                      DropdownMenuItem(value: 'custom', child: Text('ساعات مخصصة', style: TextStyle(fontFamily: 'Cairo'))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() {
                          shiftType = val;
                          if (val == 'hours24') hoursCtrl.text = '24';
                          if (val == 'hours12') hoursCtrl.text = '12';
                          if (val == 'hours8') hoursCtrl.text = '8';
                          if (val == 'hours10') hoursCtrl.text = '10';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Times
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startCtrl,
                          decoration: const InputDecoration(
                            labelText: 'وقت الاستلام',
                            hintText: '08:00 ص',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: endCtrl,
                          decoration: const InputDecoration(
                            labelText: 'وقت التسليم',
                            hintText: '08:00 م',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Hours
                  TextField(
                    controller: hoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد ساعات العمل الفعلية',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notes / Patient Health Report
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'التقرير التمريضي وملاحظات الحالة (اختياري)',
                      hintText: 'العلامات الحيوية، الأدوية، الإجراءات المنفذة...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Privacy Note
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'يوميتك المستحقة: ${(client.nurseDailyPrice > 0 ? client.nurseDailyPrice : caregiver.dailyPrice).toStringAsFixed(0)} ج.م تضاف فوراً لرصيدك.',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.blue.shade900),
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
                child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
              ),
              ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDlgState(() => isSaving = true);
                        try {
                          final hours = double.tryParse(hoursCtrl.text.trim()) ?? 12.0;
                          await provider.nurseRecordShiftAttendance(
                            clientId: client.id,
                            date: selectedDate,
                            shiftType: shiftType,
                            startTime: startCtrl.text.trim(),
                            endTime: endCtrl.text.trim(),
                            hoursCount: hours,
                            notes: notesCtrl.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تسجيل حضور الوردية بنجاح وإثبات مستحقاتك في حسابك', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setDlgState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 18),
                label: const Text('تأكيد حضور الوردية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
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
    final caregiver = provider.currentNurseCaregiver;
    final activeClient = provider.currentNurseActiveClient;
    final allClients = provider.currentNurseAllAssignedClients;
    final shifts = provider.currentNurseShifts;
    final transactions = provider.currentNurseTransactions;

    final double dailyRate = caregiver?.dailyPrice ?? 0.0;
    final int shiftsCount = shifts.length;
    final double totalEarned = provider.currentNurseTotalEarned;
    final double totalAdvances = provider.currentNurseTotalAdvances;
    final double totalPayouts = provider.currentNurseTotalPayouts;
    final double totalReceived = totalAdvances + totalPayouts;
    final double remainingBalance = provider.currentNurseRemainingBalance;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          elevation: 2,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medical_services_rounded, color: AppTheme.accentBright, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بوابة التمريض | ${caregiver?.name ?? provider.currentUser?.displayName ?? "مقدم الخدمة"}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
                  ),
                  Text(
                    caregiver?.code.isNotEmpty == true ? 'كود مقدم الخدمة: ${caregiver!.code}' : 'طاقم الرعاية والتمريض المنزلي',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Rating badge if available
            if (caregiver != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      caregiver.rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],

            // User Menu: Change password & Logout
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (val) async {
                if (val == 'password') {
                  _showChangePasswordDialog(context, provider);
                } else if (val == 'logout') {
                  await provider.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo')),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.accentBright,
            indicatorWeight: 3,
            labelColor: AppTheme.accentBright,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.personal_injury_outlined, size: 20), text: 'الحالة والعميل'),
              Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 20), text: 'كشف حسابي ومستحقاتي'),
              Tab(icon: Icon(Icons.badge_outlined, size: 20), text: 'بياناتي الشخصية'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Top Nurse Financial Summary Cards (Strictly nurse's own finances!)
            _buildTopNurseKpis(
              dailyRate: dailyRate,
              shiftsCount: shiftsCount,
              totalEarned: totalEarned,
              totalReceived: totalReceived,
              remainingBalance: remainingBalance,
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Current Assigned Case & Medical Data
                  _buildCurrentCaseTab(context, provider, activeClient, caregiver, allClients),

                  // Tab 2: Nurse's Financial Ledger
                  _buildFinancialLedgerTab(shifts, transactions, totalEarned, totalReceived, remainingBalance),

                  // Tab 3: Nurse Profile & Past Cases
                  _buildNurseProfileTab(caregiver, allClients),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top KPI Bar for Nurse
  Widget _buildTopNurseKpis({
    required double dailyRate,
    required int shiftsCount,
    required double totalEarned,
    required double totalReceived,
    required double remainingBalance,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _kpiItem('اليومية المعتمدة', '${dailyRate.toStringAsFixed(0)} ج', Colors.blue, Icons.payments_outlined)),
                    const SizedBox(width: 8),
                    Expanded(child: _kpiItem('الورديات المنفذة', '$shiftsCount وردية', Colors.purple, Icons.event_available)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _kpiItem('إجمالي المستحق', '${totalEarned.toStringAsFixed(0)} ج', Colors.teal, Icons.savings_outlined)),
                    const SizedBox(width: 8),
                    Expanded(child: _kpiItem('المتبقي الصافي لك', '${remainingBalance.toStringAsFixed(0)} ج', Colors.green, Icons.account_balance_wallet, isHighlighted: true)),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _kpiItem('اليومية المعتمدة', '${dailyRate.toStringAsFixed(0)} ج', Colors.blue, Icons.payments_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _kpiItem('الورديات المنفذة', '$shiftsCount وردية', Colors.purple, Icons.event_available)),
              const SizedBox(width: 8),
              Expanded(child: _kpiItem('إجمالي المكتسب', '${totalEarned.toStringAsFixed(0)} ج', Colors.teal, Icons.savings_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _kpiItem('المنصرف والسلف', '${totalReceived.toStringAsFixed(0)} ج', Colors.amber.shade800, Icons.money_off)),
              const SizedBox(width: 8),
              Expanded(child: _kpiItem('المتبقي الصافي لك', '${remainingBalance.toStringAsFixed(0)} ج', Colors.green, Icons.account_balance_wallet, isHighlighted: true)),
            ],
          );
        },
      ),
    );
  }

  Widget _kpiItem(String title, String val, Color color, IconData icon, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.12) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isHighlighted ? color : Colors.grey.shade200, width: isHighlighted ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade600)),
                Text(
                  val,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: isHighlighted ? color : const Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Current Assigned Case
  Widget _buildCurrentCaseTab(
    BuildContext context,
    AppProvider provider,
    ClientModel? client,
    CaregiverModel? caregiver,
    List<ClientModel> allClients,
  ) {
    if (client == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded, size: 56, color: Colors.teal.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    'أنت الآن في وضع الاستعداد (متاح لاستلام حالات جديدة)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'لا توجد حالة نشطة مسندة إليك في الوقت الحالي. عندما تقوم الإدارة بإسناد حالة جديدة لك، ستظهر جميع بيانات المريض ومكان العمل هنا فوراً.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner with Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.tealAccent, width: 1.5),
                  ),
                  child: const Icon(Icons.personal_injury_rounded, color: Colors.tealAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'الحالة المكلف بها: ${client.name}',
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('جاري تقديم الخدمة', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نوع الخدمة: ${_formatServiceType(client.serviceType)} • تاريخ البدء: ${client.startDate != null ? DateFormat('yyyy/MM/dd').format(client.startDate!) : "محدد"}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                ),
                // Action Button: Record shift
                ElevatedButton.icon(
                  onPressed: caregiver != null
                      ? () => _showRecordShiftDialog(context, provider, client, caregiver)
                      : null,
                  icon: const Icon(Icons.how_to_reg, size: 18),
                  label: const Text('تسجيل حضور الوردية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Client Details Cards (NO CLIENT FINANCIAL DATA)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.contact_phone_outlined, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'بيانات التواصل ومكان تقديم الخدمة للمريض',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Client Name
                _infoRow(
                  icon: Icons.person_outline,
                  label: 'اسم الحالة / المريض',
                  val: client.name,
                ),
                const SizedBox(height: 12),

                // Phone
                _infoRow(
                  icon: Icons.phone_outlined,
                  label: 'هاتف التواصل مع الأسرة',
                  val: client.phone.isNotEmpty ? client.phone : 'غير مسجل',
                  actionWidget: client.phone.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                          tooltip: 'نسخ رقم الهاتف',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: client.phone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ رقم الهاتف', style: TextStyle(fontFamily: 'Cairo'))),
                            );
                          },
                        )
                      : null,
                ),
                const SizedBox(height: 12),

                // Address
                _infoRow(
                  icon: Icons.location_on_outlined,
                  label: 'عنوان المريض بالتفصيل',
                  val: client.address.isNotEmpty ? client.address : 'غير مسجل',
                  actionWidget: client.address.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                          tooltip: 'نسخ العنوان',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: client.address));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ العنوان', style: TextStyle(fontFamily: 'Cairo'))),
                            );
                          },
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Medical & Care Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.healing_outlined, color: Colors.teal, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'التشخيص الطبي والتعليمات التمريضية للحالة',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Health Condition
                _infoRow(
                  icon: Icons.monitor_heart_outlined,
                  label: 'الحالة الصحية والتشخيص',
                  val: client.healthCondition.isNotEmpty ? client.healthCondition : 'لا توجد ملاحظات طبية خاصة مسجلة',
                ),
                const SizedBox(height: 12),

                // Service Shift
                _infoRow(
                  icon: Icons.schedule,
                  label: 'نظام ومواعيد الوردية',
                  val: _formatServiceType(client.serviceType),
                ),
                const SizedBox(height: 12),

                // Notes / Admin instructions
                if (client.notes.isNotEmpty) ...[
                  _infoRow(
                    icon: Icons.notes_outlined,
                    label: 'تعليمات الإدارة لمقدم الخدمة',
                    val: client.notes,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Strict Privacy Notice Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سياسة الخصوصية وسرية التعاملات المالية',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'طبقاً للسياسة المالية للشركة، أسعار التعاقد والمطالبات المالية مع العميل خاصة بإدارة الشركة فقط ولا تظهر لمقدم الخدمة. يظهر في حسابك فقط يوميتك ومستحقاتك المعتمدة وسلفك.',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFF1E40AF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Nurse's Financial Ledger
  Widget _buildFinancialLedgerTab(
    List<ServiceDayModel> shifts,
    List<NurseTransactionModel> transactions,
    double totalEarned,
    double totalReceived,
    double remainingBalance,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Financial Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF065F46)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'صافي الرصيد المستحق لك طرف الشركة',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  '${remainingBalance.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('إجمالي المكتسب', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70)),
                        Text('${totalEarned.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        const Text('المنصرف والسلف', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70)),
                        Text('${totalReceived.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        const Text('عدد الورديات', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70)),
                        Text('${shifts.length} وردية', style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Shifts Table Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'سجل الورديات المنفذة والمستحقة',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      '${shifts.length} وردية مسجلة',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (shifts.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('لا توجد ورديات مسجلة حتى الآن', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shifts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final s = shifts[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.teal.shade50,
                          child: Text('${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                        ),
                        title: Row(
                          children: [
                            Text(
                              DateFormat('yyyy/MM/dd').format(s.date),
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(s.shiftTypeArabic, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.blueGrey)),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الحالة: ${s.clientName}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey)),
                            if (s.timeRangeDisplay.isNotEmpty)
                              Text(s.timeRangeDisplay, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.indigo)),
                            if (s.notes.isNotEmpty)
                              Text('ملاحظات: ${s.notes}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.blueGrey)),
                          ],
                        ),
                        trailing: Text(
                          '+${s.nursePrice.toStringAsFixed(0)} ج',
                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Advances & Payouts Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments_outlined, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'سجل السلف والدفعات المستلمة',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      '${transactions.length} عمليات مسجلة',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (transactions.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('لا توجد سلف أو دفعات مسجلة لك حتى الآن', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final t = transactions[idx];
                      final isAdvance = t.type == 'advance';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isAdvance ? Colors.amber.shade50 : Colors.blue.shade50,
                          child: Icon(
                            isAdvance ? Icons.handshake_outlined : Icons.check_circle_outline,
                            size: 18,
                            color: isAdvance ? Colors.amber.shade800 : Colors.blue,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              t.typeArabic,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isAdvance ? Colors.amber.shade900 : Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('yyyy/MM/dd').format(t.date),
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'طريقة الصرف: ${t.channelArabic}${t.notes.isNotEmpty ? " • " + t.notes : ""}',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.blueGrey),
                        ),
                        trailing: Text(
                          '-${t.amount.toStringAsFixed(0)} ج',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isAdvance ? Colors.amber.shade800 : Colors.blue,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 3: Nurse's Profile & Experience
  Widget _buildNurseProfileTab(CaregiverModel? caregiver, List<ClientModel> allClients) {
    if (caregiver == null) {
      return const Center(
        child: Text('بيانات الملف غير متوفرة', style: TextStyle(fontFamily: 'Cairo')),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  child: const Icon(Icons.person, color: AppTheme.primary, size: 40),
                ),
                const SizedBox(height: 10),
                Text(
                  caregiver.name,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  caregiver.qualification.isNotEmpty ? caregiver.qualification : 'طاقم تمريض ورعاية صحية',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('كود: ${caregiver.code}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(5, (starIdx) {
                        return Icon(
                          starIdx < caregiver.rating.floor() ? Icons.star : Icons.star_border,
                          color: Colors.amber.shade700,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Details List
                _infoRow(icon: Icons.phone, label: 'رقم التليفون', val: caregiver.phone),
                const SizedBox(height: 12),
                _infoRow(icon: Icons.badge, label: 'الرقم القومي', val: caregiver.nationalId.isNotEmpty ? caregiver.nationalId : 'غير مسجل'),
                const SizedBox(height: 12),
                _infoRow(icon: Icons.location_on, label: 'العنوان ومكان السكن', val: '${caregiver.residenceArea} - ${caregiver.address}'),
                const SizedBox(height: 12),
                _infoRow(icon: Icons.schedule, label: 'نظام العمل المفضل', val: caregiver.shiftPreferenceArabic),
                const SizedBox(height: 12),
                _infoRow(
                  icon: Icons.fitness_center,
                  label: 'الوزن والطول',
                  val: '${caregiver.weight != null ? caregiver.weight!.toStringAsFixed(0) + " كجم" : "غير مسجل"} • ${caregiver.height != null ? caregiver.height!.toStringAsFixed(0) + " سم" : ""}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Past Cases History (NO CLIENT FINANCIAL DATA!)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_edu_outlined, color: Colors.indigo, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'سجل الحالات التي عملت معها بالشركة',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (caregiver.pastClients.isEmpty && allClients.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text('لا يوجد سجل حالات سابقة مسجلة', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                    ),
                  ),
                ] else ...[
                  ...caregiver.pastClients.map((clientName) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle_outline, color: Colors.teal, size: 18),
                        title: Text(clientName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
                      )),
                  ...allClients.map((c) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_pin, color: Colors.blue, size: 18),
                        title: Text('الحالة: ${c.name}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'تاريخ البدء: ${c.startDate != null ? DateFormat('yyyy/MM/dd').format(c.startDate!) : "محدد"} • الحالة: ${_formatClientStatus(c.status)}',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String val,
    Widget? actionWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade600)),
              Text(
                val,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
        if (actionWidget != null) actionWidget,
      ],
    );
  }

  String _formatServiceType(String type) {
    switch (type) {
      case 'hours24':
        return 'إقامة 24 ساعة';
      case 'hours12':
        return 'وردية 12 ساعة';
      case 'hours10':
        return 'وردية 10 ساعات';
      case 'hours8':
        return 'وردية 8 ساعات';
      case 'custom':
        return 'ساعات مخصصة';
      default:
        return 'وردية 12 ساعة';
    }
  }

  String _formatClientStatus(String status) {
    switch (status) {
      case 'active':
        return 'نشطة حالياً';
      case 'ready_to_start':
        return 'جاهزة للبدء';
      case 'completed':
        return 'مكتملة';
      case 'stopped_by_accountant':
        return 'متوقفة';
      default:
        return status;
    }
  }
}
