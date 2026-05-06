/// Party Ledger Screen
/// Full transaction history with one customer/supplier showing running balances and PDF statement.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../customers/data/repositories/party_repository_impl.dart';
import '../../../customers/domain/entities/party_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_list_tile.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

class PartyLedgerScreen extends ConsumerStatefulWidget {
  final String partyId;

  const PartyLedgerScreen({super.key, required this.partyId});

  @override
  ConsumerState<PartyLedgerScreen> createState() => _PartyLedgerScreenState();
}

class _PartyLedgerScreenState extends ConsumerState<PartyLedgerScreen> {
  PartyEntity? _party;

  @override
  void initState() {
    super.initState();
    _loadParty();
  }

  Future<void> _loadParty() async {
    final repo = PartyRepositoryImpl();
    final party = await repo.getPartyById(widget.partyId);
    if (mounted) {
      setState(() => _party = party);
    }
  }

  /// Calculate running balances for all transactions (sorted ASC by txnDate)
  List<double> _calculateRunningBalances(
    PartyEntity party,
    List<TransactionEntity> transactions,
  ) {
    double balance = party.isOpeningCredit
        ? party.openingBalance
        : -party.openingBalance;

    final balances = <double>[];
    for (final txn in transactions) {
      if (txn.txnType == TxnType.credit) {
        balance += txn.amount;
      } else {
        balance -= txn.amount;
      }
      balances.add(balance);
    }
    return balances;
  }

  double _getFinalBalance(
    PartyEntity party,
    List<TransactionEntity> transactions,
  ) {
    double balance = party.isOpeningCredit
        ? party.openingBalance
        : -party.openingBalance;

    for (final txn in transactions) {
      if (txn.txnType == TxnType.credit) {
        balance += txn.amount;
      } else {
        balance -= txn.amount;
      }
    }
    return balance;
  }

