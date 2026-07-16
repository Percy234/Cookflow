// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StepModelAdapter extends TypeAdapter<StepModel> {
  @override
  final int typeId = 3;

  @override
  StepModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StepModel(
      id: fields[0] as String,
      name: fields[1] as String,
      instruction: fields[2] as String,
      type: fields[3] as StepType,
      imagePath: fields[4] as String?,
      durationSeconds: fields[5] as int?,
      blocks: (fields[6] as List?)?.cast<StepBlock>(),
    );
  }

  @override
  void write(BinaryWriter writer, StepModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.instruction)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.durationSeconds)
      ..writeByte(6)
      ..write(obj.blocks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StepTypeAdapter extends TypeAdapter<StepType> {
  @override
  final int typeId = 2;

  @override
  StepType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StepType.staticStep;
      case 1:
        return StepType.timerStep;
      default:
        return StepType.staticStep;
    }
  }

  @override
  void write(BinaryWriter writer, StepType obj) {
    switch (obj) {
      case StepType.staticStep:
        writer.writeByte(0);
        break;
      case StepType.timerStep:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
