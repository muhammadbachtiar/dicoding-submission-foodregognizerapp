import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/meal.dart';

class MealApiService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<Meal>> searchByName(String name) async {
    final uri = Uri.parse('$_baseUrl/search.php?s=${Uri.encodeComponent(name)}');
    final response = await http.get(uri);

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final meals = data['meals'];
    if (meals == null) return [];

    return (meals as List).map((e) => Meal.fromJson(e)).toList();
  }

  Future<Meal?> getMealById(String id) async {
    final uri = Uri.parse('$_baseUrl/lookup.php?i=$id');
    final response = await http.get(uri);

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final meals = data['meals'];
    if (meals == null || (meals as List).isEmpty) return null;

    return Meal.fromJson(meals.first);
  }
}
