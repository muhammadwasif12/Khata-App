import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'date_formatter.dart';

class PdfHelper {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.Font? _fallbackFont;

  static Future<void> loadFonts() async {
    try {
      final regularData = await rootBundle.load(
        'assets/fonts/NotoNaskhArabic-Regular.ttf',
      );
      _regularFont = pw.Font.ttf(regularData);

      final boldData = await rootBundle.load(
        'assets/fonts/NotoNaskhArabic-Bold.ttf',
      );
      _boldFont = pw.Font.ttf(boldData);

      final fallbackData = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      _fallbackFont = pw.Font.ttf(fallbackData);
    } catch (e) {
      try {
        final regularData = await rootBundle.load(
          'assets/fonts/NotoNaskhArabic-Regular.ttf',
        );
        _regularFont = pw.Font.ttf(regularData);
        final boldData = await rootBundle.load(
          'assets/fonts/NotoNaskhArabic-Bold.ttf',
        );
        _boldFont = pw.Font.ttf(boldData);
      } catch (e2) {
        _regularFont = pw.Font.helvetica();
        _boldFont = pw.Font.helveticaBold();
      }
    }
  }

  static pw.Font get regular => _regularFont!;
  static pw.Font get bold => _boldFont!;
  static pw.Font get fallback => _fallbackFont ?? pw.Font.helvetica();

