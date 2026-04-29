import 'package:flutter/material.dart';

import '../model/classification_result.dart';
import '../model/meal.dart';
import '../service/classifier_service.dart';
import '../service/meal_api_service.dart';

class ResultController extends ChangeNotifier {
  List<ClassificationResult> results = [];
  List<Meal> meals = [];

  bool isLoadingML = false;
  bool isLoadingMeals = false;
  String? errorMessage;

  final _mealApi = MealApiService();

  Future<void> analyze(String imagePath) async {
    isLoadingML = true;
    errorMessage = null;
    results = [];
    meals = [];
    notifyListeners();

    try {
      results = await ClassifierService.classify(imagePath);
    } catch (e) {
      errorMessage = 'Gagal menjalankan analisis: $e';
      isLoadingML = false;
      notifyListeners();
      return;
    }

    isLoadingML = false;
    notifyListeners();

    if (results.isNotEmpty) {
      await _fetchMeals(results.first.label);
    }
  }

  Future<void> _fetchMeals(String foodName) async {
    isLoadingMeals = true;
    notifyListeners();

    try {
      meals = await _mealApi.searchByName(foodName);
    } catch (_) {
      meals = [];
    }

    isLoadingMeals = false;
    notifyListeners();
  }
}
