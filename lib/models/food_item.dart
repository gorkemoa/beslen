class FoodItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final NutritionInfo nutritionInfo;
  final List<String> ingredients;
  final List<String> allergens;
  final DateTime consumedAt;
  final double portionSize;
  final String portionUnit;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.nutritionInfo,
    required this.ingredients,
    required this.allergens,
    required this.consumedAt,
    this.portionSize = 1.0,
    this.portionUnit = 'porsiyon',
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      nutritionInfo: NutritionInfo.fromMap(map['nutritionInfo'] ?? {}),
      ingredients: List<String>.from(map['ingredients'] ?? []),
      allergens: List<String>.from(map['allergens'] ?? []),
      consumedAt: DateTime.parse(map['consumedAt'] ?? DateTime.now().toIso8601String()),
      portionSize: (map['portionSize'] ?? 1.0).toDouble(),
      portionUnit: map['portionUnit'] ?? 'porsiyon',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'nutritionInfo': nutritionInfo.toMap(),
      'ingredients': ingredients,
      'allergens': allergens,
      'consumedAt': consumedAt.toIso8601String(),
      'portionSize': portionSize,
      'portionUnit': portionUnit,
    };
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    NutritionInfo? nutritionInfo,
    List<String>? ingredients,
    List<String>? allergens,
    DateTime? consumedAt,
    double? portionSize,
    String? portionUnit,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      consumedAt: consumedAt ?? this.consumedAt,
      portionSize: portionSize ?? this.portionSize,
      portionUnit: portionUnit ?? this.portionUnit,
    );
  }
}

class NutritionInfo {
  final double calories;
  final double protein; // gram
  final double carbohydrates; // gram
  final double fat; // gram
  final double fiber; // gram
  final double sugar; // gram
  final double sodium; // mg
  final double calcium; // mg
  final double iron; // mg
  final double vitaminC; // mg
  final double vitaminA; // IU

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    this.fiber = 0.0,
    this.sugar = 0.0,
    this.sodium = 0.0,
    this.calcium = 0.0,
    this.iron = 0.0,
    this.vitaminC = 0.0,
    this.vitaminA = 0.0,
  });

  factory NutritionInfo.fromMap(Map<String, dynamic> map) {
    return NutritionInfo(
      calories: (map['calories'] ?? 0.0).toDouble(),
      protein: (map['protein'] ?? 0.0).toDouble(),
      carbohydrates: (map['carbohydrates'] ?? 0.0).toDouble(),
      fat: (map['fat'] ?? 0.0).toDouble(),
      fiber: (map['fiber'] ?? 0.0).toDouble(),
      sugar: (map['sugar'] ?? 0.0).toDouble(),
      sodium: (map['sodium'] ?? 0.0).toDouble(),
      calcium: (map['calcium'] ?? 0.0).toDouble(),
      iron: (map['iron'] ?? 0.0).toDouble(),
      vitaminC: (map['vitaminC'] ?? 0.0).toDouble(),
      vitaminA: (map['vitaminA'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'calcium': calcium,
      'iron': iron,
      'vitaminC': vitaminC,
      'vitaminA': vitaminA,
    };
  }

  NutritionInfo operator *(double multiplier) {
    return NutritionInfo(
      calories: calories * multiplier,
      protein: protein * multiplier,
      carbohydrates: carbohydrates * multiplier,
      fat: fat * multiplier,
      fiber: fiber * multiplier,
      sugar: sugar * multiplier,
      sodium: sodium * multiplier,
      calcium: calcium * multiplier,
      iron: iron * multiplier,
      vitaminC: vitaminC * multiplier,
      vitaminA: vitaminA * multiplier,
    );
  }
} 