// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farokht_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FarokhtModelAdapter extends TypeAdapter<FarokhtModel> {
  @override
  final int typeId = 11;

  @override
  FarokhtModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FarokhtModel(
      id: fields[0] as String,
      businessId: fields[1] as String,
      itemName: fields[2] as String,
      buyerName: fields[3] as String,
      cardNumber: fields[4] as String,
      weight: fields[5] as double,
      weightUnit: fields[6] as String,
      ratePerUnit: fields[7] as double,
      totalAmount: fields[8] as double,
      creditAmount: fields[9] as double,
      debitAmount: fields[10] as double,
      tafazul: fields[11] as double,
      paymentStatus: fields[12] as int,
      customPaymentType: fields[17] == null ? '' : fields[17] as String,
      note: fields[13] as String,
      saleDate: fields[14] as DateTime,
      createdAt: fields[15] as DateTime,
      isDeleted: fields[16] as bool,
      imagePath: fields[18] == null ? '' : fields[18] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FarokhtModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.businessId)
      ..writeByte(2)
      ..write(obj.itemName)
      ..writeByte(3)
      ..write(obj.buyerName)
      ..writeByte(4)
      ..write(obj.cardNumber)
      ..writeByte(5)
      ..write(obj.weight)
      ..writeByte(6)
      ..write(obj.weightUnit)
      ..writeByte(7)
      ..write(obj.ratePerUnit)
      ..writeByte(8)
      ..write(obj.totalAmount)
      ..writeByte(9)
      ..write(obj.creditAmount)
      ..writeByte(10)
      ..write(obj.debitAmount)
      ..writeByte(11)
      ..write(obj.tafazul)
      ..writeByte(12)
      ..write(obj.paymentStatus)
      ..writeByte(13)
      ..write(obj.note)
      ..writeByte(14)
      ..write(obj.saleDate)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.isDeleted)
      ..writeByte(17)
      ..write(obj.customPaymentType)
      ..writeByte(18)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarokhtModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
