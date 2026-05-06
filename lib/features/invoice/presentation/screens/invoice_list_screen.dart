/// Invoice List Screen — Shows all invoices/bills.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/invoice_entity.dart';
import '../providers/invoice_provider.dart';
import '../../../business/presentation/providers/business_provider.dart';
import 'daily_bill_pdf_generator.dart';
import '../../../../core/constants/app_strings.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  int _selectedFilter = 0; // 0=all, 1=paid, 2=unpaid, 3=partial
  final _searchController = TextEditingController();
  bool _showSearch = false;

  List<InvoiceEntity> _filterInvoices(List<InvoiceEntity> invoices) {
    List<InvoiceEntity> filtered;
    switch (_selectedFilter) {
      case 1:
        filtered = invoices.where((i) => i.status == InvoiceStatus.paid).toList();
        break;
      case 2:
        filtered = invoices.where((i) => i.status == InvoiceStatus.unpaid).toList();
        break;
      case 3:
        filtered = invoices.where((i) => i.status == InvoiceStatus.partial).toList();
        break;
      default:
        filtered = invoices;
    }

    // Apply search
    if (_searchController.text.trim().isNotEmpty) {
      final query = _searchController.text.trim().toLowerCase();
      filtered = filtered.where((i) =>
          i.customerName.toLowerCase().contains(query) ||
          i.invoiceNumber.toLowerCase().contains(query)).toList();
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
    final invoicesAsync = ref.watch(invoicesProvider);

    return invoicesAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text('خرابی: $e')),
      data: (allInvoices) {
        if (allInvoices.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'کوئی بل نہیں',
            description: '+ بٹن دبا کر نیا بل بنائیں',
          );
        }

        final invoices = _filterInvoices(allInvoices);

        // Summary
        final total = allInvoices.fold<double>(0, (s, i) => s + i.totalAmount);
        final received = allInvoices.fold<double>(0, (s, i) => s + i.paidAmount);
        final pending = total - received;
        final paidCount = allInvoices.where((i) => i.status == InvoiceStatus.paid).length;
        final unpaidCount = allInvoices.where((i) => i.status == InvoiceStatus.unpaid).length;
        final partialCount = allInvoices.where((i) => i.status == InvoiceStatus.partial).length;

        return Column(
          children: [
            // Search
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
                    hintText: 'بل یا گراہک تلاش کریں...',
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

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
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
                      generateDailyBillsPdf(invoices, ref, bName);
                    },
                    icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 18),
                    label: const Text('بل رپورٹ', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: AppColors.primary, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            // Summary
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
              child: Row(
                children: [
                  _Stat(
                    label: 'کل بل',
                    value: CurrencyFormatter.formatShort(total),
                    icon: Icons.receipt_long,
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _Stat(
                    label: 'وصول شدہ',
                    value: CurrencyFormatter.formatShort(received),
                    icon: Icons.check_circle_outline,
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _Stat(
                    label: 'بقایا',
                    value: CurrencyFormatter.formatShort(pending),
                    icon: pending > 0 ? Icons.warning_amber : Icons.done_all,
                  ),
                ],
              ),
            ),

            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'تمام',
                      count: allInvoices.length,
                      isSelected: _selectedFilter == 0,
                      onTap: () => setState(() => _selectedFilter = 0),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'ادا شدہ',
                      count: paidCount,
                      isSelected: _selectedFilter == 1,
                      onTap: () => setState(() => _selectedFilter = 1),
                      activeColor: AppColors.credit,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'بقایا',
                      count: unpaidCount,
                      isSelected: _selectedFilter == 2,
                      onTap: () => setState(() => _selectedFilter = 2),
                      activeColor: AppColors.debit,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'جزوی',
                      count: partialCount,
                      isSelected: _selectedFilter == 3,
                      onTap: () => setState(() => _selectedFilter = 3),
                      activeColor: AppColors.amber,
                    ),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: invoices.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'کوئی بل نہیں',
                      description: 'اس فلٹر میں کوئی بل نہیں',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 100),
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return _InvoiceCard(
                          invoice: invoice,
                          onTap: () => context.push(
                              '/home/invoices/preview/${invoice.id}'),
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.icon});

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
              fontSize: 14,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const _FilterChip({
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : color.withOpacity(0.1),
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

class _InvoiceCard extends StatelessWidget {
  final InvoiceEntity invoice;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (invoice.status) {
      case InvoiceStatus.paid:
        statusColor = AppColors.credit;
        statusLabel = 'ادا شدہ';
        statusIcon = Icons.check_circle;
        break;
      case InvoiceStatus.partial:
        statusColor = AppColors.amber;
        statusLabel = 'جزوی';
        statusIcon = Icons.hourglass_bottom;
        break;
      case InvoiceStatus.unpaid:
        statusColor = AppColors.debit;
        statusLabel = 'بقایا';
        statusIcon = Icons.warning_amber;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Invoice icon
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
                child: const Icon(Icons.receipt,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 10, color: statusColor),
                              const SizedBox(width: 3),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.urduFont,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice.customerName.isNotEmpty
                          ? invoice.customerName
                          : 'بغیر نام',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 10, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatDate(invoice.invoiceDate),
                          style: const TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                        if (invoice.customerPhone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.phone, size: 10, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              invoice.customerPhone,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatAmount(invoice.totalAmount),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (invoice.balanceAmount > 0)
                    Text(
                      'بقایا: ${CurrencyFormatter.formatAmount(invoice.balanceAmount)}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 11,
                        color: AppColors.debit,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
