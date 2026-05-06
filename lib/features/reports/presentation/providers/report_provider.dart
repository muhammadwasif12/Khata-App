/// Report Provider
/// Manages report generation state including date ranges and data aggregation.
/// Supports separate report data per tab (customers, suppliers, cashbook).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../customers/data/repositories/party_repository_impl.dart';
import '../../../customers/domain/entities/party_entity.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../cashbook/data/repositories/cashbook_repository_impl.dart';
import '../../../cashbook/domain/entities/cash_entry_entity.dart';

/// Report data class holds aggregated report results
class ReportData {
  final double totalCredit;
  final double totalDebit;
  final double netBalance;
  final List<PartyReportItem> partyItems;
  final List<TransactionEntity> transactions;
  final List<CashEntryEntity> cashEntries;

  const ReportData({
    this.totalCredit = 0,
    this.totalDebit = 0,
    this.netBalance = 0,
    this.partyItems = const [],
    this.transactions = const [],
    this.cashEntries = const [],
  });
}

/// Individual party report line item
class PartyReportItem {
  final PartyEntity party;
  final double balance;
  final bool isCredit;

  const PartyReportItem({
    required this.party,
    required this.balance,
    required this.isCredit,
  });
}

/// Report state — holds separate data for each tab
class ReportState {
  final DateTime fromDate;
  final DateTime toDate;
  final int activeTab; // 0=customers, 1=suppliers, 2=cashbook
  final ReportData? customerData;
  final ReportData? supplierData;
  final ReportData? cashData;
  final bool isLoading;
  final String? error;

  const ReportState({
    required this.fromDate,
    required this.toDate,
    this.activeTab = 0,
    this.customerData,
    this.supplierData,
    this.cashData,
    this.isLoading = false,
    this.error,
  });

  /// Convenience getter for current tab's data
  ReportData? get data {
    switch (activeTab) {
      case 0: return customerData;
      case 1: return supplierData;
      case 2: return cashData;
      default: return null;
    }
  }

  ReportState copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    int? activeTab,
    ReportData? customerData,
    ReportData? supplierData,
    ReportData? cashData,
    bool? isLoading,
    String? error,
    bool clearCustomer = false,
    bool clearSupplier = false,
    bool clearCash = false,
  }) {
    return ReportState(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      activeTab: activeTab ?? this.activeTab,
      customerData: clearCustomer ? null : (customerData ?? this.customerData),
      supplierData: clearSupplier ? null : (supplierData ?? this.supplierData),
      cashData: clearCash ? null : (cashData ?? this.cashData),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  ReportNotifier()
      : super(ReportState(
          fromDate: DateTime.now().subtract(const Duration(days: 30)),
          toDate: DateTime.now(),
        ));

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
  }

  void setActiveTab(int tab) {
    state = state.copyWith(activeTab: tab);
  }

  Future<void> generatePartyReport(String businessId, PartyType partyType, int reportTypeTab) async {
    state = state.copyWith(isLoading: true, error: null, activeTab: reportTypeTab);

    try {
      final partyRepo = PartyRepositoryImpl();
      final txnRepo = TransactionRepositoryImpl();

      final parties = await partyRepo.getPartiesByBusiness(
        businessId,
        partyType: partyType,
      );

      final allTxns = await txnRepo.getTransactionsByBusiness(businessId);
      
      final partyIds = parties.map((e) => e.id).toSet();
      
      final filteredTxns = allTxns
          .where((t) =>
              partyIds.contains(t.partyId) &&
              (t.txnDate.isAfter(state.fromDate) ||
                  t.txnDate.isAtSameMomentAs(state.fromDate)) &&
              (t.txnDate.isBefore(state.toDate.add(const Duration(days: 1)))))
          .toList();

      double totalCredit = 0;
      double totalDebit = 0;

      for (final txn in filteredTxns) {
        if (txn.txnType == TxnType.credit) {
          totalCredit += txn.amount;
        } else {
          totalDebit += txn.amount;
        }
      }

      final partyItems = <PartyReportItem>[];
      for (final party in parties) {
        double balance = party.isOpeningCredit
            ? party.openingBalance
            : -party.openingBalance;

        final partyTxns = allTxns.where((t) => t.partyId == party.id);
        for (final txn in partyTxns) {
          if (txn.txnType == TxnType.credit) {
            balance += txn.amount;
          } else {
            balance -= txn.amount;
          }
        }

        partyItems.add(PartyReportItem(
          party: party,
          balance: balance.abs(),
          isCredit: balance > 0,
        ));
      }

      final reportData = ReportData(
        totalCredit: totalCredit,
        totalDebit: totalDebit,
        netBalance: totalCredit - totalDebit,
        partyItems: partyItems,
        transactions: filteredTxns,
      );

      if (reportTypeTab == 0) {
        state = state.copyWith(isLoading: false, customerData: reportData);
      } else {
        state = state.copyWith(isLoading: false, supplierData: reportData);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> generateCashbookReport(String businessId) async {
    state = state.copyWith(isLoading: true, error: null, activeTab: 2);

    try {
      final cashRepo = CashbookRepositoryImpl();
      final entries = await cashRepo.getEntriesByBusiness(
        businessId,
        from: state.fromDate,
        to: state.toDate.add(const Duration(days: 1)),
      );

      double totalIn = 0;
      double totalOut = 0;
      for (final entry in entries) {
        if (entry.cashType == CashType.cashIn) {
          totalIn += entry.amount;
        } else {
          totalOut += entry.amount;
        }
      }

      state = state.copyWith(
        isLoading: false,
        cashData: ReportData(
          totalCredit: totalIn,
          totalDebit: totalOut,
          netBalance: totalIn - totalOut,
          cashEntries: entries,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final reportProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier();
});
