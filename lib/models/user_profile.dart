class UserProfile {
  final String id;
  final String? email;
  final String name;
  final int age;
  final double weight; // kg
  final double height; // cm
  final Gender gender;
  final ActivityLevel activityLevel;
  final List<String> allergies;
  final List<String> dietaryRestrictions;
  final double dailyCalorieGoal;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  UserProfile({
    required this.id,
    this.email,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
    this.allergies = const [],
    this.dietaryRestrictions = const [],
    required this.dailyCalorieGoal,
    this.isAnonymous = false,
    required this.createdAt,
    this.lastUpdated,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      email: map['email'],
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
      gender: Gender.values.firstWhere(
        (e) => e.toString() == map['gender'],
        orElse: () => Gender.other,
      ),
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.toString() == map['activityLevel'],
        orElse: () => ActivityLevel.moderate,
      ),
      allergies: List<String>.from(map['allergies'] ?? []),
      dietaryRestrictions: List<String>.from(map['dietaryRestrictions'] ?? []),
      dailyCalorieGoal: (map['dailyCalorieGoal'] ?? 0.0).toDouble(),
      isAnonymous: map['isAnonymous'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastUpdated: map['lastUpdated'] != null ? DateTime.parse(map['lastUpdated']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender.toString(),
      'activityLevel': activityLevel.toString(),
      'allergies': allergies,
      'dietaryRestrictions': dietaryRestrictions,
      'dailyCalorieGoal': dailyCalorieGoal,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    double? weight,
    double? height,
    Gender? gender,
    ActivityLevel? activityLevel,
    List<String>? allergies,
    List<String>? dietaryRestrictions,
    double? dailyCalorieGoal,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      allergies: allergies ?? this.allergies,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  double get bmi => weight / ((height / 100) * (height / 100));

  double calculateBMR() {
    // Mifflin-St Jeor Equation
    double bmr = 10 * weight + 6.25 * height - 5 * age;
    return gender == Gender.male ? bmr + 5 : bmr - 161;
  }

  double calculateTDEE() {
    double bmr = calculateBMR();
    return bmr * activityLevel.multiplier;
  }

  List<String> checkAllergens(List<String> foodAllergens) {
    return allergies.where((allergy) => 
      foodAllergens.any((allergen) => 
        allergen.toLowerCase().contains(allergy.toLowerCase())
      )
    ).toList();
  }
}

enum Gender {
  male,
  female,
  other,
}

enum ActivityLevel {
  sedentary(1.2, 'Hareketsiz'),
  light(1.375, 'Hafif Aktif'),
  moderate(1.55, 'Orta Aktif'),
  active(1.725, 'Aktif'),
  veryActive(1.9, 'Çok Aktif');

  const ActivityLevel(this.multiplier, this.description);
  final double multiplier;
  final String description;
} 