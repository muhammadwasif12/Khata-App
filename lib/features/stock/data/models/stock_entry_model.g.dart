// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockEntryModelAdapter extends TypeAdapter<StockEntryModel> {
  @override
  final int typeId = 5;

  @override
  StockEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockEntryModel(
      id: fields[0] as String,
      productId: fields[1] as String,
      businessId: fields[2] as String,
      entryType: fields[3] as int,
      quantity: fields[4] as double,
      rate: fields[5] as double,
      totalAmount: fields[6] as double,
      note: fields[7] as String,
      entryDate: fields[8] as DateTime,
      createdAt: fields[9] as DateTime,
      isDeleted: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StockEntryModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.businessId)
      ..writeByte(3)
      ..write(obj.entryType)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.rate)
      ..writeByte(6)
      ..write(obj.totalAmount)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.entryDate)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
