import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../domain/entities/kharcha_entity.dart';

String _fmtAmt(double a) => '${NumberFormat('#,##0', 'en_US').format(a)} Rs';

Future<void> generateKharchaItemPdf({
  required String businessName,
  required KharchaEntity record,
}) async {
  await PdfHelper.loadFonts();

  final pdf = pw.Document(theme: PdfHelper.theme);

  final categoryDisplay = record.category == 'دیگر' && record.customCategory.isNotEmpty
      ? record.customCategory
      : record.category;

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    textDirection: pw.TextDirection.rtl,
    margin: const pw.EdgeInsets.all(28),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        PdfHelper.headerBar(
          businessName: businessName,
          phone: '',
          appName: 'خرچہ رسید',
          color: PdfHelper.orange,
        ),
        pw.SizedBox(height: 16),
        pw.Center(
          child: PdfHelper.urduText('خرچہ رسید', fontSize: 20, isBold: true, align: pw.TextAlign.center),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              PdfHelper.formatDate(record.expenseDate),
              style: PdfHelper.urduStyle(fontSize: 12, color: PdfHelper.greyText),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
        pw.SizedBox(height: 16),

        _buildDetailRow('خرچہ کی قسم', categoryDisplay),
        if (record.paidTo.isNotEmpty)
          _buildDetailRow('کس کو دیا', record.paidTo),
        if (record.vehicleNumber.isNotEmpty)
          _buildDetailRow('گاڑی نمبر', record.vehicleNumber),
        if (record.driverName.isNotEmpty)
          _buildDetailRow('ڈرائیور / باری', record.driverName),
        
        pw.SizedBox(height: 12),

        _buildSectionBox(
          title: 'تفصیل رقم',
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              color: PdfHelper.lightRed,
              child: pw.Column(
                children: [
                  PdfHelper.urduText('رقم', fontSize: 12, color: PdfHelper.greyText),
                  pw.SizedBox(height: 8),
                  pw.Directionality(
                    textDirection: pw.TextDirection.ltr,
                    child: pw.Text(
                      _fmtAmt(record.amount),
                      style: PdfHelper.amountStyle(fontSize: 24, isBold: true, color: PdfHelper.debitRed),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (record.note.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _buildDetailRow('نوٹ', record.note),
        ],

        pw.Spacer(),
        
        pw.Align(
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
      ],
    ),
  ));

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

pw.Widget _buildDetailRow(String label, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: const pw.BoxDecoration(
      color: PdfHelper.lightGrey,
      border: pw.Border(bottom: pw.BorderSide(color: PdfHelper.borderColor, width: 0.5)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        PdfHelper.urduText(label, fontSize: 11, isBold: true, color: PdfHelper.headerGreen),
        pw.Expanded(
          child: PdfHelper.urduText(value, fontSize: 11, align: pw.TextAlign.left, color: PdfHelper.darkText),
        ),
      ],
    ),
  );
}

pw.Widget _buildSectionBox({required String title, required List<pw.Widget> children}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfHelper.borderColor, width: 1),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfHelper.headerGreen, width: 0.5)),
          ),
          child: PdfHelper.urduText(title, fontSize: 13, isBold: true, color: PdfHelper.headerGreen, align: pw.TextAlign.center),
        ),
        ...children,
      ],
    ),
  );
}
