// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AddressAdapter extends TypeAdapter<Address> {
  @override
  final int typeId = 2;

  @override
  Address read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Address(
      id: fields[0] as String?,
      userId: fields[1] as String?,
      title: fields[2] as String,
      fullAddress: fields[3] as String,
      city: fields[4] as String,
      district: fields[5] as String,
      street: fields[6] as String,
      building: fields[7] as String?,
      floor: fields[8] as String?,
      door: fields[9] as String?,
      latitude: fields[10] as double?,
      longitude: fields[11] as double?,
      deliveryNote: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Address obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.fullAddress)
      ..writeByte(4)
      ..write(obj.city)
      ..writeByte(5)
      ..write(obj.district)
      ..writeByte(6)
      ..write(obj.street)
      ..writeByte(7)
      ..write(obj.building)
      ..writeByte(8)
      ..write(obj.floor)
      ..writeByte(9)
      ..write(obj.door)
      ..writeByte(10)
      ..write(obj.latitude)
      ..writeByte(11)
      ..write(obj.longitude)
      ..writeByte(12)
      ..write(obj.deliveryNote);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
