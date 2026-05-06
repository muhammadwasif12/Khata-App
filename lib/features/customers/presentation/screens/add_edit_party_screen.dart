/// Add/Edit Party Screen
/// Shared screen for adding/editing both customers and suppliers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/party_provider.dart';

class AddEditPartyScreen extends ConsumerStatefulWidget {
  final bool isCustomer;
  final String? partyId;

  const AddEditPartyScreen({
    super.key,
    required this.isCustomer,
    this.partyId,
  });

  @override
  ConsumerState<AddEditPartyScreen> createState() => _AddEditPartyScreenState();
}

class _AddEditPartyScreenState extends ConsumerState<AddEditPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  bool _isOpeningCredit = true;
  bool _isLoading = false;

  bool get _isEditing => widget.partyId != null;

  String get _title {
    if (_isEditing) {
      return widget.isCustomer
          ? AppStrings.editCustomer
          : AppStrings.editSupplier;
    }
    return widget.isCustomer
        ? AppStrings.addCustomer
        : AppStrings.addSupplier;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadParty();
      });
    }
  }

  void _loadParty() {
    final provider = widget.isCustomer ? customersProvider : suppliersProvider;
    final parties = ref.read(provider).valueOrNull ?? [];
    final party =
        parties.where((p) => p.id == widget.partyId).firstOrNull;
    if (party != null) {
      _nameController.text = party.name;
      _phoneController.text = party.phone;
      _balanceController.text = party.openingBalance.toStringAsFixed(0);
      setState(() {
        _isOpeningCredit = party.isOpeningCredit;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveParty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider =
          widget.isCustomer ? customersProvider : suppliersProvider;
      final notifier = ref.read(provider.notifier);
      final balance =
          double.tryParse(_balanceController.text.trim()) ?? 0;

      if (_isEditing) {
        await notifier.updateParty(
          widget.partyId!,
          _nameController.text.trim(),
          _phoneController.text.trim(),
        );
      } else {
        await notifier.addParty(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          openingBalance: balance,
          isOpeningCredit: _isOpeningCredit,
        );
      }
      if (mounted) {
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
          _title,
          style: const TextStyle(fontFamily: AppTextStyles.urduFont),
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
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: AppStrings.partyName,
                hint: AppStrings.partyName,
                validator: Validators.validateName,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: AppStrings.partyPhone,
                hint: AppStrings.partyPhone,
                keyboardType: TextInputType.phone,
                maxLength: 11,
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _balanceController,
                  label: AppStrings.openingBalance,
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.balanceType,
                  style: TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceTypeButton(
                        label: AppStrings.willReceive,
                        isSelected: _isOpeningCredit,
                        color: AppColors.credit,
                        onTap: () =>
                            setState(() => _isOpeningCredit = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceTypeButton(
                        label: AppStrings.willPay,
                        isSelected: !_isOpeningCredit,
                        color: AppColors.debit,
                        onTap: () =>
                            setState(() => _isOpeningCredit = false),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
              CustomButton(
                label: AppStrings.save,
                onPressed: _saveParty,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _BalanceTypeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.urduFont,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
