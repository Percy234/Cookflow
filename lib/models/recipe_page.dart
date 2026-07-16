import 'package:hive/hive.dart';

part 'recipe_page.g.dart';

@HiveType(typeId: 6)
class RecipePage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> stepIds;

  @HiveField(3, defaultValue: 'static')
  String type;

  @HiveField(4)
  int? duration;

  @HiveField(5)
  double? uiX;

  @HiveField(6)
  double? uiY;

  @HiveField(7)
  String? nextId;

  RecipePage({
    required this.id,
    required this.name,
    List<String>? stepIds,
    this.type = 'static',
    this.duration,
    this.uiX,
    this.uiY,
    this.nextId,
  }) : stepIds = stepIds ?? [];

  RecipePage copyWith({
    String? id,
    String? name,
    List<String>? stepIds,
    String? type,
    int? duration,
    double? uiX,
    double? uiY,
    String? nextId,
  }) {
    return RecipePage(
      id: id ?? this.id,
      name: name ?? this.name,
      stepIds: stepIds ?? List.from(this.stepIds),
      type: type ?? this.type,
      duration: duration ?? this.duration,
      uiX: uiX ?? this.uiX,
      uiY: uiY ?? this.uiY,
      nextId: nextId ?? this.nextId,
    );
  }
}
