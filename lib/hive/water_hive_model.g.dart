// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterHiveAdapter extends TypeAdapter<WaterHive> {
  @override
  final int typeId = 7;

  @override
  WaterHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterHive(
      drankWater: fields[0] as bool,
      date: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WaterHive obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.drankWater)
      ..writeByte(1)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
