import 'food_item.dart';

class DailySummary {
  final String id;
  final String userId;
  final DateTime date;
  final List<FoodItem> consumedFoods;
  final NutritionInfo totalNutrition;
  final double calorieGoal;
  final int waterIntake; // ml
  final int waterGoal; // ml

  DailySummary({
    required this.id,
    required this.userId,
    required this.date,
    required this.consumedFoods,
    required this.totalNutrition,
    required this.calorieGoal,
    this.waterIntake = 0,
    this.waterGoal = 2000,
  });

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      consumedFoods: (map['consumedFoods'] as List<dynamic>? ?? [])
          .map((food) => FoodItem.fromMap(food as Map<String, dynamic>))
          .toList(),
      totalNutrition: NutritionInfo.fromMap(map['totalNutrition'] ?? {}),
      calorieGoal: (map['calorieGoal'] ?? 0.0).toDouble(),
      waterIntake: map['waterIntake'] ?? 0,
      waterGoal: map['waterGoal'] ?? 2000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String().split('T')[0], // Only date part
      'consumedFoods': consumedFoods.map((food) => food.toMap()).toList(),
      'totalNutrition': totalNutrition.toMap(),
      'calorieGoal': calorieGoal,
      'waterIntake': waterIntake,
      'waterGoal': waterGoal,
    };
  }

  DailySummary copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<FoodItem>? consumedFoods,
    NutritionInfo? totalNutrition,
    double? calorieGoal,
    int? waterIntake,
    int? waterGoal,
  }) {
    return DailySummary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      consumedFoods: consumedFoods ?? this.consumedFoods,
      totalNutrition: totalNutrition ?? this.totalNutrition,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      waterIntake: waterIntake ?? this.waterIntake,
      waterGoal: waterGoal ?? this.waterGoal,
    );
  }

  // Kalan kalori hesapla
  double get remainingCalories => calorieGoal - totalNutrition.calories;

  // Kalori hedefine ulaşma yüzdesi
  double get calorieProgress => (totalNutrition.calories / calorieGoal).clamp(0.0, 1.0);

  // Su tüketim yüzdesi
  double get waterProgress => (waterIntake / waterGoal).clamp(0.0, 1.0);

  // Makronutrient yüzdeleri
  double get proteinPercentage {
    double totalCals = totalNutrition.calories;
    if (totalCals == 0) return 0.0;
    return (totalNutrition.protein * 4) / totalCals;
  }

  double get carbsPercentage {
    double totalCals = totalNutrition.calories;
    if (totalCals == 0) return 0.0;
    return (totalNutrition.carbohydrates * 4) / totalCals;
  }

  double get fatPercentage {
    double totalCals = totalNutrition.calories;
    if (totalCals == 0) return 0.0;
    return (totalNutrition.fat * 9) / totalCals;
  }

  // Günlük hedef protein (vücut ağırlığı * 1.6g)
  double getProteinGoal(double bodyWeight) => bodyWeight * 1.6;

  // Günlük hedef karbonhidrat (toplam kalorinin %45-65'i)
  double getCarbGoal() => (calorieGoal * 0.55) / 4;

  // Günlük hedef yağ (toplam kalorinin %20-35'i)
  double getFatGoal() => (calorieGoal * 0.25) / 9;
} 