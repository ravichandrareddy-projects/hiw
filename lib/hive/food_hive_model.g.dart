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
      name: fields[0] as String,
      mealTypeIndex: fields[1] as int,
      calories: fields[2] as int,
      protein: fields[3] as double,
      carbs: fields[4] as double,
      fats: fields[5] as double,
      time: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FoodHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.mealTypeIndex)
      ..writeByte(2)
      ..write(obj.calories)
      ..writeByte(3)
      ..write(obj.protein)
      ..writeByte(4)
      ..write(obj.carbs)
      ..writeByte(5)
      ..write(obj.fats)
      ..writeByte(6)
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
