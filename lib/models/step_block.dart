import 'package:hive/hive.dart';

part 'step_block.g.dart';

@HiveType(typeId: 5)
enum BlockType {
  @HiveField(0)
  heading,

  @HiveField(1)
  text,

  @HiveField(2)
  image,

  @HiveField(3)
  images,

  @HiveField(4)
  checkbox,

  @HiveField(5)
  checklist,

  @HiveField(6)
  column,

  @HiveField(7)
  row,

  @HiveField(8)
  table,

  @HiveField(9)
  ordered,

  @HiveField(10)
  spacer,
}

@HiveType(typeId: 4)
class StepBlock extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  BlockType type;

  @HiveField(2)
  String content;

  @HiveField(3)
  String? color;

  @HiveField(4)
  String? headingLevel;

  @HiveField(5)
  double? fontSize;

  @HiveField(6)
  String? textAlign;

  @HiveField(7)
  bool? isBold;

  @HiveField(8)
  bool? isItalic;

  @HiveField(9)
  bool? isUnderline;

  @HiveField(10)
  double? width;

  @HiveField(11)
  double? height;

  @HiveField(12)
  String? listStyle;

  StepBlock({
    required this.id,
    required this.type,
    this.content = '',
    this.color,
    this.headingLevel,
    this.fontSize,
    this.textAlign,
    this.isBold,
    this.isItalic,
    this.isUnderline,
    this.width,
    this.height,
    this.listStyle,
  });

  StepBlock copyWith({
    String? id,
    BlockType? type,
    String? content,
    String? color,
    String? headingLevel,
    double? fontSize,
    String? textAlign,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    double? width,
    double? height,
    String? listStyle,
    bool clearColor = false,
    bool clearHeadingLevel = false,
    bool clearFontSize = false,
    bool clearTextAlign = false,
    bool clearIsBold = false,
    bool clearIsItalic = false,
    bool clearIsUnderline = false,
    bool clearWidth = false,
    bool clearHeight = false,
    bool clearListStyle = false,
  }) {
    return StepBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      color: clearColor ? null : color ?? this.color,
      headingLevel: clearHeadingLevel ? null : headingLevel ?? this.headingLevel,
      fontSize: clearFontSize ? null : fontSize ?? this.fontSize,
      textAlign: clearTextAlign ? null : textAlign ?? this.textAlign,
      isBold: clearIsBold ? null : isBold ?? this.isBold,
      isItalic: clearIsItalic ? null : isItalic ?? this.isItalic,
      isUnderline: clearIsUnderline ? null : isUnderline ?? this.isUnderline,
      width: clearWidth ? null : width ?? this.width,
      height: clearHeight ? null : height ?? this.height,
      listStyle: clearListStyle ? null : listStyle ?? this.listStyle,
    );
  }
}
