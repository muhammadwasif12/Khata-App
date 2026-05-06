import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../domain/entities/khareed_entity.dart';

String _fmtAmt(double a) => '${NumberFormat('#,##0', 'en_US').format(a)} Rs';

Future<void> generateKhareedPdf({
  required String businessName,
  required DateTime from,
  required DateTime to,
  required List<KhareedEntity> records,
}) async {
  await PdfHelper.loadFonts();

  const orange = PdfColor.fromInt(0xFFE67E22);
  const darkGreen = PdfColor.fromInt(0xFF1A6B3C);
  const creditGreen = PdfColor.fromInt(0xFF27AE60);
  const debitRed = PdfColor.fromInt(0xFFE74C3C);
  const lightGreenBg = PdfColor.fromInt(0xFFE8F5E9);
  const greyRow = PdfColor.fromInt(0xFFF5F5F5);

  final totalAmt = records.fold(0.0, (s, r) => s + r.totalAmount);
  final totalJama = records.fold(0.0, (s, r) => s + r.jama);
  final totalBaqaya = records.fold(0.0, (s, r) => s + r.netBaqaya);

  final pdf = pw.Document(theme: PdfHelper.theme);

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    textDirection: pw.TextDirection.rtl,
    margin: const pw.EdgeInsets.all(24),
    header: (ctx) => pw.Column(children: [
      PdfHelper.headerBar(
        businessName: businessName,
        phone: '',
        appName: 'خریداری رپورٹ',
        color: orange,
      ),
      pw.SizedBox(height: 12),
      pw.Center(child: PdfHelper.urduText('خریداری رپورٹ', fontSize: 18, isBold: true)),
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
          _summaryBox('کل خریداری', _fmtAmt(totalAmt), orange),
          pw.SizedBox(width: 12),
          _summaryBox('کل جمع', _fmtAmt(totalJama), creditGreen),
          pw.SizedBox(width: 12),
          _summaryBox('کل بقایا', _fmtAmt(totalBaqaya), debitRed),
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
      final rows = <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: darkGreen),
          children: [
            _tableHeaderCell('#'),
            _tableHeaderCell('نام خریداری'),
            _tableHeaderCell('گاڑی نمبر'),
            _tableHeaderCell('وزن'),
            _tableHeaderCell('کٹوتی'),
            _tableHeaderCell('خالص وزن'),
            _tableHeaderCell('ریٹ'),
            _tableHeaderCell('کل رقم'),
            _tableHeaderCell('جمع'),
            _tableHeaderCell('بقایا'),
            _tableHeaderCell('سابق بقایا'),
            _tableHeaderCell('خالص بقایا'),
          ],
        )
      ];

      for (int i = 0; i < records.length; i++) {
        final r = records[i];
        final bg = i.isEven ? PdfColors.white : greyRow;
        rows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: bg),
          children: [
            _tableCell('${i + 1}', align: pw.TextAlign.center, color: PdfHelper.greyText),
            _tableCell(r.itemName),
            _tableCell(r.vehicleNumber.isEmpty ? '-' : r.vehicleNumber, align: pw.TextAlign.center),
            _tableCell('${r.weight} ${r.weightUnit}', align: pw.TextAlign.center),
            _tableCell(r.deduction > 0 ? '${r.deduction} ${r.weightUnit}' : '-', align: pw.TextAlign.center),
            _tableCell('${r.netWeight} ${r.weightUnit}', align: pw.TextAlign.center),
            _amountCell(_fmtAmt(r.ratePerUnit)),
            _amountCell(_fmtAmt(r.totalAmount)),
            _amountCell(_fmtAmt(r.jama)),
            _amountCell(r.baqaya > 0 ? _fmtAmt(r.baqaya) : '-'),
            _amountCell(r.sabhaBaqaya > 0 ? _fmtAmt(r.sabhaBaqaya) : '-'),
            _amountCell(_fmtAmt(r.netBaqaya), isBold: true),
          ],
        ));
      }

      // Totals row
      rows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(color: lightGreenBg),
        children: [
          _tableCell('ٹوٹل', isBold: true, color: darkGreen, align: pw.TextAlign.center),
          _tableCell('-', align: pw.TextAlign.center),
          _tableCell('-', align: pw.TextAlign.center),
          _tableCell('-', align: pw.TextAlign.center),
          _tableCell('-', align: pw.TextAlign.center),
          _tableCell('-', align: pw.TextAlign.center),
          _tableCell('-', align: pw.TextAlign.center),
          _amountCell(_fmtAmt(totalAmt), isBold: true),
          _amountCell(_fmtAmt(totalJama), isBold: true),
          _tableCell('-', align: pw.TextAlign.center),
          _tableCell('-', align: pw.TextAlign.center),
          _amountCell(_fmtAmt(totalBaqaya), isBold: true),
        ],
      ));

      return [
        pw.Table(
          border: pw.TableBorder.all(color: PdfHelper.borderColor, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.4),
            1: const pw.FlexColumnWidth(1.8),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(0.8),
            4: const pw.FlexColumnWidth(0.7),
            5: const pw.FlexColumnWidth(0.8),
            6: const pw.FlexColumnWidth(1.0),
            7: const pw.FlexColumnWidth(1.2),
            8: const pw.FlexColumnWidth(1.2),
            9: const pw.FlexColumnWidth(1.0),
            10: const pw.FlexColumnWidth(1.0),
            11: const pw.FlexColumnWidth(1.0),
          },
          children: rows,
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
