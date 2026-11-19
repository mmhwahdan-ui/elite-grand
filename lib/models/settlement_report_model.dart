import 'client_model.dart';
import 'service_day_model.dart';

class CaregiverSettlementItem {
  final String nurseName;
  final String? nurseCode;
  final String? nursePhone;
  final List<String> clientNames;
  final int shiftsCount;
  final double dailyRate;
  final double totalEarned; // إجمالي المستحق في الفترة
  final double advances; // إجمالي السلف في الفترة
  final double payouts; // إجمالي المسدد في الفترة
  final double periodNetDue; // صافي المستحق للدفع في الفترة
  final double allTimeRemaining; // باقي الحساب التراكمي الشامل
  final List<ServiceDayModel> shifts;

  CaregiverSettlementItem({
    required this.nurseName,
    this.nurseCode,
    this.nursePhone,
    required this.clientNames,
    required this.shiftsCount,
    required this.dailyRate,
    required this.totalEarned,
    required this.advances,
    required this.payouts,
    required this.periodNetDue,
    required this.allTimeRemaining,
    required this.shifts,
  });
}

class ClientSettlementItem {
  final ClientModel client;
  final int daysServedInPeriod;
  final double dailyPrice;
  final double periodAccruedCost; // تكلفة الخدمة في الفترة
  final double periodCollected; // المبالغ المحصلة في الفترة
  final double periodRemaining; // باقي المستحق للفترة
  final double allTimeBalance; // الرصيد التراكمي الشامل للعميل

  ClientSettlementItem({
    required this.client,
    required this.daysServedInPeriod,
    required this.dailyPrice,
    required this.periodAccruedCost,
    required this.periodCollected,
    required this.periodRemaining,
    required this.allTimeBalance,
  });
}

class WeeklyMonthlySettlementReport {
  final DateTime startDate;
  final DateTime endDate;
  final String periodType; // 'weekly' or 'monthly'
  final String title;
  final List<CaregiverSettlementItem> caregivers;
  final List<ClientSettlementItem> clients;

  WeeklyMonthlySettlementReport({
    required this.startDate,
    required this.endDate,
    required this.periodType,
    required this.title,
    required this.caregivers,
    required this.clients,
  });

  double get totalCaregiverEarned =>
      caregivers.fold(0.0, (sum, c) => sum + c.totalEarned);

  double get totalCaregiverAdvances =>
      caregivers.fold(0.0, (sum, c) => sum + c.advances);

  double get totalCaregiverPayouts =>
      caregivers.fold(0.0, (sum, c) => sum + c.payouts);

  double get totalCaregiverNetPayable =>
      caregivers.fold(0.0, (sum, c) => sum + (c.periodNetDue > 0 ? c.periodNetDue : 0));

  double get totalClientAccruedCost =>
      clients.fold(0.0, (sum, c) => sum + c.periodAccruedCost);

  double get totalClientCollected =>
      clients.fold(0.0, (sum, c) => sum + c.periodCollected);

  double get totalClientRemaining =>
      clients.fold(0.0, (sum, c) => sum + (c.periodRemaining > 0 ? c.periodRemaining : 0));

  double get netCompanyProfit => totalClientAccruedCost - totalCaregiverEarned;

  int get totalShiftsCount =>
      caregivers.fold(0, (sum, c) => sum + c.shiftsCount);

  int get activeCaregiversCount => caregivers.length;
  int get activeClientsCount => clients.length;
}
