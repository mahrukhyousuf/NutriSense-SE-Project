import 'food_item_model.dart';

enum MealType { breakfast, lunch, dinner, snack }

class Meal {
  final String id;
  final DateTime timestamp;
  final MealType type;
  final List<FoodItem> foodItems;
  final String? notes;
  final String? imageUrl;

  Meal({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.foodItems,
    this.notes,
    this.imageUrl,
  });

  // Calculate total calories for the meal
  double get totalCalories {
    return foodItems.fold(0, (sum, item) => sum + item.calories);
  }

  // Calculate total proteins for the meal
  double get totalProteins {
    return foodItems.fold(0, (sum, item) => sum + item.proteins);
  }

  // Calculate total carbs for the meal
  double get totalCarbs {
    return foodItems.fold(0, (sum, item) => sum + item.carbs);
  }

  // Calculate total fats for the meal
  double get totalFats {
    return foodItems.fold(0, (sum, item) => sum + item.fats);
  }
}
