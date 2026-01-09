import 'package:hive/hive.dart';

part 'avatar_hive_model.g.dart';

@HiveType(typeId: 2)
class AvatarHive extends HiveObject {
  @HiveField(0)
  double health;

  @HiveField(1)
  double energy;

  @HiveField(2)
  double stamina;

  AvatarHive({
    required this.health,
    required this.energy,
    required this.stamina,
  });
}