/// Daily Bills PDF Report Generator — Professional billing summary report.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../domain/entities/invoice_entity.dart';

Future<void> generateDailyBillsPdf(
    List<InvoiceEntity> invoices, WidgetRef ref, String businessName) async {
  await PdfHelper.loadFonts();
  final pdf = pw.Document();

  // Calculate summary
  final totalBills = invoices.length;
  final totalAmount = invoices.fold<double>(0, (s, i) => s + i.totalAmount);
  final totalPaid = invoices.fold<double>(0, (s, i) => s + i.paidAmount);
  final totalPending = totalAmount - totalPaid;
  final paidCount =
      invoices.where((i) => i.status == InvoiceStatus.paid).length;
  final unpaidCount =
      invoices.where((i) => i.status == InvoiceStatus.unpaid).length;

  // Build table rows
  final tableRows = <pw.TableRow>[];

  // Header
  tableRows.add(
    PdfHelper.tableHeaderRow([
      '#',
      'بل نمبر',
      'نام گراہک',
      'فون',
      'کل رقم',
      'ادا شدہ',
      'بقایا',
      'حالت',
    ]),
  );

  // Data rows
  for (int i = 0; i < invoices.length; i++) {
    final inv = invoices[i];
    final bg = PdfHelper.rowColor(i);

    // Status color
    PdfColor statusColor;
    String statusText;
    switch (inv.status) {
      case InvoiceStatus.paid:
        statusColor = PdfHelper.creditGreen;
        statusText = 'ادا شدہ';
        break;
      case InvoiceStatus.partial:
        statusColor = PdfHelper.amberColor;
        statusText = 'جزوی';
        break;
      case InvoiceStatus.unpaid:
        statusColor = PdfHelper.debitRed;
        statusText = 'بقایا';
        break;
    }

    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          PdfHelper.tableCell('${i + 1}'),
          PdfHelper.tableCell(inv.invoiceNumber),
          PdfHelper.tableCell(inv.customerName.isEmpty ? '-' : inv.customerName),
          PdfHelper.tableCell(
              inv.customerPhone.isNotEmpty ? inv.customerPhone : '-'),
          PdfHelper.tableCell(PdfHelper.formatAmount(inv.totalAmount), isBold: true),
          PdfHelper.tableCell(PdfHelper.formatAmount(inv.paidAmount), color: PdfHelper.creditGreen),
          PdfHelper.tableCell(PdfHelper.formatAmount(inv.balanceAmount),
              color: inv.balanceAmount > 0 ? PdfHelper.debitRed : PdfHelper.creditGreen),
          PdfHelper.tableCell(statusText, color: statusColor, isBold: true),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(24),
      theme: PdfHelper.theme,
      header: (context) => pw.Column(
        children: [
          PdfHelper.headerBar(businessName: businessName, phone: '', appName: 'بلنگ رپورٹ', color: PdfColors.deepPurple),
          pw.SizedBox(height: 8),
          PdfHelper.urduText('تاریخ: ${PdfHelper.formatDate(DateTime.now())}', color: PdfColors.grey),
          pw.SizedBox(height: 16),
        ],
      ),
      footer: (context) => PdfHelper.pageFooter(context),
      build: (context) => [
        // Summary stats
        pw.Row(
          children: [
            PdfHelper.summaryBox(label: 'کل بلز', amount: totalBills.toDouble(), amountColor: PdfHelper.orange),
            pw.SizedBox(width: 8),
            PdfHelper.summaryBox(label: 'کل رقم', amount: totalAmount, amountColor: PdfHelper.orange),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            PdfHelper.summaryBox(label: 'وصول شدہ', amount: totalPaid, amountColor: PdfHelper.creditGreen),
            pw.SizedBox(width: 8),
            PdfHelper.summaryBox(label: 'بقایا رقم', amount: totalPending,
                amountColor: totalPending > 0 ? PdfHelper.debitRed : PdfHelper.creditGreen),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            PdfHelper.summaryBox(label: 'ادا شدہ بلز', amount: paidCount.toDouble(), amountColor: PdfHelper.creditGreen),
            pw.SizedBox(width: 8),
            PdfHelper.summaryBox(label: 'بقایا بلز', amount: unpaidCount.toDouble(), amountColor: PdfHelper.debitRed),
          ],
        ),
        pw.SizedBox(height: 16),

        // Table
        pw.Table(
          border: pw.TableBorder.all(color: PdfHelper.borderColor, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.7),  // #
            1: const pw.FlexColumnWidth(1.5),  // بل نمبر
            2: const pw.FlexColumnWidth(2.5),  // نام
            3: const pw.FlexColumnWidth(1.5),  // فون
            4: const pw.FlexColumnWidth(1.5),  // کل رقم
            5: const pw.FlexColumnWidth(1.5),  // ادا شدہ
            6: const pw.FlexColumnWidth(1.5),  // بقایا
            7: const pw.FlexColumnWidth(1.2),  // حالت
          },
          children: tableRows,
        ),
        pw.SizedBox(height: 16),

        // Totals row at bottom
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfHelper.lightGrey,
            border: pw.Border.all(color: PdfHelper.borderColor),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfHelper.urduText('مجموعی بلنگ:',
                      fontSize: 11, isBold: true),
                  PdfHelper.amountText(totalAmount,
                      fontSize: 13, isBold: true, color: PdfHelper.orange),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfHelper.urduText('وصول شدہ:',
                      fontSize: 10),
                  PdfHelper.amountText(totalPaid,
                      fontSize: 11, isBold: true, color: PdfHelper.creditGreen),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfHelper.urduText('بقایا رقم:',
                      fontSize: 10),
                  PdfHelper.amountText(totalPending,
                      fontSize: 11, isBold: true, color: totalPending > 0 ? PdfHelper.debitRed : PdfHelper.creditGreen),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
