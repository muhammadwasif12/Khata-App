import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/invoice_item_entity.dart';

final invoiceRepositoryProvider =
    Provider((ref) => InvoiceRepositoryImpl());

final invoicesProvider =
    StateNotifierProvider<InvoicesNotifier, AsyncValue<List<InvoiceEntity>>>(
  (ref) {
    final activeId = ref.watch(activeBusinessIdProvider);
    return InvoicesNotifier(ref, activeId);
  },
);

class InvoicesNotifier
    extends StateNotifier<AsyncValue<List<InvoiceEntity>>> {
  final Ref ref;
  final String? businessId;
  final _repo = InvoiceRepositoryImpl();

  InvoicesNotifier(this.ref, this.businessId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() {
    if (businessId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = AsyncValue.data(_repo.getInvoices(businessId!));
  }

  String getNextInvoiceNumber() {
    if (businessId == null) return 'INV-0001';
    return _repo.generateInvoiceNumber(businessId!);
  }

  Future<void> createInvoice({
    required String customerName,
    required String customerPhone,
    String? partyId,
    required List<InvoiceItemEntity> items,
    required double subtotal,
    required double discount,
    required double totalAmount,
    required double paidAmount,
    required DateTime invoiceDate,
    String note = '',
    String vehicleNumber = '',
  }) async {
    if (businessId == null) return;

    final invoiceId = const Uuid().v4();
    final invoiceNumber = _repo.generateInvoiceNumber(businessId!);

    InvoiceStatus status;
    if (paidAmount >= totalAmount) {
      status = InvoiceStatus.paid;
    } else if (paidAmount > 0) {
      status = InvoiceStatus.partial;
    } else {
      status = InvoiceStatus.unpaid;
    }

    final entity = InvoiceEntity(
      id: invoiceId,
      businessId: businessId!,
      invoiceNumber: invoiceNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      partyId: partyId,
      subtotal: subtotal,
      discount: discount,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      status: status,
      invoiceDate: invoiceDate,
      createdAt: DateTime.now(),
      note: note,
      vehicleNumber: vehicleNumber,
    );

    // Set invoiceId on items
    final linkedItems = items
        .map((item) => InvoiceItemEntity(
              id: item.id,
              invoiceId: invoiceId,
              productName: item.productName,
              productId: item.productId,
              quantity: item.quantity,
              rate: item.rate,
              amount: item.amount,
              unit: item.unit,
            ))
        .toList();

    await _repo.addInvoice(entity, linkedItems);
    _load();
  }

  Future<void> recordPayment(String invoiceId, double amount) async {
    final invoice = _repo.getInvoiceById(invoiceId);
    if (invoice == null) return;

    final newPaid = invoice.paidAmount + amount;
    InvoiceStatus status;
    if (newPaid >= invoice.totalAmount) {
      status = InvoiceStatus.paid;
    } else if (newPaid > 0) {
      status = InvoiceStatus.partial;
    } else {
      status = InvoiceStatus.unpaid;
    }

    await _repo.updatePayment(invoiceId, newPaid, status);
    _load();
  }

  Future<void> deleteInvoice(String id) async {
    await _repo.deleteInvoice(id);
    _load();
  }

  List<InvoiceItemEntity> getInvoiceItems(String invoiceId) {
    return _repo.getInvoiceItems(invoiceId);
  }

  void refresh() => _load();
}
