import 'package:intl/intl.dart' hide TextDirection;
import '../models/client_model.dart';
import '../models/expense_model.dart';
import '../models/payment_model.dart';
import '../providers/app_provider.dart';

import 'export_stub.dart'
    if (dart.library.js_interop) 'export_web.dart';

class ExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

  // 1. Export Clients Ledger to Excel
  static void exportClientsToExcel(AppProvider provider) {
    final StringBuffer csv = StringBuffer();

    // Headers
    csv.writeln(
      'اسم العميل,نوع العميل,الرصيد الافتتاحي (ج.م),رقم الهاتف,العنوان,الحالة الصحية,نوع الشيفت,سعر العميل (ج.م),يومية الممرض (ج.م),مكسب الشركة اليومي (ج.م),تاريخ البدء,تاريخ الإنهاء,عدد الأيام,إجمالي تعاقد العميل (ج.م),إجمالي مستحق التمريض (ج.م),إجمالي مكسب الشركة من الحالة (ج.م),المدفوع نقداً (ج.م),الرصيد النهائي ومستحقات الشركة,حالة الخدمة,الممرض المسند,ملاحظات'
    );

    for (var c in provider.clients) {
      final paid = provider.getClientTotalPaid(c.id);
      final bal = provider.getClientBalance(c);
      final servedDays = provider.getClientServedDaysCount(c);
      final clientCost = provider.getClientAccruedCost(c);
      final nurseCost = provider.getClientNurseCost(c);
      final profit = provider.getClientCompanyProfit(c);

      final balanceText = bal < 0
          ? 'مستحق على العميل: ${bal.abs().toStringAsFixed(0)} ج.م'
          : (bal > 0 ? 'مستحق للعميل: ${bal.toStringAsFixed(0)} ج.م' : 'خالص');

      final row = [
        _escape(c.name),
        c.isExistingClient ? 'عميل حالي' : 'عميل جديد',
        c.openingBalance.toStringAsFixed(0),
        _escape(c.phone),
        _escape(c.address),
        _escape(c.healthCondition),
        _escape(c.serviceTypeArabic),
        c.dailyPrice.toStringAsFixed(0),
        c.nurseDailyPrice.toStringAsFixed(0),
        c.dailyCompanyProfit.toStringAsFixed(0),
        c.startDate != null ? _dateFormat.format(c.startDate!) : 'لم تبدأ',
        c.endDate != null ? _dateFormat.format(c.endDate!) : (c.startDate != null ? 'مستمرة' : '-'),
        servedDays.toString(),
        clientCost.toStringAsFixed(0),
        nurseCost.toStringAsFixed(0),
        profit.toStringAsFixed(0),
        paid.toStringAsFixed(0),
        _escape(balanceText),
        _escape(c.statusArabic),
        _escape(c.nurseAssigned ?? '-'),
        _escape(c.notes),
      ];

      csv.writeln(row.join(','));
    }

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    saveAndDownloadFile(
      csv.toString(),
      'تقرير_حالات_وعملاء_إيليت_جراند_$dateStr.csv',
      'text/csv;charset=utf-8;',
    );
  }

  // 2. Export Payments Ledger to Excel
  static void exportPaymentsToExcel(AppProvider provider) {
    final StringBuffer csv = StringBuffer();

    csv.writeln('التاريخ,اسم العميل,المبلغ المحصل (ج.م),مكان التحصيل والإيداع,المستلم,ملاحظات');

    for (var p in provider.payments) {
      final row = [
        _dateFormat.format(p.paymentDate),
        _escape(p.clientName),
        p.amount.toStringAsFixed(0),
        _escape(p.channelArabic),
        _escape(p.receivedBy),
        _escape(p.notes),
      ];
      csv.writeln(row.join(','));
    }

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    saveAndDownloadFile(
      csv.toString(),
      'سجل_مقبوضات_وتحصيلات_إيليت_جراند_$dateStr.csv',
      'text/csv;charset=utf-8;',
    );
  }

  // 3. Export Expenses to Excel
  static void exportExpensesToExcel(AppProvider provider) {
    final StringBuffer csv = StringBuffer();

    csv.writeln('التاريخ,بند المصروف,بيان وتفاصيل المصروف,المبلغ (ج.م),قناة الدفع والصرف,سُجل بواسطة,يخص مريض,ملاحظات');

    for (var exp in provider.expenses) {
      String clientName = 'عام للشركة';
      if (exp.relatedClientId != null) {
        final matches = provider.clients.where((c) => c.id == exp.relatedClientId);
        if (matches.isNotEmpty) {
          clientName = matches.first.name;
        }
      }

      final row = [
        _dateFormat.format(exp.expenseDate),
        _escape(exp.categoryArabic),
        _escape(exp.title),
        exp.amount.toStringAsFixed(0),
        _escape(exp.channelArabic),
        _escape(exp.recordedBy),
        _escape(clientName),
        _escape(exp.notes),
      ];

      csv.writeln(row.join(','));
    }

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    saveAndDownloadFile(
      csv.toString(),
      'تقرير_مصروفات_إيليت_جراند_$dateStr.csv',
      'text/csv;charset=utf-8;',
    );
  }

  // 4. Export Comprehensive Financial Statement to Excel
  static void exportFinancialReportToExcel(AppProvider provider) {
    final StringBuffer csv = StringBuffer();

    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());
    csv.writeln('تقرير المركز المالي والأرباح التشغيلية وحسابات البنوك - شركة إيليت جراند');
    csv.writeln('تاريخ استخراج التقرير: $dateStr');
    csv.writeln('');

    // Treasury & Accounts breakdown
    csv.writeln('--- أرصدة الحسابات ومصادر السيولة النقدية والبنكية ---,,');
    csv.writeln('الحساب / القناة,رصيد أول المدة (ج.م),إجمالي التحصيلات (الوارد),إجمالي المصروفات (المنصرف),الرصيد الفعلي الحالي (ج.م)');
    csv.writeln('📱 المحفظة الإلكترونية (فودافون كاش / إنستاباي),${provider.walletOpeningBalance.toStringAsFixed(0)},${provider.walletCollections.toStringAsFixed(0)},${provider.walletExpenses.toStringAsFixed(0)},${provider.currentWalletBalance.toStringAsFixed(0)}');
    csv.writeln('🏦 الحساب البنكي (تحويلات وإيداعات),${provider.bankOpeningBalance.toStringAsFixed(0)},${provider.bankCollections.toStringAsFixed(0)},${provider.bankExpenses.toStringAsFixed(0)},${provider.currentBankBalance.toStringAsFixed(0)}');
    csv.writeln('💵 الخزينة النقدية (كاش المقر والمندوبين),${provider.cashOpeningBalance.toStringAsFixed(0)},${provider.cashCollections.toStringAsFixed(0)},${provider.cashExpenses.toStringAsFixed(0)},${provider.currentCashBalance.toStringAsFixed(0)}');
    csv.writeln('💰 إجمالي السيولة المتاحة للشركة,,, ,${provider.totalTreasuryBalance.toStringAsFixed(0)}');
    csv.writeln('');

    // Case profitability & price difference
    csv.writeln('--- تصفية أرباح الحالات وفروق الأسعار (العميل vs التمريض) ---,,');
    csv.writeln('إجمالي تعاقدات العملاء (إيرادات الخدمة المحققة),${provider.totalAccruedRevenues.toStringAsFixed(0)},(مجموع الأيام × سعر العميل)');
    csv.writeln('إجمالي مستحقات ويوميات التمريض المنقضية,${provider.totalNurseAccruedCosts.toStringAsFixed(0)},(مجموع الأيام × يومية الممرض)');
    csv.writeln('💎 صافي مكسب الشركة من فروق الأسعار,${provider.totalCompanyGrossProfit.toStringAsFixed(0)},(إيرادات العملاء - مستحقات التمريض)');
    csv.writeln('');

    // Summary financials
    csv.writeln('--- المؤشرات المالية الإجمالية ---,,');
    csv.writeln('البند المالي,القيمة بالجنيه المصري (ج.م),التفاصيل والملاحظات');
    csv.writeln('إجمالي المقبوضات النقدية والبنكية المحصلة,${provider.totalPaymentsCollected.toStringAsFixed(0)},المبالغ المستلمة فعلياً من العملاء');
    csv.writeln('إجمالي المصروفات التشغيلية والرواتب,${provider.totalExpenses.toStringAsFixed(0)},كافة المصروفات المسجلة');
    csv.writeln('صافي الأرباح التشغيلية المحققة,${provider.netAccruedProfit.toStringAsFixed(0)},(إيرادات الخدمة - المصروفات)');
    csv.writeln('صافي التدفق النقدي الفعلي,${provider.netCashFlow.toStringAsFixed(0)},(المقبوضات - المصروفات)');
    csv.writeln('مستحقات الشركة طرف العملاء (مديونيات),${provider.totalClientDebtsOwedToCompany.toStringAsFixed(0)},ديون سابقة ومستحقات خدمة جاري تحصيلها');
    csv.writeln('مستحقات العملاء مقدماً لدى الشركة (أرصدة دائنة),${provider.totalClientAdvancesHeldByCompany.toStringAsFixed(0)},أرصدة افتتاحية ودفعات مقدمة تغطي أيام قادمة');
    csv.writeln('');

    // Expenses breakdown
    csv.writeln('--- تفصيل المصروفات حسب البند ---,,');
    final Map<String, double> expensesByCategory = {};
    for (var exp in provider.expenses) {
      expensesByCategory[exp.categoryArabic] = (expensesByCategory[exp.categoryArabic] ?? 0) + exp.amount;
    }

    for (var entry in expensesByCategory.entries) {
      csv.writeln('${entry.key},${entry.value.toStringAsFixed(0)},مصروفات');
    }

    final fileDateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    saveAndDownloadFile(
      csv.toString(),
      'التقرير_المالي_الشامل_والأرصدة_إيليت_جراند_$fileDateStr.csv',
      'text/csv;charset=utf-8;',
    );
  }

  // 5. Export Detailed Service Days / Shifts Log to Excel
  static void exportServiceDaysToExcel(AppProvider provider) {
    final StringBuffer csv = StringBuffer();

    csv.writeln('التاريخ,اسم العميل / الحالة,اسم الممرض,نوع الوردية,سعر اليوم للعميل (ج.م),يومية الممرض (ج.م),مكسب الشركة من اليومية (ج.م),سُجل بواسطة,ملاحظات');

    for (var day in provider.serviceDays) {
      final row = [
        _dateFormat.format(day.date),
        _escape(day.clientName),
        _escape(day.nurseName),
        _escape(day.shiftTypeArabic),
        day.clientPrice.toStringAsFixed(0),
        day.nursePrice.toStringAsFixed(0),
        day.companyDayProfit.toStringAsFixed(0),
        _escape(day.recordedBy),
        _escape(day.notes),
      ];
      csv.writeln(row.join(','));
    }

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    saveAndDownloadFile(
      csv.toString(),
      'سجل_أيام_الخدمة_والشفتات_إيليت_جراند_$dateStr.csv',
      'text/csv;charset=utf-8;',
    );
  }

  // 6. Export Nurses Payroll & Days Breakdown to Excel
  static void exportNursesReportToExcel(AppProvider provider) {
    final StringBuffer csv = StringBuffer();

    csv.writeln('اسم الممرض,إجمالي عدد الأيام المنفذة,إجمالي المستحقات المالية (ج.م),الحالات التي عمل معها');

    final nurseDays = provider.allNursesDaysCount;
    final nurseDues = provider.allNursesAccruedDues;
    final nurseServiceDays = provider.allNursesServiceDays;

    for (var entry in nurseDays.entries) {
      final nurseName = entry.key;
      final daysCount = entry.value;
      final dues = nurseDues[nurseName] ?? 0.0;
      final shifts = nurseServiceDays[nurseName] ?? [];
      final clientsSet = shifts.map((s) => s.clientName).toSet().join(' - ');

      final row = [
        _escape(nurseName),
        daysCount.toString(),
        dues.toStringAsFixed(0),
        _escape(clientsSet),
      ];
      csv.writeln(row.join(','));
    }

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    saveAndDownloadFile(
      csv.toString(),
      'كشف_أيام_ومستحقات_التمريض_إيليت_جراند_$dateStr.csv',
      'text/csv;charset=utf-8;',
    );
  }

  static String _escape(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
