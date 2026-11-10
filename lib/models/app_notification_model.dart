class AppNotificationModel {
  final String id;
  final String title;
  final String description;
  final String actionType; // 'add_client', 'edit_client', 'delete_client', 'pricing', 'start_service', 'extend_service', 'end_service', 'service_days', 'payment', 'delete_payment', 'expense', 'delete_expense', 'nurse_advance', 'nurse_payment', 'partner_loan', 'partner_settlement', 'balances', 'user'
  final String userId;
  final String userName; // e.g. "أ/ وهدان", "أ/ شيماء", "أ/ زيزو"
  final String userRole; // e.g. "مدير الشركة", "مديرة المتابعة والتشغيل"
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.actionType,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'actionType': actionType,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      actionType: map['actionType']?.toString() ?? 'general',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? 'مستخدم',
      userRole: map['userRole']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }
}
