class PeriodFinancialSummary {
  final String periodType; // 'daily', 'weekly', 'monthly_23'
  final String periodTitle; // e.g. "اليوم - 10 نوفمبر 2026", "آخر 7 أيام", "دورة 24 أكتوبر إلى 23 نوفمبر"
  final DateTime startDate;
  final DateTime endDate;
  final double revenues; // إجمالي إيرادات تعاقدات العملاء
  final double nurseCosts; // إجمالي مستحقات أطقم التمريض
  final double grossProfit; // مجمل ربح التشغيل من فروق الأسعار
  final double expenses; // المصروفات التشغيلية والإدارية
  final double netProfit; // صافي الربح = مجمل ربح التشغيل - المصروفات
  final int shiftsCount; // عدد الورديات وأيام الخدمة المسجلة
  final int activeClientsCount; // عدد الحالات المخدومة
  final int? daysRemainingUntil23; // للأشهر: الأيام المتبقية حتى يوم 23
  final double wahdanShare; // حصة وهدان 40%
  final double shimaaShare; // حصة شيماء 40% مع ضمان 6000 ج
  final double zezoShare; // حصة زيزو 20%

  PeriodFinancialSummary({
    required this.periodType,
    required this.periodTitle,
    required this.startDate,
    required this.endDate,
    required this.revenues,
    required this.nurseCosts,
    required this.grossProfit,
    required this.expenses,
    required this.netProfit,
    this.shiftsCount = 0,
    this.activeClientsCount = 0,
    this.daysRemainingUntil23,
    double? wahdanShare,
    double? shimaaShare,
    double? zezoShare,
  })  : wahdanShare = wahdanShare ?? (netProfit > 0 ? netProfit * 0.40 : 0.0),
        shimaaShare = shimaaShare ?? (netProfit > 0 ? (netProfit * 0.40 < 6000 ? 6000 : netProfit * 0.40) : 0.0),
        zezoShare = zezoShare ?? (netProfit > 0 ? netProfit * 0.20 : 0.0);

  bool get isProfitable => netProfit >= 0;

  double get profitMargin {
    if (revenues <= 0) return 0.0;
    return (netProfit / revenues) * 100;
  }
}
