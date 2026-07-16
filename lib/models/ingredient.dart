import 'package:hive/hive.dart';

part 'ingredient.g.dart';

@HiveType(typeId: 1)
class Ingredient extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String amount;

  @HiveField(2)
  String unit;

  Ingredient({
    required this.name,
    required this.amount,
    this.unit = '',
  });

  Ingredient copyWith({String? name, String? amount, String? unit}) {
    return Ingredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
    );
  }
}
