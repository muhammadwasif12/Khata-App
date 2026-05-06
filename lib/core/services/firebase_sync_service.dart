import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';
import '../../features/business/data/models/business_model.dart';
import '../../features/customers/data/models/party_model.dart';
import '../../features/transactions/data/models/transaction_model.dart';
import '../../features/cashbook/data/models/cash_entry_model.dart';
import '../../features/stock/data/models/product_model.dart';
import '../../features/stock/data/models/stock_entry_model.dart';
import '../../features/invoice/data/models/invoice_model.dart';
import '../../features/invoice/data/models/invoice_item_model.dart';
import '../../features/register/data/models/khareed_model.dart';
import '../../features/register/data/models/farokht_model.dart';
import '../../features/register/data/models/kharcha_model.dart';

class FirebaseSyncService {
  static bool isRestoring = false;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> backupAllData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final batch = _firestore.batch();
    final userDoc = _firestore.collection('users').doc(user.uid);

    // Business
    final businessBox = Hive.box<BusinessModel>(AppConstants.businessBox);
    for (var b in businessBox.values) {
      batch.set(userDoc.collection('businesses').doc(b.id), {
        'id': b.id, 'name': b.name, 'type': b.type, 'createdAt': b.createdAt.toIso8601String(),
        'updatedAt': b.updatedAt.toIso8601String(), 'isDeleted': b.isDeleted, 'ownerName': b.ownerName,
        'phone': b.phone, 'address': b.address, 'currency': b.currency,
      });
    }

    // Party
    final partyBox = Hive.box<PartyModel>(AppConstants.partyBox);
    for (var p in partyBox.values) {
      batch.set(userDoc.collection('parties').doc(p.id), {
        'id': p.id, 'businessId': p.businessId, 'name': p.name, 'phone': p.phone,
        'openingBalance': p.openingBalance, 'isOpeningCredit': p.isOpeningCredit,
        'partyType': p.partyType, 'isDeleted': p.isDeleted, 'createdAt': p.createdAt.toIso8601String(),
      });
    }

    // Transactions
    final txnBox = Hive.box<TransactionModel>(AppConstants.transactionBox);
    for (var t in txnBox.values) {
      batch.set(userDoc.collection('transactions').doc(t.id), {
        'id': t.id, 'partyId': t.partyId, 'businessId': t.businessId, 'txnType': t.txnType,
        'amount': t.amount, 'note': t.note, 'txnDate': t.txnDate.toIso8601String(),
        'createdAt': t.createdAt.toIso8601String(), 'isDeleted': t.isDeleted,
        'paymentMethod': t.paymentMethod, 'attachmentPath': t.attachmentPath, 'attachmentType': t.attachmentType,
      });
    }

    // Cash Entry
    final cashBox = Hive.box<CashEntryModel>(AppConstants.cashEntryBox);
    for (var c in cashBox.values) {
      batch.set(userDoc.collection('cash_entries').doc(c.id), {
        'id': c.id, 'businessId': c.businessId, 'cashType': c.cashType, 'amount': c.amount,
        'note': c.note, 'entryDate': c.entryDate.toIso8601String(), 'createdAt': c.createdAt.toIso8601String(),
        'isDeleted': c.isDeleted, 'paymentMethod': c.paymentMethod, 'personName': c.personName,
        'accountTitle': c.accountTitle, 'attachmentPath': c.attachmentPath, 'attachmentType': c.attachmentType,
      });
    }

    // Product
    final productBox = Hive.box<ProductModel>(AppConstants.productBox);
    for (var p in productBox.values) {
      batch.set(userDoc.collection('products').doc(p.id), {
        'id': p.id, 'businessId': p.businessId, 'name': p.name, 'unit': p.unit,
        'purchasePrice': p.purchasePrice, 'salePrice': p.salePrice, 'currentStock': p.currentStock,
        'lowStockAlert': p.lowStockAlert, 'createdAt': p.createdAt.toIso8601String(), 'isDeleted': p.isDeleted,
      });
    }

