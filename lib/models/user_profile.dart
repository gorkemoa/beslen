import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final int age;
  final double weight;
  final double height;
  final String gender;
  final String activityLevel;
  final String goal;
  final double dailyWaterTarget;
  final DateTime? lastSleepTime; // Son uyku zamanı
  final DateTime? lastWakeUpTime; // Son uyanma zamanı
  final DateTime? lastResetDate; // Son sıfırlama tarihi
  final double? lastSleepDuration; // Son uyku süresi (saat)

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.dailyWaterTarget,
    this.lastSleepTime,
    this.lastWakeUpTime,
    this.lastResetDate,
    this.lastSleepDuration,
  });


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
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'activityLevel': activityLevel,
      'goal': goal,
      'dailyCalorieNeeds': dailyCalorieNeeds,
      'dailyWaterTarget': dailyWaterTarget,
      'lastSleepTime': lastSleepTime != null 
          ? Timestamp.fromDate(lastSleepTime!)
          : null,
      'lastWakeUpTime': lastWakeUpTime != null 
          ? Timestamp.fromDate(lastWakeUpTime!)
          : null,
      'lastResetDate': lastResetDate != null 
          ? Timestamp.fromDate(lastResetDate!)
          : null,
      'lastSleepDuration': lastSleepDuration,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
      gender: map['gender'] ?? '',
      activityLevel: map['activityLevel'] ?? '',
      goal: map['goal'] ?? '',
      dailyWaterTarget: (map['dailyWaterTarget'] ?? 2.5).toDouble(),
      lastSleepTime: map['lastSleepTime'] != null 
          ? (map['lastSleepTime'] as Timestamp).toDate()
          : null,
      lastWakeUpTime: map['lastWakeUpTime'] != null 
          ? (map['lastWakeUpTime'] as Timestamp).toDate()
          : null,
      lastResetDate: map['lastResetDate'] != null 
          ? (map['lastResetDate'] as Timestamp).toDate()
          : null,
      lastSleepDuration: map['lastSleepDuration']?.toDouble(),
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    double? weight,
    double? height,
    String? gender,
    String? activityLevel,
    String? goal,
    double? dailyWaterTarget,
    DateTime? lastSleepTime,
    DateTime? lastWakeUpTime,
    DateTime? lastResetDate,
    double? lastSleepDuration,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      dailyWaterTarget: dailyWaterTarget ?? this.dailyWaterTarget,
      lastSleepTime: lastSleepTime ?? this.lastSleepTime,
      lastWakeUpTime: lastWakeUpTime ?? this.lastWakeUpTime,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      lastSleepDuration: lastSleepDuration ?? this.lastSleepDuration,
    );
  }
} 