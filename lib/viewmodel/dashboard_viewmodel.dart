import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/food_item.dart';
import '../models/daily_summary.dart';
import '../service/firebase_service.dart';
import '../service/gemini_ai_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiAIService _aiService = GeminiAIService();

  UserProfile? _userProfile;
  List<FoodItem> _todaysFoods = [];
  List<String> _dailyRecommendations = [];
  DailySummary? _todaySummary;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<FoodItem> get todaysFoods => _todaysFoods;
  List<String> get dailyRecommendations => _dailyRecommendations;
  DailySummary? get todaySummary => _todaySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Günlük istatistikler
  double get todayCalories => _todaysFoods.fold(0.0, (sum, food) => sum + food.totalCalories);
  double get todayProtein => _todaysFoods.fold(0.0, (sum, food) => sum + food.totalProtein);
  double get todayCarbs => _todaysFoods.fold(0.0, (sum, food) => sum + food.totalCarbohydrates);
  double get todayFat => _todaysFoods.fold(0.0, (sum, food) => sum + food.totalFat);

  double get calorieProgress {
    if (_userProfile == null) return 0.0;
    final target = _userProfile!.dailyCalorieNeeds;
    return target > 0 ? (todayCalories / target) * 100 : 0.0;
  }

  String get calorieProgressText {
    if (_userProfile == null) return '0 / 0 kalori';
    return '${todayCalories.toInt()} / ${_userProfile!.dailyCalorieNeeds.toInt()} kalori';
  }

  Future<void> initialize() async {
    await loadUserData();
  }

  Future<void> loadUserData() async {
    _setLoading(true);
    _clearError();

    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Kullanıcı profilini yükle
      await _loadUserProfile(userId);
      
      // Bugünün yemeklerini yükle
      await _loadTodaysFoods(userId);
      
      // Günlük önerileri yükle
      await _loadDailyRecommendations();

    } catch (e) {
      _setError('Veriler yüklenemedi: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      _userProfile = await _firebaseService.getUserProfile(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Profil yüklenirken hata: $e');
    }
  }

  Future<void> _loadTodaysFoods(String userId) async {
    try {
      _todaysFoods = await _firebaseService.getTodaysFoods(userId);
      
      // Günlük özeti oluştur
      _createTodaySummary(userId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Bugünün yemekleri yüklenirken hata: $e');
    }
  }

  void _createTodaySummary(String userId) {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    _todaySummary = DailySummary(
      id: '${userId}_$dateStr',
      userId: userId,
      date: today,
      foods: _todaysFoods,
      targetCalories: _userProfile?.dailyCalorieNeeds,
    );
  }

  Future<void> _loadDailyRecommendations() async {
    try {
      final targetCalories = _userProfile?.dailyCalorieNeeds ?? 2000;
      _dailyRecommendations = await _aiService.getDailyRecommendations(_todaysFoods, targetCalories);
      notifyListeners();
    } catch (e) {
      debugPrint('Günlük öneriler yüklenirken hata: $e');
      // Varsayılan öneriler
      _dailyRecommendations = [
        'Günde en az 5 porsiyon sebze ve meyve tüketin',
        'Bol su için, günde en az 8 bardak su içmeye çalışın',
        'Öğün aralarında sağlıklı atıştırmalıklar tercih edin',
        'Porsiyon miktarlarınıza dikkat edin',
        'Düzenli öğün saatlerine uyun'
      ];
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await loadUserData();
  }

  Future<void> deleteFoodItem(String foodId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.deleteFoodItem(foodId);
      await refreshData();
    } catch (e) {
      _setError('Yemek silinemedi: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
} 