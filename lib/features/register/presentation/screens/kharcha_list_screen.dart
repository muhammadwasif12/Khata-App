import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/kharcha_entity.dart';
import '../providers/kharcha_provider.dart';
import '../widgets/kharcha_tile.dart';
import '../pdf/kharcha_pdf.dart';
import '../pdf/kharcha_item_pdf.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/widgets/pdf_options_bottom_sheet.dart';

class KharchaListScreen extends ConsumerStatefulWidget {
  const KharchaListScreen({super.key});

  @override
  ConsumerState<KharchaListScreen> createState() => _KharchaListScreenState();
}

class _KharchaListScreenState extends ConsumerState<KharchaListScreen> {
  int _dateFilter = 3; // 0=آج 1=اس ہفتے 2=اس ماہ 3=سب
  String _catFilter = 'سب';

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(kharchaProvider);
    final totalKharcha = ref.watch(totalKharchaProvider);
    final count = ref.watch(kharchaCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('خرچہ رجسٹر', style: TextStyle(fontFamily: AppTextStyles.urduFont)),
        backgroundColor: const Color(0xFFC0392B),
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
          // Summary
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC0392B), Color(0xFFE74C3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFFC0392B).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                children: [
                  const Text('اس ماہ کل خرچہ', style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(CurrencyFormatter.formatAmount(totalKharcha), style: const TextStyle(fontFamily: 'Roboto', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('کل اندراج: $count', style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Date filters
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildDateChip('آج', 0), const SizedBox(width: 8),
                _buildDateChip('اس ہفتے', 1), const SizedBox(width: 8),
                _buildDateChip('اس ماہ', 2), const SizedBox(width: 8),
                _buildDateChip('سب', 3),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category filters
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCatChip('سب'), const SizedBox(width: 8),
                ...KharchaEntity.kharchaCategories.map((c) => Padding(padding: const EdgeInsets.only(left: 8), child: _buildCatChip(c))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFC0392B))),
              error: (e, st) => Center(child: Text('خرابی: $e')),
              data: (records) {
                final filtered = _applyFilter(records);
                if (filtered.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    return KharchaTile(
                      item: item,
                      onTap: () => context.push('/kharcha/edit/${item.id}'),
                      onEdit: () => context.push('/kharcha/edit/${item.id}'),
                      onDelete: () => ref.read(kharchaProvider.notifier).delete(item.id),
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
        onPressed: () => context.push('/kharcha/add'),
        backgroundColor: const Color(0xFFC0392B),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildDateChip(String label, int index) {
    final sel = _dateFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _dateFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFC0392B).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? const Color(0xFFC0392B) : AppColors.divider),
        ),
        child: Text(label, style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 12, color: sel ? const Color(0xFFC0392B) : AppColors.textHint, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildCatChip(String cat) {
    final sel = _catFilter == cat;
    return GestureDetector(
      onTap: () => setState(() => _catFilter = cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFC0392B).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? const Color(0xFFC0392B) : AppColors.divider),
        ),
        child: Text(cat, style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 12, color: sel ? const Color(0xFFC0392B) : AppColors.textHint, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  List<KharchaEntity> _applyFilter(List<KharchaEntity> records) {
    final now = DateTime.now();
    var filtered = records;
    
    if (_catFilter != 'سب') {
      filtered = filtered.where((r) => r.category == _catFilter).toList();
    }

    switch (_dateFilter) {
      case 0:
        return filtered.where((r) => r.expenseDate.year == now.year && r.expenseDate.month == now.month && r.expenseDate.day == now.day).toList();
      case 1:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final s = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return filtered.where((r) => r.expenseDate.isAfter(s) || r.expenseDate.isAtSameMomentAs(s)).toList();
      case 2:
        return filtered.where((r) => r.expenseDate.year == now.year && r.expenseDate.month == now.month).toList();
      default:
        return filtered;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFC0392B).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.money_off, size: 40, color: Color(0xFFC0392B)),
          ),
          const SizedBox(height: 16),
          const Text('کوئی خرچہ نہیں', style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('نیچے + دبا کر خرچہ درج کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final records = ref.read(kharchaProvider).value ?? [];
    if (records.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کوئی ریکارڈ نہیں', style: TextStyle(fontFamily: AppTextStyles.urduFont))));
      return;
    }
    final businesses = ref.read(businessesProvider).value ?? [];
    final activeId = ref.read(activeBusinessIdProvider);
    final businessName = businesses.where((b) => b.id == activeId).map((b) => b.name).firstOrNull ?? 'کھاتہ';
    final now = DateTime.now();
    await generateKharchaPdf(
      businessName: businessName,
      from: DateTime(now.year, now.month, 1),
      to: now,
      records: records,
    );
  }

  Future<void> _exportItemPdf(KharchaEntity item) async {
    final businesses = ref.read(businessesProvider).value ?? [];
    final activeId = ref.read(activeBusinessIdProvider);
    final businessName = businesses.where((b) => b.id == activeId).map((b) => b.name).firstOrNull ?? 'کھاتہ';
    await generateKharchaItemPdf(
      businessName: businessName,
      record: item,
    );
  }
}
