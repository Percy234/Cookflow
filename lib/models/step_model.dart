import 'package:hive/hive.dart';
import 'step_block.dart';

part 'step_model.g.dart';

@HiveType(typeId: 2)
enum StepType {
  @HiveField(0)
  staticStep,

  @HiveField(1)
  timerStep,
}

@HiveType(typeId: 3)
class StepModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String instruction;

  @HiveField(3)
  StepType type;

  @HiveField(4)
  String? imagePath;

  /// Chỉ dùng khi type == StepType.timerStep
  @HiveField(5)
  int? durationSeconds;

  @HiveField(6)
  List<StepBlock> blocks;

  StepModel({
    required this.id,
    required this.name,
    this.instruction = '',
    required this.type,
    this.imagePath,
    this.durationSeconds,
    List<StepBlock>? blocks,
  }) : blocks = blocks ?? [];

  bool get isTimerStep => type == StepType.timerStep;
  bool get isStaticStep => type == StepType.staticStep;

  StepModel copyWith({
    String? id,
    String? name,
    String? instruction,
    StepType? type,
    String? imagePath,
    int? durationSeconds,
    List<StepBlock>? blocks,
    bool clearImage = false,
  }) {
    return StepModel(
      id: id ?? this.id,
      name: name ?? this.name,
      instruction: instruction ?? this.instruction,
      type: type ?? this.type,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      blocks: blocks ?? List.from(this.blocks),
    );
  }
}
