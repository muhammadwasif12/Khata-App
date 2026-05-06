/// Supplier List Screen
/// Displays all suppliers for the active business with search and balance info.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/party_provider.dart';
import '../../domain/entities/party_entity.dart';
import '../widgets/party_list_tile.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _calculateBalance(PartyEntity party) {
    final box = Hive.box<TransactionModel>(AppConstants.transactionBox);
    double balance = party.isOpeningCredit
        ? party.openingBalance
        : -party.openingBalance;

    final txns = box.values
        .where((t) => !t.isDeleted && t.partyId == party.id)
        .toList();

    for (final txn in txns) {
      if (txn.txnType == 0) {
        balance += txn.amount;
      } else {
        balance -= txn.amount;
      }
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: AppStrings.searchSupplier,
              hintStyle: const TextStyle(
                fontFamily: AppTextStyles.urduFont,
                color: AppColors.textHint,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontFamily: AppTextStyles.urduFont),
          ),
        ),
        Expanded(
          child: suppliersAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, st) => Center(
              child: Text(
                '${AppStrings.error}: $e',
                style: const TextStyle(fontFamily: AppTextStyles.urduFont),
              ),
            ),
            data: (suppliers) {
              final filtered = _searchQuery.isEmpty
                  ? suppliers
                  : suppliers
                      .where((s) => s.name.contains(_searchQuery))
                      .toList();

              if (filtered.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.local_shipping_outlined,
                  title: AppStrings.noSuppliers,
                  description: AppStrings.noSuppliersDesc,
                );
              }

              return ValueListenableBuilder<Box<TransactionModel>>(
                valueListenable: Hive.box<TransactionModel>(AppConstants.transactionBox).listenable(),
                builder: (context, box, child) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final party = filtered[index];
                      final balance = _calculateBalance(party);
                      final isCredit = balance > 0;

                      return PartyListTile(
                        party: party,
                        balance: balance,
                        isCredit: isCredit,
                        onTap: () => context.push('/home/suppliers/ledger/${party.id}'),
                        onEdit: () => context.push('/home/suppliers/edit/${party.id}'),
                        onDelete: () => _confirmDelete(party),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(PartyEntity party) {
    showConfirmationDialog(
      context: context,
      title: AppStrings.deleteParty,
      message: AppStrings.deletePartyMsg,
      confirmLabel: AppStrings.delete,
      onConfirm: () {
        ref.read(suppliersProvider.notifier).deleteParty(party.id);
      },
    );
  }
}
