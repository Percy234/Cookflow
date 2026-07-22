// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipeAdapter extends TypeAdapter<Recipe> {
  @override
  final int typeId = 0;

  @override
  Recipe read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recipe(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      imagePath: fields[3] as String?,
      ingredients: (fields[4] as List?)?.cast<Ingredient>(),
      stepIds: (fields[5] as List?)?.cast<String>(),
      pages: (fields[8] as List?)?.cast<RecipePage>(),
      additionalInfo: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      difficulty: fields[9] == null ? 0 : fields[9] as int,
      estimatedTime: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Recipe obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.ingredients)
      ..writeByte(5)
      ..write(obj.stepIds)
      ..writeByte(8)
      ..write(obj.pages)
      ..writeByte(6)
      ..write(obj.additionalInfo)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.difficulty)
      ..writeByte(10)
      ..write(obj.estimatedTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
