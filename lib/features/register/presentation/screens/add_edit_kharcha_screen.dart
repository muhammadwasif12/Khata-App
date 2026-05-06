import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/kharcha_entity.dart';
import '../providers/kharcha_provider.dart';
import '../../../transactions/presentation/widgets/calculator_bottom_sheet.dart';

class AddEditKharchaScreen extends ConsumerStatefulWidget {
  final String? editId;
  const AddEditKharchaScreen({super.key, this.editId});
  @override
  ConsumerState<AddEditKharchaScreen> createState() => _AddEditKharchaScreenState();
}

class _AddEditKharchaScreenState extends ConsumerState<AddEditKharchaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _paidToCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customCatCtrl = TextEditingController();

  String _selectedCategory = '';
  DateTime _expenseDate = DateTime.now();
  String _imagePath = '';
  bool _isLoading = false;
  bool get _isEditing => widget.editId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  Future<void> _loadExisting() async {
    final records = ref.read(kharchaProvider).value ?? [];
    final e = records.where((r) => r.id == widget.editId).firstOrNull;
    if (e != null) {
      _selectedCategory = e.category;
      _customCatCtrl.text = e.customCategory;
      _amountCtrl.text = e.amount.toString();
      _paidToCtrl.text = e.paidTo;
      _vehicleCtrl.text = e.vehicleNumber;
      _driverCtrl.text = e.driverName;
      _noteCtrl.text = e.note;
      _expenseDate = e.expenseDate;
      _imagePath = e.imagePath;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _paidToCtrl.dispose();
    _vehicleCtrl.dispose();
    _driverCtrl.dispose();
    _noteCtrl.dispose();
    _customCatCtrl.dispose();
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
    final isTransport = KharchaEntity.transportCategories.contains(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ترمیم کریں' : 'خرچہ درج کریں',
            style: const TextStyle(fontFamily: AppTextStyles.urduFont)),
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Category grid
            _buildLabel('خرچہ کی قسم *'),
            const SizedBox(height: 4),
            _buildCategoryGrid(),
            if (_selectedCategory.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4, right: 8),
                child: Text('خرچہ کی قسم منتخب کریں',
                    style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 11, color: AppColors.debit)),
              ),
            if (_selectedCategory == 'دیگر') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customCatCtrl,
                decoration: _inputDeco('خرچہ کی تفصیل لکھیں'),
                validator: (v) => (_selectedCategory == 'دیگر' && (v == null || v.trim().isEmpty)) ? 'تفصیل ضروری ہے' : null,
                style: _inputStyle,
              ),
            ],
            const SizedBox(height: 20),

            // 2. Amount
            _buildLabel('رقم *'),
            TextFormField(
              controller: _amountCtrl,
              decoration: _inputDeco('رقم درج کریں').copyWith(
                prefixText: 'Rs. ',
                prefixStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate_outlined, color: Color(0xFFC0392B)),
                  onPressed: () => _openCalculator(_amountCtrl),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              validator: (v) {
                final val = double.tryParse(v ?? '');
                if (val == null || val <= 0) return 'درست رقم درج کریں';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 3. Transport conditional
            if (isTransport) ...[
              _buildLabel('گاڑی نمبر'),
              TextFormField(
                controller: _vehicleCtrl,
                decoration: _inputDeco('مثلاً: LHR-1234 (اختیاری)'),
                style: _inputStyle,
              ),
              const SizedBox(height: 16),
              _buildLabel('ڈرائیور / باری'),
              TextFormField(
                controller: _driverCtrl,
                decoration: _inputDeco('ڈرائیور کا نام (اختیاری)'),
                style: _inputStyle,
              ),
              const SizedBox(height: 20),
            ],

            // 4. Details
            _buildLabel('کس کو دیا'),
            TextFormField(
              controller: _paidToCtrl,
              decoration: _inputDeco('شخص کا نام (اختیاری)'),
              style: _inputStyle,
            ),
            const SizedBox(height: 16),

            _buildLabel('نوٹ'),
            TextFormField(
              controller: _noteCtrl,
              decoration: _inputDeco('تفصیل (اختیاری)'),
              maxLines: 2,
              style: _inputStyle,
            ),
            const SizedBox(height: 16),

            // 5. Date
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
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(DateFormatter.formatDate(_expenseDate),
                      style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14, color: AppColors.textPrimary)),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            _buildLabel('تصویر منسلک کریں (اختیاری)'),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: const Color(0xFFC0392B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Icon(Icons.photo_camera, color: Color(0xFFC0392B), size: 24),
                            SizedBox(height: 4),
                            Text(
                              'تصویر',
                              style: TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC0392B),
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
                  leading: const Icon(Icons.image_outlined, color: Color(0xFFC0392B)),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('خرچہ محفوظ کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: KharchaEntity.kharchaCategories.map((cat) {
        final sel = _selectedCategory == cat;
        final icon = KharchaEntity.kharchaCategoryIcons[cat] ?? Icons.circle;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFC0392B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? const Color(0xFFC0392B) : AppColors.divider, width: sel ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: sel ? Colors.white : AppColors.textSecondary),
                const SizedBox(height: 4),
                Text(cat, style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 11, color: sel ? Colors.white : AppColors.textPrimary, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: AppColors.textHint),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC0392B), width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.debit)),
    errorStyle: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 11),
    filled: true, fillColor: Colors.white,
  );

  TextStyle get _inputStyle => const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14, color: AppColors.textPrimary);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _expenseDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _save() async {
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خرچہ کی قسم منتخب کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont))));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(kharchaProvider.notifier);
      final isTrans = KharchaEntity.transportCategories.contains(_selectedCategory);

      if (_isEditing) {
        await notifier.update(id: widget.editId!, category: _selectedCategory, customCategory: _customCatCtrl.text.trim(), amount: double.parse(_amountCtrl.text), note: _noteCtrl.text.trim(), paidTo: _paidToCtrl.text.trim(), vehicleNumber: isTrans ? _vehicleCtrl.text.trim() : '', driverName: isTrans ? _driverCtrl.text.trim() : '', expenseDate: _expenseDate, imagePath: _imagePath);
      } else {
        await notifier.add(category: _selectedCategory, customCategory: _customCatCtrl.text.trim(), amount: double.parse(_amountCtrl.text), note: _noteCtrl.text.trim(), paidTo: _paidToCtrl.text.trim(), vehicleNumber: isTrans ? _vehicleCtrl.text.trim() : '', driverName: isTrans ? _driverCtrl.text.trim() : '', expenseDate: _expenseDate, imagePath: _imagePath);
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
