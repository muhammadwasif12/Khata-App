// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kharcha_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KharchaModelAdapter extends TypeAdapter<KharchaModel> {
  @override
  final int typeId = 12;

  @override
  KharchaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KharchaModel()
      ..id = fields[0] as String
      ..businessId = fields[1] as String
      ..category = fields[2] as String
      ..customCategory = fields[3] as String
      ..amount = fields[4] as double
      ..note = fields[5] as String
      ..paidTo = fields[6] as String
      ..vehicleNumber = fields[7] as String
      ..driverName = fields[8] as String
      ..expenseDate = fields[9] as DateTime
      ..createdAt = fields[10] as DateTime
      ..isDeleted = fields[11] as bool
      ..imagePath = fields[12] == null ? '' : fields[12] as String;
  }

  @override
  void write(BinaryWriter writer, KharchaModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.businessId)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.customCategory)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.paidTo)
      ..writeByte(7)
      ..write(obj.vehicleNumber)
      ..writeByte(8)
      ..write(obj.driverName)
      ..writeByte(9)
      ..write(obj.expenseDate)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.isDeleted)
      ..writeByte(12)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KharchaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
