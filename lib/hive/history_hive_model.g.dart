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
      date: fields[0] as String,
      calories: fields[1] as int,
      protein: fields[2] as double,
      carbs: fields[3] as double,
      fats: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryHive obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.calories)
      ..writeByte(2)
      ..write(obj.protein)
      ..writeByte(3)
      ..write(obj.carbs)
      ..writeByte(4)
      ..write(obj.fats);
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
