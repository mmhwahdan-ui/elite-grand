import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../services/sms_launcher_stub.dart'
    if (dart.library.js_interop) '../services/sms_launcher_web.dart';
import '../models/case_offer_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_edit_case_offer_dialog.dart';
import '../widgets/finalize_case_dialog.dart';
import 'team_chat_screen.dart';

class CaseOffersScreen extends StatefulWidget {
  const CaseOffersScreen({super.key});

  @override
  State<CaseOffersScreen> createState() => _CaseOffersScreenState();
}

class _CaseOffersScreenState extends State<CaseOffersScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'open', 'assigned', 'closed'

  void _makePhoneCall(String phone) {
    launchPhoneCallUri(phone);
  }

  void _showAddEditDialog([CaseOfferModel? offer]) {
    showDialog(
      context: context,
      builder: (_) => AddEditCaseOfferDialog(offer: offer),
    );
  }

  void _showFinalizeDialog(CaseOfferModel offer) {
    showDialog(
      context: context,
      builder: (_) => FinalizeCaseDialog(offer: offer),
    );
  }

  void _confirmDelete(BuildContext context, CaseOfferModel offer) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف الحالة من الجروب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: Text('هل أنت متأكد من حذف حالة: ${offer.title} (${offer.code})؟', style: const TextStyle(fontFamily: 'Cairo')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await context.read<AppProvider>().deleteCaseOffer(offer.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الحالة بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allOffers = provider.caseOffers;
    final currentUser = provider.currentUser;

    final isManager = currentUser?.roleType == 'manager' || currentUser?.username == 'wahdan';
    final isShimaa = currentUser?.roleType == 'followup' || currentUser?.username == 'shimaa';
    final isZezo = currentUser?.roleType == 'accountant' || currentUser?.username == 'zezo';

    // Filter
    final filtered = allOffers.where((o) {
      if (_filterStatus == 'open' && !o.isOpen) return false;
      if (_filterStatus == 'assigned' && !o.isAssigned) return false;
      if (_filterStatus == 'closed' && o.status != 'closed') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = o.title.toLowerCase().contains(q) ||
            o.code.toLowerCase().contains(q) ||
            o.area.toLowerCase().contains(q) ||
            o.city.toLowerCase().contains(q) ||
            o.patientDescription.toLowerCase().contains(q) ||
            o.clientName.toLowerCase().contains(q) ||
            o.clientPhone.contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    final openCount = allOffers.where((o) => o.isOpen).length;
    final assignedCount = allOffers.where((o) => o.isAssigned).length;
    final totalApplicants = allOffers.fold<int>(0, (sum, o) => sum + o.applicants.length);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          titleSpacing: 10,
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppTheme.accentBright, size: 24),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('جروب الحالات والفرص الجديدة 📢', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('عرض الحالات ومتابعة تقديم التمريض وإتمام زيزو', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          actions: [
            // Chat shortcut
            IconButton(
              icon: const Icon(Icons.chat_outlined, color: Colors.white),
              tooltip: 'فتح شات الشركة',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamChatScreen()));
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: (isShimaa || isManager)
            ? FloatingActionButton.extended(
                onPressed: () => _showAddEditDialog(),
                backgroundColor: AppTheme.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('نشر حالة جديدة 📢', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
              )
            : null,
        body: Column(
          children: [
            // Top KPI Summary Cards
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildKpiCard('حالات متاحة للتقديم', '$openCount', Colors.teal, Icons.campaign),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard('طلبات متقدمي التمريض', '$totalApplicants', Colors.blue, Icons.people),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard('تم تسكينها بنجاح', '$assignedCount', Colors.green, Icons.check_circle_outline),
                  ),
                ],
              ),
            ),

            // Search and Status Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  // Search
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث بكود الحالة، المنطقة، الوصف، اسم العميل...',
                      hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                  const SizedBox(height: 8),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('الكل (${allOffers.length})', 'all'),
                        const SizedBox(width: 6),
                        _buildFilterChip('متاح للتقديم ($openCount)', 'open'),
                        const SizedBox(width: 6),
                        _buildFilterChip('تم التسكين ($assignedCount)', 'assigned'),
                        const SizedBox(width: 6),
                        _buildFilterChip('مغلق', 'closed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List of Cases
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا توجد حالات مسجلة حالياً تطابق البحث', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 12),
                          if (isShimaa || isManager)
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('نشر أول حالة للتمريض الآن 📢', style: TextStyle(fontFamily: 'Cairo')),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final offer = filtered[idx];
                        return _buildCaseCard(context, offer, isManager, isShimaa, isZezo);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade700), maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppTheme.primary.withOpacity(0.15),
      labelStyle: TextStyle(color: isSelected ? AppTheme.primary : Colors.black87),
      onSelected: (_) => setState(() => _filterStatus = value),
    );
  }

  Widget _buildCaseCard(BuildContext context, CaseOfferModel offer, bool isManager, bool isShimaa, bool isZezo) {
    Color statusColor;
    if (offer.isAssigned) {
      statusColor = Colors.green;
    } else if (offer.isOpen) {
      statusColor = Colors.teal;
    } else {
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Code, Title, Status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    offer.code,
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    offer.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    offer.statusArabic,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Location, Shift & Nurse Price
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.place, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${offer.city} - ${offer.area}',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      offer.shiftTypeArabic,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.blue.shade800),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.teal.shade300)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments, size: 14, color: Colors.teal),
                        const SizedBox(width: 4),
                        Text(
                          '${offer.nurseDailyPrice.toStringAsFixed(0)} ج.م',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Patient Medical Description
            Text(
              '📋 تفاصيل الحالة: ${offer.patientDescription}',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade800),
            ),
            if (offer.requirements.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '⚡ المتطلبات: ${offer.requirements}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.orange),
              ),
            ],
            const SizedBox(height: 10),

            // Management Confidential Box (Client phone, Zezo direct call, client price)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بيانات العميل للإدارة: ${offer.clientName.isNotEmpty ? offer.clientName : "لم يحدد"} (${offer.clientPhone.isNotEmpty ? offer.clientPhone : "بدون هاتف"})',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                        ),
                        if (offer.clientDailyPrice > 0)
                          Text(
                            'سعر العميل: ${offer.clientDailyPrice.toStringAsFixed(0)} ج | هامش الربح اليومي المتوقع: ${(offer.clientDailyPrice - offer.nurseDailyPrice).toStringAsFixed(0)} ج',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.brown.shade700),
                          ),
                      ],
                    ),
                  ),
                  if (offer.clientPhone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green, size: 20),
                      tooltip: 'اتصال هاتفي بالعميل',
                      onPressed: () => _makePhoneCall(offer.clientPhone),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Applicants Section
            if (offer.applicants.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 16, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text(
                          'المتقدمين من طاقم التمريض (${offer.applicants.length}):',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: offer.applicants.map((app) {
                        return ActionChip(
                          avatar: const Icon(Icons.person, size: 14, color: Colors.teal),
                          label: Text('${app.caregiverName} ${app.caregiverCode.isNotEmpty ? "(${app.caregiverCode})" : ""}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.teal.shade200),
                          tooltip: 'فتح شات خاص مع الممرض',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeamChatScreen(initialRecipientId: app.nurseUserId),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Assigned Badge if assigned
            if (offer.isAssigned && offer.assignedCaregiverName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'تم تسكين الحالة للممرض: ${offer.assignedCaregiverName} بنجاح ✅',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Footer Actions
            Row(
              children: [
                Text(
                  'نشرت بواسطة: ${offer.postedByUserName} • ${DateFormat('yyyy/MM/dd').format(offer.createdAt)}',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade500),
                ),
                const Spacer(),

                // Finalize Button (for Zezo, Wahdan, Shimaa)
                if (!offer.isAssigned)
                  ElevatedButton.icon(
                    onPressed: () => _showFinalizeDialog(offer),
                    icon: const Icon(Icons.phone_in_talk, size: 16),
                    label: const Text('إتمام الحالة وتسكين الممرض (زيزو) 📞', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                if (isManager || isShimaa) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                    tooltip: 'تعديل',
                    onPressed: () => _showAddEditDialog(offer),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'حذف',
                    onPressed: () => _confirmDelete(context, offer),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
