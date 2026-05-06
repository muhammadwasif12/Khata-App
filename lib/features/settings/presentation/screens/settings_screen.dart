/// Settings Screen
/// App settings including profile name, dark mode toggle, data clearing, and about info.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../business/data/models/business_model.dart';
import '../../../customers/data/models/party_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../cashbook/data/models/cash_entry_model.dart';
import '../../../stock/data/models/product_model.dart';
import '../../../stock/data/models/stock_entry_model.dart';
import '../../../invoice/data/models/invoice_model.dart';
import '../../../invoice/data/models/invoice_item_model.dart';
import '../../../register/data/models/khareed_model.dart';
import '../../../register/data/models/farokht_model.dart';
import '../../../register/data/models/kharcha_model.dart';
import '../../../../core/services/firebase_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Box _settingsBox;
  String _userName = '';
  int _versionTapCount = 0;
  bool _isSyncing = false;
  final _syncService = FirebaseSyncService();

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box(AppConstants.settingsBox);
    _userName =
        _settingsBox.get(AppConstants.keyUserName, defaultValue: 'صارف')
            as String;
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          AppStrings.editName,
          style: TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontFamily: AppTextStyles.urduFont),
          decoration: InputDecoration(
            hintText: AppStrings.profileName,
            hintStyle: const TextStyle(
              fontFamily: AppTextStyles.urduFont,
              color: AppColors.textHint,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _settingsBox.put(AppConstants.keyUserName, newName);
                setState(() => _userName = newName);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              AppStrings.save,
              style: TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
          ),
        ],
      ),
    );
  }

  void _onVersionTapped() {
    _versionTapCount++;
    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      _showFirstDeleteWarning();
    }
  }

  void _showFirstDeleteWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتہائی اہم انتباہ!', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: AppColors.debit, fontWeight: FontWeight.bold)),
        content: const Text('کیا آپ واقعی ایپ کا تمام ڈیٹا حذف کرنا چاہتے ہیں؟ اس کے بعد کوئی بھی ڈیٹا واپس نہیں لایا جا سکے گا۔', style: TextStyle(fontFamily: AppTextStyles.urduFont)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('منسوخ کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSecondDeleteWarning();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debit),
            child: const Text('جی ہاں، میں جانتا ہوں', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSecondDeleteWarning() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('آخری انتباہ!', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: AppColors.debit, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تمام ڈیٹا مستقل طور پر حذف ہو جائے گا۔ تصدیق کے لیے نیچے "delete" لکھیں:', style: TextStyle(fontFamily: AppTextStyles.urduFont)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'delete'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('منسوخ کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().toLowerCase() == 'delete') {
                Navigator.pop(context);
                _executeClearData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لفظ درست نہیں ہے!', style: TextStyle(fontFamily: AppTextStyles.urduFont)), backgroundColor: AppColors.debit));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debit),
            child: const Text('مستقل حذف کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeClearData() async {
    FirebaseSyncService.isRestoring = true; // Disable auto-sync triggers during mass delete
    try {
      await Hive.box<BusinessModel>(AppConstants.businessBox).clear();
      await Hive.box<PartyModel>(AppConstants.partyBox).clear();
      await Hive.box<TransactionModel>(AppConstants.transactionBox).clear();
      await Hive.box<CashEntryModel>(AppConstants.cashEntryBox).clear();
      // Also clear stock and invoice data
      await Hive.box<ProductModel>(AppConstants.productBox).clear();
      await Hive.box<StockEntryModel>(AppConstants.stockEntryBox).clear();
      await Hive.box<InvoiceModel>(AppConstants.invoiceBox).clear();
      await Hive.box<InvoiceItemModel>(AppConstants.invoiceItemBox).clear();
      
      // Also clear register data
      await Hive.box<KhareedModel>('khareed').clear();
      await Hive.box<FarokhtModel>('farokht').clear();
      await Hive.box<KharchaModel>('kharcha').clear();

      // Keep settings but reset active business
      _settingsBox.delete(AppConstants.keyActiveBiz);

      // Delete all data from Firestore
      await _syncService.deleteAllDataFromFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تمام ڈیٹا کامیابی سے حذف ہو گیا (کلاؤڈ سے بھی)',
              style: TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
            backgroundColor: AppColors.credit,
          ),
        );
      }
    } finally {
      FirebaseSyncService.isRestoring = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 64,
        title: const Text(
          AppStrings.settings,
          style: TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ─── Profile Card ───
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0] : 'ص',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'احسان بیلنگ پریس',
                  style: TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 160,
                  child: OutlinedButton.icon(
                    onPressed: _showEditNameDialog,
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: Colors.white),
                    label: const Text(
                      AppStrings.editName,
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Settings Section Label ───
          const Padding(
            padding: EdgeInsets.only(right: 4, bottom: 10),
            child: Text(
              'ترتیبات',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // ─── Settings List ───
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  iconColor: AppColors.primary,
                  title: 'نام تبدیل کریں',
                  subtitle: _userName,
                  onTap: _showEditNameDialog,
                  showDivider: true,
                ),
                if (_isSyncing)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _SettingsTile(
                    icon: Icons.cloud_upload_outlined,
                    iconColor: AppColors.credit,
                    title: 'کلاؤڈ پر بیک اپ لیں',
                    subtitle: 'اپنا سارا ڈیٹا محفوظ کریں',
                    onTap: () async {
                      setState(() => _isSyncing = true);
                      try {
                        await _syncService.backupAllData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('بیک اپ کامیابی سے مکمل ہو گیا', style: TextStyle(fontFamily: AppTextStyles.urduFont)),
                            backgroundColor: AppColors.credit,
                          ));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('ایرر: ${e.toString()}', style: const TextStyle(fontFamily: AppTextStyles.urduFont)),
                            backgroundColor: AppColors.debit,
                          ));
                        }
                      } finally {
                        if (mounted) setState(() => _isSyncing = false);
                      }
                    },
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: Icons.cloud_download_outlined,
                    iconColor: AppColors.primaryDark,
                    title: 'کلاؤڈ سے واپس لائیں (Restore)',
                    subtitle: 'اپنا پرانا ڈیٹا واپس لائیں',
                    onTap: () async {
                      setState(() => _isSyncing = true);
                      try {
                        await _syncService.restoreAllData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('ڈیٹا کامیابی سے واپس آ گیا', style: TextStyle(fontFamily: AppTextStyles.urduFont)),
                            backgroundColor: AppColors.credit,
                          ));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('ایرر: ${e.toString()}', style: const TextStyle(fontFamily: AppTextStyles.urduFont)),
                            backgroundColor: AppColors.debit,
                          ));
                        }
                      } finally {
                        if (mounted) setState(() => _isSyncing = false);
                      }
                    },
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: Icons.logout,
                    iconColor: AppColors.debit,
                    title: 'لاگ آؤٹ کریں',
                    subtitle: FirebaseAuth.instance.currentUser?.email ?? '',
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    showDivider: false,
                    isDestructive: true,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── About Section Label ───
          const Padding(
            padding: EdgeInsets.only(right: 4, bottom: 10),
            child: Text(
              'ایپ کے بارے میں',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // ─── About Card ───
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _onVersionTapped,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      AppStrings.appVersion,
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.developedBy,
                  style: TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: showDivider
              ? const BorderRadius.vertical(top: Radius.circular(16))
              : const BorderRadius.vertical(bottom: Radius.circular(16)),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTextStyles.urduFont,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDestructive
                              ? AppColors.debit
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.urduFont,
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDestructive
                      ? AppColors.debit.withOpacity(0.5)
                      : AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 70, endIndent: 16),
      ],
    );
  }
}
