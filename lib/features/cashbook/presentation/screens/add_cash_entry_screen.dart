/// Add Cash Entry Screen
/// Replaces the bottom sheet for adding/editing cash entries with a full-screen experience
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../domain/entities/cash_entry_entity.dart';
import '../providers/cashbook_provider.dart';
import '../../../transactions/presentation/widgets/calculator_bottom_sheet.dart';

class AddCashEntryScreen extends ConsumerStatefulWidget {
  final CashEntryEntity? existingEntry;

  const AddCashEntryScreen({
    super.key,
    this.existingEntry,
  });

  @override
  ConsumerState<AddCashEntryScreen> createState() =>
      _AddCashEntryScreenState();
}

class _AddCashEntryScreenState extends ConsumerState<AddCashEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customBankController = TextEditingController();
  final _personNameController = TextEditingController();
  final _accountTitleController = TextEditingController();
  CashType _selectedType = CashType.cashIn;
  String _selectedPaymentMethod = 'نقد';
  DateTime _selectedDate = DateTime.now();
  String? _attachmentPath;
  String? _attachmentType;
  String? _attachmentFileName;
  bool _isLoading = false;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final entry = widget.existingEntry!;
      _amountController.text = entry.amount.toStringAsFixed(0);
      _noteController.text = entry.note;
      _selectedType = entry.cashType;
      _selectedDate = entry.entryDate;
      _selectedPaymentMethod = entry.paymentMethod;
      _personNameController.text = entry.personName ?? '';
      _accountTitleController.text = entry.accountTitle ?? '';
      _attachmentPath = entry.attachmentPath;
      _attachmentType = entry.attachmentType;
      
      if (_attachmentPath != null) {
        _attachmentFileName = _attachmentPath!.split('/').last;
      }

      // If the payment method isn't in the standard list, it's a custom bank
      if (!CashEntryEntity.cashPaymentMethods
          .contains(entry.paymentMethod)) {
        _customBankController.text = entry.paymentMethod;
        _selectedPaymentMethod = 'دیگر';
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _customBankController.dispose();
    _personNameController.dispose();
    _accountTitleController.dispose();
    super.dispose();
  }

  Future<void> _openCalculator() async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CalculatorBottomSheet(),
    );
    if (result != null) {
      _amountController.text = result.truncateToDouble() == result
          ? result.toInt().toString()
          : result.toStringAsFixed(2);
    }
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

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('کیمرہ',
                  style: TextStyle(fontFamily: AppTextStyles.urduFont)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('گیلری',
                  style: TextStyle(fontFamily: AppTextStyles.urduFont)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked != null) {
        setState(() {
          _attachmentPath = picked.path;
          _attachmentType = 'image';
          _attachmentFileName = picked.name;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachmentPath = result.files.single.path;
          _attachmentType = 'pdf';
          _attachmentFileName = result.files.single.name;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickAnyFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachmentPath = result.files.single.path;
          _attachmentType = 'file';
          _attachmentFileName = result.files.single.name;
        });
      }
    } catch (_) {}
  }

  IconData _getAttachmentIcon() {
    switch (_attachmentType) {
      case 'image':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      default:
        return Icons.attach_file;
    }
  }

  String get _actualPaymentMethod {
    if (_selectedPaymentMethod == 'دیگر' &&
        _customBankController.text.trim().isNotEmpty) {
      return _customBankController.text.trim();
    }
    return _selectedPaymentMethod;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(cashEntriesProvider.notifier);
      final personName = _personNameController.text.trim().isNotEmpty
          ? _personNameController.text.trim()
          : null;
      final accountTitle = _accountTitleController.text.trim().isNotEmpty
          ? _accountTitleController.text.trim()
          : null;

      if (_isEditing) {
        await notifier.updateEntry(
          widget.existingEntry!.id,
          _selectedType,
          amount,
          _noteController.text.trim(),
          _selectedDate,
          paymentMethod: _actualPaymentMethod,
          personName: personName,
          accountTitle: accountTitle,
          attachmentPath: _attachmentPath,
          attachmentType: _attachmentType,
        );
      } else {
        await notifier.addEntry(
          _selectedType,
          amount,
          _noteController.text.trim(),
          _selectedDate,
          paymentMethod: _actualPaymentMethod,
          personName: personName,
          accountTitle: accountTitle,
          attachmentPath: _attachmentPath,
          attachmentType: _attachmentType,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, '${AppStrings.error}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = _selectedType == CashType.cashIn ? AppColors.credit : AppColors.debit;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: activeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'انٹری میں ترمیم کریں' : AppStrings.addCashEntry,
          style: const TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Type Toggle (In / Out) ───
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedType = CashType.cashIn),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedType == CashType.cashIn
                                ? AppColors.credit
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              AppStrings.cashIn,
                              style: TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedType == CashType.cashIn
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
                        onTap: () =>
                            setState(() => _selectedType = CashType.cashOut),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedType == CashType.cashOut
                                ? AppColors.debit
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              AppStrings.cashOut,
                              style: TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedType == CashType.cashOut
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
              const SizedBox(height: 24),
              
              // ─── Amount Field ───
              const Text(
                'رقم',
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
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
                        hintStyle: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHint,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: activeColor, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.calculate_outlined, color: activeColor, size: 28),
                      tooltip: 'حساب',
                      onPressed: _openCalculator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Payment Method Selector ───
              const Text(
                'ذریعہ ادائیگی',
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
                children: CashEntryEntity.cashPaymentMethods.map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  return ChoiceChip(
                    label: Text(
                      method,
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: activeColor,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected ? activeColor : AppColors.divider,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedPaymentMethod = method),
                  );
                }).toList(),
              ),

              // Custom bank name field if 'دیگر' selected
              if (_selectedPaymentMethod == 'دیگر') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customBankController,
                  decoration: InputDecoration(
                    labelText: 'بینک کا نام',
                    labelStyle: const TextStyle(fontFamily: AppTextStyles.urduFont),
                    hintText: 'بینک کا نام لکھیں',
                    hintStyle: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      color: AppColors.textHint,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: activeColor, width: 2),
                    ),
                  ),
                  style: const TextStyle(fontFamily: AppTextStyles.urduFont),
                ),
              ],
              const SizedBox(height: 16),

              // ─── Person Name (optional) ───
              TextFormField(
                controller: _personNameController,
                decoration: InputDecoration(
                  labelText: 'کس کو / کس سے (اختیاری)',
                  labelStyle: const TextStyle(fontFamily: AppTextStyles.urduFont),
                  hintText: 'شخص کا نام',
                  hintStyle: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    color: AppColors.textHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: activeColor, width: 2),
                  ),
                ),
                style: const TextStyle(fontFamily: AppTextStyles.urduFont),
              ),
              const SizedBox(height: 16),

              // ─── Account Title (optional) ───
              TextFormField(
                controller: _accountTitleController,
                decoration: InputDecoration(
                  labelText: 'اکاؤنٹ عنوان (اختیاری)',
                  labelStyle: const TextStyle(fontFamily: AppTextStyles.urduFont),
                  hintText: 'اکاؤنٹ کا عنوان',
                  hintStyle: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    color: AppColors.textHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: activeColor, width: 2),
                  ),
                ),
                style: const TextStyle(fontFamily: AppTextStyles.urduFont),
              ),
              const SizedBox(height: 16),

              // ─── Date Picker ───
              const Text(
                'تاریخ',
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
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
                      Icon(Icons.calendar_today, size: 20, color: activeColor),
                      const SizedBox(width: 12),
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
              const SizedBox(height: 16),

              // ─── Note Field ───
              TextFormField(
                controller: _noteController,
                maxLength: 200,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: 'نوٹ (اختیاری)',
                  labelStyle: const TextStyle(fontFamily: AppTextStyles.urduFont),
                  hintText: 'تفصیلات لکھیں...',
                  hintStyle: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    color: AppColors.textHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: activeColor, width: 2),
                  ),
                ),
                style: const TextStyle(fontFamily: AppTextStyles.urduFont),
              ),
              const SizedBox(height: 16),

              // ─── Attachment ───
              const Text(
                'فائل منسلک کریں (اختیاری)',
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _AttachButton(label: 'تصویر', icon: Icons.photo_camera, onTap: _pickImage),
                  const SizedBox(width: 8),
                  _AttachButton(label: 'پی ڈی ایف', icon: Icons.picture_as_pdf, onTap: _pickPdf),
                  const SizedBox(width: 8),
                  _AttachButton(label: 'فائل', icon: Icons.attach_file, onTap: _pickAnyFile),
                ],
              ),
              if (_attachmentPath != null) ...[
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(_getAttachmentIcon(), color: AppColors.primary),
                    title: Text(
                      _attachmentFileName ?? 'فائل',
                      style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.debit),
                      onPressed: () => setState(() {
                        _attachmentPath = null;
                        _attachmentType = null;
                        _attachmentFileName = null;
                      }),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              CustomButton(
                label: AppStrings.save,
                onPressed: _save,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40), // Extra scroll padding
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AttachButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
