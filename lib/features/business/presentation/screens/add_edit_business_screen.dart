/// Add or Edit Business Screen
/// Allows user to create a new business or edit an existing one.
/// Includes fields for name, type, owner, phone, address, and currency.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/business_provider.dart';

class AddEditBusinessScreen extends ConsumerStatefulWidget {
  final String? businessId;

  const AddEditBusinessScreen({super.key, this.businessId});

  @override
  ConsumerState<AddEditBusinessScreen> createState() =>
      _AddEditBusinessScreenState();
}

class _AddEditBusinessScreenState
    extends ConsumerState<AddEditBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0;

  bool get _isEditing => widget.businessId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadBusiness();
    }
  }

  void _loadBusiness() {
    final businesses = ref.read(businessesProvider).valueOrNull ?? [];
    final business =
        businesses.where((b) => b.id == widget.businessId).firstOrNull;
    if (business != null) {
      _nameController.text = business.name;
      _typeController.text = business.type;
      _ownerController.text = business.ownerName;
      _phoneController.text = business.phone;
      _addressController.text = business.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await ref.read(businessesProvider.notifier).updateBusiness(
          id: widget.businessId!,
          name: _nameController.text.trim(),
          type: _typeController.text.trim(),
          ownerName: _ownerController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          currency: 'PKR',
        );
      } else {
        await ref.read(businessesProvider.notifier).addBusiness(
          name: _nameController.text.trim(),
          type: _typeController.text.trim(),
          ownerName: _ownerController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          currency: 'PKR',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'کاروبار اپ ڈیٹ ہو گیا' : 'نیا کاروبار شامل ہو گیا',
              style: const TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
            backgroundColor: AppColors.credit,
          ),
        );
        context.pop();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.editBusiness : AppStrings.addNewBusiness,
          style: const TextStyle(fontFamily: AppTextStyles.urduFont),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Step indicator
            _buildStepIndicator(),
            // Top action buttons
            _buildTopButtons(),
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0
                      ? _buildStep1()
                      : _buildStep2(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Flexible(child: _buildStepCircle(0, 'کاروبار', Icons.store)),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: _currentStep >= 1
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
            Flexible(child: _buildStepCircle(1, 'تفصیلات', Icons.info_outline)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? AppColors.primary : Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontSize: 11,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // Business name
        _buildSectionHeader('کاروبار کا نام *', Icons.store),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _nameController,
          label: AppStrings.businessName,
          hint: AppStrings.businessNameHint,
          validator: Validators.validateName,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 24),

        // Business type
        _buildSectionHeader('کاروبار کی قسم *', Icons.category),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _typeController,
          label: AppStrings.businessType,
          hint: 'مثلاً: جنرل سٹور، کپڑے، الیکٹرانکس',
          validator: Validators.validateName,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // Summary header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty
                          ? 'نام نہیں دیا'
                          : _nameController.text,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _typeController.text.isEmpty ? 'قسم نہیں دی' : _typeController.text,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Owner name
        _buildSectionHeader(AppStrings.businessOwner, Icons.person),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _ownerController,
          label: AppStrings.businessOwner,
          hint: AppStrings.businessOwnerHint,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 20),

        // Phone
        _buildSectionHeader(AppStrings.businessPhone, Icons.phone),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _phoneController,
          label: AppStrings.businessPhone,
          hint: AppStrings.businessPhoneHint,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),

        // Address
        _buildSectionHeader(AppStrings.businessAddress, Icons.location_on),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _addressController,
          label: AppStrings.businessAddress,
          hint: AppStrings.businessAddressHint,
          keyboardType: TextInputType.streetAddress,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }



  Widget _buildTopButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'واپس',
                  style: TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _currentStep == 0
                ? CustomButton(
                    label: 'آگے — تفصیلات',
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _currentStep = 1);
                      }
                    },
                    icon: Icons.arrow_back,
                  )
                : CustomButton(
                    label: AppStrings.save,
                    onPressed: _saveBusiness,
                    isLoading: _isLoading,
                    icon: Icons.check,
                  ),
          ),
        ],
      ),
    );
  }
}
