import '../models/recipe.dart';
import '../models/step_model.dart';
import 'hive_service.dart';

class RecipeService {
  // ─── Recipe CRUD ──────────────────────────────────────────────

  List<Recipe> getAllRecipes() {
    return HiveService.recipesBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addRecipe(Recipe recipe) async {
    await HiveService.recipesBox.put(recipe.id, recipe);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await HiveService.recipesBox.put(recipe.id, recipe);
  }

  Future<void> deleteRecipe(String recipeId) async {
    final recipe = HiveService.recipesBox.get(recipeId);
    if (recipe != null) {
      if (recipe.pages != null && recipe.pages!.isNotEmpty) {
        for (final page in recipe.pages!) {
          for (final stepId in page.stepIds) {
            await HiveService.stepsBox.delete(stepId);
          }
        }
      } else {
        for (final stepId in recipe.stepIds) {
          await HiveService.stepsBox.delete(stepId);
        }
      }
    }
    await HiveService.recipesBox.delete(recipeId);
  }

  Recipe? getRecipeById(String id) {
    return HiveService.recipesBox.get(id);
  }

  // ─── Step CRUD ─────────────────────────────────────────────────

  List<StepModel> getAllSteps() {
    return HiveService.stepsBox.values.toList();
  }

  Future<void> addStep(StepModel step) async {
    await HiveService.stepsBox.put(step.id, step);
  }

  Future<void> updateStep(StepModel step) async {
    await HiveService.stepsBox.put(step.id, step);
  }

  Future<void> deleteStep(String stepId) async {
    await HiveService.stepsBox.delete(stepId);
  }

  StepModel? getStepById(String id) {
    return HiveService.stepsBox.get(id);
  }

  List<StepModel> getStepsForRecipe(Recipe recipe) {
    final steps = <StepModel>[];
    if (recipe.pages != null && recipe.pages!.isNotEmpty) {
      for (final page in recipe.pages!) {
        for (final id in page.stepIds) {
          final step = HiveService.stepsBox.get(id);
          if (step != null) steps.add(step);
        }
      }
    } else {
      // Tương thích cũ
      for (final id in recipe.stepIds) {
        final step = HiveService.stepsBox.get(id);
        if (step != null) steps.add(step);
      }
    }
    return steps;
  }

  /// Trả về danh sách Step cho một trang cụ thể
  List<StepModel> getStepsForPage(List<String> stepIds) {
    final steps = <StepModel>[];
    for (final id in stepIds) {
      final step = HiveService.stepsBox.get(id);
      if (step != null) steps.add(step);
    }
    return steps;
  }
}
