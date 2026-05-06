import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/invoice_item_entity.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';

class InvoiceRepositoryImpl {
  Box<InvoiceModel> get _invoiceBox =>
      Hive.box<InvoiceModel>(AppConstants.invoiceBox);

  Box<InvoiceItemModel> get _itemBox =>
      Hive.box<InvoiceItemModel>(AppConstants.invoiceItemBox);

  List<InvoiceEntity> getInvoices(String businessId) {
    return _invoiceBox.values
        .where((i) => i.businessId == businessId && !i.isDeleted)
        .map(_toEntity)
        .toList()
      ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
  }

  InvoiceEntity? getInvoiceById(String id) {
    final model =
        _invoiceBox.values.where((i) => i.id == id && !i.isDeleted).firstOrNull;
    return model != null ? _toEntity(model) : null;
  }

  List<InvoiceItemEntity> getInvoiceItems(String invoiceId) {
    return _itemBox.values
        .where((item) => item.invoiceId == invoiceId)
        .map(_itemToEntity)
        .toList();
  }

  String generateInvoiceNumber(String businessId) {
    final count = _invoiceBox.values
        .where((i) => i.businessId == businessId)
        .length;
    return 'INV-${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<void> addInvoice(
      InvoiceEntity entity, List<InvoiceItemEntity> items) async {
    final model = InvoiceModel(
      id: entity.id,
      businessId: entity.businessId,
      invoiceNumber: entity.invoiceNumber,
      customerName: entity.customerName,
      customerPhone: entity.customerPhone,
      partyId: entity.partyId,
      subtotal: entity.subtotal,
      discount: entity.discount,
      totalAmount: entity.totalAmount,
      paidAmount: entity.paidAmount,
      status: entity.status.index,
      invoiceDate: entity.invoiceDate,
      createdAt: entity.createdAt,
      note: entity.note,
      vehicleNumber: entity.vehicleNumber,
    );
    await _invoiceBox.put(entity.id, model);

    for (final item in items) {
      final itemModel = InvoiceItemModel(
        id: item.id,
        invoiceId: item.invoiceId,
        productName: item.productName,
        productId: item.productId,
        quantity: item.quantity,
        rate: item.rate,
        amount: item.amount,
        unit: item.unit,
      );
      await _itemBox.put(item.id, itemModel);
    }
  }

  Future<void> updatePayment(
      String invoiceId, double paidAmount, InvoiceStatus status) async {
    final existing = _invoiceBox.get(invoiceId);
    if (existing != null) {
      existing.paidAmount = paidAmount;
      existing.status = status.index;
      await existing.save();
    }
  }

  Future<void> deleteInvoice(String id) async {
    final existing = _invoiceBox.get(id);
    if (existing != null) {
      existing.isDeleted = true;
      await existing.save();
    }
  }

  InvoiceEntity _toEntity(InvoiceModel m) => InvoiceEntity(
        id: m.id,
        businessId: m.businessId,
        invoiceNumber: m.invoiceNumber,
        customerName: m.customerName,
        customerPhone: m.customerPhone,
        partyId: m.partyId,
        subtotal: m.subtotal,
        discount: m.discount,
        totalAmount: m.totalAmount,
        paidAmount: m.paidAmount,
        status: InvoiceStatus.values[m.status],
        invoiceDate: m.invoiceDate,
        createdAt: m.createdAt,
        note: m.note,
        vehicleNumber: m.vehicleNumber,
      );

  InvoiceItemEntity _itemToEntity(InvoiceItemModel m) => InvoiceItemEntity(
        id: m.id,
        invoiceId: m.invoiceId,
        productName: m.productName,
        productId: m.productId,
        quantity: m.quantity,
        rate: m.rate,
        amount: m.amount,
        unit: m.unit,
      );
}
