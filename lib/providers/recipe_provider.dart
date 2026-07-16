import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/recipe_page.dart';
import '../models/step_model.dart';
import '../services/recipe_service.dart';

class RecipeProvider extends ChangeNotifier {
  final RecipeService _service = RecipeService();
  List<Recipe> _recipes = [];

  List<Recipe> get recipes => List.unmodifiable(_recipes);

  RecipeProvider() {
    _loadRecipes();
  }

  void _loadRecipes() {
    _recipes = _service.getAllRecipes();
    notifyListeners();
  }

  // ─── Recipe CRUD ──────────────────────────────────────────────

  Future<void> addRecipe(Recipe recipe) async {
    await _service.addRecipe(recipe);
    _loadRecipes();
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _service.updateRecipe(recipe);
    _loadRecipes();
  }

  Future<void> deleteRecipe(String recipeId) async {
    await _service.deleteRecipe(recipeId);
    _loadRecipes();
  }

  Recipe? getRecipeById(String id) {
    return _service.getRecipeById(id);
  }

  // ─── Step & Page CRUD ─────────────────────────────────────────

  Future<void> addPage({
    required Recipe recipe,
    required String pageName,
  }) async {
    final newPage = RecipePage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: pageName,
      stepIds: [],
    );
    final currentPages = recipe.pages ?? [];
    final updatedRecipe = recipe.copyWith(pages: [...currentPages, newPage]);
    await _service.updateRecipe(updatedRecipe);
    _loadRecipes();
  }

  Future<void> renamePage({
    required Recipe recipe,
    required String pageId,
    required String newName,
  }) async {
    final currentPages = recipe.pages ?? [];
    final updatedPages = currentPages.map((p) {
      if (p.id == pageId) {
        return p.copyWith(name: newName);
      }
      return p;
    }).toList();
    final updatedRecipe = recipe.copyWith(pages: updatedPages);
    await _service.updateRecipe(updatedRecipe);
    _loadRecipes();
  }

  Future<void> deletePage({
    required Recipe recipe,
    required String pageId,
  }) async {
    final currentPages = recipe.pages ?? [];
    final pageToDelete = currentPages.firstWhere((p) => p.id == pageId);
    // Delete all steps in this page
    for (final stepId in pageToDelete.stepIds) {
      await _service.deleteStep(stepId);
    }
    final updatedPages = currentPages.where((p) => p.id != pageId).toList();
    final updatedRecipe = recipe.copyWith(pages: updatedPages);
    await _service.updateRecipe(updatedRecipe);
    _loadRecipes();
  }

  Future<void> addStepToRecipe({
    required Recipe recipe,
    required StepModel step,
    String? pageId, // Thêm tuỳ chọn pageId
  }) async {
    await _service.addStep(step);
    
    if (recipe.pages != null && recipe.pages!.isNotEmpty && pageId != null) {
      final updatedPages = recipe.pages!.map((p) {
        if (p.id == pageId) {
          return p.copyWith(stepIds: [...p.stepIds, step.id]);
        }
        return p;
      }).toList();
      final updatedRecipe = recipe.copyWith(pages: updatedPages);
      await _service.updateRecipe(updatedRecipe);
    } else {
      final updatedIds = [...recipe.stepIds, step.id];
      final updatedRecipe = recipe.copyWith(stepIds: updatedIds);
      await _service.updateRecipe(updatedRecipe);
    }
    _loadRecipes();
  }

  Future<void> updateStep(StepModel step) async {
    await _service.updateStep(step);
    notifyListeners();
  }

  Future<void> deleteStepFromRecipe({
    required Recipe recipe,
    required String stepId,
    String? pageId,
  }) async {
    await _service.deleteStep(stepId);
    
    if (recipe.pages != null && recipe.pages!.isNotEmpty && pageId != null) {
      final updatedPages = recipe.pages!.map((p) {
        if (p.id == pageId) {
          return p.copyWith(stepIds: p.stepIds.where((id) => id != stepId).toList());
        }
        return p;
      }).toList();
      final updatedRecipe = recipe.copyWith(pages: updatedPages);
      await _service.updateRecipe(updatedRecipe);
    } else {
      final updatedIds = recipe.stepIds.where((id) => id != stepId).toList();
      final updatedRecipe = recipe.copyWith(stepIds: updatedIds);
      await _service.updateRecipe(updatedRecipe);
    }
    _loadRecipes();
  }

  Future<void> reorderSteps({
    required Recipe recipe,
    required List<String> newStepIds,
    String? pageId,
  }) async {
    if (recipe.pages != null && recipe.pages!.isNotEmpty && pageId != null) {
      final updatedPages = recipe.pages!.map((p) {
        if (p.id == pageId) {
          return p.copyWith(stepIds: newStepIds);
        }
        return p;
      }).toList();
      final updatedRecipe = recipe.copyWith(pages: updatedPages);
      await _service.updateRecipe(updatedRecipe);
    } else {
      final updatedRecipe = recipe.copyWith(stepIds: newStepIds);
      await _service.updateRecipe(updatedRecipe);
    }
    _loadRecipes();
  }

  List<StepModel> getStepsForRecipe(Recipe recipe) {
    return _service.getStepsForRecipe(recipe);
  }
  
  List<StepModel> getStepsForPage(RecipePage page) {
    return _service.getStepsForPage(page.stepIds);
  }

  StepModel? getStepById(String id) {
    return _service.getStepById(id);
  }
}
