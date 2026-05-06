// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 2;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      partyId: fields[1] as String,
      businessId: fields[2] as String,
      txnType: fields[3] as int,
      amount: fields[4] as double,
      note: fields[5] as String,
      txnDate: fields[6] as DateTime,
      createdAt: fields[7] as DateTime,
      isDeleted: fields[8] as bool,
      paymentMethod: fields[9] as String,
      attachmentPath: fields[10] as String?,
      attachmentType: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.partyId)
      ..writeByte(2)
      ..write(obj.businessId)
      ..writeByte(3)
      ..write(obj.txnType)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.txnDate)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.isDeleted)
      ..writeByte(9)
      ..write(obj.paymentMethod)
      ..writeByte(10)
      ..write(obj.attachmentPath)
      ..writeByte(11)
      ..write(obj.attachmentType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