    // Stock Entry
    final stockBox = Hive.box<StockEntryModel>(AppConstants.stockEntryBox);
    for (var s in stockBox.values) {
      batch.set(userDoc.collection('stock_entries').doc(s.id), {
        'id': s.id, 'productId': s.productId, 'businessId': s.businessId, 'entryType': s.entryType,
        'quantity': s.quantity, 'rate': s.rate, 'totalAmount': s.totalAmount, 'note': s.note,
        'entryDate': s.entryDate.toIso8601String(), 'createdAt': s.createdAt.toIso8601String(), 'isDeleted': s.isDeleted,
      });
    }

    // Invoice
    final invoiceBox = Hive.box<InvoiceModel>(AppConstants.invoiceBox);
    for (var i in invoiceBox.values) {
      batch.set(userDoc.collection('invoices').doc(i.id), {
        'id': i.id, 'businessId': i.businessId, 'invoiceNumber': i.invoiceNumber,
        'customerName': i.customerName, 'customerPhone': i.customerPhone, 'partyId': i.partyId,
        'subtotal': i.subtotal, 'discount': i.discount, 'totalAmount': i.totalAmount, 'paidAmount': i.paidAmount,
        'status': i.status, 'invoiceDate': i.invoiceDate.toIso8601String(), 'createdAt': i.createdAt.toIso8601String(),
        'isDeleted': i.isDeleted, 'note': i.note, 'vehicleNumber': i.vehicleNumber,
      });
    }

    // Invoice Item
    final invoiceItemBox = Hive.box<InvoiceItemModel>(AppConstants.invoiceItemBox);
    for (var i in invoiceItemBox.values) {
      batch.set(userDoc.collection('invoice_items').doc(i.id), {
        'id': i.id, 'invoiceId': i.invoiceId, 'productName': i.productName, 'productId': i.productId,
        'quantity': i.quantity, 'rate': i.rate, 'amount': i.amount, 'unit': i.unit,
      });
    }

    // Khareed
    final khareedBox = Hive.box<KhareedModel>('khareed');
    for (var k in khareedBox.values) {
      batch.set(userDoc.collection('khareed').doc(k.id), {
        'id': k.id, 'businessId': k.businessId, 'itemName': k.itemName, 'vehicleNumber': k.vehicleNumber,
        'weight': k.weight, 'weightUnit': k.weightUnit, 'deduction': k.deduction, 'netWeight': k.netWeight,
        'ratePerUnit': k.ratePerUnit, 'totalAmount': k.totalAmount, 'jama': k.jama, 'baqaya': k.baqaya,
        'sabhaBaqaya': k.sabhaBaqaya, 'netBaqaya': k.netBaqaya, 'supplierName': k.supplierName, 'note': k.note,
        'purchaseDate': k.purchaseDate.toIso8601String(), 'createdAt': k.createdAt.toIso8601String(),
        'isDeleted': k.isDeleted, 'imagePath': k.imagePath,
      });
    }

    // Farokht
    final farokhtBox = Hive.box<FarokhtModel>('farokht');
    for (var f in farokhtBox.values) {
      batch.set(userDoc.collection('farokht').doc(f.id), {
        'id': f.id, 'businessId': f.businessId, 'itemName': f.itemName, 'buyerName': f.buyerName,
        'cardNumber': f.cardNumber, 'weight': f.weight, 'weightUnit': f.weightUnit, 'ratePerUnit': f.ratePerUnit,
        'totalAmount': f.totalAmount, 'creditAmount': f.creditAmount, 'debitAmount': f.debitAmount,
        'tafazul': f.tafazul, 'paymentStatus': f.paymentStatus, 'note': f.note, 'saleDate': f.saleDate.toIso8601String(),
        'createdAt': f.createdAt.toIso8601String(), 'isDeleted': f.isDeleted, 'customPaymentType': f.customPaymentType,
        'imagePath': f.imagePath,
      });
    }

