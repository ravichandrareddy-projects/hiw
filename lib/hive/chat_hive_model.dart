import 'package:hive/hive.dart';

part 'chat_hive_model.g.dart';

@HiveType(typeId: 6)
class ChatHive extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final bool isUser;

  @HiveField(2)
  final DateTime time;

  ChatHive({
    required this.text,
    required this.isUser,
    required this.time,
  });
}
