// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PartyModelAdapter extends TypeAdapter<PartyModel> {
  @override
  final int typeId = 1;

  @override
  PartyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PartyModel(
      id: fields[0] as String,
      businessId: fields[1] as String,
      name: fields[2] as String,
      phone: fields[3] as String,
      openingBalance: fields[4] as double,
      isOpeningCredit: fields[5] as bool,
      partyType: fields[6] as int,
      createdAt: fields[7] as DateTime,
      isDeleted: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PartyModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.businessId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.openingBalance)
      ..writeByte(5)
      ..write(obj.isOpeningCredit)
      ..writeByte(6)
      ..write(obj.partyType)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartyModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
