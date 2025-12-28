// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodHiveAdapter extends TypeAdapter<FoodHive> {
  @override
  final int typeId = 0;

  @override
  FoodHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodHive(
      meal: fields[0] as String,
      calories: fields[1] as int,
      protein: fields[2] as double,
      carbs: fields[3] as double,
      fats: fields[4] as double,
      time: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FoodHive obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.meal)
      ..writeByte(1)
      ..write(obj.calories)
      ..writeByte(2)
      ..write(obj.protein)
      ..writeByte(3)
      ..write(obj.carbs)
      ..writeByte(4)
      ..write(obj.fats)
      ..writeByte(5)
      ..write(obj.time);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
