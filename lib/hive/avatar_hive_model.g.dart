// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AvatarHiveAdapter extends TypeAdapter<AvatarHive> {
  @override
  final int typeId = 2;

  @override
  AvatarHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AvatarHive(
      health: fields[0] as double,
      energy: fields[1] as double,
      stamina: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AvatarHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.health)
      ..writeByte(1)
      ..write(obj.energy)
      ..writeByte(2)
      ..write(obj.stamina);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
