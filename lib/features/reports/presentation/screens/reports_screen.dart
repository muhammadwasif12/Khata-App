/// Reports Screen
/// Shows business summary, customer statements, and cashbook reports with date filters and PDF export.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../cashbook/domain/entities/cash_entry_entity.dart';
import '../../../customers/domain/entities/party_entity.dart';
import '../providers/report_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Auto-generate first tab report after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoGenerate(0));
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _autoGenerate(_tabController.index);
    }
  }

  String get _businessName {
    final businesses = ref.read(businessesProvider).valueOrNull ?? [];
    final activeId = ref.read(activeBusinessIdProvider);
    return businesses
            .where((b) => b.id == activeId)
            .map((b) => b.name)
            .firstOrNull ??
        AppStrings.appName;
  }

  String? get _activeBusinessId => ref.read(activeBusinessIdProvider);

  void _autoGenerate(int tabIndex) {
    final activeId = _activeBusinessId;
    if (activeId == null) return;
    final notifier = ref.read(reportProvider.notifier);
    notifier.setActiveTab(tabIndex);
    if (tabIndex == 0) {
      notifier.generatePartyReport(activeId, PartyType.customer, 0);
    } else if (tabIndex == 1) {
      notifier.generatePartyReport(activeId, PartyType.supplier, 1);
    } else {
      notifier.generateCashbookReport(activeId);
    }
  }

  Future<void> _selectDate(bool isFrom) async {
    final reportState = ref.read(reportProvider);
    final initial = isFrom ? reportState.fromDate : reportState.toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ur', 'PK'),
    );
    if (picked != null) {
      final notifier = ref.read(reportProvider.notifier);
      if (isFrom) {
        notifier.setDateRange(picked, reportState.toDate);
      } else {
        notifier.setDateRange(reportState.fromDate, picked);
      }
      _autoGenerate(_tabController.index);
    }
  }

  Future<pw.Document> _buildPdf(ReportData data) async {
    final reportState = ref.read(reportProvider);
    await PdfHelper.loadFonts();
    final pdf = pw.Document();

    final tabIndex = _tabController.index;
    String reportTitle = '';
    if (tabIndex == 0) reportTitle = 'کسٹمر رپورٹ';
    else if (tabIndex == 1) reportTitle = 'سپلائر رپورٹ';
    else reportTitle = 'کیش رپورٹ';

    String fmtAmt(double amt) {
      final f = CurrencyFormatter.formatShort(amt);
      return f.replaceAll('Rs', '').trim();
    }

    final partyTableRows = <pw.TableRow>[];
    if (data.partyItems.isNotEmpty) {
      partyTableRows.add(PdfHelper.tableHeaderRowWidgets([
        PdfHelper.urduText('بقیہ', fontSize: 10, isBold: true, color: PdfHelper.darkText),
        PdfHelper.urduText('قسم', fontSize: 10, isBold: true, color: PdfHelper.darkText),
        PdfHelper.urduText('نام', fontSize: 10, isBold: true, color: PdfHelper.darkText),
        pw.Directionality(textDirection: pw.TextDirection.ltr, child: pw.Text('#', style: pw.TextStyle(font: PdfHelper.bold, fontSize: 10, color: PdfHelper.darkText))),
      ]));
      for (int i = 0; i < data.partyItems.length; i++) {
        final item = data.partyItems[i];
        final bg = PdfHelper.rowColor(i);
        partyTableRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: bg),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(fmtAmt(item.balance), style: pw.TextStyle(font: PdfHelper.regular, fontSize: 10, fontWeight: pw.FontWeight.bold, color: item.isCredit ? PdfHelper.creditGreen : PdfHelper.debitRed), textAlign: pw.TextAlign.center),
              )
            ),
            PdfHelper.tableCell(
                item.isCredit ? AppStrings.lenaHai : AppStrings.denaHai,
                color: item.isCredit ? PdfHelper.creditGreen : PdfHelper.debitRed, isBold: true),
            PdfHelper.tableCell(item.party.name),
            PdfHelper.tableCell('${i + 1}'),
          ],
        ));
      }
    }

    final cashTableRows = <pw.TableRow>[];
    if (data.cashEntries.isNotEmpty) {
      cashTableRows.add(PdfHelper.tableHeaderRowWidgets([
        PdfHelper.urduText('رقم', fontSize: 10, isBold: true, color: PdfHelper.darkText),
        PdfHelper.urduText('قسم', fontSize: 10, isBold: true, color: PdfHelper.darkText),
        PdfHelper.urduText('نوٹ', fontSize: 10, isBold: true, color: PdfHelper.darkText),
        PdfHelper.urduText('تاریخ', fontSize: 10, isBold: true, color: PdfHelper.darkText),
        pw.Directionality(textDirection: pw.TextDirection.ltr, child: pw.Text('#', style: pw.TextStyle(font: PdfHelper.bold, fontSize: 10, color: PdfHelper.darkText))),
      ]));
      for (int i = 0; i < data.cashEntries.length; i++) {
        final e = data.cashEntries[i];
        final bg = PdfHelper.rowColor(i);
        final isIn = e.cashType == CashType.cashIn;
        cashTableRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: bg),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(fmtAmt(e.amount), style: pw.TextStyle(font: PdfHelper.regular, fontSize: 10, fontWeight: pw.FontWeight.bold, color: isIn ? PdfHelper.creditGreen : PdfHelper.debitRed), textAlign: pw.TextAlign.center),
              )
            ),
            PdfHelper.tableCell(isIn ? 'نقد آمد' : 'نقد خرچ',
                color: isIn ? PdfHelper.creditGreen : PdfHelper.debitRed, isBold: true),
            PdfHelper.tableCell(e.note.isNotEmpty ? e.note : '-'),
            PdfHelper.tableCell(DateFormatter.formatDateShort(e.entryDate)),
            PdfHelper.tableCell('${i + 1}'),
          ],
        ));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.only(top: 20, bottom: 20, left: 24, right: 24),
        theme: PdfHelper.theme,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            PdfHelper.headerBar(businessName: _businessName, phone: '', appName: reportTitle),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text('(${DateFormatter.formatDateShort(reportState.fromDate)} - ${DateFormatter.formatDateShort(reportState.toDate)})',
                  style: pw.TextStyle(font: PdfHelper.regular, fontSize: 11, color: PdfColors.grey600),
                  textDirection: pw.TextDirection.ltr,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfHelper.borderColor, width: 0.5),
              ),
              child: pw.Row(
                children: [
                  PdfHelper.summaryBox(label: 'کل خرچ / دینا', amount: data.totalDebit, amountColor: PdfHelper.debitRed),
                  PdfHelper.verticalDivider(),
                  PdfHelper.summaryBox(label: 'کل آمد / لینا', amount: data.totalCredit, amountColor: PdfHelper.creditGreen),
                  PdfHelper.verticalDivider(),
                  PdfHelper.summaryBox(
                    label: 'خالص بقیہ',
                    amount: data.netBalance.abs(),
                    subLabel: data.netBalance == 0 ? 'برابر' : (data.netBalance > 0 ? 'آمد' : 'خرچ'),
                    amountColor: data.netBalance >= 0 ? PdfHelper.creditGreen : PdfHelper.debitRed,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (context) => PdfHelper.pageFooter(context),
        build: (context) => [
          if (data.partyItems.isNotEmpty) ...[
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('( ', style: pw.TextStyle(font: PdfHelper.regular, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    PdfHelper.urduText('تمام', fontSize: 11, isBold: true),
                    pw.Text(': ${data.partyItems.length} )', style: pw.TextStyle(font: PdfHelper.regular, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.SizedBox(width: 4),
                    PdfHelper.urduText('تعداد انٹریز', fontSize: 11, isBold: true),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder(
                top: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
                bottom: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
                left: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
                right: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
                horizontalInside: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
                verticalInside: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(24),
              },
              children: partyTableRows,
            ),
          ],
          if (data.cashEntries.isNotEmpty) ...[
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('( ', style: pw.TextStyle(font: PdfHelper.regular, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    PdfHelper.urduText('تمام', fontSize: 11, isBold: true),
                    pw.Text(': ${data.cashEntries.length} )', style: pw.TextStyle(font: PdfHelper.regular, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.SizedBox(width: 4),
                    PdfHelper.urduText('تعداد انٹریز', fontSize: 11, isBold: true),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder(
                top: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
                bottom: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
                left: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
                right: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
                horizontalInside: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
                verticalInside: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FixedColumnWidth(24),
              },
              children: cashTableRows,
            ),
          ],
        ],
      ),
    );
    return pdf;
  }

  Future<void> _exportPdf() async {
    final reportState = ref.read(reportProvider);
    if (reportState.data == null) return;
    final pdf = await _buildPdf(reportState.data!);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _shareWhatsApp() async {
    final reportState = ref.read(reportProvider);
    if (reportState.data == null) return;
    try {
      final pdf = await _buildPdf(reportState.data!);
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/khata_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: '$_businessName - ${AppStrings.reports}\n${DateFormatter.formatDateShort(reportState.fromDate)} - ${DateFormatter.formatDateShort(reportState.toDate)}',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('شیئر نہیں ہو سکا: $e',
              style: const TextStyle(fontFamily: AppTextStyles.urduFont)),
          backgroundColor: AppColors.debit,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text(AppStrings.reports,
            style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontFamily: AppTextStyles.urduFont, fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 12),
          tabs: const [
            Tab(text: 'کسٹمرز رپورٹ'),
            Tab(text: 'سپلائرز رپورٹ'),
            Tab(text: 'کیش رپورٹ'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date range bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _DateButton(label: AppStrings.fromDate, date: reportState.fromDate, onTap: () => _selectDate(true))),
                  const SizedBox(width: 10),
                  Expanded(child: _DateButton(label: AppStrings.toDate, date: reportState.toDate, onTap: () => _selectDate(false))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _QuickFilter(label: 'آج', onTap: () {
                    final today = DateTime.now();
                    ref.read(reportProvider.notifier).setDateRange(DateTime(today.year, today.month, today.day), today);
                    _autoGenerate(_tabController.index);
                  }),
                  const SizedBox(width: 8),
                  _QuickFilter(label: 'اس ہفتے', onTap: () {
                    final now = DateTime.now();
                    final ws = now.subtract(Duration(days: now.weekday - 1));
                    ref.read(reportProvider.notifier).setDateRange(DateTime(ws.year, ws.month, ws.day), now);
                    _autoGenerate(_tabController.index);
                  }),
                  const SizedBox(width: 8),
                  _QuickFilter(label: 'اس مہینے', onTap: () {
                    final now = DateTime.now();
                    ref.read(reportProvider.notifier).setDateRange(DateTime(now.year, now.month, 1), now);
                    _autoGenerate(_tabController.index);
                  }),
                ]),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabBody(reportState, 0),
                _buildTabBody(reportState, 1),
                _buildTabBody(reportState, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(ReportState reportState, int tabIndex) {
    final ReportData? tabData;
    switch (tabIndex) {
      case 0: tabData = reportState.customerData; break;
      case 1: tabData = reportState.supplierData; break;
      case 2: tabData = reportState.cashData; break;
      default: tabData = null;
    }

    if (reportState.isLoading && reportState.activeTab == tabIndex) {
      return const LoadingWidget();
    }
    if (reportState.error != null && reportState.activeTab == tabIndex) {
      return Center(child: Text('خرابی: ${reportState.error}',
          style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 16, color: AppColors.debit)));
    }
    if (tabData == null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, size: 50, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('رپورٹ لوڈ ہو رہی ہے...',
              style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 15, color: AppColors.textSecondary)),
        ],
      ));
    }
    return _buildReportContent(tabData);
  }

  Widget _buildReportContent(ReportData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary cards
          Row(children: [
            Expanded(child: _SummaryCard(label: 'کل آمد / لینا', amount: data.totalCredit, color: AppColors.credit, bgColor: AppColors.creditBg)),
            const SizedBox(width: 10),
            Expanded(child: _SummaryCard(label: 'کل خرچ / دینا', amount: data.totalDebit, color: AppColors.debit, bgColor: AppColors.debitBg)),
          ]),
          const SizedBox(height: 10),
          // Net balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: data.netBalance >= 0 ? AppColors.creditBg : AppColors.debitBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text(AppStrings.netBalance,
                  style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(width: 12),
              Text(CurrencyFormatter.formatAmount(data.netBalance.abs()),
                  style: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.bold,
                      color: data.netBalance >= 0 ? AppColors.credit : AppColors.debit)),
            ]),
          ),
          const SizedBox(height: 16),

          // Party list
          if (data.partyItems.isNotEmpty) ...[
            const Text('تفصیلات', style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ...data.partyItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
              child: Row(children: [
                CircleAvatar(radius: 18, backgroundColor: AppColors.primarySurface,
                    child: Text(item.party.name.isNotEmpty ? item.party.name[0] : '?',
                        style: const TextStyle(fontFamily: AppTextStyles.urduFont, color: AppColors.primary, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Expanded(child: Text(item.party.name, style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(CurrencyFormatter.formatAmount(item.balance),
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.bold,
                          color: item.isCredit ? AppColors.credit : AppColors.debit)),
                  Text(item.isCredit ? AppStrings.lenaHai : AppStrings.denaHai,
                      style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 11,
                          color: item.isCredit ? AppColors.credit : AppColors.debit)),
                ]),
              ]),
            )),
          ],

          // Cash entries
          if (data.cashEntries.isNotEmpty) ...[
            const Text('روقدان تفصیلات', style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ...data.cashEntries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
              child: Row(children: [
                Icon(entry.cashType == CashType.cashIn ? Icons.arrow_downward : Icons.arrow_upward,
                    color: entry.cashType == CashType.cashIn ? AppColors.credit : AppColors.debit, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry.note.isNotEmpty ? entry.note : (entry.cashType == CashType.cashIn ? AppStrings.cashIn : AppStrings.cashOut),
                      style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13)),
                  Text(DateFormatter.formatDate(entry.entryDate),
                      style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 11, color: AppColors.textHint)),
                ])),
                Text(CurrencyFormatter.formatAmount(entry.amount),
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.bold,
                        color: entry.cashType == CashType.cashIn ? AppColors.credit : AppColors.debit)),
              ]),
            )),
          ],

          // No data message
          if (data.partyItems.isEmpty && data.cashEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('اس مدت میں کوئی ڈیٹا نہیں',
                  style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 15, color: AppColors.textHint))),
            ),

          const SizedBox(height: 16),
          // Export buttons
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
              label: const Text('PDF دیکھیں', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: _shareWhatsApp,
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text('واٹس ایپ شیئر', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(child: Text(DateFormatter.formatDateShort(date),
                style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ]),
        ]),
      ),
    );
  }
}

class _QuickFilter extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickFilter({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final Color bgColor;
  const _SummaryCard({required this.label, required this.amount, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(label, style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 12, color: color)),
        const SizedBox(height: 6),
        Text(CurrencyFormatter.formatAmount(amount),
            style: TextStyle(fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}
