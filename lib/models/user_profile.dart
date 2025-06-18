class UserProfile {
  final String id;
  final String name;
  final int age;
  final double weight;
  final double height;
  final String goal; // "weight_loss", "maintain", "weight_gain"
  final String activityLevel; // "sedentary", "light", "moderate", "active"
  final double dailyWaterTarget; // Günlük su hedefi (litre)
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
    required this.activityLevel,
    double? dailyWaterTarget,
    required this.createdAt,
  }) : dailyWaterTarget = dailyWaterTarget ?? _calculateRecommendedWaterIntake(weight, activityLevel);

  // Önerilen günlük su tüketimi hesaplama (litre)
  static double _calculateRecommendedWaterIntake(double weight, String activityLevel) {
    // Temel hesaplama: Kilo başına 35ml
    double baseWater = (weight * 35) / 1000; // litreye çevir
    
    // Aktivite seviyesine göre ayarlama
    double activityMultiplier = switch (activityLevel) {
      'sedentary' => 1.0,
      'light' => 1.1,
      'moderate' => 1.2,
      'active' => 1.3,
      _ => 1.0,
    };
    
    return (baseWater * activityMultiplier).clamp(1.5, 4.0); // 1.5-4 litre arası
  }

  // BMR hesaplama (Basal Metabolic Rate - Harris-Benedict)
  double get bmr {
    // Erkek formülü kullanıyoruz (basitleştirme için)
    return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
  }

  // Günlük kalori ihtiyacı
  double get dailyCalorieNeeds {
    double activityMultiplier = switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      _ => 1.2,
    };
    
    double goalMultiplier = switch (goal) {
      'weight_loss' => 0.8,
      'weight_gain' => 1.2,
      _ => 1.0,
    };
    
    return bmr * activityMultiplier * goalMultiplier;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'goal': goal,
      'activityLevel': activityLevel,
      'dailyWaterTarget': dailyWaterTarget,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      age: map['age']?.toInt() ?? 0,
      weight: map['weight']?.toDouble() ?? 0.0,
      height: map['height']?.toDouble() ?? 0.0,
      goal: map['goal'] ?? 'maintain',
      activityLevel: map['activityLevel'] ?? 'sedentary',
      dailyWaterTarget: map['dailyWaterTarget']?.toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
} 