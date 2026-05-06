// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceModelAdapter extends TypeAdapter<InvoiceModel> {
  @override
  final int typeId = 6;

  @override
  InvoiceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceModel(
      id: fields[0] as String,
      businessId: fields[1] as String,
      invoiceNumber: fields[2] as String,
      customerName: fields[3] as String,
      customerPhone: fields[4] as String,
      partyId: fields[5] as String?,
      subtotal: fields[6] as double,
      discount: fields[7] as double,
      totalAmount: fields[8] as double,
      paidAmount: fields[9] as double,
      status: fields[10] as int,
      invoiceDate: fields[11] as DateTime,
      createdAt: fields[12] as DateTime,
      isDeleted: fields[13] as bool,
      note: fields[14] as String,
      vehicleNumber: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.businessId)
      ..writeByte(2)
      ..write(obj.invoiceNumber)
      ..writeByte(3)
      ..write(obj.customerName)
      ..writeByte(4)
      ..write(obj.customerPhone)
      ..writeByte(5)
      ..write(obj.partyId)
      ..writeByte(6)
      ..write(obj.subtotal)
      ..writeByte(7)
      ..write(obj.discount)
      ..writeByte(8)
      ..write(obj.totalAmount)
      ..writeByte(9)
      ..write(obj.paidAmount)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.invoiceDate)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.isDeleted)
      ..writeByte(14)
      ..write(obj.note)
      ..writeByte(15)
      ..write(obj.vehicleNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
