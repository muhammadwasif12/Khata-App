/// Stock In Screen — Full screen for recording stock IN entries.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/stock_entry_entity.dart';
import '../providers/stock_provider.dart';

class StockInScreen extends ConsumerStatefulWidget {
  final String productId;
  const StockInScreen({super.key, required this.productId});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _rateController = TextEditingController();
  final _noteController = TextEditingController();
  final _supplierController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill rate from product's purchase price
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final products = ref.read(productsProvider).valueOrNull ?? [];
      final product = products.where((p) => p.id == widget.productId).firstOrNull;
      if (product != null) {
        _rateController.text = product.purchasePrice.toStringAsFixed(0);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ur', 'PK'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.credit,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(stockEntriesProvider(widget.productId).notifier)
          .addStockEntry(
            entryType: StockType.stockIn,
            quantity: double.tryParse(_qtyController.text) ?? 0,
            rate: double.tryParse(_rateController.text) ?? 0,
            note: _supplierController.text.trim().isNotEmpty
                ? '${_supplierController.text.trim()}${_noteController.text.trim().isNotEmpty ? ' - ${_noteController.text.trim()}' : ''}'
                : _noteController.text.trim(),
            date: _selectedDate,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خرابی: $e',
                style: const TextStyle(fontFamily: AppTextStyles.urduFont)),
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
    _qtyController.dispose();
    _rateController.dispose();
    _noteController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider).valueOrNull ?? [];
    final product = products.where((p) => p.id == widget.productId).firstOrNull;
    final entriesAsync = ref.watch(stockEntriesProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اسٹاک ان (خرید)',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            if (product != null)
              Text(
                '${product.name} — ${product.currentStock.toStringAsFixed(0)} ${product.unit} موجود',
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.credit,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          // ─── Form Section ───
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.creditBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.credit.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.credit.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.credit.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_downward, color: AppColors.credit, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'نیا اسٹاک اندراج',
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.credit,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _qtyController,
                          label: 'مقدار',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'مقدار درج کریں';
                            final num = double.tryParse(v);
                            if (num == null || num <= 0) return 'درست مقدار';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _rateController,
                          label: 'فی یونٹ قیمت',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'قیمت درج کریں';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _supplierController,
                    label: 'سپلائر / پارٹی کا نام (اختیاری)',
                    hint: 'سپلائر کا نام',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _noteController,
                    label: 'نوٹ (اختیاری)',
                    hint: 'مثلاً: بل نمبر 123',
                  ),
                  const SizedBox(height: 12),
                  // Date
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 18, color: AppColors.credit),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'تاریخ تبدیل کریں',
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 12,
                              color: AppColors.credit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Show calculated total
                  if (_qtyController.text.isNotEmpty && _rateController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.credit.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'کل رقم:',
                              style: TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatAmount(
                                (double.tryParse(_qtyController.text) ?? 0) *
                                    (double.tryParse(_rateController.text) ?? 0),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.credit,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'اسٹاک ان محفوظ کریں',
                    onPressed: _save,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
          // ─── Recent Stock In Entries ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.credit.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, size: 16, color: AppColors.credit),
                ),
                const SizedBox(width: 8),
                const Text(
                  'حالیہ اسٹاک ان',
                  style: TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          entriesAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('خرابی: $e')),
              data: (entries) {
                final inEntries = entries
                    .where((e) => e.entryType == StockType.stockIn)
                    .toList()
                    .reversed
                    .toList();
                if (inEntries.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.arrow_downward,
                    title: 'ابھی کوئی اسٹاک ان نہیں',
                    description: 'اوپر فارم سے اسٹاک ان کریں',
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                  itemCount: inEntries.length,
                  itemBuilder: (context, index) {
                    final entry = inEntries[index];
                    return _StockInEntryCard(
                      entry: entry,
                      product: product!,
                      onDelete: () {
                        ref
                            .read(stockEntriesProvider(widget.productId).notifier)
                            .deleteEntry(entry);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StockInEntryCard extends StatelessWidget {
  final StockEntryEntity entry;
  final ProductEntity product;
  final VoidCallback onDelete;

  const _StockInEntryCard({
    required this.entry,
    required this.product,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.credit.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward, color: AppColors.credit, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+${entry.quantity.toStringAsFixed(0)} ${product.unit}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.credit,
                  ),
                ),
                if (entry.note.isNotEmpty)
                  Text(
                    entry.note,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  DateFormatter.formatDate(entry.entryDate),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatAmount(entry.totalAmount),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '@ ${CurrencyFormatter.formatAmount(entry.rate)}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('اندراج حذف کریں',
                      style: TextStyle(fontFamily: AppTextStyles.urduFont)),
                  content: const Text('کیا آپ واقعی حذف کرنا چاہتے ہیں؟',
                      style: TextStyle(fontFamily: AppTextStyles.urduFont)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('منسوخ',
                          style: TextStyle(fontFamily: AppTextStyles.urduFont)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onDelete();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.debit,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('حذف کریں',
                          style: TextStyle(fontFamily: AppTextStyles.urduFont)),
                    ),
                  ],
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.debit.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, size: 16, color: AppColors.debit),
            ),
          ),
        ],
      ),
    );
  }
}
