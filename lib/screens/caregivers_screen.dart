import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/caregiver_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_edit_caregiver_dialog.dart';
import '../widgets/caregiver_detail_dialog.dart';
import '../widgets/nurse_account_dialog.dart';
import '../widgets/management_instructions_dialog.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'nurse_portal_screen.dart';

class CaregiversScreen extends StatefulWidget {
  const CaregiversScreen({super.key});

  @override
  State<CaregiversScreen> createState() => _CaregiversScreenState();
}

class _CaregiversScreenState extends State<CaregiversScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, working, available, blocked, 12h, 24h

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final canManage = provider.canManageCaregivers;
    final isZezo = provider.currentUser?.username == 'zezo';
    final caregivers = provider.caregivers;

    // Filter calculations
    final searchQuery = _searchController.text.trim().toLowerCase();

    final filtered = caregivers.where((c) {
      final currentCase = provider.getCaregiverCurrentCase(c.name);
      final isWorking = c.isCurrentlyWorking || currentCase != null;

      // Filter by status/shift
      if (_selectedFilter == 'working' && !isWorking) return false;
      if (_selectedFilter == 'available' && (isWorking || c.isBlocked)) return false;
      if (_selectedFilter == 'blocked' && !c.isBlocked) return false;
      if (_selectedFilter == '12h' && c.shiftPreference != 'hours12' && c.shiftPreference != 'both') return false;
      if (_selectedFilter == '24h' && c.shiftPreference != 'hours24' && c.shiftPreference != 'both') return false;

      // Search query
      if (searchQuery.isNotEmpty) {
        final matchName = c.name.toLowerCase().contains(searchQuery);
        final matchCode = c.code.toLowerCase().contains(searchQuery);
        final matchPhone = c.phone.contains(searchQuery);
        final matchNationalId = c.nationalId.contains(searchQuery);
        final matchArea = c.residenceArea.toLowerCase().contains(searchQuery);
        final matchQual = c.qualification.toLowerCase().contains(searchQuery);
        final matchCase = (currentCase ?? '').toLowerCase().contains(searchQuery);
        return matchName || matchCode || matchPhone || matchNationalId || matchArea || matchQual || matchCase;
      }

      return true;
    }).toList();

    // Stats
    final totalCount = caregivers.length;
    final workingCount = caregivers.where((c) => c.isCurrentlyWorking || provider.getCaregiverCurrentCase(c.name) != null).length;
    final blockedCount = caregivers.where((c) => c.isBlocked).length;
    final availableCount = caregivers.where((c) => !c.isBlocked && !c.isCurrentlyWorking && provider.getCaregiverCurrentCase(c.name) == null).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.badge_rounded, color: AppTheme.accentBright, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'قاعدة بيانات وسجل مقدمي الخدمة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  Text(
                    'ملفات الكوادر التمريضية، الشفتات، الحالات القائمة والتقييمات',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const ManagementInstructionsDialog(isCaregiverView: false),
                );
              },
              icon: const Icon(Icons.gavel_rounded, size: 16, color: Colors.white),
              label: const Text('لوحة تعليمات الإدارة 📋', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(width: 8),
            if (canManage && !isZezo)
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddEditCaregiverDialog(),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('إضافة مقدم خدمة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBright,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            const SizedBox(width: 12),
          ],
        ),
        floatingActionButton: canManage && !isZezo
            ? FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddEditCaregiverDialog(),
                  );
                },
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة مقدم خدمة جديد',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
              )
            : null,
        body: Column(
          children: [
            // Zezo View-Only Notice Banner
            if (isZezo) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.amber.shade100,
                child: const Row(
                  children: [
                    Icon(Icons.visibility, color: Color(0xFFB45309), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'وضع الاطلاع فقط: مرحباً أ/ زيزو، مصرح لك بالاطلاع الكامل والبحث في سجلات مقدمي الخدمة. التعديل والإضافة متاح لمدير الشركة وهدان ومديرة المتابعة شيماء.',
                        style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF78350F), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Top Quick Statistics Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatCard(
                      title: 'إجمالي مقدمي الخدمة',
                      count: totalCount,
                      icon: Icons.people_alt,
                      color: AppTheme.primary,
                      isSelected: _selectedFilter == 'all',
                      onTap: () => setState(() => _selectedFilter = 'all'),
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      title: 'يعملون بحالات الآن',
                      count: workingCount,
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      isSelected: _selectedFilter == 'working',
                      onTap: () => setState(() => _selectedFilter = 'working'),
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      title: 'متاحين للتشغيل',
                      count: availableCount,
                      icon: Icons.event_available,
                      color: Colors.blue,
                      isSelected: _selectedFilter == 'available',
                      onTap: () => setState(() => _selectedFilter = 'available'),
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      title: 'محظورين بمشاكل',
                      count: blockedCount,
                      icon: Icons.block,
                      color: Colors.red,
                      isSelected: _selectedFilter == 'blocked',
                      onTap: () => setState(() => _selectedFilter = 'blocked'),
                    ),
                  ],
                ),
              ),
            ),

            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'بحث بالاسم، الكود، التليفون، الرقم القومي، المحافظة، أو الحالة القائمة...',
                            hintStyle: const TextStyle(fontSize: 13, fontFamily: 'Cairo'),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setState(() => _searchController.clear()),
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('الكل ($totalCount)', 'all'),
                        const SizedBox(width: 6),
                        _buildFilterChip('يعملون الآن ($workingCount)', 'working', icon: Icons.check_circle, activeColor: Colors.green),
                        const SizedBox(width: 6),
                        _buildFilterChip('متاحين ($availableCount)', 'available', icon: Icons.event_available, activeColor: Colors.blue),
                        const SizedBox(width: 6),
                        _buildFilterChip('محظورين ($blockedCount)', 'blocked', icon: Icons.block, activeColor: Colors.red),
                        const SizedBox(width: 6),
                        _buildFilterChip('ورديات 12 ساعة', '12h', icon: Icons.schedule),
                        const SizedBox(width: 6),
                        _buildFilterChip('إقامة 24 ساعة', '24h', icon: Icons.hotel),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Main Content: List of Caregivers
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          Text(
                            caregivers.isEmpty
                                ? 'لا توجد بيانات مسجلة لمقدمي الخدمة بعد'
                                : 'لا توجد نتائج تطابق معايير البحث والفلترة',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 8),
                          if (caregivers.isEmpty && canManage && !isZezo)
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const AddEditCaregiverDialog(),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة أول مقدم خدمة', style: TextStyle(fontFamily: 'Cairo')),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final caregiver = filtered[index];
                        final currentCase = provider.getCaregiverCurrentCase(caregiver.name);
                        final isWorking = caregiver.isCurrentlyWorking || currentCase != null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: caregiver.isBlocked
                                  ? Colors.red.shade300
                                  : (isWorking ? Colors.green.shade300 : Colors.grey.shade200),
                              width: (caregiver.isBlocked || isWorking) ? 1.5 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => CaregiverDetailDialog(caregiver: caregiver),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Top Card Row: Avatar, Name, Code, Badges & Actions
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: caregiver.isBlocked
                                            ? Colors.red.shade100
                                            : (isWorking ? Colors.green.shade100 : AppTheme.primary.withOpacity(0.1)),
                                        child: Icon(
                                          caregiver.isBlocked ? Icons.person_off : Icons.medical_services_rounded,
                                          color: caregiver.isBlocked
                                              ? Colors.red
                                              : (isWorking ? Colors.green : AppTheme.primary),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Name & Title
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    caregiver.name,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Cairo',
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Code badge (تكويد مقدم الخدمة)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.indigo.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: Colors.indigo.shade200),
                                                  ),
                                                  child: Text(
                                                    caregiver.code,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Cairo',
                                                      color: Colors.indigo,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Rating stars
                                                Row(
                                                  children: List.generate(5, (starIdx) {
                                                    return Icon(
                                                      starIdx < caregiver.rating.floor() ? Icons.star : Icons.star_border,
                                                      color: Colors.amber.shade700,
                                                      size: 15,
                                                    );
                                                  }),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              caregiver.qualification.isNotEmpty
                                                  ? caregiver.qualification
                                                  : 'طاقم تمريض ورعاية صحية',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Edit / Actions for Wahdan & Shimaa
                                      if (canManage && !isZezo) ...[
                                        PopupMenuButton<String>(
                                          onSelected: (val) async {
                                            if (val == 'account') {
                                              showDialog(
                                                context: context,
                                                builder: (_) => NurseAccountDialog(caregiver: caregiver),
                                              );
                                            } else if (val == 'edit') {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AddEditCaregiverDialog(caregiver: caregiver),
                                              );
                                            } else if (val == 'block') {
                                              if (caregiver.isBlocked) {
                                                await provider.toggleCaregiverBlock(caregiver.id, isBlocked: false);
                                              } else {
                                                _showBlockDialog(context, provider, caregiver);
                                              }
                                            } else if (val == 'delete') {
                                              _showDeleteDialog(context, provider, caregiver);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            PopupMenuItem(
                                              value: 'account',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.sms_outlined, color: Colors.teal, size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    caregiver.hasLoginAccount ? 'حساب الدخول وإرسال SMS' : 'إنشاء حساب دخول + SMS',
                                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.teal, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, color: Colors.blue, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('تعديل البيانات', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'block',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    caregiver.isBlocked ? Icons.check_circle : Icons.block,
                                                    color: caregiver.isBlocked ? Colors.green : Colors.red,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    caregiver.isBlocked ? 'إلغاء الحظر' : 'حظر بسبب مشاكل',
                                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, color: Colors.red, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('حذف من السجل', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Status Banner: Working Now with Case Name (المطلوب: ولما يكون شغال معانا الآن تظهر بجوار اسمه اسم الحالة التي يعمل فيها)
                                  if (isWorking) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.green.shade300),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'شغال معانا الآن مع الحالة: ',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green, fontFamily: 'Cairo'),
                                          ),
                                          Expanded(
                                            child: Text(
                                              currentCase ?? caregiver.currentClientName ?? 'حالة نشطة',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF14532D),
                                                fontFamily: 'Cairo',
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  // Block Banner if Blacklisted
                                  if (caregiver.isBlocked) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.red.shade300),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: const TextStyle(fontFamily: 'Cairo', color: Colors.red, fontSize: 12),
                                                children: [
                                                  const TextSpan(text: 'محظور بسبب مشاكل: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  TextSpan(text: caregiver.blockReason ?? 'غير محدد'),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  // Specs & Attributes Row
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                       // Live GPS Location
                                       if (caregiver.hasLocation)
                                         _buildTag(
                                           icon: Icons.my_location_rounded,
                                           label: 'موقع GPS 📍',
                                           color: Colors.green,
                                           bold: true,
                                           onTap: () => LocationService.openMapUrl(caregiver.locationMapsUrl!),
                                         ),
                                       // Phone
                                      if (caregiver.phone.isNotEmpty)
                                        _buildTag(
                                          icon: Icons.phone,
                                          label: caregiver.phone,
                                          color: Colors.teal,
                                        ),
                                      // Shift Preference
                                      _buildTag(
                                        icon: Icons.schedule,
                                        label: caregiver.shiftPreferenceArabic,
                                        color: Colors.indigo,
                                      ),
                                      // Daily Price
                                      _buildTag(
                                        icon: Icons.payments_outlined,
                                        label: '${caregiver.dailyPrice.toStringAsFixed(0)} ج/يوم',
                                        color: Colors.green,
                                        bold: true,
                                      ),
                                      // Residence Area
                                      if (caregiver.residenceArea.isNotEmpty)
                                        _buildTag(
                                          icon: Icons.location_on_outlined,
                                          label: caregiver.residenceArea,
                                          color: Colors.orange,
                                        ),
                                      // Weight & Height
                                      if (caregiver.weight != null || caregiver.height != null)
                                        _buildTag(
                                          icon: Icons.accessibility,
                                          label: '${caregiver.weight != null ? "${caregiver.weight!.toStringAsFixed(0)} كجم" : ""} ${caregiver.height != null ? "| ${caregiver.height!.toStringAsFixed(0)} سم" : ""}',
                                          color: Colors.blueGrey,
                                        ),
                                      // Past clients count
                                      if (provider.getCaregiverPastClients(caregiver.name).isNotEmpty)
                                        _buildTag(
                                          icon: Icons.history,
                                          label: '${provider.getCaregiverPastClients(caregiver.name).length} عميل سابق',
                                          color: Colors.purple,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (caregiver.hasLoginAccount) ...[
                                        Row(
                                          children: [
                                            const Icon(Icons.verified_user, color: Colors.teal, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              'حساب النظام: ${caregiver.loginUsername ?? "مفعل"}',
                                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                                            ),
                                          ],
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => NurseAccountDialog(caregiver: caregiver),
                                            );
                                          },
                                          icon: const Icon(Icons.sms, size: 14, color: Colors.teal),
                                          label: const Text('إرسال SMS / إدارة الحساب', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.teal)),
                                        ),
                                      ] else ...[
                                        const Row(
                                          children: [
                                            Icon(Icons.no_accounts_outlined, color: Colors.grey, size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              'لم يتم إنشاء حساب دخول بعد',
                                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        if (canManage && !isZezo)
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => NurseAccountDialog(caregiver: caregiver),
                                              );
                                            },
                                            icon: const Icon(Icons.person_add_alt_1, size: 14, color: Colors.teal),
                                            label: const Text('إنشاء حساب + SMS', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.teal),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Impersonation & Location Quick Actions
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await provider.loginAsCaregiver(caregiver);
                                          if (context.mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const NursePortalScreen()),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.remove_red_eye_rounded, size: 15),
                                        label: const Text('دخول ومعاينة الشاشة 👁️', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6366F1),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          elevation: 1,
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _showCaregiverLocationDialog(context, caregiver),
                                        icon: Icon(Icons.location_on, size: 15, color: caregiver.hasLocation ? Colors.green.shade700 : Colors.teal.shade700),
                                        label: Text(
                                          caregiver.hasLocation ? 'موقع GPS مباشر 📍' : 'تحديد الموقع الجغرافي 📍',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: caregiver.hasLocation ? Colors.green.shade800 : Colors.teal.shade800,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: caregiver.hasLocation ? Colors.green : Colors.teal),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Cairo',
                    color: isSelected ? color : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {IconData? icon, Color? activeColor}) {
    final isSelected = _selectedFilter == value;
    final color = activeColor ?? AppTheme.primary;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Cairo',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.grey.shade800,
        ),
      ),
      avatar: icon != null
          ? Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : color,
            )
          : null,
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: color,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
      showCheckmark: false,
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
    bool bold = false,
    VoidCallback? onTap,
  }) {
    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Cairo',
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 11, color: color),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: tag,
      );
    }
    return tag;
  }

  void _showBlockDialog(BuildContext context, AppProvider provider, CaregiverModel caregiver) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('حظر مقدم الخدمة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد حظر: ${caregiver.name} بسبب مشاكل؟', style: const TextStyle(fontFamily: 'Cairo')),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'نوع المشكلة وسبب الحظر *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              await provider.toggleCaregiverBlock(caregiver.id, isBlocked: true, reason: reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('تأكيد الحظر', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AppProvider provider, CaregiverModel caregiver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('هل أنت متأكد من حذف مقدم الخدمة: ${caregiver.name} نهائياً من قاعدة البيانات؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteCaregiver(caregiver.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('حذف نهائي', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showCaregiverLocationDialog(BuildContext context, CaregiverModel caregiver) {
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');
    final provider = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: caregiver.hasLocation ? Colors.green.shade100 : Colors.teal.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.location_on, color: caregiver.hasLocation ? Colors.green.shade800 : Colors.teal.shade800, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الموقع الجغرافي: ${caregiver.name}',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'كود: ${caregiver.code} • تليفون: ${caregiver.phone}',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (caregiver.hasLocation) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'تم رصد إحداثيات GPS فعلية عبر هاتف مقدم الخدمة',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF14532D)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'خط العرض: ${caregiver.lastLatitude!.toStringAsFixed(6)}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                      Text(
                        'خط الطول: ${caregiver.lastLongitude!.toStringAsFixed(6)}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                      if (caregiver.lastLocationAccuracy != null)
                        Text(
                          'دقة التحديد: ±${caregiver.lastLocationAccuracy!.toStringAsFixed(0)} متر',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                        ),
                      if (caregiver.lastLocationUpdate != null)
                        Text(
                          'آخر توقيت تحديث: ${dateFormat.format(caregiver.lastLocationUpdate!)}',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    LocationService.openMapUrl(caregiver.locationMapsUrl!);
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text(
                    'فتح الموقع المباشر على خرائط Google 🗺️',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'لم يسجل إحداثيات GPS تلقائية حتى الآن عبر البوابة',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF78350F)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'المنطقة السكنية المسجلة: ${caregiver.residenceArea.isNotEmpty ? caregiver.residenceArea : "غير محددة"}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final query = caregiver.residenceArea.isNotEmpty ? caregiver.residenceArea : caregiver.name;
                    final mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
                    LocationService.openMapUrl(mapUrl);
                  },
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text(
                    'البحث عن عنوان سكنه على خرائط Google 🗺️',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await provider.loginAsCaregiver(caregiver);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NursePortalScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                label: const Text(
                  'دخول فوري ومعاينة شاشته في البوابة 👁️',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
