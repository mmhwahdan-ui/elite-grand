import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_edit_client_dialog.dart';
import '../widgets/pricing_dialog.dart';
import '../widgets/start_service_dialog.dart';
import '../widgets/extend_service_dialog.dart';
import '../widgets/stop_service_dialog.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/add_service_day_dialog.dart';
import 'client_detail_screen.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Filter by tab
    List<ClientModel> filtered = provider.clients;
    if (_selectedFilter == 'active') {
      filtered = filtered.where((c) => c.status == 'active').toList();
    } else if (_selectedFilter == 'pending_pricing') {
      filtered = filtered.where((c) => c.status == 'pending_pricing').toList();
    } else if (_selectedFilter == 'ready_to_start') {
      filtered = filtered.where((c) => c.status == 'ready_to_start').toList();
    } else if (_selectedFilter == 'stopped') {
      filtered = filtered.where((c) => c.status == 'stopped_by_accountant').toList();
    } else if (_selectedFilter == 'completed') {
      filtered = filtered.where((c) => c.status == 'completed').toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.address.toLowerCase().contains(q) ||
            c.healthCondition.toLowerCase().contains(q);
      }).toList();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            // Search and filter area
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'بحث باسم العميل، الهاتف، العنوان، أو الحالة...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Filter Chips Carousel
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'الكل (${provider.clients.length})'),
                        _buildFilterChip('active', 'قيد الخدمة (${provider.activeClients.length})', color: AppTheme.blueActive),
                        _buildFilterChip('pending_pricing', 'بانتظار التسعير (${provider.pendingPricingClients.length})', color: AppTheme.amberPending),
                        _buildFilterChip('ready_to_start', 'جاهز للبدء (${provider.readyToStartClients.length})', color: AppTheme.accent),
                        _buildFilterChip('stopped', 'متوقفة لتعثر (${provider.stoppedClients.length})', color: AppTheme.redDebt),
                        _buildFilterChip('completed', 'منتهية (${provider.completedClients.length})', color: AppTheme.grayCompleted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Clients List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد حالات مسجلة حالياً',
                            style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, index) {
                        final client = filtered[index];
                        return _buildClientCard(context, provider, client);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: provider.canAddClient
            ? FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddEditClientDialog(),
                  );
                },
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('تسجيل حالة جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? color}) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Cairo',
          color: isSelected ? Colors.white : Colors.grey.shade800,
        ),
        backgroundColor: Colors.grey.shade100,
        selectedColor: color ?? AppTheme.primary,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedFilter = key),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, AppProvider provider, ClientModel client) {
    final balance = provider.getClientBalance(client);
    final servedDays = provider.getClientServedDaysCount(client);
    final accruedCost = provider.getClientAccruedCost(client);
    final companyProfit = provider.getClientCompanyProfit(client);
    final clientDays = provider.getClientServiceDays(client.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientDetailScreen(clientId: client.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name & Status & Delete Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primary.withOpacity(0.08),
                    child: const Icon(Icons.person_outline, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              client.phone,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                        // Existing client badge with opening balance
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
                                fontSize: 10,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusBadge(client.status, client.statusArabic),
                      if (provider.canEditAnyData) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          tooltip: 'حذف الحالة نهائياً',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('تأكيد حذف الحالة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                content: Text(
                                  'هل أنت متأكد من حذف حالة العميل "${client.name}" نهائياً من السيستم؟\nسيتم حذفها فوراً ولن تعود للظهور على أي جهاز.',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                                  ),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم حذف حالة "${client.name}" نهائياً وتحديث السحابة', style: const TextStyle(fontFamily: 'Cairo')),
                                    backgroundColor: Colors.red.shade700,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Address & Condition
              Text(
                '📍 ${client.address}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontFamily: 'Cairo'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '🩺 الحالة: ${client.healthCondition}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Termination alert box if stopped
              if (client.status == 'stopped_by_accountant' && client.terminationReason != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppTheme.redDebt),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'سبب الإيقاف: ${client.terminationReason}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.redDebt, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 18),

              // Service details, Nurse Rate, and Financial Balance row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Service & Nurse rate info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${client.serviceTypeArabic} | سعر العميل: ${client.dailyPrice > 0 ? '${client.dailyPrice.toStringAsFixed(0)} ج.م/يوم' : 'بانتظار التسعير'}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade900, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                        if (client.nurseDailyPrice > 0)
                          Text(
                            'يومية الممرض: ${client.nurseDailyPrice.toStringAsFixed(0)} ج.م | مكسب الشركة: ${client.dailyCompanyProfit.toStringAsFixed(0)} ج.م/يوم',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                          ),
                        if (client.startDate != null || clientDays.isNotEmpty)
                          Text(
                            client.isOpenEnded
                                ? 'المدة: مفتوحة (منقضي $servedDays يوم) | إيراد الخدمة: ${accruedCost.toStringAsFixed(0)} ج.م ${client.nurseDailyPrice > 0 || clientDays.isNotEmpty ? '| أرباح: ${companyProfit.toStringAsFixed(0)} ج.م' : ''}'
                                : (client.endDate != null
                                    ? 'المدة: ${client.totalContractDays ?? "-"} يوم (منقضي $servedDays | باقي ${client.remainingContractDays ?? 0}) | إيراد: ${accruedCost.toStringAsFixed(0)} ج.م'
                                    : 'المدة: $servedDays يوم | إيراد الخدمة: ${accruedCost.toStringAsFixed(0)} ج.م'),
                            style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontFamily: 'Cairo'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Financial balance badge
                  _buildBalanceBadge(balance),
                ],
              ),
              const SizedBox(height: 10),

              // Direct Action Buttons on Card
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  // Log Shift / Service Days
                  if (client.status == 'active' || client.status == 'ready_to_start')
                    ActionChip(
                      avatar: const Icon(Icons.event_available, size: 16, color: Colors.teal),
                      label: const Text('تسجيل ورديات / أيام', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.teal.shade50,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddServiceDayDialog(client: client),
                        );
                      },
                    ),
                  // Start Service (Shimaa & Wahdan)
                  if (client.startDate == null && provider.canStartService)
                    ActionChip(
                      avatar: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                      label: const Text('بدء الخدمة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white)),
                      backgroundColor: AppTheme.accent,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => StartServiceDialog(client: client),
                        );
                      },
                    ),

                  // Pricing & Nurse Rate (Zezo & Wahdan)
                  if (provider.canSetPrice)
                    ActionChip(
                      avatar: const Icon(Icons.attach_money, size: 16, color: AppTheme.primary),
                      label: Text(
                        client.dailyPrice > 0 ? 'تعديل السعر واليومية' : 'تحديد السعر ويومية الممرض',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: AppTheme.primary.withOpacity(0.08),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => PricingDialog(client: client),
                        );
                      },
                    ),

                  // Record Payment (Zezo & Wahdan)
                  if (provider.canRecordPayment)
                    ActionChip(
                      avatar: const Icon(Icons.receipt_outlined, size: 16, color: AppTheme.accent),
                      label: const Text('تحصيل دفعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.accent)),
                      backgroundColor: AppTheme.accent.withOpacity(0.1),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => PaymentDialog(preSelectedClient: client),
                        );
                      },
                    ),

                  // Extend or Open Duration for active clients
                  if (client.status == 'active' && (provider.canStartService || provider.canEditClient || provider.isManager))
                    ActionChip(
                      avatar: const Icon(Icons.update, size: 16, color: Colors.indigo),
                      label: const Text('تمديد / فتح المدة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.indigo.withValues(alpha: 0.08),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ExtendServiceDialog(client: client),
                        );
                      },
                    ),

                  // Stop Service due to default (Zezo & Wahdan)
                  if (client.status == 'active' && provider.canEndService)
                    ActionChip(
                      avatar: const Icon(Icons.stop_circle_outlined, size: 16, color: AppTheme.redDebt),
                      label: const Text('إنهاء الخدمة لتعثر', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.redDebt)),
                      backgroundColor: AppTheme.redDebt.withOpacity(0.1),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => StopServiceDialog(client: client),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, String arabic) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        arabic,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text, fontFamily: 'Cairo'),
      ),
    );
  }

  Widget _buildBalanceBadge(double balance) {
    if (balance < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Text(
          'مستحق على العميل: ${balance.abs().toStringAsFixed(0)} ج.م',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.redDebt, fontFamily: 'Cairo'),
        ),
      );
    } else if (balance > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Text(
          'مستحق للعميل: ${balance.toStringAsFixed(0)} ج.م',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.greenCredit, fontFamily: 'Cairo'),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'خالص',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, fontFamily: 'Cairo'),
        ),
      );
    }
  }
}
