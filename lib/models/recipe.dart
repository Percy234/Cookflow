import 'package:hive/hive.dart';
import 'ingredient.dart';
import 'recipe_page.dart';

part 'recipe.g.dart';

@HiveType(typeId: 0)
class Recipe extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  String? imagePath;

  @HiveField(4)
  List<Ingredient> ingredients;

  /// Danh sách ID của Steps theo thứ tự thực hiện (cũ, để tương thích)
  @HiveField(5)
  List<String> stepIds;

  @HiveField(8)
  List<RecipePage>? pages;

  @HiveField(6)
  String? additionalInfo;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(9, defaultValue: 0)
  int difficulty; // 0: Dễ, 1: Trung bình, 2: Khó

  Recipe({
    required this.id,
    required this.name,
    this.description = '',
    this.imagePath,
    List<Ingredient>? ingredients,
    List<String>? stepIds,
    this.pages,
    this.additionalInfo,
    DateTime? createdAt,
    this.difficulty = 0,
  })  : ingredients = ingredients ?? [],
        stepIds = stepIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    List<Ingredient>? ingredients,
    List<String>? stepIds,
    List<RecipePage>? pages,
    String? additionalInfo,
    bool clearImage = false,
    int? difficulty,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
      ingredients: ingredients ?? List.from(this.ingredients),
      stepIds: stepIds ?? List.from(this.stepIds),
      pages: pages ?? (this.pages != null ? List.from(this.pages!) : null),
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}
