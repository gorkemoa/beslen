import 'package:cloud_firestore/cloud_firestore.dart';

class SleepRecord {
  final String id;
  final String userId;
  final DateTime sleepTime;
  final DateTime? wakeUpTime;
  final double? duration; // Uyku süresi (saat)
  final String quality; // 'poor', 'fair', 'good', 'excellent'
  final String? notes;
  final DateTime createdAt;

  SleepRecord({
    required this.id,
    required this.userId,
    required this.sleepTime,
    this.wakeUpTime,
    this.duration,
    this.quality = 'good',
    this.notes,
    required this.createdAt,
  });

  // Uyku kalitesi belirleme
  String get qualityText {
    switch (quality) {
      case 'poor':
        return 'Kötü';
      case 'fair':
        return 'Orta';
      case 'good':
        return 'İyi';
      case 'excellent':
        return 'Mükemmel';
      default:
        return 'İyi';
    }
  }

  // Uyku süresine göre otomatik kalite belirleme
  static String calculateQuality(double durationHours) {
    if (durationHours < 5) return 'poor';
    if (durationHours < 6.5) return 'fair';
    if (durationHours <= 9) return 'good';
    return 'excellent';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sleepTime': Timestamp.fromDate(sleepTime),
      'wakeUpTime': wakeUpTime != null ? Timestamp.fromDate(wakeUpTime!) : null,
      'duration': duration,
      'quality': quality,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map, String id) {
    return SleepRecord(
      id: id,
      userId: map['userId'] ?? '',
      sleepTime: (map['sleepTime'] as Timestamp).toDate(),
      wakeUpTime: map['wakeUpTime'] != null 
          ? (map['wakeUpTime'] as Timestamp).toDate() 
          : null,
      duration: map['duration']?.toDouble(),
      quality: map['quality'] ?? 'good',
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  SleepRecord copyWith({
    String? userId,
    DateTime? sleepTime,
    DateTime? wakeUpTime,
    double? duration,
    String? quality,
    String? notes,
    DateTime? createdAt,
  }) {
    return SleepRecord(
      id: id,
      userId: userId ?? this.userId,
      sleepTime: sleepTime ?? this.sleepTime,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      duration: duration ?? this.duration,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 