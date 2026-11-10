import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_edit_client_dialog.dart';
import '../widgets/pricing_dialog.dart';
import '../widgets/start_service_dialog.dart';
import '../widgets/extend_service_dialog.dart';
import '../widgets/stop_service_dialog.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/add_service_day_dialog.dart';
import '../widgets/edit_service_day_dialog.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd');

    final clientIndex = provider.clients.indexWhere((c) => c.id == clientId);
    if (clientIndex == -1) {
      return const Scaffold(
        body: Center(
          child: Text('الحالة غير موجودة أو تم حذفها', style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
    }

    final client = provider.clients[clientIndex];
    final clientPayments = provider.payments.where((p) => p.clientId == client.id).toList();
    final clientDays = provider.getClientServiceDays(client.id);
    final servedDaysCount = provider.getClientServedDaysCount(client);
    final totalAccruedCost = provider.getClientAccruedCost(client);
    final totalNurseCost = provider.getClientNurseCost(client);
    final companyProfit = provider.getClientCompanyProfit(client);
    final nurseDaysMap = provider.getNurseDaysBreakdownForClient(client.id);
    final nurseCostMap = provider.getNurseCostBreakdownForClient(client.id);
    final totalPaid = provider.getClientTotalPaid(client.id);
    final balance = provider.getClientBalance(client);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          actions: [
            if (provider.canEditClient || provider.canEditAnyData)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'تعديل البيانات',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddEditClientDialog(client: client),
                  );
                },
              ),
            if (provider.canEditAnyData)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'حذف العميل نهائياً (صلاحية المدير)',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تأكيد الحذف النهائي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      content: Text(
                        'هل أنت متأكد من حذف ملف "${client.name}" وجميع سجلاته وحساباته نهائياً من السيستم؟',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('حذف نهائي', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await provider.deleteClient(client.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم حذف ملف "${client.name}" نهائياً من السيستم', style: const TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status & Termination banner if stopped
              if (client.status == 'stopped_by_accountant')
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.redDebt.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.redDebt, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تم إيقاف الخدمة بقرار مدير الحسابات',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.redDebt, fontFamily: 'Cairo', fontSize: 13),
                            ),
                            if (client.terminationReason != null)
                              Text(
                                'السبب: ${client.terminationReason}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.redDebt, fontFamily: 'Cairo'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // 1. Client Profile Card
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            child: const Icon(Icons.person, color: AppTheme.primary, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: AppTheme.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      client.phone,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accent),
                                    ),
                                  ],
                                ),
                                if (client.isExistingClient) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: client.openingBalance >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: client.openingBalance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                    ),
                                    child: Text(
                                      client.openingBalance >= 0
                                          ? 'عميل حالي | رصيد دائن سابق: +${client.openingBalance.toStringAsFixed(0)} ج.م (مستحق للعميل)'
                                          : 'عميل حالي | مديونية سابقة: ${client.openingBalance.toStringAsFixed(0)} ج.م (مستحق على العميل)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                        color: client.openingBalance >= 0 ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _buildStatusChip(client.status, client.statusArabic),
                        ],
                      ),
                      const Divider(height: 24),
                      // Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'العنوان: ${client.address}',
                              style: const TextStyle(fontSize: 13, fontFamily: 'Cairo', height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Health Condition
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.healing_outlined, size: 20, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'الحالة الصحية: ${client.healthCondition}',
                              style: const TextStyle(fontSize: 13, fontFamily: 'Cairo', height: 1.4, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      if (client.nurseAssigned != null && client.nurseAssigned!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 20, color: AppTheme.primaryLight),
                            const SizedBox(width: 8),
                            Text(
                              'الممرض المسند: ${client.nurseAssigned}',
                              style: const TextStyle(fontSize: 13, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      if (client.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ملاحظات: ${client.notes}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Financial & Accounting Ledger Card
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
                          const Text(
                            'الحسابات ومستحقات الخدمة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                          if (provider.canSetPrice)
                            TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PricingDialog(client: client),
                                );
                              },
                              icon: const Icon(Icons.price_change_outlined, size: 18),
                              label: const Text('تعديل السعر واليومية', style: TextStyle(fontFamily: 'Cairo')),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Service terms row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailTile(
                              'نوع الوردية',
                              client.serviceTypeArabic,
                              Icons.access_time,
                              AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDetailTile(
                              'سعر العميل',
                              client.dailyPrice > 0 ? '${client.dailyPrice.toStringAsFixed(0)} ج.م' : 'غير مسعر',
                              Icons.monetization_on_outlined,
                              AppTheme.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDetailTile(
                              'يومية الممرض',
                              client.nurseDailyPrice > 0 ? '${client.nurseDailyPrice.toStringAsFixed(0)} ج.م' : 'غير مسعر',
                              Icons.medical_services_outlined,
                              Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailTile(
                              'الأيام المنقضية',
                              clientDays.isNotEmpty ? '$servedDaysCount يوم (شفتات مسجلة)' : '$servedDaysCount يوم',
                              Icons.event_available,
                              AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDetailTile(
                              'تاريخ البدء',
                              client.startDate != null ? dateFormat.format(client.startDate!) : 'لم تبدأ بعد',
                              Icons.calendar_month,
                              Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDetailTile(
                              'تاريخ الإنهاء',
                              client.endDate != null ? dateFormat.format(client.endDate!) : 'مدة مفتوحة (مستمرة)',
                              Icons.event_busy,
                              client.endDate != null ? AppTheme.redDebt : Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      if (client.status == 'active' && client.startDate != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: client.isOpenEnded ? Colors.teal.shade50 : Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: client.isOpenEnded ? Colors.teal.shade200 : Colors.indigo.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                client.isOpenEnded ? Icons.all_inclusive : Icons.date_range,
                                size: 18,
                                color: client.isOpenEnded ? Colors.teal : Colors.indigo,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  client.isOpenEnded
                                      ? 'مدة الخدمة مفتوحة ومستمرة (منقضي $servedDaysCount يوم حتى الآن)'
                                      : 'التعاقد: ${client.totalContractDays ?? "-"} يوم (منقضي $servedDaysCount يوم | متبقي ${client.remainingContractDays ?? 0} يوم)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    color: client.isOpenEnded ? Colors.teal.shade900 : Colors.indigo.shade900,
                                  ),
                                ),
                              ),
                              if (provider.canStartService || provider.canEditClient || provider.isManager)
                                TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => ExtendServiceDialog(client: client),
                                    );
                                  },
                                  icon: const Icon(Icons.update, size: 16, color: Colors.indigo),
                                  label: const Text(
                                    'تمديد / فتح المدة',
                                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(height: 24),

                      // Billing summary box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            if (client.isExistingClient && client.openingBalance != 0) ...[
                              _buildAccountingRow(
                                client.openingBalance >= 0
                                    ? 'الرصيد الافتتاحي السابق (رصيد دائن مستحق للعميل):'
                                    : 'الرصيد الافتتاحي السابق (مديونية سابقة مستحقة على العميل):',
                                '${client.openingBalance >= 0 ? '+' : ''}${client.openingBalance.toStringAsFixed(0)} ج.م',
                                isBold: true,
                                color: client.openingBalance >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                              const SizedBox(height: 8),
                            ],
                            _buildAccountingRow(
                              clientDays.isNotEmpty
                                  ? 'إجمالي قيمة الخدمة المستحقة ($servedDaysCount يوم شفتات مسجلة):'
                                  : 'إجمالي قيمة الخدمة المستحقة ($servedDaysCount يوم × ${client.dailyPrice.toStringAsFixed(0)} ج.م):',
                              '${totalAccruedCost.toStringAsFixed(0)} ج.م',
                              isBold: false,
                            ),
                            const SizedBox(height: 8),
                            _buildAccountingRow(
                              'إجمالي المدفوعات والتحصيلات المستلمة من العميل:',
                              '${totalPaid.toStringAsFixed(0)} ج.م',
                              isBold: false,
                              color: AppTheme.accent,
                            ),
                            const Divider(height: 18),
                            // Net Balance
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  balance < 0
                                      ? '⚠️ مستحقات الشركة عند العميل (مديونية):'
                                      : (balance > 0 ? '✅ مستحقات العميل لدى الشركة (رصيد دائن):' : 'حالة الحساب:'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: balance < 0 ? AppTheme.redDebt : (balance > 0 ? AppTheme.greenCredit : Colors.grey),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                Text(
                                  balance < 0
                                      ? '${balance.abs().toStringAsFixed(0)} ج.م'
                                      : (balance > 0 ? '${balance.toStringAsFixed(0)} ج.م' : 'خالص تماماً'),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: balance < 0 ? AppTheme.redDebt : (balance > 0 ? AppTheme.greenCredit : Colors.grey),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Company Profit from Price Difference Box
                      if (client.dailyPrice > 0 || client.nurseDailyPrice > 0 || clientDays.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '💎 تصفية مكسب الشركة من فرق السعر:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857), fontFamily: 'Cairo'),
                                  ),
                                  Text(
                                    '${client.dailyCompanyProfit.toStringAsFixed(0)} ج.م / يوم',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF047857), fontFamily: 'Cairo'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildAccountingRow(
                                'إجمالي تعاقد العميل المنقضي:',
                                '${totalAccruedCost.toStringAsFixed(0)} ج.م',
                              ),
                              const SizedBox(height: 4),
                              _buildAccountingRow(
                                clientDays.isNotEmpty
                                    ? 'إجمالي مستحقات التمريض المنقضية (شفتات مسجلة):'
                                    : 'إجمالي مستحقات التمريض المنقضية ($servedDaysCount يوم × ${client.nurseDailyPrice.toStringAsFixed(0)} ج.م):',
                                '${totalNurseCost.toStringAsFixed(0)} ج.م',
                              ),
                              const Divider(height: 12),
                              _buildAccountingRow(
                                'إجمالي أرباح ومكسب الشركة من الحالة حتى الآن:',
                                '${companyProfit.toStringAsFixed(0)} ج.م',
                                isBold: true,
                                color: const Color(0xFF047857),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- سجل أيام الخدمة والشفتات (أيام العميل والتمريض المتغيرة) ---
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
                          Row(
                            children: [
                              const Icon(Icons.event_note, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'سجل أيام الخدمة والشفتات ($servedDaysCount يوم)',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AddServiceDayDialog(client: client),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('تسجيل ورديات / أيام', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nurse Breakdown Badges
                      if (nurseDaysMap.isNotEmpty) ...[
                        const Text(
                          'توزيع أيام ومستحقات أطقم التمريض:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: nurseDaysMap.entries.map((entry) {
                            final nurseName = entry.key;
                            final days = entry.value;
                            final dues = nurseCostMap[nurseName] ?? 0.0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.badge, size: 16, color: Colors.teal),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$nurseName: $days يوم (${dues.toStringAsFixed(0)} ج.م)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Days List or Empty info
                      if (clientDays.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'يتم احتساب أيام الخدمة لهذه الحالة تلقائياً وفق التقويم (${client.servedDays} يوم).\nإذا كان العميل يحتاج أياماً متغيرة (مثل 4 أيام في أسبوع و 5 أيام في أسبوع آخر) أو تمريض متغير، اضغط على زر "تسجيل ورديات / أيام" أعلاه لتحديد الأيام بدقة.',
                                  style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF78350F), fontFamily: 'Cairo'),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // List of logged service days
                        ...clientDays.map((day) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.event_available, color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            dateFormat.format(day.date),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.blue.shade200),
                                            ),
                                            child: Text(
                                              day.shiftTypeArabic,
                                              style: TextStyle(fontSize: 10, color: Colors.blue.shade900, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.teal.shade200),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.badge, size: 10, color: Colors.teal),
                                                const SizedBox(width: 3),
                                                Text(
                                                  day.nurseName,
                                                  style: const TextStyle(fontSize: 10, color: Colors.teal, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (day.timeRangeDisplay.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.purple.shade200),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.access_time_rounded, size: 10, color: Colors.purple),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    day.timeRangeDisplay,
                                                    style: const TextStyle(fontSize: 10, color: Colors.purple, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'سعر العميل: ${day.clientPrice.toStringAsFixed(0)} ج.م',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey, fontFamily: 'Cairo'),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'يومية الممرض: ${day.nursePrice.toStringAsFixed(0)} ج.م',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange, fontFamily: 'Cairo'),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'مكسب اليوم: ${day.companyDayProfit.toStringAsFixed(0)} ج.م',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: day.companyDayProfit >= 0 ? const Color(0xFF047857) : Colors.red,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (day.notes.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'ملاحظة: ${day.notes}',
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'Cairo'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (provider.canEditAnyData || provider.isManager || provider.isAccountant || provider.isFollowup) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                    tooltip: 'تعديل الوردية أو تبديل الممرض',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => EditServiceDayDialog(
                                          serviceDay: day,
                                          client: client,
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    tooltip: 'حذف هذا اليوم',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('تأكيد حذف اليومية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                          content: Text(
                                            'هل تريد حذف سجل وردية يوم ${dateFormat.format(day.date)} الخاصة بالممرض "${day.nurseName}"؟',
                                            style: const TextStyle(fontFamily: 'Cairo'),
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await provider.deleteServiceDay(day.id);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Payment Receipts Ledger
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
                          const Text(
                            'سجل المقبوضات والدفعات المستلمة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                          if (provider.canRecordPayment)
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PaymentDialog(preSelectedClient: client),
                                );
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('تسجيل تحصيل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (clientPayments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'لا توجد دفعات مسجلة لهذا العميل حتى الآن',
                              style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                            ),
                          ),
                        )
                      else
                        ...clientPayments.map((p) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.accent.withOpacity(0.15),
                                    child: const Icon(Icons.check, color: AppTheme.accent, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${p.amount.toStringAsFixed(0)} ج.م',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.blueGrey.shade200),
                                              ),
                                              child: Text(
                                                p.channelShortArabic,
                                                style: TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.blueGrey.shade900, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (p.notes.isNotEmpty)
                                          Text(
                                            p.notes,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                                          ),
                                        Text(
                                          'التاريخ: ${dateFormat.format(p.paymentDate)} | المستلم: ${p.receivedBy}',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (provider.canEditAnyData)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                      onPressed: () => provider.deletePayment(p.id),
                                    ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Action Buttons Footer
              Row(
                children: [
                  // Start Service button (for Shimaa or Wahdan)
                  if (client.startDate == null && provider.canStartService)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => StartServiceDialog(client: client),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('بدء الخدمة الآن', style: TextStyle(fontFamily: 'Cairo')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  // Extend or Open Duration (when client requests extension)
                  if (client.status == 'active' && (provider.canStartService || provider.canEditClient || provider.isManager)) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => ExtendServiceDialog(client: client),
                          );
                        },
                        icon: const Icon(Icons.update),
                        label: const Text('تمديد / فتح المدة', style: TextStyle(fontFamily: 'Cairo')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Stop Service button (for Zezo or Wahdan if client defaults)
                  if (client.status == 'active' && provider.canEndService) ...[
                    if (client.startDate == null && provider.canStartService) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => StopServiceDialog(client: client),
                          );
                        },
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('إنهاء الخدمة لتعثر', style: TextStyle(fontFamily: 'Cairo')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.redDebt,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
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
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo'),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountingRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF475569),
              fontFamily: 'Cairo',
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? const Color(0xFF0F172A),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, String arabic) {
    Color bg;
    Color text;

    switch (status) {
      case 'active':
        bg = const Color(0xFFE0F2FE);
        text = const Color(0xFF0369A1);
        break;
      case 'stopped_by_accountant':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFB91C1C);
        break;
      case 'pending_pricing':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        break;
      case 'ready_to_start':
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        arabic,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text, fontFamily: 'Cairo'),
      ),
    );
  }
}
