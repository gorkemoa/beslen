import 'food_item.dart';

class DailySummary {
  final String id;
  final String userId;
  final DateTime date;
  final List<FoodItem> foods;
  final double? targetCalories;

  DailySummary({
    required this.id,
    required this.userId,
    required this.date,
    required this.foods,
    this.targetCalories,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      foods: (json['foods'] as List<dynamic>? ?? [])
          .map((food) => FoodItem.fromJson(food))
          .toList(),
      targetCalories: json['targetCalories']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'foods': foods.map((food) => food.toJson()).toList(),
      'targetCalories': targetCalories,
    };
  }

  // Toplam besin değerleri hesaplamaları
  double get totalCalories => foods.fold(0.0, (sum, food) => sum + food.totalCalories);
  double get totalProtein => foods.fold(0.0, (sum, food) => sum + food.totalProtein);
  double get totalCarbohydrates => foods.fold(0.0, (sum, food) => sum + food.totalCarbohydrates);
  double get totalFat => foods.fold(0.0, (sum, food) => sum + food.totalFat);
  double get totalFiber => foods.fold(0.0, (sum, food) => sum + food.totalFiber);

  // Yüzde hesaplamaları
  double get calorieProgress {
    if (targetCalories == null || targetCalories == 0) return 0.0;
    return (totalCalories / targetCalories!) * 100;
  }

  bool get isTargetMet => targetCalories != null && totalCalories >= targetCalories!;

  // Makro besin yüzdeleri
  double get proteinPercentage {
    if (totalCalories == 0) return 0.0;
    return (totalProtein * 4 / totalCalories) * 100; // 1g protein = 4 kalori
  }

  double get carbohydratePercentage {
    if (totalCalories == 0) return 0.0;
    return (totalCarbohydrates * 4 / totalCalories) * 100; // 1g carb = 4 kalori
  }

  double get fatPercentage {
    if (totalCalories == 0) return 0.0;
    return (totalFat * 9 / totalCalories) * 100; // 1g fat = 9 kalori
  }

  int get mealCount => foods.length;

  DailySummary copyWith({
    List<FoodItem>? foods,
    double? targetCalories,
  }) {
    return DailySummary(
      id: id,
      userId: userId,
      date: date,
      foods: foods ?? this.foods,
      targetCalories: targetCalories ?? this.targetCalories,
    );
  }
} 