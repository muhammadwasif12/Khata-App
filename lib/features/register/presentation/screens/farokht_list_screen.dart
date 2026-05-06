import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/farokht_entity.dart';
import '../providers/farokht_provider.dart';
import '../widgets/farokht_tile.dart';
import '../pdf/farokht_pdf.dart';
import '../pdf/farokht_item_pdf.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/widgets/pdf_options_bottom_sheet.dart';

class FarokhtListScreen extends ConsumerStatefulWidget {
  const FarokhtListScreen({super.key});

  @override
  ConsumerState<FarokhtListScreen> createState() => _FarokhtListScreenState();
}

class _FarokhtListScreenState extends ConsumerState<FarokhtListScreen> {
  int _paymentFilter = -1; // -1=سب, 1=نقد, 0=ادھار, 2=جزوی

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(farokhtProvider);
    final totalFarokht = ref.watch(totalFarokhtProvider);
    final totalCredit = ref.watch(totalCreditProvider);
    final totalDebit = ref.watch(totalDebitProvider);
    final totalProfit = ref.watch(farokhtProfitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'فروخت رجسٹر',
          style: TextStyle(fontFamily: AppTextStyles.urduFont),
        ),
        backgroundColor: const Color(0xFFE67E22),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
            tooltip: 'PDF',
            onPressed: () => _exportPdf(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE67E22), Color(0xFFF39C12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE67E22).withValues(alpha: 0.3),
                  blurRadius: 12,
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
                          const Text('کل فروخت',
                              style: TextStyle(
                                  fontFamily: AppTextStyles.urduFont,
                                  fontSize: 11,
                                  color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(CurrencyFormatter.formatAmount(totalFarokht),
                              style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('وصول',
                              style: TextStyle(
                                  fontFamily: AppTextStyles.urduFont,
                                  fontSize: 11,
                                  color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(CurrencyFormatter.formatAmount(totalCredit),
                              style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('باقی ادھار',
                              style: TextStyle(
                                  fontFamily: AppTextStyles.urduFont,
                                  fontSize: 11,
                                  color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(CurrencyFormatter.formatAmount(totalDebit),
                              style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('منافع',
                              style: TextStyle(
                                  fontFamily: AppTextStyles.urduFont,
                                  fontSize: 11,
                                  color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(CurrencyFormatter.formatAmount(totalProfit),
                              style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payment status filter
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('سب', -1),
                const SizedBox(width: 8),
                _buildFilterChip('نقد', 1),
                const SizedBox(width: 8),
                _buildFilterChip('ادھار', 0),
                const SizedBox(width: 8),
                _buildFilterChip('جزوی', 2),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFE67E22)),
              ),
              error: (e, st) => Center(
                child: Text('خرابی: $e',
                    style: const TextStyle(fontFamily: AppTextStyles.urduFont)),
              ),
              data: (records) {
                final filtered = _paymentFilter == -1
                    ? records
                    : records.where((r) => r.paymentStatus == _paymentFilter).toList();
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return FarokhtTile(
                      item: item,
                      onTap: () => context.push('/farokht/edit/${item.id}'),
                      onEdit: () => context.push('/farokht/edit/${item.id}'),
                      onDelete: () => _confirmDelete(item),
                      onPdf: () => _exportItemPdf(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/farokht/add'),
        backgroundColor: const Color(0xFFE67E22),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label, int status) {
    final isSelected = _paymentFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _paymentFilter = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE67E22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFE67E22) : AppColors.divider,
          ),
        ),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sell_outlined,
                size: 40, color: Color(0xFFE67E22)),
          ),
          const SizedBox(height: 16),
          const Text(
            'کوئی فروخت نہیں',
            style: TextStyle(
              fontFamily: AppTextStyles.urduFont,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'نیچے + دبا کر فروخت درج کریں',
            style: TextStyle(
              fontFamily: AppTextStyles.urduFont,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(FarokhtEntity item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کریں',
            style: TextStyle(fontFamily: AppTextStyles.urduFont)),
        content: Text(
          'کیا آپ واقعی "${item.itemName}" کی فروخت حذف کرنا چاہتے ہیں؟',
          style: const TextStyle(fontFamily: AppTextStyles.urduFont),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('نہیں',
                style: TextStyle(fontFamily: AppTextStyles.urduFont)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(farokhtProvider.notifier).delete(item.id);
            },
            child: const Text('ہاں، حذف کریں',
                style: TextStyle(
                    fontFamily: AppTextStyles.urduFont, color: AppColors.debit)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final records = ref.read(farokhtProvider).value ?? [];
    if (records.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کوئی ریکارڈ نہیں',
            style: TextStyle(fontFamily: AppTextStyles.urduFont))),
      );
      return;
    }
    final businesses = ref.read(businessesProvider).value ?? [];
    final activeId = ref.read(activeBusinessIdProvider);
    final businessName = businesses
        .where((b) => b.id == activeId)
        .map((b) => b.name)
        .firstOrNull ?? 'کھاتہ';
    final now = DateTime.now();
    await generateFarokhtPdf(
      businessName: businessName,
      from: DateTime(now.year, now.month, 1),
      to: now,
      records: records,
    );
  }

  Future<void> _exportItemPdf(FarokhtEntity item) async {
    final businesses = ref.read(businessesProvider).value ?? [];
    final activeId = ref.read(activeBusinessIdProvider);
    final businessName = businesses.where((b) => b.id == activeId).map((b) => b.name).firstOrNull ?? 'کھاتہ';
    await generateFarokhtItemPdf(
      businessName: businessName,
      record: item,
    );
  }
}
