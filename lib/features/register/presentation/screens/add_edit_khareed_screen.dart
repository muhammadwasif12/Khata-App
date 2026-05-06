import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/khareed_entity.dart';
import '../providers/khareed_provider.dart';
import '../../../transactions/presentation/widgets/calculator_bottom_sheet.dart';

class AddEditKhareedScreen extends ConsumerStatefulWidget {
  final String? editId;
  const AddEditKhareedScreen({super.key, this.editId});

  @override
  ConsumerState<AddEditKhareedScreen> createState() => _AddEditKhareedScreenState();
}

class _AddEditKhareedScreenState extends ConsumerState<AddEditKhareedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _deductionCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _jamaCtrl = TextEditingController();
  final _sabhaBaqayaCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customUnitCtrl = TextEditingController();

  String _weightUnit = 'کلو';
  DateTime _purchaseDate = DateTime.now();
  String _imagePath = '';
  bool _isLoading = false;

  static const _weightUnits = ['کلو', 'بوری', 'من', 'پیس', 'لیٹر', 'میٹر', 'درجن', 'دیگر'];

  bool get _isEditing => widget.editId != null;

  double get _weight => double.tryParse(_weightCtrl.text) ?? 0;
  double get _deduction => double.tryParse(_deductionCtrl.text) ?? 0;
  double get _netWeight => (_weight - _deduction).clamp(0, double.infinity);
  double get _rate => double.tryParse(_rateCtrl.text) ?? 0;
  double get _totalAmount => _netWeight * _rate;
  double get _jama => double.tryParse(_jamaCtrl.text) ?? 0;
  double get _baqaya => (_totalAmount - _jama).clamp(0, double.infinity);
  double get _sabhaBaqaya => double.tryParse(_sabhaBaqayaCtrl.text) ?? 0;
  double get _netBaqaya => _baqaya + _sabhaBaqaya;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
    _weightCtrl.addListener(() => setState(() {}));
    _deductionCtrl.addListener(() => setState(() {}));
    _rateCtrl.addListener(() => setState(() {}));
    _jamaCtrl.addListener(() => setState(() {}));
    _sabhaBaqayaCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadExisting() async {
    final records = ref.read(khareedProvider).value ?? [];
    final existing = records.where((r) => r.id == widget.editId).firstOrNull;
    if (existing != null) {
      _itemNameCtrl.text = existing.itemName;
      _supplierCtrl.text = existing.supplierName;
      _cardCtrl.text = existing.vehicleNumber;
      _weightCtrl.text = existing.weight.toString();
      _deductionCtrl.text = existing.deduction > 0 ? existing.deduction.toString() : '';
      _rateCtrl.text = existing.ratePerUnit.toString();
      _jamaCtrl.text = existing.jama > 0 ? existing.jama.toString() : '';
      _sabhaBaqayaCtrl.text = existing.sabhaBaqaya > 0 ? existing.sabhaBaqaya.toString() : '';
      _noteCtrl.text = existing.note;
      if (_weightUnits.contains(existing.weightUnit) && existing.weightUnit != 'دیگر') {
        _weightUnit = existing.weightUnit;
      } else {
        _weightUnit = 'دیگر';
        _customUnitCtrl.text = existing.weightUnit;
      }
      _purchaseDate = existing.purchaseDate;
      _imagePath = existing.imagePath;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _supplierCtrl.dispose();
    _cardCtrl.dispose();
    _weightCtrl.dispose();
    _deductionCtrl.dispose();
    _rateCtrl.dispose();
    _jamaCtrl.dispose();
    _sabhaBaqayaCtrl.dispose();
    _noteCtrl.dispose();
    _customUnitCtrl.dispose();
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
        title: Text(_isEditing ? 'ترمیم کریں' : 'خریداری درج کریں', style: const TextStyle(fontFamily: AppTextStyles.urduFont)),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // SECTION 1 — مال کی تفصیل
            _buildSectionHeader('مال کی تفصیل'),
            _buildLabel('نام خریداری *'),
            TextFormField(controller: _itemNameCtrl, decoration: _inputDecoration('مثلاً: آلو، گندم، چاول'), validator: (v) => (v == null || v.trim().length < 2) ? 'ضروری ہے' : null, style: _inputStyle),
            const SizedBox(height: 16),
            _buildLabel('سپلائر / فروشندہ'),
            TextFormField(controller: _supplierCtrl, decoration: _inputDecoration('نام لکھیں'), style: _inputStyle),
            const SizedBox(height: 16),
            _buildLabel('گاڑی نمبر'),
            TextFormField(controller: _cardCtrl, decoration: _inputDecoration('مثلاً: LHR-1234'), style: _inputStyle),
            const SizedBox(height: 16),
            _buildLabel('تاریخ *'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)), child: Row(children: [const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary), const SizedBox(width: 12), Text(DateFormatter.formatDate(_purchaseDate), style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14, color: AppColors.textPrimary))])),
            ),
            const SizedBox(height: 24),

            // SECTION 2 — وزن اور ریٹ
            _buildSectionHeader('وزن اور ریٹ'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel('وزن (برٹو) *'),
                  TextFormField(controller: _weightCtrl, decoration: _inputDecoration('کل وزن').copyWith(suffixIcon: IconButton(icon: const Icon(Icons.calculate_outlined, color: Color(0xFF1A6B3C)), onPressed: () => _openCalculator(_weightCtrl))), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) { final val = double.tryParse(v ?? ''); if (val == null || val <= 0) return 'ضروری ہے'; return null; }, style: _inputStyle),
                ])),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel('اکائی *'),
                  DropdownButtonFormField<String>(value: _weightUnit, items: _weightUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14)))).toList(), onChanged: (v) => setState(() => _weightUnit = v!), decoration: _inputDecoration('')),
                  if (_weightUnit == 'دیگر') ...[const SizedBox(height: 8), TextFormField(controller: _customUnitCtrl, decoration: _inputDecoration('اکائی لکھیں'), validator: (v) => (v == null || v.trim().isEmpty) ? 'اکائی لکھیں' : null, style: _inputStyle)],
                ])),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('کٹوتی (اختیاری)'),
            TextFormField(controller: _deductionCtrl, decoration: _inputDecoration('وزن میں کٹوتی').copyWith(suffixIcon: IconButton(icon: const Icon(Icons.calculate_outlined, color: Color(0xFF1A6B3C)), onPressed: () => _openCalculator(_deductionCtrl))), keyboardType: const TextInputType.numberWithOptions(decimal: true), style: _inputStyle),
            const SizedBox(height: 16),
            _buildLabel('خالص وزن'),
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1A6B3C).withValues(alpha: 0.3))), child: Text('$_netWeight', style: const TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A6B3C)))),
            const SizedBox(height: 16),
            _buildLabel('ریٹ فی اکائی *'),
            TextFormField(controller: _rateCtrl, decoration: _inputDecoration('فی اکائی قیمت').copyWith(prefixText: 'Rs. ', prefixStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: AppColors.textPrimary), suffixIcon: IconButton(icon: const Icon(Icons.calculate_outlined, color: Color(0xFF1A6B3C)), onPressed: () => _openCalculator(_rateCtrl))), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) { final val = double.tryParse(v ?? ''); if (val == null || val <= 0) return 'ضروری ہے'; return null; }, style: _inputStyle),
            const SizedBox(height: 16),
            _buildLabel('کل رقم'),
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1A6B3C).withValues(alpha: 0.3))), child: Text(CurrencyFormatter.formatAmount(_totalAmount), style: const TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A6B3C)))),
            const SizedBox(height: 24),

            // SECTION 3 — ادائیگی
            _buildSectionHeader('ادائیگی'),
            _buildLabel('جمع رقم (ادا کی گئی)'),
            TextFormField(controller: _jamaCtrl, decoration: _inputDecoration('آج کی ادائیگی').copyWith(prefixText: 'Rs. ', prefixStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: AppColors.textPrimary), suffixIcon: IconButton(icon: const Icon(Icons.calculate_outlined, color: Color(0xFF1A6B3C)), onPressed: () => _openCalculator(_jamaCtrl))), keyboardType: const TextInputType.numberWithOptions(decimal: true), style: _inputStyle),
            const SizedBox(height: 16),
            _buildLabel('بقایا رقم'),
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: _baqaya > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: (_baqaya > 0 ? const Color(0xFFC0392B) : const Color(0xFF1A6B3C)).withValues(alpha: 0.3))), child: Text(CurrencyFormatter.formatAmount(_baqaya), style: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.bold, color: _baqaya > 0 ? const Color(0xFFC0392B) : const Color(0xFF1A6B3C)))),
            const SizedBox(height: 16),
            _buildLabel('سابقہ بقایا (اگر ہو)'),
            TextFormField(controller: _sabhaBaqayaCtrl, decoration: _inputDecoration('پہلے کا باقی حساب').copyWith(prefixText: 'Rs. ', prefixStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: AppColors.textPrimary), suffixIcon: IconButton(icon: const Icon(Icons.calculate_outlined, color: Color(0xFF1A6B3C)), onPressed: () => _openCalculator(_sabhaBaqayaCtrl))), keyboardType: const TextInputType.numberWithOptions(decimal: true), style: _inputStyle),
            const SizedBox(height: 16),
            _buildLabel('خالص بقایا'),
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: _netBaqaya > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: (_netBaqaya > 0 ? const Color(0xFFC0392B) : const Color(0xFF1A6B3C)).withValues(alpha: 0.3))), child: Text(CurrencyFormatter.formatAmount(_netBaqaya), style: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.bold, color: _netBaqaya > 0 ? const Color(0xFFC0392B) : const Color(0xFF1A6B3C)))),
            const SizedBox(height: 24),

            // SECTION 4
            _buildSectionHeader('دیگر تفصیل'),
            _buildLabel('نوٹ (اختیاری)'),
            TextFormField(controller: _noteCtrl, decoration: _inputDecoration('کوئی بھی تفصیل'), maxLines: 2, style: _inputStyle),
            const SizedBox(height: 16),

            _buildLabel('تصویر منسلک کریں (اختیاری)'),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: const Color(0xFF1A6B3C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Icon(Icons.photo_camera, color: Color(0xFF1A6B3C), size: 24),
                            SizedBox(height: 4),
                            Text(
                              'تصویر',
                              style: TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A6B3C),
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
                  leading: const Icon(Icons.image_outlined, color: Color(0xFF1A6B3C)),
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
            const SizedBox(height: 28),

            // Save
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A6B3C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 2),
                child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('خریداری محفوظ کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A6B3C))));
  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)));
  InputDecoration _inputDecoration(String hint) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: AppColors.textHint), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A6B3C), width: 2)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.debit)), errorStyle: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 11), filled: true, fillColor: Colors.white);
  TextStyle get _inputStyle => const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14, color: AppColors.textPrimary);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _purchaseDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(khareedProvider.notifier);
      final cUnit = _weightUnit == 'دیگر' ? _customUnitCtrl.text.trim() : _weightUnit;
      if (_isEditing) {
        await notifier.update(id: widget.editId!, itemName: _itemNameCtrl.text.trim(), vehicleNumber: _cardCtrl.text.trim(), weight: _weight, weightUnit: cUnit, deduction: _deduction, ratePerUnit: _rate, jama: _jama, sabhaBaqaya: _sabhaBaqaya, supplierName: _supplierCtrl.text.trim(), note: _noteCtrl.text.trim(), purchaseDate: _purchaseDate, imagePath: _imagePath);
      } else {
        await notifier.add(itemName: _itemNameCtrl.text.trim(), vehicleNumber: _cardCtrl.text.trim(), weight: _weight, weightUnit: cUnit, deduction: _deduction, ratePerUnit: _rate, jama: _jama, sabhaBaqaya: _sabhaBaqaya, supplierName: _supplierCtrl.text.trim(), note: _noteCtrl.text.trim(), purchaseDate: _purchaseDate, imagePath: _imagePath);
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
      setState(() => _imagePath = pickedFile.path);
    }
  }


}
