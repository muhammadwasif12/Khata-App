import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../domain/entities/farokht_entity.dart';

String _fmtAmt(double a) => '${NumberFormat('#,##0', 'en_US').format(a)} Rs';

Future<void> generateFarokhtItemPdf({
  required String businessName,
  required FarokhtEntity record,
}) async {
  await PdfHelper.loadFonts();

  final pdf = pw.Document(theme: PdfHelper.theme);

  String paymentLabel;
  switch (record.paymentStatus) {
    case 1: paymentLabel = 'نقد'; break;
    case 0: paymentLabel = 'ادھار'; break;
    case 2: paymentLabel = 'جزوی ادائیگی'; break;
    case 3: paymentLabel = record.customPaymentType.isNotEmpty ? record.customPaymentType : 'دیگر'; break;
    default: paymentLabel = '-';
  }

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
          appName: 'فروخت رسید',
          color: PdfHelper.orange,
        ),
        pw.SizedBox(height: 16),
        pw.Center(
          child: PdfHelper.urduText('فروخت رسید', fontSize: 20, isBold: true, align: pw.TextAlign.center),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              PdfHelper.formatDate(record.saleDate),
              style: PdfHelper.urduStyle(fontSize: 12, color: PdfHelper.greyText),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
        pw.SizedBox(height: 16),

        _buildDetailRow('چیز کا نام', record.itemName),
        _buildDetailRow('خریدار', record.buyerName),
        if (record.cardNumber.isNotEmpty)
          _buildDetailRow('کارڈ نمبر', record.cardNumber),
        _buildDetailRow('ادائیگی کی قسم', paymentLabel),
        
        pw.SizedBox(height: 12),

        _buildSectionBox(
          title: 'وزن اور ریٹ',
          children: [
            _buildAmountRow('وزن', '${record.weight} ${record.weightUnit}', bg: PdfColors.white),
            _buildAmountRow('ریٹ فی اکائی', _fmtAmt(record.ratePerUnit), bg: PdfHelper.lightGrey),
            pw.Container(
              decoration: const pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border(top: pw.BorderSide(color: PdfHelper.headerGreen, width: 0.5)),
              ),
              child: _buildAmountRow(
                'کل رقم',
                _fmtAmt(record.totalAmount),
                isBold: true,
                labelColor: PdfHelper.headerGreen,
                valueColor: PdfHelper.headerGreen,
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        _buildSectionBox(
          title: 'ادائیگی',
          children: [
            _buildAmountRow('وصول رقم', _fmtAmt(record.creditAmount), bg: PdfColors.white),
            _buildAmountRow('باقی رقم', _fmtAmt(record.debitAmount), bg: PdfHelper.lightGrey, valueColor: record.debitAmount > 0 ? PdfHelper.debitRed : null),
            if (record.tafazul > 0)
              pw.Container(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border(top: pw.BorderSide(color: PdfHelper.headerGreen, width: 0.5)),
                ),
                child: _buildAmountRow(
                  'تفاضل / منافع',
                  _fmtAmt(record.tafazul),
                  isBold: true,
                  labelColor: PdfHelper.headerGreen,
                  valueColor: PdfHelper.creditGreen,
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

pw.Widget _buildAmountRow(String label, String value, {bool isBold = false, PdfColor? labelColor, PdfColor? valueColor, PdfColor? bg}) {
  final hasUrdu = RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  final isLtr = !hasUrdu && (value.contains(RegExp(r'[a-zA-Z]')) || value.isEmpty || value == '-');

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    color: bg,
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        PdfHelper.urduText(label, fontSize: 11, isBold: isBold, color: labelColor ?? PdfHelper.greyText),
        pw.Directionality(
          textDirection: isLtr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
          child: pw.Text(
            value,
            style: PdfHelper.amountStyle(
              fontSize: 11,
              isBold: isBold,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ),
      ],
    ),
  );
}
