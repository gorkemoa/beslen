class FoodItem {
  final String id;
  final String name;
  final String description;
  final double calories; // per 100g
  final double protein; // per 100g
  final double carbohydrates; // per 100g
  final double fat; // per 100g
  final double fiber; // per 100g
  final String? imageUrl;
  final String userId;
  final DateTime scannedAt;
  final double portion; // gram cinsinden porsiyon miktarı

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    this.imageUrl,
    required this.userId,
    required this.scannedAt,
    this.portion = 100.0,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      userId: json['userId'] ?? '',
      scannedAt: DateTime.parse(json['scannedAt'] ?? DateTime.now().toIso8601String()),
      portion: (json['portion'] ?? 100.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'imageUrl': imageUrl,
      'userId': userId,
      'scannedAt': scannedAt.toIso8601String(),
      'portion': portion,
    };
  }

  // Porsiyon miktarına göre hesaplanmış değerler
  double get totalCalories => (calories * portion) / 100;
  double get totalProtein => (protein * portion) / 100;
  double get totalCarbohydrates => (carbohydrates * portion) / 100;
  double get totalFat => (fat * portion) / 100;
  double get totalFiber => (fiber * portion) / 100;

  FoodItem copyWith({
    String? name,
    String? description,
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    double? fiber,
    String? imageUrl,
    double? portion,
  }) {
    return FoodItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId,
      scannedAt: scannedAt,
      portion: portion ?? this.portion,
    );
  }
} 