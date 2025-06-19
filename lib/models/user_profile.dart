class UserProfile {
  final String id;
  final String name;
  final String email;
  final int age;
  final double weight; // kg
  final double height; // cm
  final String goal; // "lose_weight", "gain_weight", "maintain"
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
      weight: (json['weight'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      goal: json['goal'] ?? 'maintain',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'weight': weight,
      'height': height,
      'goal': goal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  double get dailyCalorieNeeds {
    // Basit kalori hesaplaması (Harris-Benedict formülü)
    double bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    return bmr * 1.5; // Orta düzeyde aktif
  }

  UserProfile copyWith({
    String? name,
    String? email,
    int? age,
    double? weight,
    double? height,
    String? goal,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 