/// Create Invoice Screen — Full invoice creation with item list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../stock/presentation/providers/stock_provider.dart';
import '../../domain/entities/invoice_item_entity.dart';
import '../../domain/entities/invoice_entity.dart';
import '../providers/invoice_provider.dart';
import 'invoice_preview_screen.dart';
import 'stock_selection_screen.dart';
import '../../../stock/domain/entities/product_entity.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _paidController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  bool _isLoading = false;

  final List<_InvoiceLineItem> _items = [];

  double get _subtotal =>
      _items.fold<double>(0, (s, i) => s + i.amount);

  double get _discount =>
      double.tryParse(_discountController.text) ?? 0;

  double get _total => (_subtotal - _discount).clamp(0, double.infinity);

  void _addItem() {
    setState(() {
      _items.add(_InvoiceLineItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کم از کم ایک آئٹم شامل کریں',
              style: TextStyle(fontFamily: AppTextStyles.urduFont)),
          backgroundColor: AppColors.debit,
        ),
      );
      return;
    }

    // Validate all items have name and quantity
    for (final item in _items) {
      if (item.nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمام آئٹمز کا نام درج کریں',
                style: TextStyle(fontFamily: AppTextStyles.urduFont)),
            backgroundColor: AppColors.debit,
          ),
        );
        return;
      }
      if (item.unit == 'دیگر' && item.customUnitController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('دیگر اکائی درج کریں',
                style: TextStyle(fontFamily: AppTextStyles.urduFont)),
            backgroundColor: AppColors.debit,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final invoiceItems = _items
          .map((item) => InvoiceItemEntity(
                id: const Uuid().v4(),
                invoiceId: '', // Will be set by provider
                productName: item.nameController.text.trim(),
                productId: item.selectedProductId,
                quantity: double.tryParse(item.qtyController.text) ?? 1,
                rate: double.tryParse(item.rateController.text) ?? 0,
                amount: item.amount,
                unit: item.finalUnit,
              ))
          .toList();

      await ref.read(invoicesProvider.notifier).createInvoice(
            customerName: _nameController.text.trim(),
            customerPhone: _phoneController.text.trim(),
            items: invoiceItems,
            subtotal: _subtotal,
            vehicleNumber: _vehicleController.text.trim(),
            discount: _discount,
            totalAmount: _total,
            paidAmount: double.tryParse(_paidController.text) ?? 0,
            invoiceDate: _invoiceDate,
            note: _noteController.text.trim(),
          );

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خرابی: $e'),
            backgroundColor: AppColors.debit,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _discountController.dispose();
    _paidController.dispose();
    _noteController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'نیا بل بنائیں',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'گراہک کی تفصیلات',
                    style: TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _nameController,
                    label: 'گراہک کا نام',
                    hint: 'نام درج کریں',
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'موبائل نمبر (اختیاری)',
                    hint: '03001234567',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _vehicleController,
                    label: 'گاڑی نمبر (اختیاری)',
                    hint: 'LHE-1234',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'آئٹمز',
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final products = ref.read(productsProvider).valueOrNull ?? [];
                            final selectedProducts = await Navigator.push<List<ProductEntity>>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StockSelectionScreen(products: products),
                              ),
                            );
                            if (selectedProducts != null && selectedProducts.isNotEmpty) {
                              setState(() {
                                // Remove empty row if there's only one empty row
                                if (_items.length == 1 && _items[0].nameController.text.isEmpty) {
                                  _items.clear();
                                }
                                for (final p in selectedProducts) {
                                  final newItem = _InvoiceLineItem();
                                  newItem.nameController.text = p.name;
                                  newItem.rateController.text = p.salePrice.toStringAsFixed(0);
                                  newItem.qtyController.text = '1';
                                  newItem.selectedProductId = p.id;
                                  newItem.unit = p.unit;
                                  _items.add(newItem);
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                          tooltip: 'اسٹاک سے منتخب کریں',
                        ),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'آئٹم شامل کریں',
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          '+ بٹن دبا کر آئٹم شامل کریں',
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                  ...List.generate(_items.length, (index) {
                    final item = _items[index];
                    return _ItemRow(
                      item: item,
                      index: index + 1,
                      onRemove: () => _removeItem(index),
                      onChanged: () => setState(() {}),
                      products: ref
                              .watch(productsProvider)
                              .valueOrNull ??
                          [],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Totals
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _TotalRow(
                      label: 'ذیلی کل', value: _subtotal, isBold: false),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'رعایت',
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            prefixText: 'Rs. ',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _TotalRow(
                      label: 'کل رقم', value: _total, isBold: true),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ادا شدہ رقم',
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 14,
                            color: AppColors.credit,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _paidController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            prefixText: 'Rs. ',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _TotalRow(
                    label: 'بقیہ',
                    value: _total - (double.tryParse(_paidController.text) ?? 0),
                    isBold: true,
                    color: AppColors.debit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Note & Date
            CustomTextField(
              controller: _noteController,
              label: 'نوٹ (اختیاری)',
              hint: 'بل سے متعلق نوٹ',
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _invoiceDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('ur', 'PK'),
                );
                if (picked != null) setState(() => _invoiceDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'بل محفوظ کریں',
              onPressed: _save,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Helper classes ───

class _InvoiceLineItem {
  final nameController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final rateController = TextEditingController(text: '0');
  final customUnitController = TextEditingController();
  String? selectedProductId;
  String unit = 'عدد';

  String get finalUnit => unit == 'دیگر' ? customUnitController.text.trim() : unit;

  double get amount =>
      (double.tryParse(qtyController.text) ?? 0) *
      (double.tryParse(rateController.text) ?? 0);

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    rateController.dispose();
    customUnitController.dispose();
  }
}

class _ItemRow extends StatelessWidget {
  final _InvoiceLineItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final List<dynamic> products;

  const _ItemRow({
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onChanged,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: item.nameController,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '\u0622\u0626\u0679\u0645 \u06a9\u0627 \u0646\u0627\u0645',
                    hintStyle: TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      color: AppColors.textHint,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
              // Product selection from stock
              if (products.isNotEmpty)
                PopupMenuButton<dynamic>(
                  icon: const Icon(Icons.inventory_2_outlined,
                      size: 18, color: AppColors.primary),
                  tooltip: '\u0627\u0633\u0679\u0627\u06a9 \u0633\u06d2 \u0645\u0646\u062a\u062e\u0628 \u06a9\u0631\u06cc\u06ba',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (product) {
                    item.nameController.text = product.name;
                    item.rateController.text = product.salePrice.toStringAsFixed(0);
                    item.selectedProductId = product.id;
                    item.unit = product.unit;
                    onChanged();
                  },
                  itemBuilder: (_) => products.map((p) {
                    return PopupMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                p.name.isNotEmpty ? p.name[0] : '?',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.urduFont,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.urduFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rs. ${p.salePrice.toStringAsFixed(0)} | ${p.currentStock.toStringAsFixed(0)} ${p.unit}',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.debitBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close,
                      size: 16, color: AppColors.debit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.qtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: '\u0645\u0642\u062f\u0627\u0631',
                    labelStyle: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 11,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              // Unit Dropdown
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: item.unit,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    items: const [
                      'عدد',
                      'کلو',
                      'گرام',
                      'لیٹر',
                      'میٹر',
                      'فٹ',
                      'درجن',
                      'پیکٹ',
                      'بوری',
                      'کارٹن',
                      'پیس',
                      'من',
                      'دیگر',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        item.unit = newValue;
                        onChanged();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: item.rateController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: '\u0642\u06cc\u0645\u062a',
                    labelStyle: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 11,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.formatAmount(item.amount),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          if (item.unit == 'دیگر') ...[
            const SizedBox(height: 10),
            TextField(
              controller: item.customUnitController,
              style: const TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'اپنی اکائی لکھیں',
                hintStyle: const TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  color: AppColors.textHint,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final Color? color;

  const _TotalRow(
      {required this.label, required this.value, required this.isBold, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
        Text(
          CurrencyFormatter.formatAmount(value),
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: isBold ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: color ?? (isBold ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
