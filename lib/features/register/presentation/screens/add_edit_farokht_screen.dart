import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/farokht_entity.dart';
import '../providers/farokht_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import '../../../transactions/presentation/widgets/calculator_bottom_sheet.dart';

class AddEditFarokhtScreen extends ConsumerStatefulWidget {
  final String? editId;
  const AddEditFarokhtScreen({super.key, this.editId});

  @override
  ConsumerState<AddEditFarokhtScreen> createState() =>
      _AddEditFarokhtScreenState();
}

class _AddEditFarokhtScreenState extends ConsumerState<AddEditFarokhtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _buyerCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _creditCtrl = TextEditingController();
  final _tafazulCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customUnitCtrl = TextEditingController();
  final _customPaymentCtrl = TextEditingController();

  String _weightUnit = 'کلو';
  int _paymentStatus = 1; // 0=ادھار 1=نقد 2=جزوی 3=دیگر
  DateTime _saleDate = DateTime.now();
  String _imagePath = '';
  bool _isLoading = false;

  static const _weightUnits = ['کلو', 'بوری', 'من', 'پیس', 'لیٹر', 'میٹر', 'درجن', 'دیگر'];

  bool get _isEditing => widget.editId != null;

  double get _weight => double.tryParse(_weightCtrl.text) ?? 0;
  double get _rate => double.tryParse(_rateCtrl.text) ?? 0;
  double get _totalAmount => _weight * _rate;
  double get _creditAmount {
    if (_paymentStatus == 1) return _totalAmount;
    if (_paymentStatus == 0) return 0;
    return double.tryParse(_creditCtrl.text) ?? 0;
  }
  double get _debitAmount => (_totalAmount - _creditAmount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
    _weightCtrl.addListener(() => setState(() {}));
    _rateCtrl.addListener(() => setState(() {}));
    _creditCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadExisting() async {
    final records = ref.read(farokhtProvider).value ?? [];
    final existing = records.where((r) => r.id == widget.editId).firstOrNull;
    if (existing != null) {
      _itemNameCtrl.text = existing.itemName;
      _buyerCtrl.text = existing.buyerName;
      _cardCtrl.text = existing.cardNumber;
      _weightCtrl.text = existing.weight.toString();
      _rateCtrl.text = existing.ratePerUnit.toString();
      _creditCtrl.text = existing.creditAmount > 0
          ? existing.creditAmount.toString()
          : '';
      _tafazulCtrl.text = existing.tafazul > 0
          ? existing.tafazul.toString()
          : '';
      _noteCtrl.text = existing.note;
      if (_weightUnits.contains(existing.weightUnit) && existing.weightUnit != 'دیگر') {
        _weightUnit = existing.weightUnit;
      } else {
        _weightUnit = 'دیگر';
        _customUnitCtrl.text = existing.weightUnit;
      }
      _paymentStatus = existing.paymentStatus;
      if (_paymentStatus == 3) {
        _customPaymentCtrl.text = existing.customPaymentType;
      }
      _saleDate = existing.saleDate;
      _imagePath = existing.imagePath;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _buyerCtrl.dispose();
    _cardCtrl.dispose();
    _weightCtrl.dispose();
    _rateCtrl.dispose();
    _creditCtrl.dispose();
    _tafazulCtrl.dispose();
    _noteCtrl.dispose();
    _customUnitCtrl.dispose();
    _customPaymentCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCalculator(TextEditingController ctrl) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CalculatorBottomSheet(),
    );
    if (result != null) {
      setState(() {
        ctrl.text = result.truncateToDouble() == result
            ? result.toInt().toString()
            : result.toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'ترمیم کریں' : 'فروخت درج کریں',
          style: const TextStyle(fontFamily: AppTextStyles.urduFont),
        ),
        backgroundColor: const Color(0xFFE67E22),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. چیز کا نام
            _buildLabel('چیز کا نام *'),
            TextFormField(
              controller: _itemNameCtrl,
              decoration: _inputDecoration('مثلاً: آلو، گندم، چاول'),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'چیز کا نام ضروری ہے'
                  : null,
              style: _inputStyle,
            ),
            const SizedBox(height: 16),

            // 2. خریدار کا نام
            _buildLabel('خریدار کا نام *'),
            TextFormField(
              controller: _buyerCtrl,
              decoration: _inputDecoration('خریدار کا نام لکھیں'),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'خریدار کا نام ضروری ہے'
                  : null,
              style: _inputStyle,
            ),
            const SizedBox(height: 16),

            // 3. کارڈ / گاڑی نمبر
            _buildLabel('کارڈ / گاڑی نمبر'),
            TextFormField(
              controller: _cardCtrl,
              decoration: _inputDecoration('اختیاری'),
              style: _inputStyle,
            ),
            const SizedBox(height: 16),

            // 4+5. وزن + اکائی
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('وزن *'),
                      TextFormField(
                        controller: _weightCtrl,
                        decoration: _inputDecoration('مقدار درج کریں').copyWith(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calculate_outlined, color: Color(0xFFE67E22)),
                            onPressed: () => _openCalculator(_weightCtrl),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          if (val == null || val <= 0) return 'وزن ضروری ہے';
                          return null;
                        },
                        style: _inputStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('اکائی *'),
                      DropdownButtonFormField<String>(
                        value: _weightUnit,
                        items: _weightUnits
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u,
                                      style: const TextStyle(
                                          fontFamily: AppTextStyles.urduFont,
                                          fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _weightUnit = v!),
                        decoration: _inputDecoration(''),
                      ),
                      if (_weightUnit == 'دیگر') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customUnitCtrl,
                          decoration: _inputDecoration('اکائی لکھیں'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'اکائی لکھیں' : null,
                          style: _inputStyle,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. ریٹ
            _buildLabel('ریٹ فی اکائی *'),
            TextFormField(
              controller: _rateCtrl,
              decoration: _inputDecoration('فی اکائی قیمت').copyWith(
                prefixText: 'Rs. ',
                prefixStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: AppColors.textPrimary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate_outlined, color: Color(0xFFE67E22)),
                  onPressed: () => _openCalculator(_rateCtrl),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final val = double.tryParse(v ?? '');
                if (val == null || val <= 0) return 'ریٹ ضروری ہے';
                return null;
              },
              style: _inputStyle,
            ),
            const SizedBox(height: 16),

            // 7. کل رقم — READ ONLY
            _buildLabel('کل رقم (خودکار)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE67E22).withValues(alpha: 0.3)),
              ),
              child: Text(
                CurrencyFormatter.formatAmount(_totalAmount),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE67E22),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 8. ادائیگی کی قسم
            _buildLabel('ادائیگی کی قسم *'),
            Row(
              children: [
                _buildPaymentChip('نقد', 1),
                const SizedBox(width: 8),
                _buildPaymentChip('ادھار', 0),
                const SizedBox(width: 8),
                _buildPaymentChip('جزوی ادائیگی', 2),
                const SizedBox(width: 8),
                _buildPaymentChip('دیگر', 3),
              ],
            ),
            if (_paymentStatus == 3) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _customPaymentCtrl,
                decoration: _inputDecoration('ادائیگی کی قسم لکھیں (مثلاً: بینک ٹرانسفر)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'ادائیگی کی قسم لکھیں' : null,
                style: _inputStyle,
              ),
            ],
            const SizedBox(height: 16),

            // Conditional: credit input for partial
            if (_paymentStatus == 2) ...[
              _buildLabel('وصول رقم'),
              TextFormField(
                controller: _creditCtrl,
                decoration: _inputDecoration('وصول شدہ رقم').copyWith(
                  prefixText: 'Rs. ',
                  prefixStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: AppColors.textPrimary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calculate_outlined, color: Color(0xFFE67E22)),
                    onPressed: () => _openCalculator(_creditCtrl),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: _inputStyle,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.debitBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('باقی رقم:',
                        style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13)),
                    const Spacer(),
                    Text(CurrencyFormatter.formatAmount(_debitAmount),
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.debit)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 9. تفاضل / منافع
            _buildLabel('تفاضل / منافع'),
            TextFormField(
              controller: _tafazulCtrl,
              decoration: _inputDecoration('اختیاری — منافع درج کریں').copyWith(
                prefixText: 'Rs. ',
                prefixStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: AppColors.textPrimary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate_outlined, color: Color(0xFFE67E22)),
                  onPressed: () => _openCalculator(_tafazulCtrl),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: _inputStyle,
            ),
            const SizedBox(height: 16),

            // 10. نوٹ
            _buildLabel('نوٹ'),
            TextFormField(
              controller: _noteCtrl,
              decoration: _inputDecoration('اختیاری'),
              maxLines: 2,
              style: _inputStyle,
            ),
            const SizedBox(height: 24),

            // 12. بل / تصویر منسلک کریں
            _buildLabel('تصویر منسلک کریں (اختیاری)'),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Icon(Icons.photo_camera, color: Color(0xFFE67E22), size: 24),
                            SizedBox(height: 4),
                            Text(
                              'تصویر',
                              style: TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE67E22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const Spacer(),
              ],
            ),
            if (_imagePath.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () async {
                    try {
                      await OpenFile.open(_imagePath);
                    } catch (_) {}
                  },
                  leading: const Icon(Icons.image_outlined, color: Color(0xFFE67E22)),
                  title: Text(
                    _imagePath.split('/').last,
                    style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.debit),
                    onPressed: () => setState(() => _imagePath = ''),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // 13. تاریخ
            _buildLabel('تاریخ *'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormatter.formatDate(_saleDate),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Save
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('فروخت محفوظ کریں',
                        style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String label, int status) {
    final isSelected = _paymentStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentStatus = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE67E22) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFE67E22) : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontFamily: AppTextStyles.urduFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE67E22), width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.debit)),
      errorStyle: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 11),
      filled: true,
      fillColor: Colors.white,
    );
  }

  TextStyle get _inputStyle => const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14, color: AppColors.textPrimary);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _saleDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(farokhtProvider.notifier);
      final tafazul = double.tryParse(_tafazulCtrl.text) ?? 0;
      if (_isEditing) {
        await notifier.update(
          id: widget.editId!,
          itemName: _itemNameCtrl.text.trim(),
          buyerName: _buyerCtrl.text.trim(),
          cardNumber: _cardCtrl.text.trim(),
          weight: _weight,
          weightUnit: _weightUnit == 'دیگر' ? _customUnitCtrl.text.trim() : _weightUnit,
          ratePerUnit: _rate,
          creditAmount: _creditAmount,
          debitAmount: _debitAmount,
          tafazul: tafazul,
          paymentStatus: _paymentStatus,
          customPaymentType: _paymentStatus == 3 ? _customPaymentCtrl.text.trim() : '',
          note: _noteCtrl.text.trim(),
          saleDate: _saleDate,
          imagePath: _imagePath,
        );
      } else {
        await notifier.add(
          itemName: _itemNameCtrl.text.trim(),
          buyerName: _buyerCtrl.text.trim(),
          cardNumber: _cardCtrl.text.trim(),
          weight: _weight,
          weightUnit: _weightUnit == 'دیگر' ? _customUnitCtrl.text.trim() : _weightUnit,
          ratePerUnit: _rate,
          creditAmount: _creditAmount,
          debitAmount: _debitAmount,
          tafazul: tafazul,
          paymentStatus: _paymentStatus,
          customPaymentType: _paymentStatus == 3 ? _customPaymentCtrl.text.trim() : '',
          note: _noteCtrl.text.trim(),
          saleDate: _saleDate,
          imagePath: _imagePath,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خرابی: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }


}
