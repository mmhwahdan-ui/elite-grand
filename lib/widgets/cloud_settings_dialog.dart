import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/cloud_sync_service.dart';
import '../theme/app_theme.dart';

class CloudSettingsDialog extends StatefulWidget {
  const CloudSettingsDialog({super.key});

  @override
  State<CloudSettingsDialog> createState() => _CloudSettingsDialogState();
}

class _CloudSettingsDialogState extends State<CloudSettingsDialog> {
  late TextEditingController _endpointController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _endpointController = TextEditingController(
      text: provider.cloudSyncService.cloudEndpoint ?? '',
    );
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm a');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_sync, color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الربط السحابي والمزامنة عبر الإنترنت',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            'لمزامنة الـ 5 موبايلات لحظياً من أي شبكة نت أو 4G',
                            style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Status Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _getStatusColor(provider.syncStatus).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(provider.syncStatus).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(provider.syncStatus), color: _getStatusColor(provider.syncStatus)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusLabel(provider.syncStatus),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(provider.syncStatus),
                                fontFamily: 'Cairo',
                              ),
                            ),
                            if (provider.lastSyncTime != null)
                              Text(
                                'آخر مزامنة ناجحة: ${dateFormat.format(provider.lastSyncTime!)}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'رابط قاعدة البيانات السحابية (Firebase / REST Hub):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _endpointController,
                  decoration: InputDecoration(
                    hintText: 'https://<PROJECT-ID>.firebaseio.com/elite_grand.json',
                    prefixIcon: const Icon(Icons.link),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _endpointController.clear(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Quick Guide Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 كيف يعمل الربط بين الـ 5 موبايلات؟',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo', color: AppTheme.primary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• يتم إدخال نفس الرابط السحابي على الموبايلات الـ 5.\n'
                        '• عندما تضيف شيماء عميلاً، يظهر فوراً على موبايل زيزو ووهدان.\n'
                        '• عندما يسجل زيزو سعر أو دفعة أو ينهي الخدمة، يتم التحديث للجميع.\n'
                        '• لو انقطع النت على أي هاتف، يحفظ التطبيق البيانات محلياً ويقوم بالمزامنة فور عودة النت تلقائياً.',
                        style: TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF475569), fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await provider.syncWithCloud();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.statusMessage ?? 'تمت المزامنة', style: const TextStyle(fontFamily: 'Cairo')),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.sync),
                        label: const Text('مزامنة الآن', style: TextStyle(fontFamily: 'Cairo')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final url = _endpointController.text.trim();
                          await provider.setCloudEndpoint(url);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم حفظ رابط السحابة وبدء المزامنة التلقائية', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: AppTheme.accent,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('حفظ الرابط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return AppTheme.accent;
      case SyncStatus.syncing:
        return AppTheme.primaryLight;
      case SyncStatus.error:
        return AppTheme.redDebt;
      case SyncStatus.offline:
        return Colors.orange;
      case SyncStatus.idle:
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getStatusIcon(SyncStatus status) {
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

  String _getStatusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return 'السحابة متصلة وتعمل بنجاح (المزامنة نشطة)';
      case SyncStatus.syncing:
        return 'جاري إرسال واستقبال البيانات مع السحابة...';
      case SyncStatus.error:
        return 'خطأ في الربط السحابي (تأكد من الرابط أو الصلاحيات)';
      case SyncStatus.offline:
        return 'وضع عدم الاتصال (أوفلاين) - البيانات محفوظة محلياً';
      case SyncStatus.idle:
      default:
        return 'السحابة في وضع الاستعداد';
    }
  }
}
