class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderUsername;
  final String senderDisplayName;
  final String senderRole;
  final String recipientId; // 'all' for team group, or specific userId
  final String recipientName; // 'الجميع' or recipient display name
  final String text;
  final String? tag; // 'urgent', 'shift', 'payment', 'nurse', 'client', null
  final String? relatedClientName; // optional client referenced
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
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isGroupMessage => recipientId == 'all';

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
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] == true,
    );
  }
}
