/// Stock PDF Report Generator — Professional stock inventory report.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../domain/entities/product_entity.dart';

Future<void> generateStockPdf(
    List<ProductEntity> products, WidgetRef ref, String businessName) async {
  await PdfHelper.loadFonts();
  final pdf = pw.Document();

  // Calculate summary
  final totalProducts = products.length;
  final totalValue = products.fold<double>(0, (s, p) => s + p.stockValue);
  final totalProfit =
      products.fold<double>(0, (s, p) => s + (p.profitPerUnit * p.currentStock));
  final lowStockCount = products.where((p) => p.isLowStock).length;
  final outOfStockCount = products.where((p) => p.isOutOfStock).length;

  // Build table rows
  final tableRows = <pw.TableRow>[];

  // Header
  tableRows.add(
    PdfHelper.tableHeaderRow([
      '#',
      'پروڈکٹ کا نام',
      'اکائی',
      'موجودہ اسٹاک',
      'خرید قیمت',
      'فروخت قیمت',
      'منافع/یونٹ',
      'کل مالیت',
    ]),
  );

  // Data rows
  for (int i = 0; i < products.length; i++) {
    final p = products[i];
    final bg = PdfHelper.rowColor(i);

    // Status color for stock
    PdfColor stockColor = PdfHelper.creditGreen;
    if (p.isOutOfStock) {
      stockColor = PdfHelper.debitRed;
    } else if (p.isLowStock) {
      stockColor = PdfHelper.amberColor;
    }

    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          PdfHelper.tableCell('${i + 1}'),
          PdfHelper.tableCell(p.name),
          PdfHelper.tableCell(p.unit),
          PdfHelper.tableCell(p.currentStock.toStringAsFixed(0), color: stockColor, isBold: true),
          PdfHelper.tableCell(PdfHelper.formatAmount(p.purchasePrice)),
          PdfHelper.tableCell(PdfHelper.formatAmount(p.salePrice)),
          PdfHelper.tableCell(PdfHelper.formatAmount(p.profitPerUnit),
              color: p.profitPerUnit >= 0 ? PdfHelper.creditGreen : PdfHelper.debitRed),
          PdfHelper.tableCell(PdfHelper.formatAmount(p.stockValue), isBold: true),
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
          PdfHelper.headerBar(businessName: businessName, phone: '', appName: 'اسٹاک رپورٹ', color: PdfColors.indigo),
          pw.SizedBox(height: 8),
          PdfHelper.urduText('تاریخ: ${PdfHelper.formatDate(DateTime.now())}', color: PdfColors.grey),
          pw.SizedBox(height: 16),
        ],
      ),
      footer: (context) => PdfHelper.pageFooter(context),
      build: (context) => [
        // Summary stats row
        pw.Row(
          children: [
            PdfHelper.summaryBox(label: 'کل اشیاء', amount: totalProducts.toDouble(), amountColor: PdfHelper.orange),
            pw.SizedBox(width: 8),
            PdfHelper.summaryBox(label: 'اسٹاک ویلیو', amount: totalValue, amountColor: PdfHelper.orange),
            pw.SizedBox(width: 8),
            PdfHelper.summaryBox(label: 'کل منافع', amount: totalProfit,
                amountColor: totalProfit >= 0 ? PdfHelper.creditGreen : PdfHelper.debitRed),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            PdfHelper.summaryBox(label: 'کم اسٹاک', amount: lowStockCount.toDouble(), amountColor: PdfHelper.amberColor),
            pw.SizedBox(width: 8),
            PdfHelper.summaryBox(label: 'ختم', amount: outOfStockCount.toDouble(), amountColor: PdfHelper.debitRed),
            pw.SizedBox(width: 8),
            PdfHelper.summaryBox(label: 'دستیاب', amount: (totalProducts - outOfStockCount).toDouble(), amountColor: PdfHelper.creditGreen),
          ],
        ),
        pw.SizedBox(height: 16),

        // Table
        pw.Table(
          border: pw.TableBorder.all(color: PdfHelper.borderColor, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.8),  // #
            1: const pw.FlexColumnWidth(3),    // نام
            2: const pw.FlexColumnWidth(1.2),  // اکائی
            3: const pw.FlexColumnWidth(1.5),  // موجودہ
            4: const pw.FlexColumnWidth(1.8),  // خرید
            5: const pw.FlexColumnWidth(1.8),  // فروخت
            6: const pw.FlexColumnWidth(1.8),  // منافع
            7: const pw.FlexColumnWidth(2),    // مالیت
          },
          children: tableRows,
        ),
        pw.SizedBox(height: 16),

        // Total row at bottom
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfHelper.lightGrey,
            border: pw.Border.all(color: PdfHelper.borderColor),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              PdfHelper.urduText(
                'مجموعی اسٹاک ویلیو:',
                fontSize: 12, isBold: true,
              ),
              PdfHelper.amountText(
                totalValue,
                fontSize: 14, isBold: true, color: PdfHelper.orange,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
