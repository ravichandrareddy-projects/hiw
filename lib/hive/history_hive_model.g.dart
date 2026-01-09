// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryHiveAdapter extends TypeAdapter<HistoryHive> {
  @override
  final int typeId = 1;

  @override
  HistoryHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryHive(
      foodName: fields[0] as String,
      mealTypeIndex: fields[1] as int,
      calories: fields[2] as int,
      time: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.foodName)
      ..writeByte(1)
      ..write(obj.mealTypeIndex)
      ..writeByte(2)
      ..write(obj.calories)
      ..writeByte(3)
      ..write(obj.time);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
