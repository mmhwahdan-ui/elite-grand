class UserPermissions {
  final bool canAddClient;
  final bool canEditClient;
  final bool canSetPrice;
  final bool canStartService;
  final bool canEndService;
  final bool canRecordPayment;
  final bool canRecordExpense;
  final bool canViewFinancialReports;
  final bool canManagePermissions;
  final bool canEditAnyData;

  const UserPermissions({
    this.canAddClient = false,
    this.canEditClient = false,
    this.canSetPrice = false,
    this.canStartService = false,
    this.canEndService = false,
    this.canRecordPayment = false,
    this.canRecordExpense = false,
    this.canViewFinancialReports = false,
    this.canManagePermissions = false,
    this.canEditAnyData = false,
  });

  UserPermissions copyWith({
    bool? canAddClient,
    bool? canEditClient,
    bool? canSetPrice,
    bool? canStartService,
    bool? canEndService,
    bool? canRecordPayment,
    bool? canRecordExpense,
    bool? canViewFinancialReports,
    bool? canManagePermissions,
    bool? canEditAnyData,
  }) {
    return UserPermissions(
      canAddClient: canAddClient ?? this.canAddClient,
      canEditClient: canEditClient ?? this.canEditClient,
      canSetPrice: canSetPrice ?? this.canSetPrice,
      canStartService: canStartService ?? this.canStartService,
      canEndService: canEndService ?? this.canEndService,
      canRecordPayment: canRecordPayment ?? this.canRecordPayment,
      canRecordExpense: canRecordExpense ?? this.canRecordExpense,
      canViewFinancialReports: canViewFinancialReports ?? this.canViewFinancialReports,
      canManagePermissions: canManagePermissions ?? this.canManagePermissions,
      canEditAnyData: canEditAnyData ?? this.canEditAnyData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'canAddClient': canAddClient,
      'canEditClient': canEditClient,
      'canSetPrice': canSetPrice,
      'canStartService': canStartService,
      'canEndService': canEndService,
      'canRecordPayment': canRecordPayment,
      'canRecordExpense': canRecordExpense,
      'canViewFinancialReports': canViewFinancialReports,
      'canManagePermissions': canManagePermissions,
      'canEditAnyData': canEditAnyData,
    };
  }

  factory UserPermissions.fromMap(Map<String, dynamic> map) {
    return UserPermissions(
      canAddClient: map['canAddClient'] ?? false,
      canEditClient: map['canEditClient'] ?? false,
      canSetPrice: map['canSetPrice'] ?? false,
      canStartService: map['canStartService'] ?? false,
      canEndService: map['canEndService'] ?? false,
      canRecordPayment: map['canRecordPayment'] ?? false,
      canRecordExpense: map['canRecordExpense'] ?? false,
      canViewFinancialReports: map['canViewFinancialReports'] ?? false,
      canManagePermissions: map['canManagePermissions'] ?? false,
      canEditAnyData: map['canEditAnyData'] ?? false,
    );
  }
}

class UserModel {
  final String id;
  final String username;
  String password;
  String displayName;
  String roleTitle;
  final String roleType; // manager, accountant, followup, custom
  UserPermissions permissions;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.displayName,
    required this.roleTitle,
    required this.roleType,
    required this.permissions,
  });

  UserModel copyWith({
    String? id,
    String? username,
    String? password,
    String? displayName,
    String? roleTitle,
    String? roleType,
    UserPermissions? permissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      roleTitle: roleTitle ?? this.roleTitle,
      roleType: roleType ?? this.roleType,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'displayName': displayName,
      'roleTitle': roleTitle,
      'roleType': roleType,
      'permissions': permissions.toMap(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '123',
      displayName: map['displayName'] ?? '',
      roleTitle: map['roleTitle'] ?? '',
      roleType: map['roleType'] ?? 'custom',
      permissions: map['permissions'] != null
          ? UserPermissions.fromMap(Map<String, dynamic>.from(map['permissions']))
          : const UserPermissions(),
    );
  }

  // Pre-configured default users as requested
  static List<UserModel> getDefaultUsers() {
    return [
      UserModel(
        id: 'usr_wahdan',
        username: 'wahdan',
        password: '123',
        displayName: 'أ/ وهدان',
        roleTitle: 'مدير الشركة (المدير العام)',
        roleType: 'manager',
        permissions: const UserPermissions(
          canAddClient: true,
          canEditClient: true,
          canSetPrice: true,
          canStartService: true,
          canEndService: true,
          canRecordPayment: true,
          canRecordExpense: true,
          canViewFinancialReports: true,
          canManagePermissions: true,
          canEditAnyData: true,
        ),
      ),
      UserModel(
        id: 'usr_zezo',
        username: 'zezo',
        password: '123',
        displayName: 'أ/ زيزو',
        roleTitle: 'مدير الحسابات والمالية',
        roleType: 'accountant',
        permissions: const UserPermissions(
          canAddClient: false,
          canEditClient: false,
          canSetPrice: true,
          canStartService: false,
          canEndService: true,
          canRecordPayment: true,
          canRecordExpense: true,
          canViewFinancialReports: true,
          canManagePermissions: false,
          canEditAnyData: false,
        ),
      ),
      UserModel(
        id: 'usr_shimaa',
        username: 'shimaa',
        password: '123',
        displayName: 'أ/ شيماء',
        roleTitle: 'مديرة المتابعة والتشغيل',
        roleType: 'followup',
        permissions: const UserPermissions(
          canAddClient: true,
          canEditClient: true,
          canSetPrice: false,
          canStartService: true,
          canEndService: false,
          canRecordPayment: false,
          canRecordExpense: false,
          canViewFinancialReports: true,
          canManagePermissions: false,
          canEditAnyData: false,
        ),
      ),
      UserModel(
        id: 'usr_user4',
        username: 'user4',
        password: '123',
        displayName: 'حساب إضافي (1)',
        roleTitle: 'مشرف تمريض / منسق ميداني',
        roleType: 'custom',
        permissions: const UserPermissions(
          canAddClient: false,
          canEditClient: false,
          canSetPrice: false,
          canStartService: true,
          canEndService: false,
          canRecordPayment: false,
          canRecordExpense: false,
          canViewFinancialReports: true,
          canManagePermissions: false,
          canEditAnyData: false,
        ),
      ),
      UserModel(
        id: 'usr_user5',
        username: 'user5',
        password: '123',
        displayName: 'حساب إضافي (2)',
        roleTitle: 'خدمة عملاء / متابعة',
        roleType: 'custom',
        permissions: const UserPermissions(
          canAddClient: true,
          canEditClient: false,
          canSetPrice: false,
          canStartService: false,
          canEndService: false,
          canRecordPayment: false,
          canRecordExpense: false,
          canViewFinancialReports: true,
          canManagePermissions: false,
          canEditAnyData: false,
        ),
      ),
    ];
  }
}
