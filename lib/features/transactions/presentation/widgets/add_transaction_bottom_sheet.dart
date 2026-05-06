/// Add Transaction Bottom Sheet
/// Modal bottom sheet for adding/editing transactions with type toggle, amount, payment method, note, and date.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_provider.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  final String partyId;
  final String businessId;
  final TransactionEntity? existingTransaction;

  const AddTransactionBottomSheet({
    super.key,
    required this.partyId,
    required this.businessId,
    this.existingTransaction,
  });

  @override
  ConsumerState<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState
    extends ConsumerState<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TxnType _selectedType = TxnType.credit;
  String _selectedPaymentMethod = 'نقد';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.existingTransaction != null;

  /// Payment method icons
  static const Map<String, IconData> _paymentIcons = {
    'نقد': Icons.money,
    'بینک ٹرانسفر': Icons.account_balance,
    'ایزی پیسہ': Icons.phone_android,
    'جاز کیش': Icons.phone_iphone,
    'یوپیسہ': Icons.smartphone,
    'دیگر': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final txn = widget.existingTransaction!;
      _amountController.text = txn.amount.toStringAsFixed(0);
      _noteController.text = txn.note;
      _selectedType = txn.txnType;
      _selectedPaymentMethod = txn.paymentMethod;
      _selectedDate = txn.txnDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ur', 'PK'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(
        transactionProviderFamily((widget.partyId, widget.businessId)).notifier,
      );

      if (_isEditing) {
        await notifier.updateTransaction(
          widget.existingTransaction!.id,
          _selectedType,
          amount,
          _noteController.text.trim(),
          _selectedDate,
          paymentMethod: _selectedPaymentMethod,
        );
      } else {
        await notifier.addTransaction(
          _selectedType,
          amount,
          _noteController.text.trim(),
          _selectedDate,
          paymentMethod: _selectedPaymentMethod,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.error}: $e',
              style: const TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
            backgroundColor: AppColors.debit,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? AppStrings.editTransaction : AppStrings.addTransaction,
                style: const TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Type toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = TxnType.credit),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedType == TxnType.credit
                                ? AppColors.debit
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              AppStrings.gave_label,
                              style: TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _selectedType == TxnType.credit
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = TxnType.debit),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedType == TxnType.debit
                                ? AppColors.credit
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              AppStrings.received_label,
                              style: TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _selectedType == TxnType.debit
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: Validators.validateAmount,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '${AppStrings.currency} ',
                  prefixStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Payment Method Selector ───
              const Text(
                'ادائیگی کا طریقہ',
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TransactionEntity.paymentMethods.map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  final icon = _paymentIcons[method] ?? Icons.payment;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPaymentMethod = method),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            method,
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Note field
              TextFormField(
                controller: _noteController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: AppStrings.note,
                  labelStyle: const TextStyle(fontFamily: AppTextStyles.urduFont),
                  hintText: AppStrings.note,
                  hintStyle: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    color: AppColors.textHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                style: const TextStyle(fontFamily: AppTextStyles.urduFont),
              ),
              const SizedBox(height: 12),
              // Date picker
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        '${AppStrings.date}: ',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.urduFont,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDate(_selectedDate),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.urduFont,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: AppStrings.save,
                onPressed: _save,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
