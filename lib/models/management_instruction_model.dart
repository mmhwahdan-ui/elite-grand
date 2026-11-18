class ManagementInstructionModel {
  final String id;
  final String title;
  final String content;
  final String authorName; // e.g. 'أ/ وهدان (المدير العام)'
  final String authorRole; // e.g. 'المدير العام'
  final String priority; // 'urgent', 'important', 'normal'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  ManagementInstructionModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    this.authorRole = 'الإدارة العامة',
    this.priority = 'important',
    DateTime? createdAt,
    this.updatedAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  String get priorityArabic {
    switch (priority) {
      case 'urgent':
        return '🚨 عاجل وملزم فوراً';
      case 'important':
        return '⭐ هام وضروري';
      default:
        return '📋 تعليمات عامة';
    }
  }

  ManagementInstructionModel copyWith({
    String? id,
    String? title,
    String? content,
    String? authorName,
    String? authorRole,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ManagementInstructionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorName': authorName,
      'authorRole': authorRole,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory ManagementInstructionModel.fromMap(Map<String, dynamic> map) {
    return ManagementInstructionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorName: map['authorName'] ?? 'الإدارة',
      authorRole: map['authorRole'] ?? 'الإدارة العامة',
      priority: map['priority'] ?? 'important',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      isActive: map['isActive'] ?? true,
    );
  }
}
