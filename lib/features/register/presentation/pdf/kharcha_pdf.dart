import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../domain/entities/kharcha_entity.dart';

String _fmtAmt(double a) => '${NumberFormat('#,##0', 'en_US').format(a)} Rs';

Future<void> generateKharchaPdf({
  required String businessName,
  required DateTime from,
  required DateTime to,
  required List<KharchaEntity> records,
}) async {
  await PdfHelper.loadFonts();

  const orange = PdfColor.fromInt(0xFFE67E22);
  const darkGreen = PdfColor.fromInt(0xFF1A6B3C);
  const debitRed = PdfColor.fromInt(0xFFE74C3C);
  const lightRedBg = PdfColor.fromInt(0xFFFFEBEE);
  const greyRow = PdfColor.fromInt(0xFFF5F5F5);

  final totalAmount = records.fold(0.0, (s, r) => s + r.amount);

  final Map<String, double> byCategory = {};
  for (final r in records) {
    final cat = (r.category == 'دیگر' && r.customCategory.isNotEmpty) ? r.customCategory : r.category;
    byCategory[cat] = (byCategory[cat] ?? 0) + r.amount;
  }
  final sortedCats = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  final pdf = pw.Document(theme: PdfHelper.theme);

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    textDirection: pw.TextDirection.rtl,
    margin: const pw.EdgeInsets.all(24),
    header: (ctx) => pw.Column(children: [
      PdfHelper.headerBar(
        businessName: businessName,
        phone: '',
        appName: 'خرچہ رپورٹ',
        color: orange,
      ),
      pw.SizedBox(height: 12),
      pw.Center(child: PdfHelper.urduText('خرچہ رپورٹ', fontSize: 18, isBold: true)),
      pw.SizedBox(height: 4),
      pw.Center(
        child: pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text(
            PdfHelper.formatDateRange(from, to),
            style: PdfHelper.urduStyle(fontSize: 11, color: PdfHelper.greyText),
          ),
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _summaryBox('کل خرچہ', _fmtAmt(totalAmount), debitRed),
          pw.SizedBox(width: 12),
          _summaryBox('کل اندراج', '${records.length}', orange),
        ],
      ),
      pw.SizedBox(height: 16),
    ]),
    footer: (ctx) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: 'تاریخ رپورٹ : ',
              style: PdfHelper.urduStyle(fontSize: 11, isBold: true, color: PdfHelper.darkText),
            ),
            pw.TextSpan(
              text: DateFormat('yyyy/M/d HH:mm').format(DateTime.now()),
              style: pw.TextStyle(font: PdfHelper.fallback, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfHelper.darkText),
            ),
          ],
        ),
      ),
    ),
    build: (ctx) {
      final catRows = <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: darkGreen),
          children: [
            _tableHeaderCell('#'),
            _tableHeaderCell('خرچہ کی قسم'),
            _tableHeaderCell('رقم'),
            _tableHeaderCell('فیصد'),
          ]
        )
      ];

      for (int i = 0; i < sortedCats.length; i++) {
        final pct = totalAmount > 0 ? (sortedCats[i].value / totalAmount * 100) : 0;
        catRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.white : greyRow),
          children: [
            _tableCell('${i + 1}', align: pw.TextAlign.center, color: PdfHelper.greyText),
            _tableCell(sortedCats[i].key),
            _amountCell(_fmtAmt(sortedCats[i].value)),
            _tableCell('${pct.toStringAsFixed(1)}%', align: pw.TextAlign.center),
          ]
        ));
      }

      final detRows = <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: darkGreen),
          children: [
            _tableHeaderCell('#'),
            _tableHeaderCell('تاریخ'),
            _tableHeaderCell('قسم'),
            _tableHeaderCell('گاڑی نمبر'),
            _tableHeaderCell('کس کو'),
            _tableHeaderCell('رقم'),
            _tableHeaderCell('نوٹ'),
          ]
        )
      ];

      for (int i = 0; i < records.length; i++) {
        final r = records[i];
        final cat = (r.category == 'دیگر' && r.customCategory.isNotEmpty) ? r.customCategory : r.category;
        detRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.white : greyRow),
          children: [
            _tableCell('${i + 1}', align: pw.TextAlign.center, color: PdfHelper.greyText),
            _tableCell(PdfHelper.formatDate(r.expenseDate), align: pw.TextAlign.center),
            _tableCell(cat),
            _tableCell(r.vehicleNumber.isEmpty ? '-' : r.vehicleNumber, align: pw.TextAlign.center),
            _tableCell(r.paidTo.isEmpty ? '-' : r.paidTo),
            _amountCell(_fmtAmt(r.amount), color: debitRed),
            _tableCell(r.note.isEmpty ? '-' : r.note),
          ]
        ));
      }

      return [
        PdfHelper.urduText('تفصیلات قسم کے لحاظ سے', fontSize: 12, isBold: true, color: darkGreen),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfHelper.borderColor, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: catRows,
        ),
        pw.SizedBox(height: 20),
        PdfHelper.urduText('تمام اخراجات کی تفصیل', fontSize: 12, isBold: true, color: darkGreen),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfHelper.borderColor, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(25),
            1: const pw.FlexColumnWidth(1.8),
            2: const pw.FlexColumnWidth(2.0),
            3: const pw.FlexColumnWidth(1.8),
            4: const pw.FlexColumnWidth(2.2),
            5: const pw.FlexColumnWidth(1.8),
            6: const pw.FlexColumnWidth(2.5),
          },
          children: detRows,
        ),
      ];
    },
  ));

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

pw.Widget _summaryBox(String label, String value, PdfColor color) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfHelper.borderColor, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          PdfHelper.urduText(label, fontSize: 10, color: PdfHelper.greyText, align: pw.TextAlign.center),
          pw.SizedBox(height: 6),
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              value,
              style: PdfHelper.amountStyle(fontSize: 14, isBold: true, color: color),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _tableHeaderCell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 3),
    child: pw.Align(
      alignment: pw.Alignment.centerRight,
      child: PdfHelper.urduText(text, fontSize: 8, isBold: true, color: PdfColors.white, align: pw.TextAlign.right),
    ),
  );
}

pw.Widget _tableCell(String text, {bool isBold = false, PdfColor? color, pw.TextAlign align = pw.TextAlign.left}) {
  final hasUrdu = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  final isLtr = !hasUrdu && (text.startsWith('Rs') || text == '-' || text.isEmpty || text.contains(RegExp(r'[a-zA-Z]')));
  final safeText = (!isLtr && (text.contains('(') || text.contains(')')))
      ? text.replaceAll('(', '\x00').replaceAll(')', '(').replaceAll('\x00', ')')
      : text;

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
    child: pw.Align(
      alignment: align == pw.TextAlign.center ? pw.Alignment.center : (align == pw.TextAlign.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft),
      child: pw.Directionality(
        textDirection: isLtr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
        child: pw.Text(
          safeText,
          style: pw.TextStyle(
            font: isBold ? PdfHelper.bold : PdfHelper.regular,
            fontSize: 8,
            color: color ?? PdfColors.black,
          ),
          textAlign: align,
        ),
      ),
    ),
  );
}

pw.Widget _amountCell(String text, {bool isBold = false, PdfColor? color}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
    child: pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Text(
          text,
          style: PdfHelper.amountStyle(fontSize: 8, isBold: isBold, color: color ?? PdfColors.black),
          textAlign: pw.TextAlign.left,
        ),
      ),
    ),
  );
}