    // Kharcha
    final kharchaBox = Hive.box<KharchaModel>('kharcha');
    for (var k in kharchaBox.values) {
      batch.set(userDoc.collection('kharcha').doc(k.id), {
        'id': k.id, 'businessId': k.businessId, 'category': k.category, 'customCategory': k.customCategory,
        'amount': k.amount, 'note': k.note, 'paidTo': k.paidTo, 'vehicleNumber': k.vehicleNumber,
        'driverName': k.driverName, 'expenseDate': k.expenseDate.toIso8601String(),
        'createdAt': k.createdAt.toIso8601String(), 'isDeleted': k.isDeleted, 'imagePath': k.imagePath,
      });
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Backup error: $e');
      rethrow;
    }
  }

  Future<void> restoreAllData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isRestoring = true;
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

    // Business
    final bSnap = await userDoc.collection('businesses').get();
    final businessBox = Hive.box<BusinessModel>(AppConstants.businessBox);
    await businessBox.clear();
    for (var doc in bSnap.docs) {
      final d = doc.data();
      businessBox.put(d['id'], BusinessModel(
        id: d['id'], name: d['name'], type: d['type'], ownerName: d['ownerName'] ?? '', phone: d['phone'] ?? '',
        address: d['address'] ?? '', currency: d['currency'] ?? 'PKR', createdAt: DateTime.parse(d['createdAt']),
        updatedAt: DateTime.parse(d['updatedAt']), isDeleted: d['isDeleted'] ?? false,
      ));
    }

    // Party
    final pSnap = await userDoc.collection('parties').get();
    final partyBox = Hive.box<PartyModel>(AppConstants.partyBox);
    await partyBox.clear();
    for (var doc in pSnap.docs) {
      final d = doc.data();
      partyBox.put(d['id'], PartyModel(
        id: d['id'], businessId: d['businessId'], name: d['name'], phone: d['phone'] ?? '',
        openingBalance: (d['openingBalance'] ?? 0).toDouble(), isOpeningCredit: d['isOpeningCredit'] ?? true,
        partyType: d['partyType'] ?? 0, isDeleted: d['isDeleted'] ?? false,
        createdAt: DateTime.parse(d['createdAt']),
      ));
    }

    // Transactions
    final tSnap = await userDoc.collection('transactions').get();
    final txnBox = Hive.box<TransactionModel>(AppConstants.transactionBox);
    await txnBox.clear();
    for (var doc in tSnap.docs) {
      final d = doc.data();
      txnBox.put(d['id'], TransactionModel(
        id: d['id'], partyId: d['partyId'], businessId: d['businessId'], txnType: d['txnType'],
        amount: (d['amount'] ?? 0).toDouble(), note: d['note'] ?? '', txnDate: DateTime.parse(d['txnDate']),
        createdAt: DateTime.parse(d['createdAt']), isDeleted: d['isDeleted'] ?? false, paymentMethod: d['paymentMethod'] ?? '',
        attachmentPath: d['attachmentPath'], attachmentType: d['attachmentType'],
      ));
    }

    // Cash Entry
    final cSnap = await userDoc.collection('cash_entries').get();
    final cashBox = Hive.box<CashEntryModel>(AppConstants.cashEntryBox);
    await cashBox.clear();
    for (var doc in cSnap.docs) {
      final d = doc.data();
      cashBox.put(d['id'], CashEntryModel(
        id: d['id'], businessId: d['businessId'], cashType: d['cashType'], amount: (d['amount'] ?? 0).toDouble(),
        note: d['note'] ?? '', entryDate: DateTime.parse(d['entryDate']), createdAt: DateTime.parse(d['createdAt']),
        isDeleted: d['isDeleted'] ?? false, paymentMethod: d['paymentMethod'] ?? 'نقد', personName: d['personName'],
        accountTitle: d['accountTitle'], attachmentPath: d['attachmentPath'], attachmentType: d['attachmentType'],
      ));
    }

    // Product
    final prSnap = await userDoc.collection('products').get();
    final productBox = Hive.box<ProductModel>(AppConstants.productBox);
    await productBox.clear();
    for (var doc in prSnap.docs) {
      final d = doc.data();
      productBox.put(d['id'], ProductModel(
        id: d['id'], businessId: d['businessId'], name: d['name'], unit: d['unit'] ?? 'O1O_O_',
        purchasePrice: (d['purchasePrice'] ?? 0).toDouble(), salePrice: (d['salePrice'] ?? 0).toDouble(),
        currentStock: (d['currentStock'] ?? 0).toDouble(), lowStockAlert: (d['lowStockAlert'] ?? 5).toDouble(),
        createdAt: DateTime.parse(d['createdAt']), isDeleted: d['isDeleted'] ?? false,
      ));
    }

    // Stock Entry
    final seSnap = await userDoc.collection('stock_entries').get();
    final stockBox = Hive.box<StockEntryModel>(AppConstants.stockEntryBox);
    await stockBox.clear();
    for (var doc in seSnap.docs) {
      final d = doc.data();
      stockBox.put(d['id'], StockEntryModel(
        id: d['id'], productId: d['productId'], businessId: d['businessId'], entryType: d['entryType'],
        quantity: (d['quantity'] ?? 0).toDouble(), rate: (d['rate'] ?? 0).toDouble(),
        totalAmount: (d['totalAmount'] ?? 0).toDouble(), note: d['note'] ?? '',
        entryDate: DateTime.parse(d['entryDate']), createdAt: DateTime.parse(d['createdAt']), isDeleted: d['isDeleted'] ?? false,
      ));
    }

    // Invoice
    final iSnap = await userDoc.collection('invoices').get();
    final invoiceBox = Hive.box<InvoiceModel>(AppConstants.invoiceBox);
    await invoiceBox.clear();
    for (var doc in iSnap.docs) {
      final d = doc.data();
      invoiceBox.put(d['id'], InvoiceModel(
        id: d['id'], businessId: d['businessId'], invoiceNumber: d['invoiceNumber'], customerName: d['customerName'] ?? '',
        customerPhone: d['customerPhone'] ?? '', partyId: d['partyId'], subtotal: (d['subtotal'] ?? 0).toDouble(),
        discount: (d['discount'] ?? 0).toDouble(), totalAmount: (d['totalAmount'] ?? 0).toDouble(),
        paidAmount: (d['paidAmount'] ?? 0).toDouble(), status: d['status'] ?? 0,
        invoiceDate: DateTime.parse(d['invoiceDate']), createdAt: DateTime.parse(d['createdAt']),
        isDeleted: d['isDeleted'] ?? false, note: d['note'] ?? '', vehicleNumber: d['vehicleNumber'] ?? '',
      ));
    }

    // Invoice Item
    final iiSnap = await userDoc.collection('invoice_items').get();
    final invoiceItemBox = Hive.box<InvoiceItemModel>(AppConstants.invoiceItemBox);
    await invoiceItemBox.clear();
    for (var doc in iiSnap.docs) {
      final d = doc.data();
      invoiceItemBox.put(d['id'], InvoiceItemModel(
        id: d['id'], invoiceId: d['invoiceId'], productName: d['productName'], productId: d['productId'],
        quantity: (d['quantity'] ?? 0).toDouble(), rate: (d['rate'] ?? 0).toDouble(),
        amount: (d['amount'] ?? 0).toDouble(), unit: d['unit'] ?? 'O1O_O_',
      ));
    }

    // Khareed
    final kSnap = await userDoc.collection('khareed').get();
    final khareedBox = Hive.box<KhareedModel>('khareed');
    await khareedBox.clear();
    for (var doc in kSnap.docs) {
      final d = doc.data();
      khareedBox.put(d['id'], KhareedModel()
        ..id = d['id']
        ..businessId = d['businessId']
        ..itemName = d['itemName']
        ..vehicleNumber = d['vehicleNumber'] ?? ''
        ..weight = (d['weight'] ?? 0).toDouble()
        ..weightUnit = d['weightUnit'] ?? ''
        ..deduction = (d['deduction'] ?? 0).toDouble()
        ..netWeight = (d['netWeight'] ?? 0).toDouble()
        ..ratePerUnit = (d['ratePerUnit'] ?? 0).toDouble()
        ..totalAmount = (d['totalAmount'] ?? 0).toDouble()
        ..jama = (d['jama'] ?? 0).toDouble()
        ..baqaya = (d['baqaya'] ?? 0).toDouble()
        ..sabhaBaqaya = (d['sabhaBaqaya'] ?? 0).toDouble()
        ..netBaqaya = (d['netBaqaya'] ?? 0).toDouble()
        ..supplierName = d['supplierName'] ?? ''
        ..note = d['note'] ?? ''
        ..purchaseDate = DateTime.parse(d['purchaseDate'])
        ..createdAt = DateTime.parse(d['createdAt'])
        ..isDeleted = d['isDeleted'] ?? false
        ..imagePath = d['imagePath'] ?? '');
    }

    // Farokht
    final fSnap = await userDoc.collection('farokht').get();
    final farokhtBox = Hive.box<FarokhtModel>('farokht');
    await farokhtBox.clear();
    for (var doc in fSnap.docs) {
      final d = doc.data();
      farokhtBox.put(d['id'], FarokhtModel(
        id: d['id'], businessId: d['businessId'], itemName: d['itemName'], buyerName: d['buyerName'],
        cardNumber: d['cardNumber'] ?? '', weight: (d['weight'] ?? 0).toDouble(), weightUnit: d['weightUnit'] ?? '',
        ratePerUnit: (d['ratePerUnit'] ?? 0).toDouble(), totalAmount: (d['totalAmount'] ?? 0).toDouble(),
        creditAmount: (d['creditAmount'] ?? 0).toDouble(), debitAmount: (d['debitAmount'] ?? 0).toDouble(),
        tafazul: (d['tafazul'] ?? 0).toDouble(), paymentStatus: d['paymentStatus'] ?? 0, customPaymentType: d['customPaymentType'] ?? '',
        note: d['note'] ?? '', saleDate: DateTime.parse(d['saleDate']), createdAt: DateTime.parse(d['createdAt']),
        isDeleted: d['isDeleted'] ?? false, imagePath: d['imagePath'] ?? '',
      ));
    }

    // Kharcha
    final khSnap = await userDoc.collection('kharcha').get();
    final kharchaBox = Hive.box<KharchaModel>('kharcha');
    await kharchaBox.clear();
    for (var doc in khSnap.docs) {
      final d = doc.data();
      kharchaBox.put(d['id'], KharchaModel()
        ..id = d['id']
        ..businessId = d['businessId']
        ..category = d['category']
        ..customCategory = d['customCategory'] ?? ''
        ..amount = (d['amount'] ?? 0).toDouble()
        ..note = d['note'] ?? ''
        ..paidTo = d['paidTo'] ?? ''
        ..vehicleNumber = d['vehicleNumber'] ?? ''
        ..driverName = d['driverName'] ?? ''
        ..expenseDate = DateTime.parse(d['expenseDate'])
        ..createdAt = DateTime.parse(d['createdAt'])
        ..isDeleted = d['isDeleted'] ?? false
        ..imagePath = d['imagePath'] ?? '');
    }
    } catch (e) {
      debugPrint('Restore error: $e');
    } finally {
      isRestoring = false;
    }
  }

  void enableAutoSync() {
    Hive.box<BusinessModel>(AppConstants.businessBox).watch().listen((event) => _syncSingleRecord(AppConstants.businessBox, event));
    Hive.box<PartyModel>(AppConstants.partyBox).watch().listen((event) => _syncSingleRecord(AppConstants.partyBox, event));
    Hive.box<TransactionModel>(AppConstants.transactionBox).watch().listen((event) => _syncSingleRecord(AppConstants.transactionBox, event));
    Hive.box<CashEntryModel>(AppConstants.cashEntryBox).watch().listen((event) => _syncSingleRecord(AppConstants.cashEntryBox, event));
    Hive.box<ProductModel>(AppConstants.productBox).watch().listen((event) => _syncSingleRecord(AppConstants.productBox, event));
    Hive.box<StockEntryModel>(AppConstants.stockEntryBox).watch().listen((event) => _syncSingleRecord(AppConstants.stockEntryBox, event));
    Hive.box<InvoiceModel>(AppConstants.invoiceBox).watch().listen((event) => _syncSingleRecord(AppConstants.invoiceBox, event));
    Hive.box<InvoiceItemModel>(AppConstants.invoiceItemBox).watch().listen((event) => _syncSingleRecord(AppConstants.invoiceItemBox, event));
    Hive.box<KhareedModel>('khareed').watch().listen((event) => _syncSingleRecord('khareed', event));
    Hive.box<FarokhtModel>('farokht').watch().listen((event) => _syncSingleRecord('farokht', event));
    Hive.box<KharchaModel>('kharcha').watch().listen((event) => _syncSingleRecord('kharcha', event));
  }

  Future<void> _syncSingleRecord(String boxName, BoxEvent event) async {
    if (isRestoring) return;
    
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid).collection(boxName).doc(event.key.toString());

    if (event.deleted) {
      try { await docRef.delete(); } catch (_) {}
      return;
    }

    final value = event.value;
    Map<String, dynamic> data = {};

    if (value is BusinessModel) {
      data = {
        'id': value.id, 'name': value.name, 'type': value.type, 'createdAt': value.createdAt.toIso8601String(),
        'updatedAt': value.updatedAt.toIso8601String(), 'isDeleted': value.isDeleted, 'ownerName': value.ownerName,
        'phone': value.phone, 'address': value.address, 'currency': value.currency,
      };
    } else if (value is PartyModel) {
      data = {
        'id': value.id, 'businessId': value.businessId, 'name': value.name, 'phone': value.phone,
        'openingBalance': value.openingBalance, 'isOpeningCredit': value.isOpeningCredit,
        'partyType': value.partyType, 'isDeleted': value.isDeleted, 'createdAt': value.createdAt.toIso8601String(),
      };
    } else if (value is TransactionModel) {
      data = {
        'id': value.id, 'partyId': value.partyId, 'businessId': value.businessId, 'txnType': value.txnType,
        'amount': value.amount, 'note': value.note, 'txnDate': value.txnDate.toIso8601String(),
        'createdAt': value.createdAt.toIso8601String(), 'isDeleted': value.isDeleted,
        'paymentMethod': value.paymentMethod, 'attachmentPath': value.attachmentPath, 'attachmentType': value.attachmentType,
      };
    } else if (value is CashEntryModel) {
      data = {
        'id': value.id, 'businessId': value.businessId, 'cashType': value.cashType, 'amount': value.amount,
        'note': value.note, 'entryDate': value.entryDate.toIso8601String(), 'createdAt': value.createdAt.toIso8601String(),
        'isDeleted': value.isDeleted, 'paymentMethod': value.paymentMethod, 'personName': value.personName,
        'accountTitle': value.accountTitle, 'attachmentPath': value.attachmentPath, 'attachmentType': value.attachmentType,
      };
    } else if (value is ProductModel) {
      data = {
        'id': value.id, 'businessId': value.businessId, 'name': value.name, 'unit': value.unit,
        'purchasePrice': value.purchasePrice, 'salePrice': value.salePrice, 'currentStock': value.currentStock,
        'lowStockAlert': value.lowStockAlert, 'createdAt': value.createdAt.toIso8601String(), 'isDeleted': value.isDeleted,
      };
    } else if (value is StockEntryModel) {
      data = {
        'id': value.id, 'productId': value.productId, 'businessId': value.businessId, 'entryType': value.entryType,
        'quantity': value.quantity, 'rate': value.rate, 'totalAmount': value.totalAmount, 'note': value.note,
        'entryDate': value.entryDate.toIso8601String(), 'createdAt': value.createdAt.toIso8601String(), 'isDeleted': value.isDeleted,
      };
    } else if (value is InvoiceModel) {
      data = {
        'id': value.id, 'businessId': value.businessId, 'invoiceNumber': value.invoiceNumber,
        'customerName': value.customerName, 'customerPhone': value.customerPhone, 'partyId': value.partyId,
        'subtotal': value.subtotal, 'discount': value.discount, 'totalAmount': value.totalAmount, 'paidAmount': value.paidAmount,
        'status': value.status, 'invoiceDate': value.invoiceDate.toIso8601String(), 'createdAt': value.createdAt.toIso8601String(),
        'isDeleted': value.isDeleted, 'note': value.note, 'vehicleNumber': value.vehicleNumber,
      };
    } else if (value is InvoiceItemModel) {
      data = {
        'id': value.id, 'invoiceId': value.invoiceId, 'productName': value.productName, 'productId': value.productId,
        'quantity': value.quantity, 'rate': value.rate, 'amount': value.amount, 'unit': value.unit,
      };
    } else if (value is KhareedModel) {
      data = {
        'id': value.id, 'businessId': value.businessId, 'itemName': value.itemName, 'vehicleNumber': value.vehicleNumber,
        'weight': value.weight, 'weightUnit': value.weightUnit, 'deduction': value.deduction, 'netWeight': value.netWeight,
        'ratePerUnit': value.ratePerUnit, 'totalAmount': value.totalAmount, 'jama': value.jama, 'baqaya': value.baqaya,
        'sabhaBaqaya': value.sabhaBaqaya, 'netBaqaya': value.netBaqaya, 'supplierName': value.supplierName, 'note': value.note,
        'purchaseDate': value.purchaseDate.toIso8601String(), 'createdAt': value.createdAt.toIso8601String(),
        'isDeleted': value.isDeleted, 'imagePath': value.imagePath,
      };
    } else if (value is FarokhtModel) {
      data = {
        'id': value.id, 'businessId': value.businessId, 'itemName': value.itemName, 'buyerName': value.buyerName,
        'cardNumber': value.cardNumber, 'weight': value.weight, 'weightUnit': value.weightUnit, 'ratePerUnit': value.ratePerUnit,
        'totalAmount': value.totalAmount, 'creditAmount': value.creditAmount, 'debitAmount': value.debitAmount,
        'tafazul': value.tafazul, 'paymentStatus': value.paymentStatus, 'note': value.note, 'saleDate': value.saleDate.toIso8601String(),
        'createdAt': value.createdAt.toIso8601String(), 'isDeleted': value.isDeleted, 'customPaymentType': value.customPaymentType,
        'imagePath': value.imagePath,
      };
    } else if (value is KharchaModel) {
      data = {
        'id': value.id, 'businessId': value.businessId, 'category': value.category, 'customCategory': value.customCategory,
        'amount': value.amount, 'note': value.note, 'paidTo': value.paidTo, 'vehicleNumber': value.vehicleNumber,
        'driverName': value.driverName, 'expenseDate': value.expenseDate.toIso8601String(),
        'createdAt': value.createdAt.toIso8601String(), 'isDeleted': value.isDeleted, 'imagePath': value.imagePath,
      };
    }

    if (data.isNotEmpty) {
      try {
        await docRef.set(data, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Auto-sync error for $boxName: $e');
      }
    }
  }

  Future<void> deleteAllDataFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final collections = [
      AppConstants.businessBox, AppConstants.partyBox, AppConstants.transactionBox,
      AppConstants.cashEntryBox, AppConstants.productBox, AppConstants.stockEntryBox,
      AppConstants.invoiceBox, AppConstants.invoiceItemBox, 'khareed', 'farokht', 'kharcha'
    ];
    
    try {
      for (var col in collections) {
        final snap = await _firestore.collection('users').doc(user.uid).collection(col).get();
        final batch = _firestore.batch();
        for (var doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Delete all from Firestore error: $e');
    }
  }
}
