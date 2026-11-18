class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderUsername;
  final String senderDisplayName;
  final String senderRole;
  final String recipientId; // 'all' for team group, 'cases_group' for cases offer board, or specific userId
  final String recipientName; // 'الجميع' or recipient display name
  final String text;
  final String? tag; // 'urgent', 'shift', 'payment', 'nurse', 'client', 'case_offer', null
  final String? relatedClientName; // optional client referenced
  final String? caseOfferId; // optional case offer ID
  final String? threadId; // optional thread identifier (e.g. 'thread_$nurseUserId')
  final bool isSupervisorAction; // true when General Manager (Wahdan) participates in Shimaa's chat
  final DateTime timestamp;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.senderDisplayName,
    required this.senderRole,
    this.recipientId = 'all',
    this.recipientName = 'الجميع',
    required this.text,
    this.tag,
    this.relatedClientName,
    this.caseOfferId,
    this.threadId,
    this.isSupervisorAction = false,
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isGroupMessage => recipientId == 'all';
  bool get isCasesGroupMessage => recipientId == 'cases_group';

  String? get tagArabic {
    switch (tag) {
      case 'urgent':
        return '🚨 عاجل';
      case 'shift':
        return '🕒 وردية / شفت';
      case 'payment':
        return '💵 دفعة / تحصيل';
      case 'nurse':
        return '🩺 طاقم التمريض';
      case 'client':
        return '📋 ملاحظة حالة';
      case 'case_offer':
        return '📢 فرصة / حالة جديدة';
      default:
        return null;
    }
  }

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? senderUsername,
    String? senderDisplayName,
    String? senderRole,
    String? recipientId,
    String? recipientName,
    String? text,
    String? tag,
    String? relatedClientName,
    String? caseOfferId,
    String? threadId,
    bool? isSupervisorAction,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderRole: senderRole ?? this.senderRole,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      text: text ?? this.text,
      tag: tag ?? this.tag,
      relatedClientName: relatedClientName ?? this.relatedClientName,
      caseOfferId: caseOfferId ?? this.caseOfferId,
      threadId: threadId ?? this.threadId,
      isSupervisorAction: isSupervisorAction ?? this.isSupervisorAction,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderDisplayName': senderDisplayName,
      'senderRole': senderRole,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'text': text,
      'tag': tag,
      'relatedClientName': relatedClientName,
      'caseOfferId': caseOfferId,
      'threadId': threadId,
      'isSupervisorAction': isSupervisorAction,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderUsername: map['senderUsername']?.toString() ?? '',
      senderDisplayName: map['senderDisplayName']?.toString() ?? 'مستخدم',
      senderRole: map['senderRole']?.toString() ?? '',
      recipientId: map['recipientId']?.toString() ?? 'all',
      recipientName: map['recipientName']?.toString() ?? 'الجميع',
      text: map['text']?.toString() ?? '',
      tag: map['tag']?.toString(),
      relatedClientName: map['relatedClientName']?.toString(),
      caseOfferId: map['caseOfferId']?.toString(),
      threadId: map['threadId']?.toString(),
      isSupervisorAction: map['isSupervisorAction'] == true,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] == true,
    );
  }
}