  static pw.ThemeData get theme {
    return pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
      fontFallback: _fallbackFont != null ? [_fallbackFont!] : [],
    );
  }

  static pw.TextStyle urduStyle({
    double fontSize = 11,
    bool isBold = false,
    PdfColor color = PdfColors.black,
  }) {
    return pw.TextStyle(
      font: isBold ? _boldFont! : _regularFont!,
      fontSize: fontSize,
      color: color,
    );
  }

  static pw.TextStyle amountStyle({
    double fontSize = 12,
    bool isBold = true,
    PdfColor color = PdfColors.black,
  }) {
    return pw.TextStyle(
      font: isBold ? _boldFont! : _regularFont!,
      fontSize: fontSize,
      color: color,
    );
  }

  static pw.Widget urduText(
    String text, {
    double fontSize = 11,
    bool isBold = false,
    PdfColor color = PdfColors.black,
    pw.TextAlign align = pw.TextAlign.right,
  }) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isBold ? _boldFont! : _regularFont!,
          fontSize: fontSize,
          color: color,
        ),
        textDirection: pw.TextDirection.rtl,
        textAlign: align,
      ),
    );
  }

  static String formatAmount(double amount) {
    final abs = amount.abs();
    final formatted = NumberFormat('#,##0.##', 'en_US').format(abs);
    return 'Rs $formatted';
  }

  static pw.Widget amountText(
    double amount, {
    double fontSize = 12,
    bool isBold = true,
    PdfColor? color,
    bool showSign = false,
  }) {
    final formatted = formatAmount(amount);
    final sign = showSign && amount > 0 ? '+' : '';
    final display = '$sign$formatted';
    final textColor = color ?? PdfColors.black;
    return pw.Text(
      display,
      style: amountStyle(fontSize: fontSize, isBold: isBold, color: textColor),
      textDirection: pw.TextDirection.ltr,
      textAlign: pw.TextAlign.center,
    );
  }

  static String formatDate(DateTime d) => DateFormatter.formatUrdu(d);
  static String formatDateShort(DateTime d) => DateFormatter.formatDateShort(d);
  static String formatDateRange(DateTime from, DateTime to) =>
      DateFormatter.formatRangeUrdu(from, to);

  static String formatDateEnglish(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year % 100}';
  }

  static const headerRedOrange = PdfColor.fromInt(
    0xFFE67E22,
  ); // Target Orange #E67E22
  static const creditGreen = PdfColor.fromInt(0xFF27AE60);
  static const debitRed = PdfColor.fromInt(0xFFE74C3C);
  static const lightGreen = PdfColor.fromInt(0xFFE8F5E9);
  static const lightRed = PdfColor.fromInt(0xFFFFEBEE);
  static const borderColor = PdfColor.fromInt(0xFFDDDDDD);
  static const darkText = PdfColor.fromInt(0xFF212121);
  static const greyText = PdfColor.fromInt(0xFF757575);
  static const lightGrey = PdfColor.fromInt(0xFFF5F5F5);

  // Restored for backward compatibility
  static const orange = PdfColor.fromInt(0xFFE67E22);
  static const amberColor = PdfColor.fromInt(0xFFF39C12);
  static const amberBg = PdfColor.fromInt(0xFFFFF8E1);
  static const headerGreen = PdfColor.fromInt(0xFF1A6B3C);
  static const subtleGreyRow = PdfColor.fromInt(0xFFF9F9F9);

  static pw.Widget headerBar({
    required String businessName,
    required String phone,
    String appName = 'کسٹمر رپورٹ',
    PdfColor color = headerRedOrange,
  }) => pw.Container(
    color: color,
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 120,
            alignment: pw.Alignment.centerLeft,
            child: urduText(appName, fontSize: 12, color: PdfColors.white),
          ),
          pw.Expanded(
            child: pw.Center(
              child: urduText(
                businessName,
                fontSize: 16,
                color: PdfColors.white,
                isBold: true,
              ),
            ),
          ),
          pw.Container(
            width: 120,
            alignment: pw.Alignment.centerRight,
            child: urduText('کھاتہ', fontSize: 13, color: PdfColors.white),
          ),
        ],
      ),
    ),
  );

  static pw.Widget tableCell(
    String text, {
    double fontSize = 10,
    bool isBold = false,
    PdfColor color = PdfColors.black,
    pw.TextAlign align = pw.TextAlign.center,
    pw.EdgeInsets? padding,
    PdfColor? backgroundColor,
  }) {
    final hasUrdu = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    final isLtr =
        !hasUrdu &&
        (text.startsWith('Rs') ||
            text == '-' ||
            text.isEmpty ||
            text.contains(RegExp(r'[a-zA-Z]')));

    // In RTL contexts, the PDF bidi algorithm mirrors brackets: ( becomes ) and vice versa.
    // To keep them visually correct, we pre-swap them before giving them to the Text widget.
    final safeText = (!isLtr && text.contains('(') || text.contains(')'))
        ? text
              .replaceAll('(', '\x00')
              .replaceAll(')', '(')
              .replaceAll('\x00', ')')
        : text;

    final child = pw.Padding(
      padding: padding ?? const pw.EdgeInsets.all(6),
      child: pw.Directionality(
        textDirection: isLtr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
        child: pw.Text(
          safeText,
          style: pw.TextStyle(
            font: isBold ? _boldFont! : _regularFont!,
            fontSize: fontSize,
            color: color,
          ),
          textDirection: isLtr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
          textAlign: align,
        ),
      ),
    );

    if (backgroundColor != null)
      return pw.Container(color: backgroundColor, child: child);
    return child;
  }

  static pw.TableRow tableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          top: pw.BorderSide(color: borderColor, width: 1),
          bottom: pw.BorderSide(color: borderColor, width: 1),
        ),
      ),
      children: headers
          .map(
            (h) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 10,
              ),
              child: pw.Center(
                child: urduText(h, fontSize: 10, isBold: true, color: darkText),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.TableRow tableHeaderRowWidgets(List<pw.Widget> headers) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          top: pw.BorderSide(color: borderColor, width: 1),
          bottom: pw.BorderSide(color: borderColor, width: 1),
        ),
      ),
      children: headers
          .map(
            (h) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 10,
              ),
              child: pw.Center(child: h),
            ),
          )
          .toList(),
    );
  }

  static PdfColor rowColor(int index) =>
      index.isEven ? PdfColors.white : subtleGreyRow;

  static pw.Widget verticalDivider() =>
      pw.Container(width: 0.5, height: 55, color: borderColor);

  static pw.Widget summaryBox({
    required String label,
    required double amount,
    String? sign, // e.g. '(-)'
    String? subLabel,
    String? dateStr,
    required PdfColor amountColor,
  }) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          if (sign != null)
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '$sign ',
                    style: pw.TextStyle(
                      font: _fallbackFont ?? _regularFont!,
                      fontSize: 9,
                      color: greyText,
                    ),
                  ),
                  urduText(label, fontSize: 9, color: greyText),
                ],
              ),
            )
          else
            urduText(
              label,
              fontSize: 9,
              color: greyText,
              align: pw.TextAlign.center,
            ),

          pw.SizedBox(height: 4),
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              formatAmount(amount),
              style: amountStyle(
                fontSize: 13,
                isBold: true,
                color: amountColor,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          if (subLabel != null && subLabel.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '( ',
                    style: pw.TextStyle(
                      font: _fallbackFont ?? _regularFont!,
                      fontSize: 9,
                      color: greyText,
                    ),
                  ),
                  urduText(subLabel, fontSize: 9, color: greyText),
                  pw.Text(
                    ' )',
                    style: pw.TextStyle(
                      font: _fallbackFont ?? _regularFont!,
                      fontSize: 9,
                      color: greyText,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (dateStr != null && dateStr.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Text(
                dateStr,
                style: pw.TextStyle(
                  font: _fallbackFont ?? _regularFont!,
                  fontSize: 9,
                  color: greyText,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  static pw.Widget pageFooter(pw.Context context) {
    final now = DateTime.now();
    final formatted = DateFormatter.formatDateTimeUrdu(now);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start, // Align to Right in RTL
        children: [
          urduText(
            'تاریخ رپورٹ :',
            fontSize: 11,
            isBold: true,
            color: darkText,
          ),
          pw.SizedBox(width: 4),
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              formatted,
              style: pw.TextStyle(
                font: _fallbackFont ?? _regularFont!,
                fontSize: 11,
                color: darkText,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<File> saveFile(pw.Document pdf, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/reports');
    await folder.create(recursive: true);
    final file = File(
      '${folder.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
