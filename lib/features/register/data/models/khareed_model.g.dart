// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'khareed_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KhareedModelAdapter extends TypeAdapter<KhareedModel> {
  @override
  final int typeId = 10;

  @override
  KhareedModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KhareedModel()
      ..id = fields[0] as String
      ..businessId = fields[1] as String
      ..itemName = fields[2] as String
      ..vehicleNumber = fields[3] as String
      ..weight = fields[4] as double
      ..weightUnit = fields[5] as String
      ..deduction = fields[6] as double
      ..netWeight = fields[7] as double
      ..ratePerUnit = fields[8] as double
      ..totalAmount = fields[9] as double
      ..jama = fields[10] as double
      ..baqaya = fields[11] as double
      ..sabhaBaqaya = fields[12] as double
      ..netBaqaya = fields[13] as double
      ..supplierName = fields[14] as String
      ..note = fields[15] as String
      ..purchaseDate = fields[16] as DateTime
      ..createdAt = fields[17] as DateTime
      ..isDeleted = fields[18] as bool
      ..imagePath = fields[19] == null ? '' : fields[19] as String;
  }

  @override
  void write(BinaryWriter writer, KhareedModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.businessId)
      ..writeByte(2)
      ..write(obj.itemName)
      ..writeByte(3)
      ..write(obj.vehicleNumber)
      ..writeByte(4)
      ..write(obj.weight)
      ..writeByte(5)
      ..write(obj.weightUnit)
      ..writeByte(6)
      ..write(obj.deduction)
      ..writeByte(7)
      ..write(obj.netWeight)
      ..writeByte(8)
      ..write(obj.ratePerUnit)
      ..writeByte(9)
      ..write(obj.totalAmount)
      ..writeByte(10)
      ..write(obj.jama)
      ..writeByte(11)
      ..write(obj.baqaya)
      ..writeByte(12)
      ..write(obj.sabhaBaqaya)
      ..writeByte(13)
      ..write(obj.netBaqaya)
      ..writeByte(14)
      ..write(obj.supplierName)
      ..writeByte(15)
      ..write(obj.note)
      ..writeByte(16)
      ..write(obj.purchaseDate)
      ..writeByte(17)
      ..write(obj.createdAt)
      ..writeByte(18)
      ..write(obj.isDeleted)
      ..writeByte(19)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhareedModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
