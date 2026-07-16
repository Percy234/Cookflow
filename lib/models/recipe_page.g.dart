// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_page.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipePageAdapter extends TypeAdapter<RecipePage> {
  @override
  final int typeId = 6;

  @override
  RecipePage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipePage(
      id: fields[0] as String,
      name: fields[1] as String,
      stepIds: (fields[2] as List?)?.cast<String>(),
      type: fields[3] == null ? 'static' : fields[3] as String,
      duration: fields[4] as int?,
      uiX: fields[5] as double?,
      uiY: fields[6] as double?,
      nextId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecipePage obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.stepIds)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.uiX)
      ..writeByte(6)
      ..write(obj.uiY)
      ..writeByte(7)
      ..write(obj.nextId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipePageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
