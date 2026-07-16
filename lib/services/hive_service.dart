import 'package:hive_flutter/hive_flutter.dart';
import '../models/recipe.dart';
import '../models/recipe_page.dart';
import '../models/step_model.dart';
import '../models/step_block.dart';
import '../models/ingredient.dart';

class HiveService {
  static const String _recipesBoxName = 'recipes';
  static const String _stepsBoxName = 'steps';
  static const String _settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(RecipeAdapter());
    Hive.registerAdapter(RecipePageAdapter());
    Hive.registerAdapter(IngredientAdapter());
    Hive.registerAdapter(StepTypeAdapter());
    Hive.registerAdapter(BlockTypeAdapter());
    Hive.registerAdapter(StepBlockAdapter());
    Hive.registerAdapter(StepModelAdapter());

    // Open boxes
    await Hive.openBox<Recipe>(_recipesBoxName);
    await Hive.openBox<StepModel>(_stepsBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  static Box<Recipe> get recipesBox => Hive.box<Recipe>(_recipesBoxName);
  static Box<StepModel> get stepsBox => Hive.box<StepModel>(_stepsBoxName);
  static Box get settingsBox => Hive.box(_settingsBoxName);

  static Future<void> closeAll() async {
    await Hive.close();
  }
}
