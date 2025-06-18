class WaterIntake {
  final String id;
  final String userId;
  final double amount; // ml cinsinden
  final DateTime timestamp;
  final String? note; // Opsiyonel not

  WaterIntake({
    required this.id,
    required this.userId,
    required this.amount,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'note': note,
    };
  }

  static WaterIntake fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      note: map['note'],
    );
  }

  // Bugün mü kontrol et
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
           timestamp.month == now.month &&
           timestamp.day == now.day;
  }
} 