// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bread.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BreadAdapter extends TypeAdapter<Bread> {
  @override
  final int typeId = 0;

  @override
  Bread read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bread(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      name: fields[2] as String,
      description: fields[3] as String,
      price: fields[4] as double,
      imageUrl: fields[5] as String,
      available: fields[6] as bool,
      tag: fields[7] as String?,
      prepTime: fields[8] as int,
      calories: fields[9] as int,
      isOrganic: fields[10] as bool,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
      rating: fields[13] as double,
      reviews: fields[14] as int,
      translations: (fields[15] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Bread obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.available)
      ..writeByte(7)
      ..write(obj.tag)
      ..writeByte(8)
      ..write(obj.prepTime)
      ..writeByte(9)
      ..write(obj.calories)
      ..writeByte(10)
      ..write(obj.isOrganic)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.rating)
      ..writeByte(14)
      ..write(obj.reviews)
      ..writeByte(15)
      ..write(obj.translations);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
