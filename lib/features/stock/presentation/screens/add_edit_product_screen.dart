/// Add/Edit Product Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/stock_provider.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _purchasePriceController = TextEditingController(text: '0');
  final _salePriceController = TextEditingController(text: '0');
  final _openingStockController = TextEditingController(text: '0');
  final _lowAlertController = TextEditingController(text: '5');
  final _descriptionController = TextEditingController();
  String _selectedUnit = 'عدد';
  bool _isLoading = false;

  bool get _isEditing => widget.productId != null;

  static const List<String> _predefinedProductNames = [
    'توڑی بنڈل',
    'ریڈ تک',
    'وائٹ تکہ',
    'سرسوں کا گٹل',
    'یلوں کا کٹل',
    'منگفلی بنڈل',
  ];

  static const List<String> _units = [
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
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
    }
  }

  void _loadProduct() {
    final products = ref.read(productsProvider).valueOrNull ?? [];
    final product =
        products.where((p) => p.id == widget.productId).firstOrNull;
    if (product != null) {
      _nameController.text = product.name;
      _purchasePriceController.text =
          product.purchasePrice.toStringAsFixed(0);
      _salePriceController.text = product.salePrice.toStringAsFixed(0);
      _openingStockController.text =
          product.currentStock.toStringAsFixed(0);
      _lowAlertController.text = product.lowStockAlert.toStringAsFixed(0);
      if (_units.contains(product.unit)) {
        setState(() => _selectedUnit = product.unit);
      } else {
        setState(() {
          _selectedUnit = 'دیگر';
          _customUnitController.text = product.unit;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customUnitController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _openingStockController.dispose();
    _lowAlertController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _productName {
    return _nameController.text.trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('پروڈکٹ کا نام درج کریں',
              style: TextStyle(fontFamily: AppTextStyles.urduFont)),
          backgroundColor: AppColors.debit,
        ),
      );
      return;
    }

    final finalUnit = _selectedUnit == 'دیگر' ? _customUnitController.text.trim() : _selectedUnit;

    if (_selectedUnit == 'دیگر' && finalUnit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اکائی درج کریں',
              style: TextStyle(fontFamily: AppTextStyles.urduFont)),
          backgroundColor: AppColors.debit,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(productsProvider.notifier);
      if (_isEditing) {
        await notifier.updateProduct(
          widget.productId!,
          name: _productName,
          unit: finalUnit,
          purchasePrice:
              double.tryParse(_purchasePriceController.text) ?? 0,
          salePrice: double.tryParse(_salePriceController.text) ?? 0,
          lowStockAlert: double.tryParse(_lowAlertController.text) ?? 5,
        );
      } else {
        await notifier.addProduct(
          name: _productName,
          unit: finalUnit,
          purchasePrice:
              double.tryParse(_purchasePriceController.text) ?? 0,
          salePrice: double.tryParse(_salePriceController.text) ?? 0,
          openingStock:
              double.tryParse(_openingStockController.text) ?? 0,
          lowStockAlert: double.tryParse(_lowAlertController.text) ?? 5,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خرابی: $e',
                style: const TextStyle(
                    fontFamily: AppTextStyles.urduFont)),
            backgroundColor: AppColors.debit,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate profit preview
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final salePrice = double.tryParse(_salePriceController.text) ?? 0;
    final profit = salePrice - purchasePrice;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'پروڈکٹ ترمیم' : 'نئی پروڈکٹ شامل کریں',
              style: const TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'اسٹاک بک',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Product Name Section ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'پروڈکٹ کا نام',
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _nameController,
                      label: 'پروڈکٹ کا نام لکھیں',
                      hint: 'مثلاً: چاول، آٹا، شکر',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'نام درج کریں'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _predefinedProductNames.map((name) {
                        final isSelected = _nameController.text.trim() == name;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _nameController.text = name;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.divider,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 12,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Unit selector ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.straighten, size: 20, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'اکائی',
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _units.map((unit) {
                        final isSelected = _selectedUnit == unit;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedUnit = unit),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
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
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedUnit == 'دیگر') ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _customUnitController,
                        label: 'اپنی اکائی لکھیں',
                        hint: 'مثلاً: بکس، بنڈل',
                        validator: (v) => _selectedUnit == 'دیگر' && (v == null || v.trim().isEmpty)
                            ? 'اکائی درج کریں'
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Pricing ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.monetization_on, size: 20, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'قیمت',
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _purchasePriceController,
                            label: 'خرید قیمت',
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _salePriceController,
                            label: 'فروخت قیمت',
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    // Profit display
                    if (purchasePrice > 0 || salePrice > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: profit >= 0
                                ? AppColors.creditBg
                                : AppColors.debitBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                profit >= 0 ? Icons.trending_up : Icons.trending_down,
                                size: 16,
                                color: profit >= 0 ? AppColors.credit : AppColors.debit,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'فی یونٹ منافع: Rs. ${profit.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.urduFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: profit >= 0 ? AppColors.credit : AppColors.debit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Stock & Alert ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warehouse, size: 20, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'اسٹاک',
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_isEditing)
                      CustomTextField(
                        controller: _openingStockController,
                        label: 'ابتدائی اسٹاک',
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    if (!_isEditing) const SizedBox(height: 12),
                    CustomTextField(
                      controller: _lowAlertController,
                      label: 'کم اسٹاک الرٹ',
                      hint: '5',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              CustomButton(
                label: 'محفوظ کریں',
                onPressed: _save,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
