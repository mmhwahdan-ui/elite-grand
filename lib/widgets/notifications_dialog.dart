import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/app_notification_model.dart';
import '../providers/app_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class NotificationsDialog extends StatelessWidget {
  const NotificationsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final notifications = provider.notifications;
    final timeFormat = DateFormat('hh:mm a', 'ar');
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: 580,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: AppTheme.accentBright,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سجل التعديلات والإشعارات الصوتية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            'تنبيه صوتي لحظي عند قيام أي حساب بإدخال أو تعديل بيانات',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Control Bar: Test Sound & Settings
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFF1F5F9),
                child: Row(
                  children: [
                    // Test Audio Chime Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: const Text('تجربة نغمة الإشعار'),
                      onPressed: () {
                        SoundService.playNotificationSound();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم تشغيل نغمة الإشعار الصوتية بنجاح 🔔',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                            duration: Duration(seconds: 2),
                            backgroundColor: AppTheme.accent,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    // Mark as read
                    if (provider.unreadNotificationCount > 0)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text(
                          'تحديد كمقروء',
                          style: TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                        ),
                        onPressed: () {
                          provider.markNotificationsAsRead();
                        },
                      ),
                  ],
                ),
              ),

              // Notifications List
              Flexible(
                child: notifications.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد تعديلات أو إشعارات مسجلة حتى الآن',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'أي تعديل أو إدخال يقوم به أي مستخدم سيظهر هنا فوراً مع صوت تنبيه',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _buildNotificationCard(notif, timeFormat, dateFormat);
                        },
                      ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إجمالي العمليات المسجلة: ${notifications.length}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    AppNotificationModel notif,
    DateFormat timeFormat,
    DateFormat dateFormat,
  ) {
    final (icon, iconColor, bgColor) = _getActionVisuals(notif.actionType);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title & User
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 12, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            notif.userName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (notif.userRole.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notif.userRole,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),

                // Description
                Text(
                  notif.description,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),

                // Timestamp
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(notif.timestamp)} - ${timeFormat.format(notif.timestamp)}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, Color) _getActionVisuals(String actionType) {
    switch (actionType) {
      case 'add_client':
        return (Icons.person_add_rounded, const Color(0xFF00D09C), const Color(0xFFE6FBF5));
      case 'edit_client':
        return (Icons.edit_note_rounded, const Color(0xFF0052CC), const Color(0xFFE8F0FE));
      case 'delete_client':
        return (Icons.person_remove_rounded, Colors.red, const Color(0xFFFEECEB));
      case 'pricing':
        return (Icons.price_change_rounded, const Color(0xFF8B5CF6), const Color(0xFFF3E8FF));
      case 'start_service':
        return (Icons.play_circle_fill_rounded, const Color(0xFF10B981), const Color(0xFFD1FAE5));
      case 'extend_service':
        return (Icons.update_rounded, const Color(0xFFF59E0B), const Color(0xFFFEF3C7));
      case 'end_service':
        return (Icons.stop_circle_rounded, Colors.redAccent, const Color(0xFFFEE2E2));
      case 'service_days':
        return (Icons.date_range_rounded, const Color(0xFF0284C7), const Color(0xFFE0F2FE));
      case 'payment':
        return (Icons.payments_rounded, const Color(0xFF059669), const Color(0xFFD1FAE5));
      case 'delete_payment':
        return (Icons.money_off_rounded, Colors.red, const Color(0xFFFEECEB));
      case 'expense':
        return (Icons.receipt_long_rounded, const Color(0xFFEA580C), const Color(0xFFFFEDD5));
      case 'delete_expense':
        return (Icons.delete_outline_rounded, Colors.red, const Color(0xFFFEECEB));
      case 'nurse_advance':
        return (Icons.volunteer_activism_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7));
      case 'nurse_payout':
        return (Icons.handshake_rounded, const Color(0xFF0D9488), const Color(0xFFCCFBF1));
      case 'partner_loan':
        return (Icons.account_balance_rounded, const Color(0xFF7C3AED), const Color(0xFFEDE9FE));
      case 'partner_settlement':
        return (Icons.stars_rounded, const Color(0xFFEAB308), const Color(0xFFFEF9C3));
      case 'user_permissions':
        return (Icons.security_rounded, const Color(0xFF4F46E5), const Color(0xFFEEF2FF));
      case 'balances':
        return (Icons.savings_rounded, const Color(0xFF0891B2), const Color(0xFFCFFAFE));
      default:
        return (Icons.info_rounded, AppTheme.primary, const Color(0xFFE2E8F0));
    }
  }
}
