/// Cashbook Screen
/// Displays daily cash in/out entries with summary card and date filters.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/cash_entry_entity.dart';
import '../providers/cashbook_provider.dart';
import '../widgets/cash_entry_tile.dart';
import '../widgets/daily_summary_card.dart';
import 'package:go_router/go_router.dart';

class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  int _selectedFilter = 0; // 0=all, 1=today, 2=month, 3=specific date
  DateTime? _selectedDate;

  List<CashEntryEntity> _filterEntries(List<CashEntryEntity> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case 1: // today
        return entries
            .where((e) =>
                e.entryDate.year == today.year &&
                e.entryDate.month == today.month &&
                e.entryDate.day == today.day)
            .toList();
      case 2: // this month
        return entries
            .where((e) =>
                e.entryDate.year == today.year &&
                e.entryDate.month == today.month)
            .toList();
      case 3: // specific date
        if (_selectedDate != null) {
          return entries
              .where((e) =>
                  e.entryDate.year == _selectedDate!.year &&
                  e.entryDate.month == _selectedDate!.month &&
                  e.entryDate.day == _selectedDate!.day)
              .toList();
        }
        return entries;
      default:
        return entries;
    }
  }

  double _calculateCashIn(List<CashEntryEntity> entries) {
    return entries
        .where((e) => e.cashType == CashType.cashIn)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double _calculateCashOut(List<CashEntryEntity> entries) {
    return entries
        .where((e) => e.cashType == CashType.cashOut)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  void _showAddCashEntry({CashEntryEntity? existing}) {
    context.push('/home/cashbook/add_cash_entry', extra: existing);
  }

  Future<void> _pickSpecificDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ur', 'PK'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedFilter = 3;
      });
    }
  }

  /// Group entries by date for display
  Map<String, List<CashEntryEntity>> _groupByDate(
      List<CashEntryEntity> entries) {
    final Map<String, List<CashEntryEntity>> grouped = {};
    for (final entry in entries) {
      final key = DateFormatter.formatDate(entry.entryDate);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final cashAsync = ref.watch(cashEntriesProvider);

    return cashAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, st) => Center(
        child: Text(
          '${AppStrings.error}: $e',
          style: const TextStyle(fontFamily: AppTextStyles.urduFont),
        ),
      ),
      data: (allEntries) {
        final entries = _filterEntries(allEntries);
        final cashIn = _calculateCashIn(entries);
        final cashOut = _calculateCashOut(entries);

        // Get date label for summary
        String dateLabel;
        switch (_selectedFilter) {
          case 1:
            dateLabel = 'آج';
            break;
          case 2:
            dateLabel = 'اس مہینے';
            break;
          case 3:
            dateLabel = _selectedDate != null
                ? DateFormatter.formatDate(_selectedDate!)
                : 'منتخب تاریخ';
            break;
          default:
            dateLabel = 'مجموعی';
        }

        return Column(
          children: [
            DailySummaryCard(
              cashIn: cashIn,
              cashOut: cashOut,
              dateLabel: dateLabel,
            ),
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'سب',
                    isSelected: _selectedFilter == 0,
                    onTap: () => setState(() => _selectedFilter = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'آج',
                    isSelected: _selectedFilter == 1,
                    onTap: () => setState(() => _selectedFilter = 1),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'اس مہینے',
                    isSelected: _selectedFilter == 2,
                    onTap: () => setState(() => _selectedFilter = 2),
                  ),
                  const SizedBox(width: 8),
                  // Date Picker Filter
                  _DateFilterChip(
                    isSelected: _selectedFilter == 3,
                    selectedDate: _selectedDate,
                    onTap: _pickSpecificDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Show selected date info bar when specific date is selected
            if (_selectedFilter == 3 && _selectedDate != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تاریخ: ${DateFormatter.formatDate(_selectedDate!)}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.urduFont,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${entries.length} اندراجات',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() {
                        _selectedFilter = 0;
                        _selectedDate = null;
                      }),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.debit.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, size: 14, color: AppColors.debit),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            // Entry list
            Expanded(
              child: entries.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.account_balance_wallet_outlined,
                      title: _selectedFilter == 3
                          ? 'اس تاریخ کا کوئی اندراج نہیں'
                          : AppStrings.noCashEntries,
                      description: _selectedFilter == 3
                          ? 'اس تاریخ پر کوئی کیش اندراج نہیں ملا'
                          : AppStrings.noCashDesc,
                    )
                  : _buildGroupedList(entries),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupedList(List<CashEntryEntity> entries) {
    final grouped = _groupByDate(entries);
    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final dateEntries = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...dateEntries.map(
              (entry) => CashEntryTile(
                entry: entry,
                onTap: () => _showAddCashEntry(existing: entry),
                onDelete: () {
                  ref.read(cashEntriesProvider.notifier).deleteEntry(entry.id);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final bool isSelected;
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const _DateFilterChip({
    required this.isSelected,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month,
              size: 14,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              isSelected && selectedDate != null
                  ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                  : '📅 تاریخ منتخب',
              style: TextStyle(
                fontFamily: AppTextStyles.urduFont,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
