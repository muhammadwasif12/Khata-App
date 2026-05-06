/// Home Screen
/// Main dashboard with bottom navigation for Home, Customers, Suppliers, and Cashbook tabs.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../customers/presentation/screens/customer_list_screen.dart';
import '../../../customers/presentation/screens/supplier_list_screen.dart';
import '../../../cashbook/presentation/screens/cashbook_screen.dart';
import '../../../customers/data/models/party_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../cashbook/data/models/cash_entry_model.dart';
import '../../../stock/presentation/screens/stock_screen.dart';
import '../../../invoice/presentation/screens/invoice_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(businessesProvider.notifier);
      final activeId = notifier.getActiveBusinessId();
      if (activeId != null) {
        ref.read(activeBusinessIdProvider.notifier).state = activeId;
      }
    });
  }

  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return AppStrings.appName;
      case 1:
        return AppStrings.navCustomers;
      case 2:
        return AppStrings.navSuppliers;
      case 3:
        return AppStrings.navCashbook;
      case 4:
        return 'اسٹاک بک';
      case 5:
        return 'احسان بیلنگ پریس';
      default:
        return AppStrings.appName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(businessesProvider);
    final activeBusinessId = ref.watch(activeBusinessIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontFamily: AppTextStyles.urduFont),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () => context.push('/reports'),
            tooltip: AppStrings.reports,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: AppStrings.settings,
          ),
        ],
      ),
      body: businessesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, st) => Center(child: Text('${AppStrings.error}: $e')),
        data: (businesses) {
          if (businesses.isEmpty) {
            return _buildEmptyBusinessState();
          }

          final activeBusiness = businesses.firstWhere(
            (b) => b.id == activeBusinessId,
            orElse: () => businesses.first,
          );

          if (activeBusinessId == null ||
              !businesses.any((b) => b.id == activeBusinessId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(activeBusinessIdProvider.notifier).state =
                  activeBusiness.id;
            });
          }

          return _buildTabContent(activeBusiness.name, activeBusiness.id);
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _currentIndex == 0 ? null : _buildFab(),
    );
  }

  Widget _buildEmptyBusinessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primarySurface,
                  AppColors.primaryMuted,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business_outlined,
                size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            AppStrings.noBusiness,
            style: TextStyle(
              fontFamily: AppTextStyles.urduFont,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.noBusinessDesc,
            style: TextStyle(
              fontFamily: AppTextStyles.urduFont,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/home/businesses/add'),
            icon: const Icon(Icons.add),
            label: const Text(
              AppStrings.addBusiness,
              style: TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 52),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: AppStrings.navHome,
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavBarItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: AppStrings.navCustomers,
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavBarItem(
                icon: Icons.local_shipping_outlined,
                activeIcon: Icons.local_shipping,
                label: AppStrings.navSuppliers,
                isSelected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavBarItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet,
                label: AppStrings.navCashbook,
                isSelected: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _NavBarItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: 'اسٹاک',
                isSelected: _currentIndex == 4,
                onTap: () => setState(() => _currentIndex = 4),
              ),
              _NavBarItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'بل',
                isSelected: _currentIndex == 5,
                onTap: () => setState(() => _currentIndex = 5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () => _handleFabPress(),
      backgroundColor: AppColors.primary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  Widget _buildTabContent(String businessName, String businessId) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(businessName, businessId);
      case 1:
        return const CustomerListScreen();
      case 2:
        return const SupplierListScreen();
      case 3:
        return const CashbookScreen();
      case 4:
        return const StockScreen();
      case 5:
        return const InvoiceListScreen();
      default:
        return _buildHomeTab(businessName, businessId);
    }
  }

  Widget _buildHomeTab(String businessName, String businessId) {
    // Calculate real data
    final partyBox = Hive.box<PartyModel>(AppConstants.partyBox);
    final txnBox = Hive.box<TransactionModel>(AppConstants.transactionBox);
    final cashBox = Hive.box<CashEntryModel>(AppConstants.cashEntryBox);

    // Get parties for this business
    final parties = partyBox.values
        .where((p) => !p.isDeleted && p.businessId == businessId)
        .toList();
    final customers = parties.where((p) => p.partyType == 0).toList();
    final suppliers = parties.where((p) => p.partyType == 1).toList();

    // Calculate totals per party
    double totalReceivable = 0;
    double totalPayable = 0;

    for (final party in parties) {
      double balance = party.isOpeningCredit
          ? party.openingBalance
          : -party.openingBalance;

      final txns = txnBox.values
          .where((t) => !t.isDeleted && t.partyId == party.id)
          .toList();
      for (final txn in txns) {
        if (txn.txnType == 0) {
          balance += txn.amount;
        } else {
          balance -= txn.amount;
        }
      }

      if (balance > 0) {
        totalReceivable += balance;
      } else {
        totalPayable += balance.abs();
      }
    }

    // Today's cash
    final today = DateTime.now();
    final todayCash = cashBox.values
        .where((c) =>
            !c.isDeleted &&
            c.businessId == businessId &&
            c.entryDate.year == today.year &&
            c.entryDate.month == today.month &&
            c.entryDate.day == today.day)
        .toList();
    double todayCashIn = 0;
    double todayCashOut = 0;
    for (final c in todayCash) {
      if (c.cashType == 0) {
        todayCashIn += c.amount;
      } else {
        todayCashOut += c.amount;
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.tagline,
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextButton.icon(
                      onPressed: () => context.push('/home/businesses'),
                      icon: const Icon(Icons.swap_horiz,
                          size: 18, color: Colors.white),
                      label: const Text(
                        'تبدیل کریں',
                        style: TextStyle(
                          fontFamily: AppTextStyles.urduFont,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Summary card with REAL data
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            AppStrings.totalReceivable,
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatAmount(totalReceivable),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.credit,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            AppStrings.totalPayable,
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatAmount(totalPayable),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.debit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.netBalance,
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.formatAmount(
                          (totalReceivable - totalPayable).abs()),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: totalReceivable >= totalPayable
                            ? AppColors.credit
                            : AppColors.debit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatCard(
                  icon: Icons.people,
                  label: 'گراہک',
                  value: '${customers.length}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.local_shipping,
                  label: 'سپلائر',
                  value: '${suppliers.length}',
                  color: AppColors.amber,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.arrow_downward,
                  label: 'آج آمد',
                  value: CurrencyFormatter.formatShort(todayCashIn),
                  color: AppColors.credit,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.arrow_upward,
                  label: 'آج خرچ',
                  value: CurrencyFormatter.formatShort(todayCashOut),
                  color: AppColors.debit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reports tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () => context.push('/reports'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.assessment_outlined,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.reports,
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'کاروباری رپورٹ اور PDF',
                            style: TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Register tiles — خریداری / فروخت / خرچہ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _RegisterNavTile(
                  icon: Icons.shopping_cart_outlined,
                  label: 'خریداری',
                  subtitle: 'خریداری رجسٹر',
                  color: const Color(0xFF1A6B3C),
                  onTap: () => context.push('/khareed'),
                ),
                const SizedBox(height: 10),
                _RegisterNavTile(
                  icon: Icons.sell_outlined,
                  label: 'فروخت',
                  subtitle: 'فروخت رجسٹر',
                  color: const Color(0xFFE67E22),
                  onTap: () => context.push('/farokht'),
                ),
                const SizedBox(height: 10),
                _RegisterNavTile(
                  icon: Icons.money_off_outlined,
                  label: 'خرچہ',
                  subtitle: 'خرچہ رجسٹر',
                  color: const Color(0xFFC0392B),
                  onTap: () => context.push('/kharcha'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _handleFabPress() {
    switch (_currentIndex) {
      case 1:
        context.push('/home/customers/add');
        break;
      case 2:
        context.push('/home/suppliers/add');
        break;
      case 3:
        context.push('/home/cashbook/add_cash_entry');
        break;
      case 4:
        context.push('/home/stock/add');
        break;
      case 5:
        context.push('/home/invoices/create');
        break;
    }
  }
}

/// Custom bottom nav bar item
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.primary : AppColors.textHint,
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat card for the home tab
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation tile for register features on the home tab
class _RegisterNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RegisterNavTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios,
                  size: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
