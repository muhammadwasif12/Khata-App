/// Give Screen — Full page for recording "دیا" (gave / credit given)
/// Uses shared _TransactionFormBody widget for code reuse with ReceiveScreen.
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
import '../../../customers/data/repositories/party_repository_impl.dart';
import '../../../customers/domain/entities/party_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_provider.dart';
import '../widgets/calculator_bottom_sheet.dart';

class GiveScreen extends ConsumerStatefulWidget {
  final String partyId;
  const GiveScreen({super.key, required this.partyId});

  @override
  ConsumerState<GiveScreen> createState() => _GiveScreenState();
}

class _GiveScreenState extends ConsumerState<GiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customBankController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _attachmentPath;
  String? _attachmentType;
  String? _attachmentFileName;
  bool _isLoading = false;
  PartyEntity? _party;
  String _selectedPaymentMethod = 'نقد';

  @override
  void initState() {
    super.initState();
    _loadParty();
  }

  Future<void> _loadParty() async {
    final repo = PartyRepositoryImpl();
    final party = await repo.getPartyById(widget.partyId);
    if (mounted) setState(() => _party = party);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _customBankController.dispose();
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
    if (picked != null) setState(() => _selectedDate = picked);
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
    if (amount == null || amount <= 0) {
      ErrorSnackbar.show(context, AppStrings.invalidAmount);
      return;
    }
    if (_party == null) return;

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(
        transactionProviderFamily((widget.partyId, _party!.businessId)).notifier,
      );
      await notifier.addTransaction(
        TxnType.credit, // credit = gave
        amount,
        _noteController.text.trim(),
        _selectedDate,
        paymentMethod: _actualPaymentMethod,
        attachmentPath: _attachmentPath,
        attachmentType: _attachmentType,
      );
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.debit,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80, // Increased height for Urdu text
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'دیا — ادھار دیا',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (_party != null)
              Text(
                _party!.name,
                style: const TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Section 1: Amount ───
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
                          borderSide: const BorderSide(
                              color: AppColors.debit, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.debit.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.calculate_outlined,
                          color: AppColors.debit, size: 28),
                      tooltip: 'حساب',
                      onPressed: _openCalculator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                  return ChoiceChip(
                    label: Text(
                      method,
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.debit,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color:
                          isSelected ? AppColors.debit : AppColors.divider,
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
                    labelStyle:
                        const TextStyle(fontFamily: AppTextStyles.urduFont),
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
                      borderSide: const BorderSide(
                          color: AppColors.debit, width: 2),
                    ),
                  ),
                  style: const TextStyle(fontFamily: AppTextStyles.urduFont),
                ),
              ],
              const SizedBox(height: 20),

              // ─── Section 2: Date ───
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
                      const Icon(Icons.calendar_today,
                          size: 20, color: AppColors.debit),
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
              const SizedBox(height: 20),

              // ─── Section 3: Note ───
              TextFormField(
                controller: _noteController,
                maxLength: 200,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: 'نوٹ (اختیاری)',
                  labelStyle:
                      const TextStyle(fontFamily: AppTextStyles.urduFont),
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
                    borderSide:
                        const BorderSide(color: AppColors.debit, width: 2),
                  ),
                ),
                style: const TextStyle(fontFamily: AppTextStyles.urduFont),
              ),
              const SizedBox(height: 20),

              // ─── Section 4: Attachment ───
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
                  _AttachButton(
                    label: 'تصویر',
                    icon: Icons.photo_camera,
                    onTap: _pickImage,
                  ),
                  const SizedBox(width: 8),
                  _AttachButton(
                    label: 'پی ڈی ایف',
                    icon: Icons.picture_as_pdf,
                    onTap: _pickPdf,
                  ),
                  const SizedBox(width: 8),
                  _AttachButton(
                    label: 'فائل',
                    icon: Icons.attach_file,
                    onTap: _pickAnyFile,
                  ),
                ],
              ),
              if (_attachmentPath != null) ...[
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading:
                        Icon(_getAttachmentIcon(), color: AppColors.primary),
                    title: Text(
                      _attachmentFileName ?? 'فائل',
                      style: const TextStyle(
                          fontFamily: AppTextStyles.urduFont, fontSize: 13),
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

              // ─── Section 5: Save ───
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
