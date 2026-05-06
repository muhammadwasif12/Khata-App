/// Invoice Preview Screen — View invoice details, record payments, delete and generate PDF.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/invoice_item_entity.dart';
import '../providers/invoice_provider.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  final String invoiceId;
  const InvoicePreviewScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoicesProvider).valueOrNull ?? [];
    final invoice =
        invoices.where((i) => i.id == invoiceId).firstOrNull;

    if (invoice == null) {
      return const Scaffold(body: LoadingWidget());
    }

    final items = ref.read(invoicesProvider.notifier).getInvoiceItems(invoiceId);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'احسان بیلنگ پریس',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${invoice.invoiceNumber} — ${invoice.customerName.isNotEmpty ? invoice.customerName : 'بغیر نام'}',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                showConfirmationDialog(
                  context: context,
                  title: 'بل حذف کریں',
                  message: 'کیا آپ واقعی یہ بل حذف کرنا چاہتے ہیں؟',
                  confirmLabel: 'حذف کریں',
                  onConfirm: () {
                    ref.read(invoicesProvider.notifier).deleteInvoice(invoiceId);
                    context.pop();
                  },
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.debit),
                    SizedBox(width: 8),
                    Text('حذف کریں',
                        style: TextStyle(fontFamily: AppTextStyles.urduFont)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Invoice header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primarySurface, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                DateFormatter.formatDate(invoice.invoiceDate),
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.urduFont,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _StatusBadge(status: invoice.status),
                    ],
                  ),
                  const Divider(height: 24),
                  // Customer info
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            invoice.customerName.isNotEmpty
                                ? invoice.customerName[0]
                                : '؟',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.customerName.isNotEmpty
                                  ? invoice.customerName
                                  : 'بغیر نام',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (invoice.customerPhone.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone,
                                        size: 14, color: AppColors.textHint),
                                    const SizedBox(width: 4),
                                    Text(
                                      invoice.customerPhone,
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items table
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'آئٹم',
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'مقدار',
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'قیمت',
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'رقم',
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Items
                  ...items.asMap().entries.map(
                    (entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: idx.isEven ? Colors.white : AppColors.background,
                          border: const Border(
                            bottom: BorderSide(color: AppColors.divider, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primarySurface,
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.urduFont,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.formatAmount(item.rate),
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.formatAmount(item.amount),
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Totals card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTotalRow('ذیلی کل', invoice.subtotal, false),
                  if (invoice.discount > 0)
                    _buildTotalRow('رعایت', -invoice.discount, false),
                  const Divider(height: 16),
                  _buildTotalRow('کل رقم', invoice.totalAmount, true),
                  const SizedBox(height: 4),
                  _buildTotalRow('ادا شدہ', invoice.paidAmount, false,
                      color: AppColors.credit),
                  if (invoice.balanceAmount > 0) ...[
                    const Divider(height: 12),
                    _buildTotalRow('باقی رقم', invoice.balanceAmount, true,
                        color: AppColors.debit),
                  ],
                ],
              ),
            ),

            if (invoice.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amberBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_outlined,
                        size: 18, color: AppColors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        invoice.note,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.urduFont,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Payment button for unpaid invoices
            if (invoice.status != InvoiceStatus.paid) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(context, ref, invoice),
                icon: const Icon(Icons.payments),
                label: const Text(
                  'رقم وصول کریں',
                  style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.credit,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ],

            // PDF & Share buttons
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _generatePdf(context, invoice, items),
                    icon: const Icon(Icons.picture_as_pdf, size: 20),
                    label: const Text(
                      'PDF دیکھیں',
                      style: TextStyle(fontFamily: AppTextStyles.urduFont),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sharePdf(context, invoice, items),
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text(
                      'شیئر کریں',
                      style: TextStyle(fontFamily: AppTextStyles.urduFont),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.indigo,
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: AppColors.indigo),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, bool isBold,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.urduFont,
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.textSecondary,
            ),
          ),
          Text(
            CurrencyFormatter.formatAmount(value.abs()),
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: isBold ? 20 : 14,
              fontWeight: FontWeight.bold,
              color: color ?? (isBold ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
      BuildContext context, WidgetRef ref, InvoiceEntity invoice) {
    final controller =
        TextEditingController(text: invoice.balanceAmount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.payments, color: AppColors.credit, size: 24),
            SizedBox(width: 8),
            Text(
              'رقم وصول کریں',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'باقی رقم: ${CurrencyFormatter.formatAmount(invoice.balanceAmount)}',
              style: const TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 14,
                color: AppColors.debit,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 20),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                labelText: 'وصول شدہ رقم',
                labelStyle: const TextStyle(fontFamily: AppTextStyles.urduFont),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.credit, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('منسوخ',
                style: TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                ref
                    .read(invoicesProvider.notifier)
                    .recordPayment(invoiceId, amount);
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.credit,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            label: const Text('وصول کریں',
                style: TextStyle(fontFamily: AppTextStyles.urduFont)),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, InvoiceEntity invoice,
      List<InvoiceItemEntity> items) async {
    final pdf = await _buildPdf(invoice, items);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Future<void> _sharePdf(BuildContext context, InvoiceEntity invoice,
      List<InvoiceItemEntity> items) async {
    final pdf = await _buildPdf(invoice, items);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${invoice.invoiceNumber}.pdf',
    );
  }

  Future<pw.Document> _buildPdf(
      InvoiceEntity invoice, List<InvoiceItemEntity> items) async {
    await PdfHelper.loadFonts();

    // Build items table rows
    final tableRows = <pw.TableRow>[];
    tableRows.add(PdfHelper.tableHeaderRow([
      '#',
      'آئٹم',
      'مقدار',
      'یونٹ',
      'قیمت',
      'رقم',
    ]));
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final bg = PdfHelper.rowColor(i);
      tableRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          PdfHelper.tableCell('${i + 1}'),
          PdfHelper.tableCell(item.productName),
          PdfHelper.tableCell(item.quantity.toStringAsFixed(0)),
          PdfHelper.tableCell(item.unit),
          PdfHelper.tableCell(PdfHelper.formatAmount(item.rate)),
          PdfHelper.tableCell(PdfHelper.formatAmount(item.amount), isBold: true),
        ],
      ));
    }

    // Status text
    String statusText;
    PdfColor statusColor;
    switch (invoice.status) {
      case InvoiceStatus.paid:
        statusText = 'ادا شدہ';
        statusColor = PdfHelper.creditGreen;
        break;
      case InvoiceStatus.partial:
        statusText = 'جزوی ادائیگی';
        statusColor = PdfHelper.amberColor;
        break;
      case InvoiceStatus.unpaid:
        statusText = 'بقایا';
        statusColor = PdfHelper.debitRed;
        break;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: PdfHelper.theme,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ─── Header ───
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const pw.BoxDecoration(
                color: PdfHelper.orange,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      PdfHelper.urduText('احسان بیلنگ پریس',
                          fontSize: 18, isBold: true, color: PdfColors.white),
                      pw.SizedBox(height: 2),
                      PdfHelper.urduText('بل / انوائس',
                          fontSize: 10, color: PdfColor.fromInt(0xFFFFCCBC)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(invoice.invoiceNumber,
                          style: PdfHelper.amountStyle(fontSize: 14, isBold: true, color: PdfColors.white),
                          textDirection: pw.TextDirection.ltr),
                      pw.SizedBox(height: 2),
                      pw.Text(
                          '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                          style: PdfHelper.amountStyle(fontSize: 10, color: PdfColor.fromInt(0xFFFFCCBC)),
                          textDirection: pw.TextDirection.ltr),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ─── Customer details ───
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfHelper.borderColor),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        PdfHelper.urduText('گاہک: ',
                            fontSize: 10, color: PdfColors.grey700),
                        PdfHelper.urduText(
                            invoice.customerName.isNotEmpty
                                ? invoice.customerName
                                : 'بغیر نام',
                            fontSize: 11, isBold: true),
                      ]),
                      if (invoice.customerPhone.isNotEmpty) ...
                        [pw.SizedBox(height: 2),
                        pw.Row(children: [
                          PdfHelper.urduText('فون: ',
                              fontSize: 9, color: PdfColors.grey700),
                          pw.Text(invoice.customerPhone,
                              style: PdfHelper.amountStyle(fontSize: 10),
                              textDirection: pw.TextDirection.ltr),
                        ])],
                      if (invoice.vehicleNumber.isNotEmpty) ...
                        [pw.SizedBox(height: 2),
                        pw.Row(children: [
                          PdfHelper.urduText('گاڑی: ',
                              fontSize: 9, color: PdfColors.grey700),
                          pw.Text(invoice.vehicleNumber,
                              style: PdfHelper.amountStyle(fontSize: 10),
                              textDirection: pw.TextDirection.ltr),
                        ])],
                    ],
                  ),
                  // Status badge
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: statusColor,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: PdfHelper.urduText(statusText,
                        fontSize: 9, isBold: true, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ─── Items Table ───
            pw.Table(
              border: pw.TableBorder.all(color: PdfHelper.borderColor, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.6),  // #
                1: const pw.FlexColumnWidth(3),    // آئٹم
                2: const pw.FlexColumnWidth(1.2),  // مقدار
                3: const pw.FlexColumnWidth(1),    // یونٹ
                4: const pw.FlexColumnWidth(1.5),  // قیمت
                5: const pw.FlexColumnWidth(1.8),  // رقم
              },
              children: tableRows,
            ),
            pw.SizedBox(height: 16),

            // ─── Amount Summary ───
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfHelper.lightGrey,
                border: pw.Border.all(color: PdfHelper.borderColor),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  _pdfAmountRow('ذیلی کل', invoice.subtotal),
                  if (invoice.discount > 0)
                    _pdfAmountRow('رعایت', invoice.discount, color: PdfHelper.debitRed),
                  pw.Divider(color: PdfHelper.borderColor),
                  _pdfAmountRow('کل رقم', invoice.totalAmount,
                      bold: true, color: PdfHelper.orange),
                  _pdfAmountRow('ادا شدہ', invoice.paidAmount,
                      color: PdfHelper.creditGreen),
                  if (invoice.balanceAmount > 0)
                    _pdfAmountRow('باقی رقم', invoice.balanceAmount,
                        bold: true, color: PdfHelper.debitRed),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // ─── Footer ───
            pw.Divider(color: PdfHelper.borderColor),
            pw.SizedBox(height: 8),
            pw.Center(
              child: PdfHelper.urduText('کھاتہ ایپ — احسان بیلنگ پریس',
                  fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
    return pdf;
  }

  pw.Widget _pdfAmountRow(String label, double amount,
      {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          PdfHelper.urduText(label,
              fontSize: bold ? 12 : 11, isBold: bold),
          PdfHelper.amountText(amount,
              fontSize: bold ? 14 : 12, isBold: bold, color: color),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case InvoiceStatus.paid:
        color = AppColors.credit;
        label = 'ادا شدہ';
        icon = Icons.check_circle;
        break;
      case InvoiceStatus.partial:
        color = AppColors.amber;
        label = 'جزوی ادائیگی';
        icon = Icons.hourglass_bottom;
        break;
      case InvoiceStatus.unpaid:
        color = AppColors.debit;
        label = 'بقایا';
        icon = Icons.warning_amber;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.urduFont,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
