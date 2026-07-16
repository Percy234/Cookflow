// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step_block.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StepBlockAdapter extends TypeAdapter<StepBlock> {
  @override
  final int typeId = 4;

  @override
  StepBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StepBlock(
      id: fields[0] as String,
      type: fields[1] as BlockType,
      content: fields[2] as String,
      color: fields[3] as String?,
      headingLevel: fields[4] as String?,
      fontSize: fields[5] as double?,
      textAlign: fields[6] as String?,
      isBold: fields[7] as bool?,
      isItalic: fields[8] as bool?,
      isUnderline: fields[9] as bool?,
      width: fields[10] as double?,
      height: fields[11] as double?,
      listStyle: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StepBlock obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.headingLevel)
      ..writeByte(5)
      ..write(obj.fontSize)
      ..writeByte(6)
      ..write(obj.textAlign)
      ..writeByte(7)
      ..write(obj.isBold)
      ..writeByte(8)
      ..write(obj.isItalic)
      ..writeByte(9)
      ..write(obj.isUnderline)
      ..writeByte(10)
      ..write(obj.width)
      ..writeByte(11)
      ..write(obj.height)
      ..writeByte(12)
      ..write(obj.listStyle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlockTypeAdapter extends TypeAdapter<BlockType> {
  @override
  final int typeId = 5;

  @override
  BlockType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BlockType.heading;
      case 1:
        return BlockType.text;
      case 2:
        return BlockType.image;
      case 3:
        return BlockType.images;
      case 4:
        return BlockType.checkbox;
      case 5:
        return BlockType.checklist;
      case 6:
        return BlockType.column;
      case 7:
        return BlockType.row;
      case 8:
        return BlockType.table;
      case 9:
        return BlockType.ordered;
      default:
        return BlockType.heading;
    }
  }

  @override
  void write(BinaryWriter writer, BlockType obj) {
    switch (obj) {
      case BlockType.heading:
        writer.writeByte(0);
        break;
      case BlockType.text:
        writer.writeByte(1);
        break;
      case BlockType.image:
        writer.writeByte(2);
        break;
      case BlockType.images:
        writer.writeByte(3);
        break;
      case BlockType.checkbox:
        writer.writeByte(4);
        break;
      case BlockType.checklist:
        writer.writeByte(5);
        break;
      case BlockType.column:
        writer.writeByte(6);
        break;
      case BlockType.row:
        writer.writeByte(7);
        break;
      case BlockType.table:
        writer.writeByte(8);
        break;
      case BlockType.ordered:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
