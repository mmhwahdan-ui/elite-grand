import 'package:excel/excel.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/client_model.dart';
import '../models/expense_model.dart';
import '../models/payment_model.dart';
import '../models/partner_settlement_model.dart';
import '../models/period_financial_summary.dart';
import '../providers/app_provider.dart';

import 'export_stub.dart'
    if (dart.library.js_interop) 'export_web.dart';

class ExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');
  static const String _xlsxMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  // Styles
  static final CellStyle _headerStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#0A2540'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _subHeaderStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#1E5180'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _titleStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#0052CC'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _totalRowStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static CellValue _cell(dynamic val) {
    if (val == null) return TextCellValue('');
    if (val is int) return IntCellValue(val);
    if (val is double) {
      if (val == val.roundToDouble()) {
        return IntCellValue(val.toInt());
      }
      return DoubleCellValue(double.parse(val.toStringAsFixed(2)));
    }
    if (val is bool) return TextCellValue(val ? 'نعم' : 'لا');
    return TextCellValue(val.toString());
  }

  static void _styleRow(Sheet sheet, int rowIndex, int colCount, CellStyle style) {
    for (int col = 0; col < colCount; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.cellStyle = style;
    }
  }

  static Sheet _createSheet(Excel excel, String sheetName) {
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];
    sheet.isRTL = true;
    return sheet;
  }

  static void _saveExcel(Excel excel, String fileName) {
    final bytes = excel.save();
    if (bytes != null) {
      saveAndDownloadBytes(bytes, fileName, _xlsxMimeType);
    }
  }

  // 1. Export Clients Ledger to Excel (.xlsx)
  static void exportClientsToExcel(AppProvider provider) {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'العملاء والحالات');

    final headers = [
      'اسم العميل',
      'نوع العميل',
      'الرصيد الافتتاحي (ج.م)',
      'رقم الهاتف',
      'العنوان',
      'الحالة الصحية',
      'نوع الشيفت',
      'سعر العميل (ج.م)',
      'يومية الممرض (ج.م)',
      'مكسب الشركة اليومي (ج.م)',
      'تاريخ البدء',
      'تاريخ الإنهاء',
      'عدد الأيام المنفذة',
      'إجمالي تعاقد العميل (ج.م)',
      'إجمالي مستحق التمريض (ج.م)',
      'إجمالي مكسب الشركة (ج.م)',
      'المدفوع نقداً (ج.م)',
      'الرصيد ومستحقات الشركة',
      'حالة الخدمة',
      'الممرض المسند',
      'ملاحظات',
    ];

    sheet.appendRow(headers.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, headers.length, _headerStyle);

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
        c.name,
        c.isExistingClient ? 'عميل حالي' : 'عميل جديد',
        c.openingBalance,
        c.phone,
        c.address,
        c.healthCondition,
        c.serviceTypeArabic,
        c.dailyPrice,
        c.nurseDailyPrice,
        c.dailyCompanyProfit,
        c.startDate != null ? _dateFormat.format(c.startDate!) : 'لم تبدأ',
        c.endDate != null ? _dateFormat.format(c.endDate!) : (c.startDate != null ? 'مستمرة' : '-'),
        servedDays,
        clientCost,
        nurseCost,
        profit,
        paid,
        balanceText,
        c.statusArabic,
        c.nurseAssigned ?? '-',
        c.notes,
      ];

      sheet.appendRow(row.map(_cell).toList());
    }

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _saveExcel(excel, 'تقرير_حالات_وعملاء_إيليت_جراند_$dateStr.xlsx');
  }

  // 2. Export Payments Ledger to Excel (.xlsx)
  static void exportPaymentsToExcel(AppProvider provider) {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'المقبوضات والتحصيلات');

    final headers = [
      'التاريخ',
      'اسم العميل',
      'المبلغ المحصل (ج.م)',
      'مكان التحصيل والإيداع',
      'المستلم',
      'ملاحظات',
    ];

    sheet.appendRow(headers.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, headers.length, _headerStyle);

    double totalAmount = 0;
    for (var p in provider.payments) {
      totalAmount += p.amount;
      final row = [
        _dateFormat.format(p.paymentDate),
        p.clientName,
        p.amount,
        p.channelArabic,
        p.receivedBy,
        p.notes,
      ];
      sheet.appendRow(row.map(_cell).toList());
    }

    // Total Row
    final totalRow = ['الإجمالي', '', totalAmount, '', '', ''];
    sheet.appendRow(totalRow.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, headers.length, _totalRowStyle);

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _saveExcel(excel, 'سجل_مقبوضات_وتحصيلات_إيليت_جراند_$dateStr.xlsx');
  }

  // 3. Export Expenses to Excel (.xlsx)
  static void exportExpensesToExcel(AppProvider provider) {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'المصروفات');

    final headers = [
      'التاريخ',
      'بند المصروف',
      'بيان وتفاصيل المصروف',
      'المبلغ (ج.م)',
      'قناة الدفع والصرف',
      'سُجل بواسطة',
      'يخص مريض',
      'ملاحظات',
    ];

    sheet.appendRow(headers.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, headers.length, _headerStyle);

    double totalAmount = 0;
    for (var exp in provider.expenses) {
      totalAmount += exp.amount;
      String clientName = 'عام للشركة';
      if (exp.relatedClientId != null) {
        final matches = provider.clients.where((c) => c.id == exp.relatedClientId);
        if (matches.isNotEmpty) {
          clientName = matches.first.name;
        }
      }

      final row = [
        _dateFormat.format(exp.expenseDate),
        exp.categoryArabic,
        exp.title,
        exp.amount,
        exp.channelArabic,
        exp.recordedBy,
        clientName,
        exp.notes,
      ];
      sheet.appendRow(row.map(_cell).toList());
    }

    // Total Row
    final totalRow = ['الإجمالي', '', '', totalAmount, '', '', '', ''];
    sheet.appendRow(totalRow.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, headers.length, _totalRowStyle);

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _saveExcel(excel, 'تقرير_مصروفات_إيليت_جراند_$dateStr.xlsx');
  }

  // 4. Export Comprehensive Financial Statement to Excel (.xlsx)
  static void exportFinancialReportToExcel(AppProvider provider) {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'التقرير المالي الشامل');

    final nowStr = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());

    // Title
    sheet.appendRow([_cell('تقرير المركز المالي والأرباح التشغيلية وحسابات البنوك - شركة إيليت جراند')]);
    _styleRow(sheet, sheet.maxRows - 1, 5, _titleStyle);
    sheet.appendRow([_cell('تاريخ استخراج التقرير: $nowStr')]);
    sheet.appendRow([_cell('')]);

    // Section 1: Treasury & Liquidity
    sheet.appendRow([_cell('أرصدة الحسابات ومصادر السيولة النقدية والبنكية')]);
    _styleRow(sheet, sheet.maxRows - 1, 5, _subHeaderStyle);

    final treasuryHeaders = [
      'الحساب / القناة',
      'رصيد أول المدة (ج.م)',
      'إجمالي التحصيلات (الوارد)',
      'إجمالي المصروفات (المنصرف)',
      'الرصيد الفعلي الحالي (ج.م)',
    ];
    sheet.appendRow(treasuryHeaders.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 5, _headerStyle);

    sheet.appendRow([
      '📱 المحفظة الإلكترونية (فودافون كاش / إنستاباي)',
      provider.walletOpeningBalance,
      provider.walletCollections,
      provider.walletExpenses,
      provider.currentWalletBalance,
    ].map(_cell).toList());

    sheet.appendRow([
      '🏦 الحساب البنكي (تحويلات وإيداعات)',
      provider.bankOpeningBalance,
      provider.bankCollections,
      provider.bankExpenses,
      provider.currentBankBalance,
    ].map(_cell).toList());

    sheet.appendRow([
      '💵 الخزينة النقدية (كاش المقر والمندوبين)',
      provider.cashOpeningBalance,
      provider.cashCollections,
      provider.cashExpenses,
      provider.currentCashBalance,
    ].map(_cell).toList());

    sheet.appendRow([
      '💰 إجمالي السيولة المتاحة للشركة',
      '',
      '',
      '',
      provider.totalTreasuryBalance,
    ].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 5, _totalRowStyle);

    sheet.appendRow([_cell('')]);

    // Section 2: Case Profitability
    sheet.appendRow([_cell('تصفية أرباح الحالات وفروق الأسعار (العميل vs التمريض)')]);
    _styleRow(sheet, sheet.maxRows - 1, 3, _subHeaderStyle);

    sheet.appendRow(['البيان المالي', 'المبلغ (ج.م)', 'ملاحظات'].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 3, _headerStyle);

    sheet.appendRow([
      'إجمالي تعاقدات العملاء (إيرادات الخدمة المحققة)',
      provider.totalAccruedRevenues,
      'مجموع الأيام × سعر العميل',
    ].map(_cell).toList());

    sheet.appendRow([
      'إجمالي مستحقات ويوميات التمريض المنقضية',
      provider.totalNurseAccruedCosts,
      'مجموع الأيام × يومية الممرض',
    ].map(_cell).toList());

    sheet.appendRow([
      '💎 صافي مكسب الشركة من فروق الأسعار',
      provider.totalCompanyGrossProfit,
      'إيرادات العملاء - مستحقات التمريض',
    ].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 3, _totalRowStyle);

    sheet.appendRow([_cell('')]);

    // Section 3: Summary Indicators
    sheet.appendRow([_cell('المؤشرات المالية الإجمالية')]);
    _styleRow(sheet, sheet.maxRows - 1, 3, _subHeaderStyle);

    sheet.appendRow(['البند المالي', 'القيمة بالجنيه المصري (ج.م)', 'التفاصيل والملاحظات'].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 3, _headerStyle);

    sheet.appendRow(['إجمالي المقبوضات النقدية والبنكية المحصلة', provider.totalPaymentsCollected, 'المبالغ المستلمة فعلياً من العملاء'].map(_cell).toList());
    sheet.appendRow(['إجمالي المصروفات التشغيلية والرواتب', provider.totalExpenses, 'كافة المصروفات المسجلة'].map(_cell).toList());
    sheet.appendRow(['صافي الأرباح التشغيلية المحققة', provider.netAccruedProfit, 'إيرادات الخدمة - المصروفات'].map(_cell).toList());
    sheet.appendRow(['صافي التدفق النقدي الفعلي', provider.netCashFlow, 'المقبوضات - المصروفات'].map(_cell).toList());
    sheet.appendRow(['مستحقات الشركة طرف العملاء (مديونيات)', provider.totalClientDebtsOwedToCompany, 'ديون سابقة ومستحقات خدمة جاري تحصيلها'].map(_cell).toList());
    sheet.appendRow(['مستحقات العملاء مقدماً لدى الشركة (أرصدة دائنة)', provider.totalClientAdvancesHeldByCompany, 'أرصدة افتتاحية ودفعات مقدمة تغطي أيام قادمة'].map(_cell).toList());

    sheet.appendRow([_cell('')]);

    // Section 4: Expenses by Category
    sheet.appendRow([_cell('تفصيل المصروفات حسب البند')]);
    _styleRow(sheet, sheet.maxRows - 1, 3, _subHeaderStyle);

    sheet.appendRow(['بند المصروف', 'المبلغ (ج.م)', 'النوع'].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 3, _headerStyle);

    final Map<String, double> expensesByCategory = {};
    for (var exp in provider.expenses) {
      expensesByCategory[exp.categoryArabic] = (expensesByCategory[exp.categoryArabic] ?? 0) + exp.amount;
    }
    for (var entry in expensesByCategory.entries) {
      sheet.appendRow([entry.key, entry.value, 'مصروفات تشغيلية'].map(_cell).toList());
    }

    sheet.appendRow([_cell('')]);

    // Section 5: Periodic Net Profits (Daily, Weekly, Monthly Cycle 23)
    sheet.appendRow([_cell('مؤشرات صافي الأرباح الدورية (اليومي، الأسبوعي، ودورة نهاية الشهر حتى يوم 23)')]);
    _styleRow(sheet, sheet.maxRows - 1, 9, _subHeaderStyle);

    final periodicHeaders = [
      'الفترة المحاسبية',
      'إيراد التعاقدات (ج.م)',
      'مستحقات التمريض (ج.م)',
      'ربح فروق الأسعار (ج.م)',
      'المصروفات التشغيلية (ج.م)',
      'صافي الربح الفعلي (ج.م)',
      'هامش الربح',
      'الورديات المنفذة',
      'الحالات المخدومة',
    ];
    sheet.appendRow(periodicHeaders.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, periodicHeaders.length, _headerStyle);

    final daily = provider.getDailyNetProfitSummary();
    final weekly = provider.getWeeklyNetProfitSummary();
    final monthly = provider.getMonthlyNetProfitSummary();

    sheet.appendRow([
      'اليومي (اليوم)',
      daily.revenues,
      daily.nurseCosts,
      daily.grossProfit,
      daily.expenses,
      daily.netProfit,
      '${daily.profitMargin.toStringAsFixed(1)}%',
      daily.shiftsCount,
      daily.activeClientsCount,
    ].map(_cell).toList());

    sheet.appendRow([
      'الأسبوعي (آخر 7 أيام)',
      weekly.revenues,
      weekly.nurseCosts,
      weekly.grossProfit,
      weekly.expenses,
      weekly.netProfit,
      '${weekly.profitMargin.toStringAsFixed(1)}%',
      weekly.shiftsCount,
      weekly.activeClientsCount,
    ].map(_cell).toList());

    sheet.appendRow([
      'الشهري (${monthly.periodTitle})',
      monthly.revenues,
      monthly.nurseCosts,
      monthly.grossProfit,
      monthly.expenses,
      monthly.netProfit,
      '${monthly.profitMargin.toStringAsFixed(1)}%',
      monthly.shiftsCount,
      monthly.activeClientsCount,
    ].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, periodicHeaders.length, _totalRowStyle);

    sheet.appendRow([_cell('')]);

    // Monthly Partner Distributions Summary
    sheet.appendRow([_cell('توزيع أرباح دورة يوم 23 الشهرية على الشركاء:')]);
    _styleRow(sheet, sheet.maxRows - 1, 4, _subHeaderStyle);

    final partnerHeaders = ['الشريك والصفة', 'النسبة المعتمدة', 'مبلغ صافي الربح المستحق (ج.م)', 'ملاحظات الضمان'];
    sheet.appendRow(partnerHeaders.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, partnerHeaders.length, _headerStyle);

    sheet.appendRow([
      'أ/ وهدان (المدير العام)',
      '40%',
      monthly.wahdanShare,
      'حصة أساسية بعد المصروفات',
    ].map(_cell).toList());

    sheet.appendRow([
      'أ/ شيماء (المتابعة والتشغيل)',
      '40%',
      monthly.shimaaShare,
      monthly.netProfit > 0 && (monthly.netProfit * 0.40 < 6000)
          ? 'تم تطبيق الحد الأدنى للضمان (6000 ج.م)'
          : 'حصة أساسية 40%',
    ].map(_cell).toList());

    sheet.appendRow([
      'أ/ زيزو (الحسابات والمالية)',
      '20%',
      monthly.zezoShare,
      'حصة أساسية 20%',
    ].map(_cell).toList());

    sheet.appendRow([
      'حالة تصفية دورة الشهر (يوم 23)',
      monthly.daysRemainingUntil23 != null && monthly.daysRemainingUntil23! > 0
          ? 'متبقي ${monthly.daysRemainingUntil23} يوم على التصفية'
          : 'موعد تصفية الشهر اليوم',
      monthly.netProfit,
      'الدورة من 24 الشهر السابق إلى 23 الشهر الحالي',
    ].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, partnerHeaders.length, _totalRowStyle);

    final fileDateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _saveExcel(excel, 'التقرير_المالي_الشامل_والأرصدة_إيليت_جراند_$fileDateStr.xlsx');
  }

  // 5. Export Detailed Service Days / Shifts Log to Excel (.xlsx)
  static void exportServiceDaysToExcel(AppProvider provider) {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'سجل الورديات');

    final headers = [
      'التاريخ',
      'اسم العميل / الحالة',
      'اسم الممرض',
      'نوع الوردية',
      'سعر اليوم للعميل (ج.م)',
      'يومية الممرض (ج.م)',
      'مكسب الشركة من اليومية (ج.م)',
      'سُجل بواسطة',
      'ملاحظات',
    ];

    sheet.appendRow(headers.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, headers.length, _headerStyle);

    for (var day in provider.serviceDays) {
      final row = [
        _dateFormat.format(day.date),
        day.clientName,
        day.nurseName,
        day.shiftTypeArabic,
        day.clientPrice,
        day.nursePrice,
        day.companyDayProfit,
        day.recordedBy,
        day.notes,
      ];
      sheet.appendRow(row.map(_cell).toList());
    }

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _saveExcel(excel, 'سجل_أيام_الخدمة_والشفتات_إيليت_جراند_$dateStr.xlsx');
  }

  // 6. Export All Nurses Comprehensive Ledger to Excel (.xlsx)
  static void exportNursesReportToExcel(AppProvider provider) {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'حسابات أطقم التمريض');

    final headers = [
      'اسم الممرض',
      'إجمالي عدد أيام العمل',
      'إجمالي الأجر المستحق (ج.م)',
      'إجمالي السلف المنصرفة (ج.م)',
      'إجمالي دفعات المستحقات (ج.م)',
      'إجمالي ما استلمه (ج.م)',
      'صافي باقي المستحق للممرض (ج.م)',
      'الحالات التي عمل معها',
    ];

    sheet.appendRow(headers.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, headers.length, _headerStyle);

    double totalDays = 0;
    double totalEarned = 0;
    double totalAdvances = 0;
    double totalPayouts = 0;
    double totalReceivedAll = 0;
    double totalRemaining = 0;

    final nurseNames = provider.allNurseNames;
    for (var nurseName in nurseNames) {
      final days = provider.getNurseDaysCount(nurseName);
      final earned = provider.getNurseTotalEarned(nurseName);
      final advances = provider.getNurseTotalAdvances(nurseName);
      final payouts = provider.getNurseTotalPayouts(nurseName);
      final totalReceived = provider.getNurseTotalReceived(nurseName);
      final remaining = provider.getNurseRemainingBalance(nurseName);
      final shifts = provider.getNurseShifts(nurseName);
      final clientsSet = shifts.map((s) => s.clientName).toSet().join(' - ');

      totalDays += days;
      totalEarned += earned;
      totalAdvances += advances;
      totalPayouts += payouts;
      totalReceivedAll += totalReceived;
      totalRemaining += remaining;

      final row = [
        nurseName,
        days,
        earned,
        advances,
        payouts,
        totalReceived,
        remaining,
        clientsSet,
      ];
      sheet.appendRow(row.map(_cell).toList());
    }

    // Total Row
    final totalRow = [
      'الإجمالي',
      totalDays,
      totalEarned,
      totalAdvances,
      totalPayouts,
      totalReceivedAll,
      totalRemaining,
      '',
    ];
    sheet.appendRow(totalRow.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, headers.length, _totalRowStyle);

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _saveExcel(excel, 'كشف_حسابات_ومستحقات_وسلف_التمريض_إيليت_جراند_$dateStr.xlsx');
  }

  // 7. Export Single Nurse Detailed Statement to Excel (.xlsx)
  static void exportSingleNurseStatementToExcel(AppProvider provider, String nurseName) {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'كشف حساب $nurseName');

    final days = provider.getNurseDaysCount(nurseName);
    final earned = provider.getNurseTotalEarned(nurseName);
    final advances = provider.getNurseTotalAdvances(nurseName);
    final payouts = provider.getNurseTotalPayouts(nurseName);
    final totalReceived = provider.getNurseTotalReceived(nurseName);
    final remaining = provider.getNurseRemainingBalance(nurseName);

    // Title
    sheet.appendRow([_cell('كشف حساب تفصيلي للممرض: $nurseName - شركة إيليت جراند')]);
    _styleRow(sheet, sheet.maxRows - 1, 6, _titleStyle);
    sheet.appendRow([_cell('تاريخ التقرير: ${_dateFormat.format(DateTime.now())}')]);
    sheet.appendRow([_cell('')]);

    // Summary Block
    sheet.appendRow([_cell('الملخص المالي للممرض')]);
    _styleRow(sheet, sheet.maxRows - 1, 3, _subHeaderStyle);

    sheet.appendRow(['البيان', 'القيمة', 'الوحدة'].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 3, _headerStyle);

    sheet.appendRow(['إجمالي أيام العمل المنفذة', days, 'يوم'].map(_cell).toList());
    sheet.appendRow(['إجمالي المستحقات والأجر عن الورديات', earned, 'ج.م'].map(_cell).toList());
    sheet.appendRow(['إجمالي السلف المأخوذة', advances, 'ج.م'].map(_cell).toList());
    sheet.appendRow(['إجمالي الدفعات المنصرفة', payouts, 'ج.م'].map(_cell).toList());
    sheet.appendRow(['إجمالي ما تم استلامه (سلف + دفعات)', totalReceived, 'ج.م'].map(_cell).toList());
    sheet.appendRow(['صافي باقي المستحق للممرض طرف الشركة', remaining, 'ج.م'].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 3, _totalRowStyle);

    sheet.appendRow([_cell('')]);

    // Table 1: Shifts worked
    sheet.appendRow([_cell('جدول الورديات وأيام العمل المنفذة')]);
    _styleRow(sheet, sheet.maxRows - 1, 6, _subHeaderStyle);

    final shiftHeaders = [
      'التاريخ',
      'اسم العميل / الحالة',
      'نوع الشيفت',
      'سعر اليوم للممرض (ج.م)',
      'سُجل بواسطة',
      'ملاحظات',
    ];
    sheet.appendRow(shiftHeaders.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 6, _headerStyle);

    final shifts = provider.getNurseShifts(nurseName);
    for (var s in shifts) {
      final row = [
        _dateFormat.format(s.date),
        s.clientName,
        s.shiftTypeArabic,
        s.nursePrice,
        s.recordedBy,
        s.notes,
      ];
      sheet.appendRow(row.map(_cell).toList());
    }

    sheet.appendRow([_cell('')]);

    // Table 2: Advances and payouts
    sheet.appendRow([_cell('جدول السلف والدفعات المالية المنصرفة للممرض')]);
    _styleRow(sheet, sheet.maxRows - 1, 6, _subHeaderStyle);

    final transHeaders = [
      'التاريخ',
      'نوع العملية',
      'المبلغ (ج.م)',
      'طريقة الصرف',
      'سُجل بواسطة',
      'ملاحظات',
    ];
    sheet.appendRow(transHeaders.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 6, _headerStyle);

    final trans = provider.getNurseTransactions(nurseName);
    for (var t in trans) {
      final row = [
        _dateFormat.format(t.date),
        t.typeArabic,
        t.amount,
        t.channelArabic,
        t.recordedBy,
        t.notes,
      ];
      sheet.appendRow(row.map(_cell).toList());
    }

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _saveExcel(excel, 'كشف_حساب_الممرض_${nurseName}_$dateStr.xlsx');
  }

  // 8. Export Partner Settlements (Day 23 Cycle) to Excel (.xlsx)
  static void exportPartnerSettlementToExcel(
    AppProvider provider,
    Map<String, dynamic> calc,
    DateTime settlementDate,
  ) {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'تصفية دورة 23');

    final cycleTitle = 'تصفية أرباح دورة 23 ${_dateFormat.format(settlementDate)}';

    // Title
    sheet.appendRow([_cell('تقرير $cycleTitle - شركة إيليت جراند للتمريض المنزلي')]);
    _styleRow(sheet, sheet.maxRows - 1, 7, _titleStyle);
    sheet.appendRow([_cell('تاريخ التصفية: ${_dateFormat.format(settlementDate)}')]);
    sheet.appendRow([_cell('الفترة المحاسبية: من ${_dateFormat.format(calc['startDate'] as DateTime)} إلى ${_dateFormat.format(calc['endDate'] as DateTime)}')]);
    sheet.appendRow([_cell('')]);

    // Treasury & Profit Summary
    sheet.appendRow([_cell('ملخص أرباح الشركة والسيولة بالخزينة')]);
    _styleRow(sheet, sheet.maxRows - 1, 3, _subHeaderStyle);

    sheet.appendRow(['البيان', 'المبلغ (ج.م)', 'ملاحظات'].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 3, _headerStyle);

    sheet.appendRow(['صافي أرباح الشركة في هذه الدورة', calc['profit'], 'صافي الدورة المنتهية'].map(_cell).toList());
    sheet.appendRow(['إجمالي السيولة المتاحة بالخزائن قبل الصرف', calc['treasuryBefore'], 'كاش + بنك + محافظ'].map(_cell).toList());
    sheet.appendRow(['إجمالي المبالغ المنصرفة للشركاء', calc['totalDisbursed'], 'المبالغ المعتمدة'].map(_cell).toList());
    sheet.appendRow(['باقي النقدية والسيولة بالخزينة بعد الصرف', calc['remainingTreasury'], 'الرصيد المتبقي بالخزينة'].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 3, _totalRowStyle);

    sheet.appendRow([_cell('')]);

    // Partners Share Table
    sheet.appendRow([_cell('جدول تصفية أرباح الشركاء وتوزيع الأرباح وخصم السلف')]);
    _styleRow(sheet, sheet.maxRows - 1, 7, _subHeaderStyle);

    final partnerHeaders = [
      'الشريك',
      'النسبة المئوية',
      'الربح الأساسي (ج.م)',
      'تعديل ضمان شيماء (6000 ج.م)',
      'الربح بعد الضمان (ج.م)',
      'استقطاع سلف الشريك (ج.م)',
      'صافي المستحق للصرف للشريك (ج.م)',
    ];
    sheet.appendRow(partnerHeaders.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 7, _headerStyle);

    // Wahdan (40%)
    sheet.appendRow([
      'أ/ وهدان (المدير العام)',
      '40%',
      calc['wahdanBase'],
      calc['wahdanAdminDeduction'] > 0
          ? 'خصم إداري: -${(calc['wahdanAdminDeduction'] as double).toStringAsFixed(0)} ج.م'
          : 'لا يوجد خصم',
      calc['wahdanFinal'],
      calc['wahdanLoan'],
      calc['wahdanNet'],
    ].map(_cell).toList());

    // Shimaa (40% with minimum guarantee)
    sheet.appendRow([
      'أ/ شيماء (المتابعة والتشغيل)',
      '40% (ضمان 6000)',
      calc['shimaaBase'],
      calc['shimaaSubsidy'] > 0
          ? 'دعم ضمان: +${(calc['shimaaSubsidy'] as double).toStringAsFixed(0)} ج.م'
          : 'حصة أصلية كاملة',
      calc['shimaaFinal'],
      calc['shimaaLoan'],
      calc['shimaaNet'],
    ].map(_cell).toList());

    // Zezo (20%)
    sheet.appendRow([
      'أ/ زيزو (الحسابات والمالية)',
      '20%',
      calc['zezoBase'],
      calc['zezoAdminDeduction'] > 0
          ? 'خصم إداري: -${(calc['zezoAdminDeduction'] as double).toStringAsFixed(0)} ج.م'
          : 'لا يوجد خصم',
      calc['zezoFinal'],
      calc['zezoLoan'],
      calc['zezoNet'],
    ].map(_cell).toList());

    // Total Row
    sheet.appendRow([
      'الإجمالي المنصرف',
      '100%',
      '',
      '',
      '',
      '',
      calc['totalDisbursed'],
    ].map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, 7, _totalRowStyle);

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _saveExcel(excel, 'تصفية_أرباح_الشركاء_دورة_23_$dateStr.xlsx');
  }

  // 9. Export Partner Loans Ledger to Excel (.xlsx)
  static void exportPartnerLoansToExcel(AppProvider provider) {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'سجل سلف الشركاء');

    final headers = [
      'اسم الشريك',
      'تاريخ السلفة',
      'إجمالي مبلغ السلفة (ج.م)',
      'نظام السداد',
      'القسط الشهري (ج.م)',
      'المبلغ المسدد (ج.م)',
      'المتبقي طرف الشريك (ج.م)',
      'حالة السلفة',
      'وسيلة الصرف',
      'ملاحظات',
    ];

    sheet.appendRow(headers.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, headers.length, _headerStyle);

    double totalLoans = 0;
    double totalPaid = 0;
    double totalRemaining = 0;

    for (var loan in provider.partnerLoans) {
      totalLoans += loan.totalAmount;
      totalPaid += loan.paidAmount;
      totalRemaining += loan.remainingAmount;

      final row = [
        loan.partnerName,
        _dateFormat.format(loan.date),
        loan.totalAmount,
        loan.repaymentTypeArabic,
        loan.monthlyDeduction,
        loan.paidAmount,
        loan.remainingAmount,
        loan.isFullyPaid ? 'تم السداد بالكامل' : 'جاري السداد',
        loan.channelArabic,
        loan.notes,
      ];
      sheet.appendRow(row.map(_cell).toList());
    }

    // Total Row
    final totalRow = [
      'الإجمالي',
      '',
      totalLoans,
      '',
      '',
      totalPaid,
      totalRemaining,
      '',
      '',
      '',
    ];
    sheet.appendRow(totalRow.map(_cell).toList());
    _styleRow(sheet, sheet.maxRows - 1, headers.length, _totalRowStyle);

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _saveExcel(excel, 'سجل_سلف_الشركاء_إيليت_جراند_$dateStr.xlsx');
  }
}
