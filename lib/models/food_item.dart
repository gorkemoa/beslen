class FoodItem {
  final String id;
  final String name;
  final String imageUrl;
  final int calories;
  final double protein;
  final double carbs; 
  final double fat;
  final DateTime scannedAt;
  final String userId;

  FoodItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.scannedAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'scannedAt': scannedAt.millisecondsSinceEpoch,
      'userId': userId,
    };
  }

  static FoodItem fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      calories: map['calories']?.toInt() ?? 0,
      protein: map['protein']?.toDouble() ?? 0.0,
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fat: map['fat']?.toDouble() ?? 0.0,
      scannedAt: DateTime.fromMillisecondsSinceEpoch(map['scannedAt'] ?? 0),
      userId: map['userId'] ?? '',
    );
  }
} 