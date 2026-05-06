/// Stock Screen — Main product list with stock overview, filter tabs, and status badges.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/stock_provider.dart';
import '../../../business/presentation/providers/business_provider.dart';
import 'stock_pdf_generator.dart';
import '../../../../core/constants/app_strings.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  int _selectedFilter = 0; // 0=all, 1=low stock, 2=out of stock
  final _searchController = TextEditingController();
  bool _showSearch = false;

  List<ProductEntity> _filterProducts(List<ProductEntity> products) {
    List<ProductEntity> filtered;
    switch (_selectedFilter) {
      case 1:
        filtered = products.where((p) => p.isLowStock).toList();
        break;
      case 2:
        filtered = products.where((p) => p.isOutOfStock).toList();
        break;
      default:
        filtered = products;
    }

    // Apply search filter
    if (_searchController.text.trim().isNotEmpty) {
      final query = _searchController.text.trim().toLowerCase();
      filtered = filtered.where((p) => p.name.toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text('خرابی: $e')),
      data: (allProducts) {
        if (allProducts.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.inventory_2_outlined,
            title: 'کوئی پروڈکٹ نہیں',
            description: '+ بٹن دبا کر نئی پروڈکٹ شامل کریں',
          );
        }

        final products = _filterProducts(allProducts);

        // Summary calculations from ALL products
        final totalProducts = allProducts.length;
        final totalValue = allProducts.fold<double>(
            0, (sum, p) => sum + p.stockValue);
        final lowStockCount =
            allProducts.where((p) => p.isLowStock).length;
        final outOfStockCount =
            allProducts.where((p) => p.isOutOfStock).length;
        final totalProfit = allProducts.fold<double>(
            0, (sum, p) => sum + (p.profitPerUnit * p.currentStock));

        return Column(
          children: [
            // ─── Search Bar ───
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'پروڈکٹ تلاش کریں...',
                    hintStyle: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      color: AppColors.textHint,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _showSearch = false);
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // ─── Actions ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Search button
                  if (!_showSearch)
                    InkWell(
                      onTap: () => setState(() => _showSearch = true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.search, color: AppColors.primary, size: 20),
                      ),
                    ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      final businesses = ref.read(businessesProvider).valueOrNull ?? [];
                      final activeId = ref.read(activeBusinessIdProvider);
                      final bName = businesses.where((b) => b.id == activeId).map((b) => b.name).firstOrNull ?? AppStrings.appName;
                      generateStockPdf(products, ref, bName);
                    },
                    icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 18),
                    label: const Text('اسٹاک رپورٹ', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: AppColors.primary, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            // ─── Summary Stats Bar ───
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
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
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _SummaryItem(
                        label: 'کل اشیاء',
                        value: totalProducts.toString(),
                        icon: Icons.inventory_2,
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _SummaryItem(
                        label: 'کل منافع',
                        value: CurrencyFormatter.formatShort(totalProfit.abs()),
                        icon: totalProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _SummaryItem(
                        label: 'اسٹاک ویلیو',
                        value: CurrencyFormatter.formatShort(totalValue),
                        icon: Icons.account_balance_wallet,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Filter Tabs ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _FilterTab(
                    label: 'تمام',
                    count: totalProducts,
                    isSelected: _selectedFilter == 0,
                    onTap: () => setState(() => _selectedFilter = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'کم اسٹاک',
                    count: lowStockCount,
                    isSelected: _selectedFilter == 1,
                    onTap: () => setState(() => _selectedFilter = 1),
                    activeColor: AppColors.amber,
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'ختم',
                    count: outOfStockCount,
                    isSelected: _selectedFilter == 2,
                    onTap: () => setState(() => _selectedFilter = 2),
                    activeColor: AppColors.debit,
                  ),
                ],
              ),
            ),

            // ─── Product list ───
            Expanded(
              child: products.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'کوئی آئٹم نہیں',
                      description: 'اس فلٹر میں کوئی پروڈکٹ نہیں',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 100),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _ProductCard(
                          product: product,
                          onTap: () => context.push(
                              '/home/stock/ledger/${product.id}'),
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('پروڈکٹ حذف کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont, fontWeight: FontWeight.bold)),
                                content: Text('کیا آپ واقعی ${product.name} کو مکمل طور پر حذف کرنا چاہتے ہیں؟ اس سے متعلقہ سارا ریکارڈ ختم ہو جائے گا۔', style: const TextStyle(fontFamily: AppTextStyles.urduFont)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('منسوخ کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: AppColors.textSecondary)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref.read(productsProvider.notifier).deleteProduct(product.id);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پروڈکٹ کامیابی سے حذف ہو گئی', style: TextStyle(fontFamily: AppTextStyles.urduFont))));
                                    },
                                    child: const Text('حذف کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: AppColors.debit)),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.urduFont,
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ProductCard({required this.product, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    Color stockColor;
    String stockLabel;
    IconData stockIcon;
    if (product.isOutOfStock) {
      stockColor = AppColors.debit;
      stockLabel = 'اسٹاک ختم';
      stockIcon = Icons.error_outline;
    } else if (product.isLowStock) {
      stockColor = AppColors.amber;
      stockLabel = 'کم اسٹاک';
      stockIcon = Icons.warning_amber;
    } else {
      stockColor = AppColors.credit;
      stockLabel = 'موجود';
      stockIcon = Icons.check_circle_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Product icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primarySurface,
                      AppColors.primaryMuted.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    product.name.isNotEmpty ? product.name[0] : '؟',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'خرید: ${CurrencyFormatter.formatAmount(product.purchasePrice)} | فروخت: ${CurrencyFormatter.formatAmount(product.salePrice)}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Profit per unit
                    Row(
                      children: [
                        Icon(
                          product.profitPerUnit >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 12,
                          color: product.profitPerUnit >= 0 ? AppColors.credit : AppColors.debit,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'منافع: ${CurrencyFormatter.formatAmount(product.profitPerUnit)}/یونٹ',
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: product.profitPerUnit >= 0 ? AppColors.credit : AppColors.debit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Stock info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product.currentStock.toStringAsFixed(product.currentStock.truncateToDouble() == product.currentStock ? 0 : 1)} ${product.unit}',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stockIcon, size: 10, color: stockColor),
                        const SizedBox(width: 3),
                        Text(
                          stockLabel,
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: stockColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
