/// Add Stock Entry Bottom Sheet
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/stock_entry_entity.dart';
import '../providers/stock_provider.dart';

class AddStockEntryBottomSheet extends ConsumerStatefulWidget {
  final String productId;
  final StockType entryType;

  const AddStockEntryBottomSheet({
    super.key,
    required this.productId,
    required this.entryType,
  });

  @override
  ConsumerState<AddStockEntryBottomSheet> createState() =>
      _AddStockEntryBottomSheetState();
}

class _AddStockEntryBottomSheetState
    extends ConsumerState<AddStockEntryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _rateController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isStockIn => widget.entryType == StockType.stockIn;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ur', 'PK'),
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
            entryType: widget.entryType,
            quantity: double.tryParse(_qtyController.text) ?? 0,
            rate: double.tryParse(_rateController.text) ?? 0,
            note: _noteController.text.trim(),
            date: _selectedDate,
          );
      if (mounted) Navigator.pop(context);
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
    _qtyController.dispose();
    _rateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              _isStockIn ? 'اسٹاک ان (خرید)' : 'اسٹاک آؤٹ (فروخت)',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isStockIn ? AppColors.credit : AppColors.debit,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
                      if (num == null || num <= 0) return 'درست مقدار درج کریں';
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
              controller: _noteController,
              label: 'نوٹ (اختیاری)',
              hint: 'مثلاً: پارٹی کا نام',
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
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: AppColors.primary),
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
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'محفوظ کریں',
              onPressed: _save,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
