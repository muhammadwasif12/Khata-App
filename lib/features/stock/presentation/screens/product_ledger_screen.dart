/// Product Ledger Screen — Stock IN/OUT history for a single product.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/stock_entry_entity.dart';
import '../providers/stock_provider.dart';

class ProductLedgerScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductLedgerScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductLedgerScreen> createState() => _ProductLedgerScreenState();
}

class _ProductLedgerScreenState extends ConsumerState<ProductLedgerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilter = 0; // 0=all, 1=in, 2=out

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedFilter = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider).valueOrNull ?? [];
    final product =
        products.where((p) => p.id == widget.productId).firstOrNull;

    if (product == null) {
      return const Scaffold(body: LoadingWidget());
    }

    final entriesAsync = ref.watch(stockEntriesProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${product.currentStock.toStringAsFixed(0)} ${product.unit} موجود',
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                context.push('/home/stock/edit/${widget.productId}');
              } else if (value == 'delete') {
                showConfirmationDialog(
                  context: context,
                  title: 'پروڈکٹ حذف کریں',
                  message: 'کیا آپ واقعی یہ پروڈکٹ حذف کرنا چاہتے ہیں؟',
                  confirmLabel: 'حذف کریں',
                  onConfirm: () {
                    ref
                        .read(productsProvider.notifier)
                        .deleteProduct(widget.productId);
                    context.pop();
                  },
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('ترمیم',
                        style: TextStyle(
                            fontFamily: AppTextStyles.urduFont)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.debit),
                    SizedBox(width: 8),
                    Text('حذف کریں',
                        style: TextStyle(
                            fontFamily: AppTextStyles.urduFont)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'تمام'),
            Tab(text: 'اسٹاک ان'),
            Tab(text: 'اسٹاک آؤٹ'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stock summary
          _StockSummaryBar(product: product),
          // Entries
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('خرابی: $e')),
              data: (entries) {
                // Filter based on tab
                List<StockEntryEntity> filteredEntries;
                switch (_selectedFilter) {
                  case 1:
                    filteredEntries = entries
                        .where((e) => e.entryType == StockType.stockIn)
                        .toList();
                    break;
                  case 2:
                    filteredEntries = entries
                        .where((e) => e.entryType == StockType.stockOut)
                        .toList();
                    break;
                  default:
                    filteredEntries = entries;
                }

                if (filteredEntries.isEmpty) {
                  return EmptyStateWidget(
                    icon: _selectedFilter == 1
                        ? Icons.arrow_downward
                        : _selectedFilter == 2
                            ? Icons.arrow_upward
                            : Icons.swap_vert_outlined,
                    title: 'کوئی اسٹاک اندراج نہیں',
                    description: _selectedFilter == 1
                        ? 'اسٹاک ان بٹن دبا کر اندراج کریں'
                        : _selectedFilter == 2
                            ? 'اسٹاک آؤٹ بٹن دبا کر اندراج کریں'
                            : 'نیچے بٹن دبا کر اسٹاک ان/آؤٹ درج کریں',
                  );
                }
                final reversed = filteredEntries.reversed.toList();
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: reversed.length,
                  itemBuilder: (context, index) {
                    final entry = reversed[index];
                    return _StockEntryTile(
                      entry: entry,
                      product: product,
                      onDelete: () {
                        ref
                            .read(stockEntriesProvider(widget.productId).notifier)
                            .deleteEntry(entry);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Two FABs for Stock IN and Stock OUT — now navigating to separate screens
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'stockOut',
            onPressed: () => context.push('/home/stock/out/${widget.productId}'),
            backgroundColor: AppColors.debit,
            icon: const Icon(Icons.arrow_upward, color: Colors.white),
            label: const Text(
              'آؤٹ',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'stockIn',
            onPressed: () => context.push('/home/stock/in/${widget.productId}'),
            backgroundColor: AppColors.credit,
            icon: const Icon(Icons.arrow_downward, color: Colors.white),
            label: const Text(
              'ان',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockSummaryBar extends StatelessWidget {
  final ProductEntity product;
  const _StockSummaryBar({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      CurrencyFormatter.formatAmount(product.purchasePrice),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'خرید قیمت',
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      CurrencyFormatter.formatAmount(product.salePrice),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'فروخت قیمت',
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      CurrencyFormatter.formatAmount(product.stockValue),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.credit,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'اسٹاک ویلیو',
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'فی یونٹ منافع: ',
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(product.profitPerUnit),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: product.profitPerUnit >= 0
                      ? AppColors.credit
                      : AppColors.debit,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'کل منافع: ',
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.formatAmount(
                    product.profitPerUnit * product.currentStock),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: product.profitPerUnit >= 0
                      ? AppColors.credit
                      : AppColors.debit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockEntryTile extends StatelessWidget {
  final StockEntryEntity entry;
  final ProductEntity product;
  final VoidCallback onDelete;

  const _StockEntryTile({
    required this.entry,
    required this.product,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIn = entry.entryType == StockType.stockIn;

    return GestureDetector(
      key: Key(entry.id),
      onLongPress: () {
        showConfirmationDialog(
          context: context,
          title: 'اندراج حذف کریں',
          message: 'کیا آپ واقعی یہ اندراج حذف کرنا چاہتے ہیں؟',
          confirmLabel: 'حذف کریں',
          onConfirm: onDelete,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isIn ? AppColors.credit : AppColors.debit)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIn ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIn ? AppColors.credit : AppColors.debit,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIn ? 'اسٹاک ان (خرید)' : 'اسٹاک آؤٹ (فروخت)',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (entry.note.isNotEmpty)
                    Text(
                      entry.note,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    DateFormatter.formatDate(entry.entryDate),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity & amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIn ? '+' : '-'}${entry.quantity.toStringAsFixed(0)} ${product.unit}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isIn ? AppColors.credit : AppColors.debit,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatAmount(entry.totalAmount),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
