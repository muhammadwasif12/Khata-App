import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/khareed_entity.dart';
import '../providers/khareed_provider.dart';
import '../widgets/khareed_tile.dart';
import '../pdf/khareed_pdf.dart';
import '../pdf/khareed_item_pdf.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/widgets/pdf_options_bottom_sheet.dart';

class KhareedListScreen extends ConsumerStatefulWidget {
  const KhareedListScreen({super.key});

  @override
  ConsumerState<KhareedListScreen> createState() => _KhareedListScreenState();
}

class _KhareedListScreenState extends ConsumerState<KhareedListScreen> {
  int _filterIndex = 3; // 0=آج 1=اس ہفتے 2=اس ماہ 3=سب

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(khareedProvider);
    final totalKhareed = ref.watch(totalKhareedAmountProvider);
    final totalJama = ref.watch(totalJamaProvider);
    final totalBaqaya = ref.watch(totalBaqayaProvider);
    final count = ref.watch(khareedCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('خریداری رجسٹر', style: TextStyle(fontFamily: AppTextStyles.urduFont)),
        backgroundColor: const Color(0xFF1A6B3C),
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
          // Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A6B3C), Color(0xFF2ECC71)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A6B3C).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  _buildSummaryCol('کل خریداری', totalKhareed),
                  Container(width: 1, height: 40, color: Colors.white30),
                  _buildSummaryCol('کل جمع', totalJama),
                  Container(width: 1, height: 40, color: Colors.white30),
                  _buildSummaryCol('کل بقایا', totalBaqaya),
                ],
              ),
            ),
          ),

          // Filters
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('آج', 0),
                const SizedBox(width: 8),
                _buildFilterChip('اس ہفتے', 1),
                const SizedBox(width: 8),
                _buildFilterChip('اس ماہ', 2),
                const SizedBox(width: 8),
                _buildFilterChip('سب', 3),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B3C))),
              error: (err, st) => Center(child: Text('خرابی: $err', style: const TextStyle(fontFamily: AppTextStyles.urduFont))),
              data: (records) {
                final filtered = _applyFilter(records);
                if (filtered.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    return KhareedTile(
                      item: item,
                      onTap: () => context.push('/khareed/edit/${item.id}'),
                      onEdit: () => context.push('/khareed/edit/${item.id}'),
                      onDelete: () => ref.read(khareedProvider.notifier).delete(item.id),
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
        onPressed: () => context.push('/khareed/add'),
        backgroundColor: const Color(0xFF1A6B3C),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSummaryCol(String label, double amount) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 6),
          Text(CurrencyFormatter.formatAmount(amount), style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A6B3C).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF1A6B3C) : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontSize: 12,
            color: isSelected ? const Color(0xFF1A6B3C) : AppColors.textHint,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<KhareedEntity> _applyFilter(List<KhareedEntity> records) {
    final now = DateTime.now();
    switch (_filterIndex) {
      case 0:
        return records.where((r) => r.purchaseDate.year == now.year && r.purchaseDate.month == now.month && r.purchaseDate.day == now.day).toList();
      case 1:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final s = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return records.where((r) => r.purchaseDate.isAfter(s) || r.purchaseDate.isAtSameMomentAs(s)).toList();
      case 2:
        return records.where((r) => r.purchaseDate.year == now.year && r.purchaseDate.month == now.month).toList();
      default:
        return records;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: const Color(0xFF1A6B3C).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.shopping_cart_outlined, size: 40, color: Color(0xFF1A6B3C)),
          ),
          const SizedBox(height: 16),
          const Text('کوئی خریداری نہیں', style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('نیچے + دبا کر خریداری درج کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final records = ref.read(khareedProvider).value ?? [];
    if (records.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کوئی ریکارڈ نہیں', style: TextStyle(fontFamily: AppTextStyles.urduFont))));
      return;
    }
    final businesses = ref.read(businessesProvider).value ?? [];
    final activeId = ref.read(activeBusinessIdProvider);
    final businessName = businesses.where((b) => b.id == activeId).map((b) => b.name).firstOrNull ?? 'کھاتہ';
    final now = DateTime.now();
    final filtered = _applyFilter(records);
    await generateKhareedPdf(
      businessName: businessName,
      from: DateTime(now.year, now.month, 1),
      to: now,
      records: filtered,
    );
  }

  Future<void> _exportItemPdf(KhareedEntity item) async {
    final businesses = ref.read(businessesProvider).value ?? [];
    final activeId = ref.read(activeBusinessIdProvider);
    final businessName = businesses.where((b) => b.id == activeId).map((b) => b.name).firstOrNull ?? 'کھاتہ';
    await generateKhareedItemPdf(
      businessName: businessName,
      record: item,
    );
  }
}