  void _showAddTransaction({TransactionEntity? existing}) {
    if (_party == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddTransactionBottomSheet(
        partyId: widget.partyId,
        businessId: _party!.businessId,
        existingTransaction: existing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_party == null) {
      return const Scaffold(body: LoadingWidget());
    }

    final party = _party!;
    final txnAsync = ref.watch(
      transactionProviderFamily((widget.partyId, party.businessId)),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              party.name,
              style: const TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (party.phone.isNotEmpty)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  party.phone,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // PDF / Share
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF رپورٹ',
            onPressed: () {
              final txns = txnAsync.valueOrNull ?? [];
              _generatePdf(party, txns);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'شیئر کریں',
            onPressed: () {
              final txns = txnAsync.valueOrNull ?? [];
              _sharePdf(party, txns);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                final isCustomer = party.partyType == PartyType.customer;
                final prefix = isCustomer ? 'customers' : 'suppliers';
                context.push('/home/$prefix/edit/${party.id}');
              } else if (value == 'delete') {
                _confirmDeleteParty();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'ترمیم',
                      style: TextStyle(fontFamily: AppTextStyles.urduFont),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.debit),
                    SizedBox(width: 8),
                    Text(
                      'حذف کریں',
                      style: TextStyle(fontFamily: AppTextStyles.urduFont),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: txnAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => Center(
          child: Text(
            '${AppStrings.error}: $e',
            style: const TextStyle(fontFamily: AppTextStyles.urduFont),
          ),
        ),
        data: (transactions) {
          final balance = _getFinalBalance(party, transactions);
          final isCredit = balance > 0;
          final isSettled = balance == 0;
          final runningBalances =
              _calculateRunningBalances(party, transactions);

          return Column(
            children: [
              // Balance summary card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSettled
                      ? Colors.grey.shade100
                      : (isCredit ? AppColors.creditBg : AppColors.debitBg),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSettled
                        ? Colors.grey.shade300
                        : (isCredit ? AppColors.credit : AppColors.debit)
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      CurrencyFormatter.formatAmount(balance.abs()),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isSettled
                            ? AppColors.textSecondary
                            : (isCredit
                                ? AppColors.credit
                                : AppColors.debit),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSettled
                          ? AppStrings.settled
                          : (isCredit
                              ? AppStrings.lenaHai
                              : AppStrings.denaHai),
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 16,
                        color: isSettled
                            ? AppColors.textSecondary
                            : (isCredit
                                ? AppColors.credit
                                : AppColors.debit),
                      ),
                    ),
                  ],
                ),
              ),
              // Transaction list
              Expanded(
                child: transactions.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.receipt_long_outlined,
                        title: AppStrings.noTransactions,
                        description: AppStrings.noTxnDesc,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          // Show newest first in display
                          final reverseIndex =
                              transactions.length - 1 - index;
                          final txn = transactions[reverseIndex];
                          final rb = runningBalances[reverseIndex];

                          return TransactionListTile(
                            transaction: txn,
                            runningBalance: rb,
                            onTap: () =>
                                _showAddTransaction(existing: txn),
                            onDelete: () {
                              ref
                                  .read(transactionProviderFamily(
                                          (widget.partyId, party.businessId))
                                      .notifier)
                                  .deleteTransaction(txn.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      // Two FABs for Gave and Received — navigate to full screens
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'gave',
            onPressed: () => context.push('/parties/give/${widget.partyId}'),
            backgroundColor: AppColors.debit,
            icon: const Icon(Icons.arrow_upward, color: Colors.white),
            label: const Text(
              AppStrings.gave,
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'received',
            onPressed: () => context.push('/parties/receive/${widget.partyId}'),
            backgroundColor: AppColors.credit,
            icon: const Icon(Icons.arrow_downward, color: Colors.white),
            label: const Text(
              AppStrings.received,
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteParty() {
    showConfirmationDialog(
      context: context,
      title: AppStrings.deleteParty,
      message: AppStrings.deletePartyMsg,
      confirmLabel: AppStrings.delete,
      onConfirm: () {
        final repo = PartyRepositoryImpl();
        repo.deleteParty(widget.partyId);
        context.pop();
      },
    );
  }

  // ─── PDF Generation (DigiKhata style) ───

  String _getBusinessName() {
    final businesses = ref.read(businessesProvider).valueOrNull ?? [];
    if (_party != null && businesses.isNotEmpty) {
      final biz = businesses
          .where((b) => b.id == _party!.businessId)
          .firstOrNull;
      if (biz != null) return biz.name;
    }
    return AppStrings.appName;
  }

  Future<void> _generatePdf(
      PartyEntity party, List<TransactionEntity> txns) async {
    final pdf = await _buildStatementPdf(party, txns);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Future<void> _sharePdf(
      PartyEntity party, List<TransactionEntity> txns) async {
    final pdf = await _buildStatementPdf(party, txns);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${party.name}_statement.pdf',
    );
  }

  Future<pw.Document> _buildStatementPdf(
      PartyEntity party, List<TransactionEntity> txns) async {
    await PdfHelper.loadFonts();
    final pdf = pw.Document();
    final businesses = ref.read(businessesProvider).valueOrNull ?? [];
    final activeId = ref.read(activeBusinessIdProvider);
    final activeBusiness = businesses.where((b) => b.id == activeId).firstOrNull;
    final businessName = activeBusiness?.name ?? AppStrings.appName;
    final businessPhone = activeBusiness?.phone ?? '';
    final now = DateTime.now();

    String fmtAmt(double amount) {
      if (amount == 0) return 'Rs 0';
      return PdfHelper.formatAmount(amount);
    }

    String fmtDate(DateTime d) {
      return PdfHelper.formatDateEnglish(d);
    }

    final openingBalance = party.isOpeningCredit ? party.openingBalance : -party.openingBalance;

    double totalCredit = 0;
    double totalDebit = 0;
    double runningBalance = openingBalance;

    final isCustomer = party.partyType == PartyType.customer;
    final tableRows = <pw.TableRow>[];

    final headers = <pw.Widget>[
      PdfHelper.urduText('بقایا', fontSize: 10, isBold: true, color: PdfHelper.darkText),
      pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
          pw.Text('(+) ', style: pw.TextStyle(font: PdfHelper.bold, fontSize: 10, color: PdfHelper.darkText)),
          PdfHelper.urduText('جمع', fontSize: 10, isBold: true, color: PdfHelper.darkText),
        ]),
      ),
      pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
          pw.Text('(-) ', style: pw.TextStyle(font: PdfHelper.bold, fontSize: 10, color: PdfHelper.darkText)),
          PdfHelper.urduText('بنام', fontSize: 10, isBold: true, color: PdfHelper.darkText),
        ]),
      ),
      PdfHelper.urduText('تفصیلات', fontSize: 10, isBold: true, color: PdfHelper.darkText),
      PdfHelper.urduText('تاریخ', fontSize: 10, isBold: true, color: PdfHelper.darkText),
      pw.Directionality(textDirection: pw.TextDirection.ltr, child: pw.Text('#', style: pw.TextStyle(font: PdfHelper.bold, fontSize: 10, color: PdfHelper.darkText))),
    ];
    tableRows.add(PdfHelper.tableHeaderRowWidgets(headers));

    // OPENING BALANCE ROW
    final dateStr = txns.isNotEmpty ? fmtDate(txns.first.txnDate) : fmtDate(now);
    tableRows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfHelper.lightGrey,
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('${fmtAmt(openingBalance.abs())} : ( ', style: pw.TextStyle(font: PdfHelper.bold, fontSize: 10, color: PdfColors.black)),
                PdfHelper.urduText('اوپننگ بیلنس', fontSize: 10, isBold: true, color: PdfColors.black),
                pw.Text(' )', style: pw.TextStyle(font: PdfHelper.bold, fontSize: 10, color: PdfColors.black)),
              ],
            ),
          ),
        ),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.SizedBox(),
        PdfHelper.tableCell(dateStr, fontSize: 10, isBold: true),
        pw.SizedBox(),
      ],
    ));

    // Data rows
    for (int i = 0; i < txns.length; i++) {
      final txn = txns[i];
      final isCredit = txn.txnType == TxnType.credit;

      if (isCredit) {
        totalCredit += txn.amount;
        runningBalance += txn.amount;
      } else {
        totalDebit += txn.amount;
        runningBalance -= txn.amount;
      }

      String details = txn.note;
      if (txn.paymentMethod != 'نقد') {
        details += details.isNotEmpty ? ' (${txn.paymentMethod})' : '(${txn.paymentMethod})';
      }

      final balColor = runningBalance >= 0 ? PdfHelper.creditGreen : PdfHelper.debitRed;
      final balLabel = runningBalance >= 0 ? 'جمع' : 'بنام';

      tableRows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.3)),
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 3),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: pw.Text(fmtAmt(runningBalance.abs()),
                    style: pw.TextStyle(font: PdfHelper.bold, fontSize: 10, color: balColor),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 1),
                PdfHelper.urduText(balLabel, fontSize: 8, color: balColor, align: pw.TextAlign.center),
              ],
            ),
          ),
          PdfHelper.tableCell(
            isCredit ? fmtAmt(txn.amount) : '',
            fontSize: 10,
            color: PdfHelper.creditGreen,
            backgroundColor: isCredit ? PdfHelper.lightGreen : null,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
          ),
          PdfHelper.tableCell(
            !isCredit ? fmtAmt(txn.amount) : '',
            fontSize: 10,
            color: PdfHelper.debitRed,
            backgroundColor: !isCredit ? PdfHelper.lightRed : null,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
          ),
          PdfHelper.tableCell(details.isEmpty ? '-' : details, fontSize: 10, align: pw.TextAlign.right, padding: const pw.EdgeInsets.symmetric(vertical: 8)),
          PdfHelper.tableCell(fmtDate(txn.txnDate), fontSize: 10, padding: const pw.EdgeInsets.symmetric(vertical: 8)),
          PdfHelper.tableCell('${i + 1}', fontSize: 10, color: PdfColors.grey700, padding: const pw.EdgeInsets.symmetric(vertical: 8)),
        ],
      ));
    }

    final finalBalance = runningBalance;
    final finalBalColor = finalBalance >= 0 ? PdfHelper.creditGreen : PdfHelper.debitRed;

    String dateRange = '';
    String headerDateRange = '';
    if (txns.isNotEmpty) {
      final first = txns.first.txnDate;
      final last = txns.last.txnDate;
      headerDateRange = '(${fmtDate(first)} - ${fmtDate(last)})';
      dateRange = headerDateRange;
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.only(top: 20, bottom: 20, left: 24, right: 24),
          textDirection: pw.TextDirection.rtl,
          theme: PdfHelper.theme,
        ),

        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            PdfHelper.headerBar(
              businessName: businessName,
              appName: isCustomer ? 'کسٹمر رپورٹ' : 'سپلائر رپورٹ',
              phone: businessPhone,
            ),
            pw.SizedBox(height: 16),

            pw.Center(
              child: PdfHelper.urduText('${party.name} سٹیٹمنٹ', fontSize: 22, isBold: true),
            ),
            if (party.phone.isNotEmpty)
              pw.Center(
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Text('فون نمبر : ${party.phone}',
                    style: pw.TextStyle(font: PdfHelper.regular, fontSize: 12, color: PdfColors.grey700),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ),
            if (headerDateRange.isNotEmpty)
              pw.Center(
                child: pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: pw.Text(headerDateRange,
                    style: pw.TextStyle(font: PdfHelper.regular, fontSize: 11, color: PdfColors.grey600),
                    textDirection: pw.TextDirection.ltr,
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            pw.SizedBox(height: 16),

            // Summary Boxes Row
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfHelper.borderColor, width: 0.5),
              ),
              child: pw.Row(
                children: [
                  PdfHelper.summaryBox(
                    label: 'اوپننگ بیلنس',
                    amount: openingBalance.abs(),
                    subLabel: openingBalance == 0 ? 'برابر' : (openingBalance > 0 ? 'لینا' : 'دینا'),
                    dateStr: dateRange,
                    amountColor: PdfColors.grey800,
                  ),
                  PdfHelper.verticalDivider(),
                  PdfHelper.summaryBox(
                    label: 'ٹوٹل بنام',
                    sign: '(-)',
                    amount: totalDebit,
                    amountColor: PdfHelper.debitRed,
                  ),
                  PdfHelper.verticalDivider(),
                  PdfHelper.summaryBox(
                    label: 'ٹوٹل جمع',
                    sign: '(+)',
                    amount: totalCredit,
                    amountColor: PdfHelper.creditGreen,
                  ),
                  PdfHelper.verticalDivider(),
                  PdfHelper.summaryBox(
                    label: 'بقایا',
                    amount: finalBalance.abs(),
                    subLabel: finalBalance == 0 ? 'برابر' : (finalBalance > 0 ? '${party.name} نے دینے ہیں' : 'آپ نے دینے ہیں'),
                    dateStr: dateRange,
                    amountColor: finalBalColor,
                  ),
                  PdfHelper.verticalDivider(),
                  PdfHelper.summaryBox(
                    label: 'موجودہ بیلنس',
                    amount: finalBalance.abs(),
                    subLabel: finalBalance == 0 ? 'برابر' : (finalBalance > 0 ? '${party.name} نے دینے ہیں' : 'آپ نے دینے ہیں'),
                    dateStr: dateRange,
                    amountColor: finalBalColor,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Entry count
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('( ', style: pw.TextStyle(font: PdfHelper.regular, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    PdfHelper.urduText('تمام', fontSize: 11, isBold: true),
                    pw.Text(': ${txns.length} )', style: pw.TextStyle(font: PdfHelper.regular, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.SizedBox(width: 4),
                    PdfHelper.urduText('تعداد انٹریز', fontSize: 11, isBold: true),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ],
        ),

        build: (context) => [
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
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(3),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FixedColumnWidth(24),
            },
            children: tableRows,
          ),
          pw.Table(
            border: pw.TableBorder(
              bottom: const pw.BorderSide(color: PdfHelper.borderColor, width: 1),
              left: const pw.BorderSide(color: PdfHelper.borderColor, width: 1),
              right: const pw.BorderSide(color: PdfHelper.borderColor, width: 1),
              verticalInside: const pw.BorderSide(color: PdfHelper.borderColor, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(3),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FixedColumnWidth(24),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfHelper.lightGrey,
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: pw.Text(fmtAmt(finalBalance.abs()), style: pw.TextStyle(font: PdfHelper.bold, fontSize: 11, color: PdfColors.black)),
                        ),
                        pw.SizedBox(width: 4),
                        PdfHelper.urduText('بنام', fontSize: 11, isBold: true, color: PdfColors.black),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10),
                    child: pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Text(fmtAmt(totalCredit), style: pw.TextStyle(font: PdfHelper.regular, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black), textAlign: pw.TextAlign.center),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10),
                    child: pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Text(fmtAmt(totalDebit), style: pw.TextStyle(font: PdfHelper.regular, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black), textAlign: pw.TextAlign.center),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: PdfHelper.urduText('گرینڈ ٹوٹل', fontSize: 11, isBold: true, color: PdfHelper.creditGreen, align: pw.TextAlign.right),
                  ),
                  pw.SizedBox(),
                  pw.SizedBox(),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
        ],

        footer: (context) => PdfHelper.pageFooter(context),
      ),
    );
    return pdf;
  }
}
