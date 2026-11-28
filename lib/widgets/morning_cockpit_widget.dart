import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/app_provider.dart';
import '../models/client_model.dart';
import '../models/service_day_model.dart';
import '../theme/app_theme.dart';
import '../widgets/daily_reconciliation_dialog.dart';

class MorningCockpitWidget extends StatefulWidget {
  const MorningCockpitWidget({super.key});

  @override
  State<MorningCockpitWidget> createState() => _MorningCockpitWidgetState();
}

class _MorningCockpitWidgetState extends State<MorningCockpitWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeClients = provider.clients.where((c) => c.status == 'active').toList();

    final now = DateTime.now();
    final todayLoggedDays = provider.serviceDays.where((d) {
      final dl = d.date.toLocal();
      return dl.year == now.year && dl.month == now.month && dl.day == now.day;
    }).toList();

    final loggedClientIds = todayLoggedDays.map((d) => d.clientId).toSet();
    final confirmedCount = todayLoggedDays.length;
    final pendingClients = activeClients.where((c) => !loggedClientIds.contains(c.id)).toList();

    double totalDebtsOwed = 0.0;
    for (final c in provider.clients) {
      final b = provider.getClientBalance(c);
      if (b < 0) totalDebtsOwed += b.abs();
    }

    final todayFormatted = DateFormat('EEEE d MMMM yyyy', 'ar').format(now);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFF0F766E), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'الموقف الصباحي والتشغيلي اليومي',
                              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: pendingClients.isEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                pendingClients.isEmpty ? 'جميع الورديات مؤكدة ✓' : '${pendingClients.length} ورديات بانتظار التأكيد',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: pendingClients.isEmpty ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          todayFormatted,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Summary KPI Pills Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    label: 'حالات اليوم',
                    value: '${activeClients.length}',
                    color: const Color(0xFF2563EB),
                    icon: Icons.personal_injury_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricItem(
                    label: 'حضور مؤكد',
                    value: '$confirmedCount',
                    color: const Color(0xFF16A34A),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricItem(
                    label: 'مديونيات للتحصيل',
                    value: '${totalDebtsOwed.toStringAsFixed(0)} ج',
                    color: const Color(0xFFD97706),
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricItem(
                    label: 'الخزينة (كاش)',
                    value: '${provider.currentCashBalance.toStringAsFixed(0)} ج',
                    color: const Color(0xFF0F766E),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
          ),

          // Expanded Details & Bulk Action
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fast Daily Reconciliation Button
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const DailyReconciliationDialog(),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2540),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.balance_rounded, color: Colors.amberAccent, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'مطابقة وتقفيل الخزينة اليومي (مطابقة النقدية والدرج مع السيستم)',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 12),
                        ],
                      ),
                    ),
                  ),

                  // Pending shift confirmation section
                  if (pendingClients.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.pending_actions_rounded, size: 15, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Text(
                          'حالات منتظمة لم تُسجل ورديتها اليوم (${pendingClients.length}):',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...pendingClients.take(4).map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Text(c.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Text(
                            '• التمريض: ${(c.nurseAssigned?.isNotEmpty == true) ? c.nurseAssigned : "غير محدد"}',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                          const Spacer(),
                          Text(
                            '${c.dailyPrice.toStringAsFixed(0)} ج',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                          ),
                        ],
                      ),
                    )),
                    if (pendingClients.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '... وعدد ${pendingClients.length - 4} حالات أخرى',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Color(0xFF64748B)),
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Quick Bulk Confirm Button
                    ElevatedButton.icon(
                      onPressed: () => _confirmBulkShifts(context, provider, pendingClients),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: Text(
                        'تأكيد وتسجيل ورديات اليوم لجميع الحالات (${pendingClients.length}) بضغطة واحدة',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ممتاز! تم تسجيل وتأكيد ورديات اليوم لجميع الحالات النشطة بنجاح.',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 9.5, color: color, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _confirmBulkShifts(BuildContext context, AppProvider provider, List<ClientModel> pendingClients) {
    final now = DateTime.now();
    final todayFormatted = DateFormat('yyyy/MM/dd').format(now);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.done_all_rounded, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Expanded(
                child: Text('تأكيد ورديات اليوم للجميع', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من تسجيل وتأكيد وردية اليوم ($todayFormatted) لعدد (${pendingClients.length}) حالات؟',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pendingClients.length,
                  separatorBuilder: (_, __) => const Divider(height: 6),
                  itemBuilder: (_, idx) {
                    final c = pendingClients[idx];
                    return Text(
                      '${idx + 1}. ${c.name} - تمريض: ${(c.nurseAssigned?.isNotEmpty == true) ? c.nurseAssigned : "مقدم خدمة"} (${c.dailyPrice.toStringAsFixed(0)} ج)',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'سيتم احتساب الإيراد ومستحق التمريض وتحديث الحسابات فوراً.',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                int count = 0;
                for (final client in pendingClients) {
                  final nurseName = (client.nurseAssigned?.isNotEmpty == true) ? client.nurseAssigned! : 'مقدم خدمة';
                  await provider.recordServiceDay(
                    clientId: client.id,
                    date: DateTime(now.year, now.month, now.day),
                    clientPrice: client.dailyPrice,
                    nursePrice: client.nurseDailyPrice,
                    nurseName: nurseName,
                    notes: 'تسجيل وتأكيد جماعي من لوحة الموقف الصباحي',
                    shiftType: client.serviceType,
                  );
                  count++;
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تسجيل وتأكيد $count ورديات لليوم بنجاح ✓', style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: const Color(0xFF0D9488),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد وتسجيل الكل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
